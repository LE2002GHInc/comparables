CREATE TABLE EMPLOYEES(	
        employee_id         NUMBER(6,0), 
        first_name          VARCHAR2(20), 
        last_name           VARCHAR2(25) NOT NULL ENABLE, 
        email               VARCHAR2(25) NOT NULL ENABLE, 
        phone_number        VARCHAR2(20), 
        hire_date           DATE NOT NULL ENABLE, 
        job_id              VARCHAR2(10) NOT NULL ENABLE, 
        salary              NUMBER(8,2), 
        commission_pct      NUMBER(2,2), 
        manager_id          NUMBER(6,0), 
        department_id       NUMBER(4,0), 
        address_id          NUMBER, 
        CONSTRAINT PK_EMP_ID PRIMARY KEY (EMPLOYEE_ID)
);
/

--INSERT INTO employees SELECT * FROM HR.bank_employees;
--/
CREATE TABLE business_process(
        process_id  NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 100 INCREMENT by 1)
   ,    name        VARCHAR2(500) not null
   ,    descrbtn    CLOB
   ,    mgr         NUMBER DEFAULT 115 CONSTRAINT fk_bp2emp REFERENCES employees(employee_id)
   ,    status      VARCHAR2(50) DEFAULT 'ACTIVE'
   ,    created_on  DATE DEFAULT SYSDATE
   ,    created_by  number 
   ,    CONSTRAINT pk_process_id PRIMARY KEY(process_id)
   ,    CONSTRAINT uq_proc_name UNIQUE(name)
);
/
ALTER TABLE business_process
ADD (how_to_doc CLOB, wiki_link URITYPE);
/
ALTER TABLE business_process ADD effort_hrs INTERVAL DAY (6) TO SECOND (5)
DEFAULT INTERVAL '15' DAY;
/

CREATE TABLE activity(
        activity_id     NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 0 INCREMENT by 1 MINVALUE 0)
    ,   name            VARCHAR2(500) not null
    ,   activity_mgr    NUMBER DEFAULT 111 CONSTRAINT fk_activ2emp REFERENCES employees(employee_id)
    ,   short_desc      VARCHAR2(2000) 
    ,   how_to          CLOB
    ,   status          VARCHAR2(50) DEFAULT 'ACTIVE'
    ,   created_on      DATE DEFAULT SYSDATE
    ,   created_by      number 
    ,   CONSTRAINT pk_proc_activity_id PRIMARY KEY(activity_id)
    ,   CONSTRAINT uq_activity_name UNIQUE(name)
);
/
ALTER TABLE activity ADD effort_hrs INTERVAL DAY (6) TO SECOND (5);
/
CREATE TABLE status_change_tracker(
        table_name          VARCHAR2(50)
  ,     status_col_name     VARCHAR2(50)
  ,     from_val            VARCHAR2(50)
  ,     to_val              VARCHAR2(50)
  ,     change_dt           DATE DEFAULT SYSDATE
  ,     changed_by          VARCHAR2(45) 
);
/
ALTER TABLE status_change_tracker ADD (pk_column VARCHAR(50),pk_col_val VARCHAR2(100));
/
CREATE TYPE number_ttyp AS TABLE OF NUMBER;
/
CREATE TABLE process_activities(
        process_id NUMBER CONSTRAINT fk_process_activ2proc REFERENCES business_process
   ,    activity_id  NUMBER CONSTRAINT fk_process_activ2activity REFERENCES activity
   ,    priority  number
   ,    dependent_list number_ttyp
) NESTED TABLE dependent_list STORE AS activity_deplist;
/
CREATE TABLE business_case(
         case_number     NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT by 1 MINVALUE 0) primary key
     ,   process_id      NUMBER CONSTRAINT fk_bizcase2proc REFERENCES business_process(process_id)
     ,   status          VARCHAR2(50) DEFAULT 'PENDING'
     ,   created_on      DATE DEFAULT SYSDATE
     ,   completed_on    DATE
     ,   created_by      NUMBER DEFAULT 112 CONSTRAINT fk_bizcase2emp REFERENCES employees(employee_id) 
     ,   outcome         VARCHAR2(100) CONSTRAINT ck_bizcaseoutcome CHECK(UPPER(outcome) IN ('APPROVED','REJECTED','UNKNOWN')) 
     ,   CONSTRAINT ck_statusvals CHECK(UPPER(status) in ('PENDING','IN PROGRESS','COMPLETED','WAITING'))
);
/
CREATE TABLE workflow(
        case_number     NUMBER CONSTRAINT fk_workflow2bzcase REFERENCES business_case   
    ,   activity_id     NUMBER CONSTRAINT fk_workflow2activity REFERENCES activity    
    ,   created_on      DATE DEFAULT SYSDATE
    ,   completed_on    DATE
    ,   created_by      number 
    ,   assigned_to     NUMBER CONSTRAINT fk_workflow2emp REFERENCES employees(employee_id)
    ,   assigned_on     DATE 
    ,   status          VARCHAR2(50) DEFAULT 'PENDING' CONSTRAINT ck_wf_status CHECK(UPPER(status) in ('PENDING','IN PROGRESS','COMPLETED','WAITING'))
    ,   CONSTRAINT uq_wfcase UNIQUE(case_number,activity_id)
);
/
ALTER TABLE workflow ADD (last_updated_on DATE, last_updated_by NUMBER);
/
ALTER TABLE business_case MODIFY outcome DEFAULT 'UNKNOWN';
/


