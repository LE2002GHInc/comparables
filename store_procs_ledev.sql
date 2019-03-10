/******************************************************************************************************************************
                                                        Data Objects
******************************************************************************************************************************/
CREATE OR REPLACE TYPE activity_objtyp AS OBJECT(
        activity_id        NUMBER
    ,   activity_priority  NUMBER
    ,   depndnt_list       number_ttyp
);

CREATE OR REPLACE TYPE activity_ttyp IS TABLE OF activity_objtyp;
/******************************************************************************************************************************
                                                Pkg Specification
                                        ********************************/
CREATE OR REPLACE PACKAGE process_mgmt_pkg
AS
  PROCEDURE create_bzproc_definition(
        p_process_name VARCHAR2
    ,   p_short_desc VARCHAR2
    ,   p_howto VARCHAR2
    ,   p_wiki  URITYPE
    ,   p_mgr NUMBER
  );

   PROCEDURE create_bizactivity(
            p_activity_name VARCHAR2
        ,   p_short_desc VARCHAR2
        ,   p_mgr NUMBER
   );
   
   PROCEDURE create_business_process(
            p_process_id          NUMBER
        ,   p_activity_list       activity_ttyp       
   );
END process_mgmt_pkg;

/*****************************************    Body   *******************************************************/

CREATE OR REPLACE PACKAGE BODY process_mgmt_pkg
AS
  PROCEDURE create_bzproc_definition(
        p_process_name VARCHAR2
    ,   p_short_desc VARCHAR2
    ,   p_howto VARCHAR2
    ,   p_wiki  URITYPE
    ,   p_mgr NUMBER
  )IS
     v_how_to CLOB;
  BEGIN
      INSERT INTO business_process(name,descrbtn,mgr,created_by,wiki_link,how_to_doc)
      VALUES(p_process_name,p_short_desc,p_mgr,p_mgr,p_wiki,empty_clob())
      RETURNING how_to_doc INTO v_how_to;
      
      IF(p_howto IS NOT NULL) THEN
         dbms_lob.write(v_how_to,length(p_howto),1,p_howto);
      END IF;
  END;

   PROCEDURE create_bizactivity(
            p_activity_name VARCHAR2
        ,   p_short_desc VARCHAR2
        ,   p_mgr NUMBER
   )IS
   
   BEGIN
     INSERT INTO activity(name,short_desc,created_by,activity_mgr)
     VALUES(p_activity_name,p_short_desc,p_mgr,p_mgr);
   END;
   
   PROCEDURE create_business_process(
            p_process_id          NUMBER 
        ,   p_activity_list       activity_ttyp 
   )IS
      v_cntrl_val NUMBER := 0;
      process_already_exist_exception EXCEPTION;
   BEGIN
      BEGIN
          SELECT 1 INTO v_cntrl_val FROM business_process WHERE process_id = p_process_id;
          
          SELECT v_cntrl_val + 3 INTO v_cntrl_val FROM dual
          WHERE EXISTS (SELECT NULL FROM process_activities WHERE process_id = p_process_id);
      EXCEPTION
         WHEN no_data_found THEN null;
      END;
      
      IF (v_cntrl_val = 0) THEN
         RAISE process_already_exist_exception;
      ELSE 
          IF(v_cntrl_val > 1) THEN      
             DELETE FROM process_activities WHERE process_id = p_process_id;
          END IF;
          
          FOR i IN p_activity_list.FIRST..p_activity_list.LAST 
          LOOP
              INSERT INTO process_activities(process_id,activity_id,priority,dependent_list)
              VALUES(p_process_id,p_activity_list(i).activity_id,p_activity_list(i).activity_priority,p_activity_list(i).depndnt_list);      
          END LOOP;              
      END IF;
   EXCEPTION
      WHEN process_already_exist_exception THEN
         DBMS_OUTPUT.PUT_LINE('This process does not exist');
   END;
END process_mgmt_pkg;

CREATE OR REPLACE PACKAGE case_mgt_pkg
AS
  PROCEDURE create_business_case(
     p_process_id NUMBER
   , p_user_id NUMBER DEFAULT 100
   , p_case_id OUT NUMBER
  );
  
  PROCEDURE assign_task(
     p_case#          NUMBER
   , p_activity_id    NUMBER
   , p_assignee       NUMBER
  );

  PROCEDURE track_status_changes(
        p_tab VARCHAR2
      , p_status_col VARCHAR2
      , p_pkcol VARCHAR2
      , p_pkval VARCHAR2
      , p_from_val VARCHAR2
      , p_toval VARCHAR2
      , p_user_id NUMBER DEFAULT 110
  );
  
   PROCEDURE update_task(
        p_case#          NUMBER
     ,  p_activity_id    NUMBER
     ,  p_assignee       NUMBER DEFAULT NULL
     ,  p_status         VARCHAR2 DEFAULT NULL
     ,  p_outcome        VARCHAR2 DEFAULT NULL
    );  
END case_mgt_pkg;


CREATE OR REPLACE PACKAGE BODY case_mgt_pkg
AS
    PROCEDURE create_business_case(
         p_process_id NUMBER
       , p_user_id NUMBER DEFAULT 100
       , p_case_id OUT NUMBER
    )AS
       v_case_number NUMBER;
    BEGIN
        INSERT INTO business_case(process_id,created_by)
        VALUES(p_process_id,p_user_id) RETURNING case_number INTO v_case_number;
    
        INSERT INTO workflow(case_number,activity_id,created_by)
        SELECT v_case_number,pa.activity_id,p_user_id
        FROM process_activities pa WHERE pa.process_id = p_process_id order by pa.priority;
        
        p_case_id := v_case_number;
    END;

    PROCEDURE update_task(
        p_case#          NUMBER
     ,  p_activity_id    NUMBER
     ,  p_assignee       NUMBER DEFAULT NULL
     ,  p_status         VARCHAR2 DEFAULT NULL
     ,  p_outcome        VARCHAR2 DEFAULT NULL
    )IS   
       v_cntrl_val NUMBER;
       v_status workflow.status%TYPE;
       v_assigned NUMBER := 0; 
       completed_task_exception EXCEPTION;
       MISSING_DATA_EXCEPTION EXCEPTION;
    BEGIN
       SELECT status,case when assigned_to is not null then 1 else 0 end
       INTO v_status,v_assigned 
       FROM workflow 
       WHERE case_number =  p_case# and activity_id = p_activity_id;
       
       IF v_status = 'COMPLETED' THEN
          RAISE completed_task_exception;
       END IF;
       
       IF v_assigned = 1 THEN
           UPDATE workflow 
           SET  status          = p_status
            ,   last_updated_on = sysdate
           WHERE case_number =  p_case# and activity_id = p_activity_id;
           
           IF p_status = 'COMPLETED' THEN
              UPDATE workflow SET completed_on = sysdate 
              WHERE case_number =  p_case# and activity_id = p_activity_id;
              
              UPDATE business_case SET status = 'COMPLETED', outcome = p_outcome
              WHERE NOT EXISTS(SELECT NULL FROM workflow
                               WHERE case_number =  p_case# and status <> 'COMPLETED')
              AND case_number =  p_case#; 
           END IF;
       ELSE
          IF p_assignee IS NULL THEN 
             RAISE missing_data_exception;
          END IF;
          
          UPDATE workflow 
          SET  status          = p_status 
          ,    assigned_on     = sysdate 
          ,    assigned_to     = p_assignee
          ,    last_updated_on = sysdate
          WHERE case_number =  p_case# and activity_id = p_activity_id;
       END IF;          
    END;
    
    PROCEDURE assign_task(
         p_case#          NUMBER
       , p_activity_id    NUMBER
       , p_assignee       NUMBER
    )AS
      v_cntrl_val NUMBER := 0;
      v_uncompleted_dep_activities EXCEPTION;
    BEGIN
       SELECT 1 INTO v_cntrl_val FROM dual
       WHERE NOT EXISTS(
                           WITH src AS(
                                 SELECT pa.process_id,pa.activity_id,dl.column_value
                                 FROM process_activities pa, table(pa.dependent_list) dl
                                 WHERE activity_id = p_activity_id
                           )
                           SELECT 'exists' flag
                           FROM business_case bc
                           JOIN workflow wf on bc.case_number = wf.case_number
                           JOIN src s on s.process_id = bc.process_id AND s.column_value = wf.activity_id
                           WHERE bc.case_number = p_case# AND UPPER(wf.status) != 'COMPLETED'
                    );       
       
       -- IF v_cntrl_val = 1 THEN RAISE v_uncompleted_dep_activities; END IF;       
       update_task(p_case#,p_activity_id,p_assignee,'IN PROGRESS');
    EXCEPTION
       WHEN no_data_found THEN 
          -- log error 
          dbms_output.put_line('There are uncompleted dependent activities, you cannot proceed without completing them');          
    END;

    PROCEDURE track_status_changes(
        p_tab VARCHAR2
      , p_status_col VARCHAR2
      , p_pkcol VARCHAR2
      , p_pkval VARCHAR2
      , p_from_val VARCHAR2
      , p_toval VARCHAR2
      , p_user_id NUMBER DEFAULT 110
    ) 
    IS
    BEGIN
      INSERT INTO status_change_tracker(table_name,status_col_name,pk_column,pk_col_val,from_val,to_val,changed_by)
      VALUES(p_tab,p_status_col,p_pkcol,p_pkval,p_from_val,p_toval,p_user_id);
    END;    
END case_mgt_pkg;
/

CREATE OR REPLACE TRIGGER wf_status_trg
AFTER UPDATE OF status ON workflow
FOR EACH ROW
DECLARE
   v_pkval VARCHAR2(100);
BEGIN
  v_pkval := :old.case_number||','||:old.activity_id;
  
  case_mgt_pkg.track_status_changes(p_tab => 'Workflow'
                     , p_status_col => 'Status'                     
                     , p_pkcol => 'Case# Activity'                       
                     , p_pkval => v_pkval
                     , p_from_val => :old.status
                     , p_toval => :new.status);
END;




