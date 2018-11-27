BEGIN
   EXECUTE IMMEDIATE 'DROP USER ledev CASCADE';
EXCEPTION
   WHEN others THEN
   dbms_output.put_line('Ouch, the user does not exist');
END;
/
CREATE USER ledev IDENTIFIED BY oracle;
/
GRANT CONNECT, RESOURCE, DBA TO ledev;
/

CREATE TABLE employee as
select * from hr.bank_employees where 1 = 2;

CREATE TABLE departments as
select * from hr.departments where 1 = 2;

CREATE TABLE jobs as
select * from hr.jobs where 1 = 2;

CREATE TABLE spatial_object (
  spatial_id     NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 100 INCREMENT BY 1) PRIMARY KEY,
  descriptn      VARCHAR2(3200),
  shape          SDO_GEOMETRY
);

CREATE TABLE address(
        address_id          NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 100 INCREMENT BY 1)
   ,    street              VARCHAR2(300)
   ,    apt_unit#           VARCHAR2(10)
   ,    city                VARCHAR2(45)
   ,    state_region        VARCHAR2(20)
   ,    zip_code            VARCHAR2(20)
   ,    country             VARCHAR2(100) default 'Ghana' 
   ,    CONSTRAINT pk_address PRIMARY KEY(address_id)
);

ALTER TABLE address ADD CONSTRAINT uq_zip_code UNIQUE(street,apt_unit#,zip_code);
ALTER TABLE address ADD (spatial_id NUMBER CONSTRAINT fk4address2spatialobj REFERENCES spatial_object(spatial_id));

CREATE TABLE economic_zones(
        zone_id         NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1)
   ,    name            VARCHAR2(100)
   ,    descriptn       CLOB
   ,    economic_class  VARCHAR2(20) 
   ,    polygon         VARCHAR2(2000)
);

ALTER TABLE economic_zones ADD CONSTRAINT pk_ecozone_id PRIMARY KEY(zone_id);
ALTER TABLE economic_zones ADD (spatial_id NUMBER CONSTRAINT fk4ecozone2spatialobj REFERENCES spatial_object(spatial_id));

CREATE TABLE property(
        address_id          NUMBER CONSTRAINT fk_phyprpty2address REFERENCES address(address_id)
  ,     descrptn            CLOB
  ,     prop_type           VARCHAR2(50) 
  ,     year_built          INTEGER CONSTRAINT ck_yrbuilt CHECK(year_built > 0)
  ,     zone_id             NUMBER CONSTRAINT fk_phyprop2ecozone REFERENCES economic_zones(zone_id)
  ,     zoned_for           VARCHAR2(100)
  ,     current_use         VARCHAR2(100)
  ,     total_useable_space NUMBER
  ,     rent_per_unit       NUMBER
  ,     CONSTRAINT pk_propaddress_id PRIMARY KEY (address_id)
  ,     CONSTRAINT ck_proptype CHECK (lower(prop_type) in ('commercial','residential','industrial','government','other'))
);

CREATE TABLE prop_data(
        address_id NUMBER CONSTRAINT fk_propdet2phyprop REFERENCES property(address_id)
     ,  feature              varchar2(200)
     ,  feature_type         varchar2(30) CHECK (lower(feature_type) in('physical','economic','social','other'))
     ,  descrptn             VARCHAR2(2000)
     ,  quantity             VARCHAR2(45)
     ,  msrmnt_unit          varchar2(45)     
     ,  freq                 varchar2(20)
     ,  effective_fromdt     date
     ,  effective_untildt    date   
);

ALTER TABLE prop_data ADD (relates_to number,purpose VARCHAR2(50));

CREATE TABLE party(
    party_id varchar2(50) constraint pk_party_id primary key
  , id_type VARCHAR2(45)
  , first_name VARCHAR2(45)
  , last_name VARCHAR2(45)
  , dob DATE
  , party_type varchar2(45)
  , address number CONSTRAINT fk_party2address REFERENCES address(address_id)
  , phone_number varchar2(20)
  , email_address varchar2(100)
);

CREATE TABLE estate_professional(
        license#                VARCHAR2(50) CONSTRAINT pk_estateprof PRIMARY KEY
    ,   party_id                varchar2(50) CONSTRAINT fk_estprof2party REFERENCES party(party_id)
    ,   current_standing        varchar2(45)
    ,   licensed_dt             DATE
    ,   professional_title      VARCHAR2(50)
    ,   area_of_specilization   VARCHAR2(50)
);

CREATE TABLE interest(
        interest_id NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1)
   ,    address_id NUMBER CONSTRAINT fk_interest2phyprop REFERENCES property(address_id)
   ,    name     varchar2(56)
   ,    descrptn VARCHAR2(2000)
   ,    type     varchar2(40)
   ,    from_dt  date
   ,    to_dt    date
   ,    current_value       NUMBER
   ,    last_estimated_val  number
   ,    last_valuation_dt   DATE
   ,    CONSTRAINT pk_interest_id PRIMARY KEY(interest_id)
);

CREATE TABLE interest_owner(
     interest_id     NUMBER CONSTRAINT fk_owner2interest REFERENCES interest(interest_id)
  ,  party_id        VARCHAR2(50) CONSTRAINT fk_owner2party REFERENCES party(party_id)
  ,  party_share     number
  ,  ownership_type  VARCHAR2(100) DEFAULT 'Joint Ownership'
);

CREATE TABLE ownership_history as select * from interest_owner where 1 = 2;

CREATE TABLE inspection(
        inspection_id   NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 100 INCREMENT BY 1) PRIMARY KEY
   ,    interest_id     NUMBER CONSTRAINT inspect2interest REFERENCES interest(interest_id)
   ,    inspected_on    DATE
   ,    inspected_by    VARCHAR2(50) 
   ,    basis           VARCHAR2(50)
   ,    purpose         VARCHAR2(500)
   ,    method          VARCHAR2(100)
);

CREATE TABLE valuation(
        valuation_id        NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 100 INCREMENT BY 1) PRIMARY KEY
   ,    interest_id         NUMBER CONSTRAINT val2interest REFERENCES interest(interest_id)
   ,    valued_on           DATE
   ,    valuer_license#     VARCHAR2(50) CONSTRAINT fk4val2estprof REFERENCES estate_professional(license#)
   ,    amount              NUMBER
   ,    basis               VARCHAR2(50)
   ,    purpose             VARCHAR2(500)
   ,    method              VARCHAR2(100)
);

CREATE TABLE sales_history(
     interest_id        NUMBER CONSTRAINT fk_sales_hist2interest REFERENCES interest(interest_id)
   , sales_dt           TIMESTAMP
   , sales_amount       number
   , circumstances      VARCHAR2(100) DEFAULT 'Normal'
   , taxpaid            number
   , seller_agent_id    varchar2(50)
   , buyer_agent_id     varchar2(50)
   , escrow_agent_id    varchar2(50)
   , CONSTRAINT pk_intsalesdt PRIMARY KEY(interest_id,sales_dt)
);

ALTER TABLE sales_history 
ADD(CONSTRAINT fk_salehistsi2estprof FOREIGN KEY(seller_agent_id) REFERENCES estate_professional(license#)
,   CONSTRAINT fk_salehistbi2estprof FOREIGN KEY(buyer_agent_id)  REFERENCES estate_professional(license#)
,   CONSTRAINT fk_salehistei2estprof FOREIGN KEY(escrow_agent_id) REFERENCES estate_professional(license#));

ALTER TABLE sales_history ADD valuation_id NUMBER CONSTRAINT fk2valution REFERENCES valuation(valuation_id);

