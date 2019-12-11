CREATE OR REPLACE FUNCTION k_os_transaction.kos_func_delete_client_contact(p_contact_id numeric, p_user_email text)
 RETURNS TABLE(contact_id numeric, error_code text, user_message text, api_message text, basic_requeriments text)
 LANGUAGE plpgsql
AS $function$

/*********************************************************************************
 Objetivo: Función que se encarga de eliminar el registro del contacto del cliente
 Creación: ABEL VARGAS 06/11/2019
 Modificación: 
**********************************************************************************/
declare
	v_contact_id 				numeric;
	v_use_id numeric;
    /*PARA ERRORES*/
    v_error_code            text;
    v_api_message           text;
    v_user_message          text;
    v_basic_requeriments    text;
    v_state                 text;
    v_msg                   text;
    v_detail                text;

begin
	
	if p_contact_id is null 
	then 
		raise exception 'Error: el id del contacto es nulo'; 
	end if;
	
	select kic_id 
	  into v_contact_id
	  from k_os_transaction.kos_tbl_transaction_contact
	 where kic_id = p_contact_id;
	 
	select use_id
	  into v_use_id
	  from "user".usr_tbl_user
	 where lower(trim(use_email)) = lower(trim(p_user_email));
	 
	if v_use_id is null then
		v_error_code = 'M0008';									   
		raise exception 'Error: email de usuario invalido';
	end if; 
	
	  if v_contact_id is not null then  
			update k_os_transaction.kos_tbl_transaction_contact
			   set kic_is_active = 0,
			       kic_last_update = current_timestamp,
				   kic_upd_use_id = v_use_id
			 where kic_id = p_contact_id;
	  else 
			raise exception 'Error: No existe el contacto'; 

	  end if;
 
  		return query 
        select
            v_contact_id,
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
                configuration.cnf_func_post_error_function_log('SELECT * FROM k_os_configuration.kos_func_delete_client_contact('||case when p_contact_id is null then 'null' else p_contact_id::text end || ', ' ||
															        															   case when p_user_email is null then 'null' else p_user_email::text end || ')',msg_code, msg_user_message, msg_api_message, msg_basic_requirement, v_detail, v_state, v_msg)
                from
                        configuration.cnf_tbl_message
                where
                        msg_code = case 
                                      when v_error_code is null then 'M0000' 
                                      else v_error_code 
                                    end;
                        
            RETURN QUERY 
                    select
                        null::numeric,
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
