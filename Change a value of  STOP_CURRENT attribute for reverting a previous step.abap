******************************************************************
* This program enables stop_current to revert a previous step.
* If you want to revert STOP_CURRENT to 4 steps ago, then just run 
* the program 4 times.
******************************************************************
DATA:
  lr_action_param TYPE REF TO /scmtms/s_tor_a_set_handl_exec,
  lt_key          TYPE /bobf/t_frw_key.

SELECT b~db_key AS key
  FROM /scmtms/d_torrot AS a
  JOIN /scmtms/d_torstp AS b
   ON b~parent_key = a~db_key
  AND ( b~stop_current = 'L' OR b~stop_current = 'C' )
  WHERE a~tor_id IN @s_torid[]
  INTO TABLE @lt_key.


DATA(lo_srv) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).
DATA(lo_tra) = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).

CREATE DATA lr_action_param.
lr_action_param->revoke_status = abap_true.
lr_action_param->set_handl_exec_stop = abap_true.
lr_action_param->propagate_status    = abap_true.
*  lr_action_param->ui_action_source    = abap_true.
lo_srv->do_action(
  EXPORTING
    iv_act_key    = /scmtms/if_tor_c=>sc_action-stop-set_handling_execution
    it_key        = lt_key  " here is stop keys that you want to revoke evens.
    is_parameters = lr_action_param
  IMPORTING
    et_failed_key = DATA(lt_failed_key)
    eo_change     = DATA(lo_change)
    eo_message    = DATA(lo_message) ).

IF lt_failed_key IS NOT INITIAL.
  WRITE: 'FAILED'.
  lo_tra->cleanup( ).
  RETURN.
ENDIF.

lo_tra->save(
  IMPORTING
    ev_rejected = DATA(lv_rejected)
    eo_change   = DATA(lo_chage2)
    eo_message  = DATA(lo_message2)
).
IF lv_rejected = abap_true.
  WRITE: 'REJECTED'.
ENDIF.

lo_tra->cleanup( ).
