BEGIN
   DBMS_AQADM.DROP_QUEUE_TABLE(queue_table => 'order_queue_table',force => true);
END;
/

DROP TABLE orders PURGE;
DROP TYPE orders_lisT_tt;
DROP TYPE order_ot;

--------------*****---------------------
CREATE TABLE orders( 
        order_id    NUMBER
    ,   order_total NUMBER
    ,   ordered     DATE 
);

CREATE OR REPLACE TYPE order_ot AS OBJECT(
        order_id    NUMBER
    ,   order_total NUMBER
    ,   ordered     DATE 
);
/

CREATE OR REPLACE TYPE orders_lisT_tt AS TABLE OF order_ot;
/

BEGIN
  DBMS_AQADM.CREATE_QUEUE_TABLE (queue_table => 'order_queue_table',queue_payload_type => 'order_ot',multiple_consumers => TRUE);
  DBMS_AQADM.CREATE_QUEUE (queue_name => 'order_queue', queue_table => 'order_queue_table');
  DBMS_AQADM.START_QUEUE('order_queue');
END;
/

CREATE OR REPLACE PROCEDURE process_order_from_queue(               
    context  RAW, 
    reginfo  SYS.AQ$_REG_INFO, 
    descr    SYS.AQ$_DESCRIPTOR, 
    payload  raw,
    payloadl NUMBER
) AS
   r_dequeue_options    DBMS_AQ.DEQUEUE_OPTIONS_T;
   r_message_properties DBMS_AQ.MESSAGE_PROPERTIES_T;
   v_message_handle     RAW(16);
   o_payload            order_ot;
   v_case_id            NUMBER;
BEGIN
   r_dequeue_options.msgid          := descr.msg_id;
   r_dequeue_options.consumer_name  := descr.consumer_name;
   
   DBMS_OUTPUT.PUT_LINE('Starting.........');
   /* Dequeue message from queue */
   DBMS_AQ.DEQUEUE(
          queue_name         => descr.queue_name,
          dequeue_options    => r_dequeue_options,
          message_properties => r_message_properties,
          payload            => o_payload,
          msgid              => v_message_handle
   );
   
   DBMS_OUTPUT.PUT_LINE('Dequeue => Successful');
   
   /* Dequeue message from queue */   
   INSERT INTO orders( order_id, order_total, ordered )
   VALUES ( o_payload.order_id,o_payload.order_total,o_payload.ordered);
   
   ledev.case_mgt_pkg.create_business_case(141,110,v_case_id);
   ledev.case_mgt_pkg.update_task(v_case_id,60,115,'COMPLETED',null);
   ledev.case_mgt_pkg.update_task(v_case_id,61,116,'IN PROGRESS',null);
   
   COMMIT;
   DBMS_OUTPUT.PUT_LINE('Insertion => Successful'); 
END;
/
   
DECLARE
   o_reg_info SYS.AQ$_REG_INFO;
BEGIN
   DBMS_AQADM.ADD_SUBSCRIBER (
      queue_name => 'order_queue',
      subscriber => SYS.AQ$_AGENT('order_queue_subscriber',NULL,NULL)
   );

   o_reg_info := SYS.AQ$_REG_INFO(
                         'AQ_ADM.ORDER_QUEUE:ORDER_QUEUE_SUBSCRIBER',
                         DBMS_AQ.NAMESPACE_AQ,
                         'plsql://aq_adm.process_order_from_queue?pr=0',
                         HEXTORAW('FF')
                 );
   DBMS_AQ.REGISTER (SYS.AQ$_REG_INFO_LIST(o_reg_info),1);
END;
/

CREATE OR REPLACE PROCEDURE enqueue_order(
            order_id NUMBER
        ,   order_total NUMBER
)AS
   r_enqueue_options    DBMS_AQ.ENQUEUE_OPTIONS_T;
   r_message_properties DBMS_AQ.MESSAGE_PROPERTIES_T;
   v_message_handle     RAW(16);
   o_payload            order_ot;
BEGIN

   o_payload := order_ot(order_id,order_total,sysdate);

   DBMS_AQ.ENQUEUE(
      queue_name         => 'order_queue',
      enqueue_options    => r_enqueue_options,
      message_properties => r_message_properties,
      payload            => o_payload,
      msgid              => v_message_handle
    );
END;
/

/**************************************************************************************************
CREATE type Message_typ as object( 
      subject VARCHAR2(30)
    , text    VARCHAR2(80)
);
/
BEGIN
    DBMS_AQADM.CREATE_QUEUE_TABLE( 
            queue_table         => 'objmsgs80_qtab',
            queue_payload_type  => 'Message_typ',
            multiple_consumers  => TRUE 
    );

    DBMS_AQADM.CREATE_QUEUE( 
            queue_name  => 'MSG_QUEUE',
            queue_table => 'objmsgs80_qtab'
    );

    DBMS_AQADM.START_QUEUE(queue_name => 'MSG_QUEUE');
END;
/


CREATE OR REPLACE PROCEDURE enqueue_msg( 
    p_msg in varchar2 
)AS
    enqueue_options     dbms_aq.enqueue_options_t;
    message_properties  dbms_aq.message_properties_t;
    message_handle      RAW(16);
    message             message_typ;
BEGIN
        message := message_typ('NORMAL MESSAGE', p_msg );
        
        dbms_aq.enqueue(queue_name          => 'msg_queue',
                        enqueue_options     => enqueue_options,
                        message_properties  => message_properties,
                        payload             => message,
                        msgid => message_handle);
END;
 /
 
create table message_table( subjct VARCHAR2(45),msg varchar2(80));
/

CREATE OR REPLACE PROCEDURE process_msg( 
    context     raw,
    reginfo     sys.aq$_reg_info,
    descr       sys.aq$_descriptor,
    payload     raw,
    payloadl    number
)AS
    dequeue_options     dbms_aq.dequeue_options_t;
    message_properties  dbms_aq.message_properties_t;
    message_handle      RAW(16);
    message             message_typ;
BEGIN
    dequeue_options.msgid := descr.msg_id;
    dequeue_options.consumer_name := descr.consumer_name;
    DBMS_AQ.DEQUEUE(
                    queue_name          => descr.queue_name,
                    dequeue_options     => dequeue_options,
                    message_properties  => message_properties,
                    payload             => message,
                    msgid               => message_handle);
    INSERT INTO message_table values(message.subject, 'Dequeued and processed "' || message.text || '"' );
END;
/

BEGIN
     dbms_aqadm.add_subscriber( 
                queue_name => 'msg_queue',
                subscriber => sys.aq$_agent( 'recipient', null, null ) 
     );
END;
/

BEGIN
    dbms_aq.register( 
            sys.aq$_reg_info_list(
                sys.aq$_reg_info('AQ_ADM.MSG_QUEUE:RECIPIENT'
                                 ,DBMS_AQ.NAMESPACE_AQ
                                 ,'plsql://aq_adm.process_msg'
                                 ,HEXTORAW('FF')) ) ,
            1 );
END;
*/
