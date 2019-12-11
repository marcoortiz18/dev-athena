CREATE OR REPLACE FUNCTION k_os_transaction.kos_func_delete_paperwork(p_file_id numeric, p_user_email text)
 RETURNS TABLE(file json, error_code text, user_message text, api_message text, basic_requeriments text)
 LANGUAGE plpgsql
AS $function$

/*********************************************************************************
 Objetivo: Función que se encarga de eliminar archivos asignados una inspeccion/transaccion
 Creación: ABEL VARGAS 07/11/2019
 Modificación: 
**********************************************************************************/
declare
    v_transacion_id         numeric;
    v_file_type             numeric;
    v_file                  json;
    v_use_id numeric;
    v_inspection_id numeric;
    v_active_files json;
    /*PARA ERRORES*/
    v_error_code            text;
    v_api_message           text;
    v_user_message          text;
    v_basic_requeriments    text;
    v_state                 text;
    v_msg                   text;
    v_detail                text;
begin
    
    if p_file_id is null 
    then
        raise exception 'Error: nulo';
    end if;
     
       
    select use_id
      into v_use_id
      from "user".usr_tbl_user
     where trim(lower(use_email)) = trim(lower(p_user_email));
    
    if v_use_id is null 
    then
        v_error_code = 'M0008';                                    
        raise exception 'Error: Email no existe';
    end if;
                                               
    if v_transacion_id is null then
        raise exception 'Error: transacion_id no existe';
    end if;

    update k_os_transaction.kos_tbl_transaction_paperwork
       set ktp_is_active = 0,
           ktp_last_update = current_timestamp,
           ktp_upd_use_id = v_use_id
     where ktp_id = p_file_id;
                                                 
    select json_agg(row_to_json(x.*))
      into v_active_files                       
      from (select ktp_id as file_id, 
                   ktp_name as file_name, 
                   ktp_url as file_url, 
                   kpt_name as file_type
              from k_os_transaction.kos_tbl_transaction_paperwork
        inner join k_os_configuration.kcn_tbl_transaction_paperwork_type
                on ktp_kpt_id = kpt_id
               and ktp_is_active = 1
             where ktp_id = p_file_id) x;
                                                 
        return query 
           select v_active_files::json,
                  null::text,
                  null::text,
                  null::text,
                  null::text;
          
EXCEPTION 
    WHEN others THEN
        GET STACKED DIAGNOSTICS
            v_state  = RETURNED_SQLSTATE,
            v_msg    = MESSAGE_TEXT,
            v_detail = PG_EXCEPTION_DETAIL;

            raise info '-- %',v_state;
            raise info '-- %',v_msg;
            raise info '-- %',v_detail;
            PERFORM 
                configuration.cnf_func_post_error_function_log(
                'SELECT * FROM k_os_configuration.kos_func_delete_paperwork('
                ||case when p_file_id is null then 'null' else p_file_id::text end  ||','
                ||case when p_user_email is null then 'null' else p_user_email::text end  ||')'
                ,msg_code, msg_user_message, msg_api_message, msg_basic_requirement, v_detail, v_state, v_msg)
                from configuration.cnf_tbl_message
                where msg_code = case 
                      when v_error_code is null then 'M0000' 
                      else v_error_code end;
                        
            RETURN QUERY 
                    select
                        null::json,
                        msg_code,
                        msg_user_message,
                        msg_api_message,
                        msg_basic_requirement
                    from configuration.cnf_tbl_message
                    where msg_code = case 
                    when v_error_code is null then 'M0000' 
                    else v_error_code 
                    end; 
END; 

$function$
;
