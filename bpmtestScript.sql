ALTER SESSION SET nls_date_format = 'dd-mon-yyyy hh:mi:ss';

WITH src AS(
    SELECT pa.process_id,pa.activity_id,dl.column_value
    FROM process_activities pa, table(pa.dependent_list) dl
)
SELECT  bp.process_id,bp.name "Process Name", e.first_name||' '||e.last_name "Process Mgr",A.activity_id, a.name Activity
   ,    pa.priority, e2.first_name||' '||e2.last_name activity_lead
   ,    LISTAGG(S.COLUMN_VALUE,',') WITHIN GROUP(ORDER BY S.process_id,s.column_value) dept_actv_id_list
   ,    LISTAGG(a2.name,',') WITHIN GROUP(ORDER BY S.process_id,s.column_value) dependent_activity_list
FROM business_process bp 
JOIN process_activities pa on pa.process_id = bp.process_id
JOIN activity a ON a.activity_id = pa.activity_id
JOIN employees e on e.employee_id = bp.mgr
JOIN employees e2 on e2.employee_id = a.activity_mgr
LEFT JOIN src s ON (S.process_id = bp.process_id and s.activity_id = a.activity_id)
LEFT JOIN activity a2 ON a2.activity_id = s.COLUMN_VALUE 
where bp.process_id = 141
GROUP BY bp.process_id, A.activity_id, bp.name, bp.mgr, a.name,pa.priority, a.activity_mgr, e.last_name, e.first_name,e2.last_name,e2.first_name
ORDER BY pa.priority ;

BEGIN case_mgt_pkg.create_business_case(141,110); end;
BEGIN case_mgt_pkg.assign_task(1,40,113); end;
BEGIN case_mgt_pkg.update_task(1,41,114,'IN PROGRESS',null); end;

GRANT EXECUTE ON case_mgt_pkg TO aq_adm;

begin process_mgmt_pkg.create_bzproc_definition('Order Process','Fulfilling orders placed',empty_clob(),null,115); end;
BEGIN process_mgmt_pkg.create_bizactivity('Place Order','Customer palcing order',113); end;
BEGIN process_mgmt_pkg.create_bizactivity('Submit Payment','Customer payment info',113); end;
BEGIN process_mgmt_pkg.create_bizactivity('Verify Payment','Provider verifies payment info',113); end;
BEGIN process_mgmt_pkg.create_bizactivity('Prepare shipment','Prepare shipment',113); end;
BEGIN process_mgmt_pkg.create_bizactivity('Ship items','Ship item to customers',113); end;


select * from business_process where name = 'Order Process';

select * from activity where activity_id > 46;

DECLARE
   activity_list activity_ttyp;
BEGIN
    activity_list := activity_ttyp(activity_objtyp(60,5,null),
                      activity_objtyp(61,6,number_ttyp(60)),
                      activity_objtyp(62,7,number_ttyp(61)),
                      activity_objtyp(63,8,number_ttyp(62)),
                      activity_objtyp(64,9,number_ttyp(63)));
    process_mgmt_pkg.create_business_process(141,activity_list);
END;
/


/**** User based search ****/

select lpad(bc.case_number,5,'0') Lodgement#,bp.name "Business Process",a.name Activity,wf.status,wf.created_on
  ,    e.first_name||' '||last_name assigned_to, wf.assigned_on, wf.completed_on
from workflow wf 
join business_case bc on bc.case_number = wf.case_number
join business_process bp on bp.process_id = bc.process_id
join activity a on A.activity_id = wf.activity_id
join process_activities pa on pa.activity_id = a.activity_id and pa.process_id = bp.process_id
left join employees e on e.employee_id = wf.assigned_to
where 1 = 1
-- and wf.assigned_to = 115
and wf.case_number = 1
order by wf.assigned_on, pa.process_id, pa.priority;


/*** Task based search **/

select lpad(bc.case_number,5,'0') Lodgement#,bp.name "Business Process",a.name Activity,a.activity_id, wf.status,wf.created_on
  ,    e.first_name||' '||last_name assigned_to, wf.assigned_on
from workflow wf 
join business_case bc on bc.case_number = wf.case_number
join business_process bp on bp.process_id = bc.process_id
join activity a on A.activity_id = wf.activity_id
join process_activities pa on pa.activity_id = a.activity_id and pa.process_id = bp.process_id
left join employees e on e.employee_id = wf.assigned_to
where wf.case_number = 3
order by wf.assigned_on, pa.process_id, pa.priority;

select * from business_process e;
select * from activity;
select * from process_activities;

select * from business_case;
select * from employees;

select * from workflow WHERE case_number = 1;
SELECT * FROM status_change_tracker;

select * from departments;

select * from orders;

