BEGIN
    EXECUTE IMMEDIATE 'DROP USER aq_adm CASCADE';
    EXECUTE IMMEDIATE 'DROP USER aq_dev CASCADE';
    EXECUTE IMMEDIATE 'DROP TABLESPACE aq_tbs INCLUDING CONTENTS AND DATAFILES';
EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line('One or more users do not exist in this database');
END;
/
CREATE TABLESPACE aq_tbs DATAFILE 'aq_f1.dbf' SIZE 200M AUTOEXTEND ON MAXSIZE UNLIMITED ONLINE;
/
CREATE USER aq_adm IDENTIFIED BY oracle DEFAULT TABLESPACE aq_tbs;
/
ALTER USER aq_adm QUOTA UNLIMITED ON aq_tbs;
/
GRANT DBA, CREATE ANY TYPE TO aq_adm;
/
GRANT EXECUTE ON DBMS_AQADM TO aq_adm;
/
GRANT EXECUTE ON DBMS_AQ TO aq_adm;
/
GRANT aq_administrator_role TO aq_adm;
/
BEGIN
    DBMS_AQADM.GRANT_SYSTEM_PRIVILEGE(
                    privilege       => 'MANAGE_ANY',
                    grantee         => 'aq_adm',
                    admin_option    => FALSE);
END;
/
CREATE USER aq_dev IDENTIFIED BY oracle;
/
GRANT EXECUTE ON dbms_aq TO aq_dev;
/
GRANT CREATE SESSION TO aq_dev;
/
ALTER USER aq_dev DEFAULT TABLESPACE aq_tbs;
/
ALTER USER aq_dev QUOTA UNLIMITED ON aq_tbs;
/
ALTER USER aq_dev QUOTA 20M ON users;
/