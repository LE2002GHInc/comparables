EXEC enqueue_order(10005, 507.5);

commit;

SELECT * FROM dual;

select * from reg$; 

select * from dba_triggers
where trigger_type = 'AFTER EVENT' and to_char(trigger_body) = '%LOGON%';

SELECT u.username, sr.subscription_name, sr.location_name
FROM dba_subscr_registrations sr, dba_users u
WHERE u.user_id = sr.user#;
   
select * from order_queue_table;
select * from aq$_order_queue_table_s;
select * from aq$_order_queue_table;

select * from orders;


select * from dba_queues where owner = 'ADMIN' AND queue_type = 'EXCEPTION_QUEUE';


SELECT * FROM user_subscr_registrations;
select * from dba_queue_schedules;

select * from v$process where pname like 'J%';

select * from message_table;

