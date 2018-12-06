--BEGIN
--   EXECUTE IMMEDIATE 'DROP USER ledev CASCADE';
--EXCEPTION
--   WHEN others THEN
--   dbms_output.put_line('Ouch, the user does not exist');
--END;
--/
--CREATE USER ledev IDENTIFIED BY oracle;
--/
--GRANT CONNECT, RESOURCE, DBA TO ledev;
--/

CREATE TABLE spatial_object (
  spatial_id     BIGSERIAL,
  descriptn      VARCHAR(3200),
  shape          polygon
);

ALTER TABLE spatial_object ADD CONSTRAINT pk_spatial_obj_id PRIMARY KEY(spatial_id);

CREATE TABLE economic_zones(
        zone_id         BIGSERIAL
   ,    name            VARCHAR(100)
   ,    descriptn       TEXT
   ,    economic_class  VARCHAR(100) 
   ,    geo_zone 		polygon  
   ,    spatial_id      BIGINT CONSTRAINT fk4ecozone2spatialobj REFERENCES spatial_object(spatial_id)
   ,    CONSTRAINT pk_ecozone_id PRIMARY KEY(zone_id)
);

CREATE TABLE address(
        address_id          SERIAL
   ,    street              VARCHAR(300)
   ,    apt_unit            VARCHAR(10)
   ,    city_town           VARCHAR(45)
   ,    state_region        VARCHAR(20)
   ,    zipcode             VARCHAR(20)
   ,    country             VARCHAR(100) default 'Ghana' 
   ,    spatial_id          BIGINT
   ,    CONSTRAINT pk_address PRIMARY KEY(address_id)
   ,    CONSTRAINT uq_zip_code UNIQUE(street,apt_unit,zipcode)
   ,    CONSTRAINT fk4address2spatialobj FOREIGN KEY(spatial_id) REFERENCES spatial_object(spatial_id)
);

CREATE TABLE physical_property(
        address_id          INT CONSTRAINT fk_phyprpty2address REFERENCES address(address_id)
  ,     descrptn            TEXT
  ,     prop_type           VARCHAR(100) 
  ,     year_built          INT CONSTRAINT ck_yrbuilt CHECK(year_built > 1500)
  ,     eco_zone_id         BIGINT CONSTRAINT fk_phyprop2ecozone REFERENCES economic_zones(zone_id)
  ,     zoned_for           VARCHAR(300)
  ,     current_use         VARCHAR(300)
  ,     total_useable_space NUMERIC
  ,     rent_per_unit       NUMERIC
  ,     val_per_unit        NUMERIC
  ,     possession          VARCHAR(500) DEFAULT 'owner occupied'
  ,     CONSTRAINT pk_propaddress_id PRIMARY KEY (address_id)
  ,     CONSTRAINT ck_proptype CHECK (lower(prop_type) in ('commercial','residential','industrial','government','other'))
);

CREATE TABLE prop_data(
        address_id           BIGINT CONSTRAINT fk_propdet2address REFERENCES address(address_id)
	 ,  feature_id           SERIAL
     ,  feature              varchar(200)
     ,  feature_type         varchar(30) CHECK (lower(feature_type) in('physical','economic','social','other'))
     ,  descrptn             VARCHAR(2000)
     ,  quantity             VARCHAR(45)
     ,  msrmnt_unit          varchar(45)     
     ,  freq                 varchar(20)
     ,  effective_fromdt     date
     ,  effective_untildt    date
	 ,  relates_to           numeric
     ,  purpose              VARCHAR(50)
     ,  CONSTRAINT pk_prop_data PRIMARY KEY(address_id,feature_id)
);

CREATE TABLE party(
    party_id varchar(100) constraint pk_party_id primary key
  , id_type VARCHAR(100)
  , first_name VARCHAR(45)
  , last_name VARCHAR(45)
  , dob DATE
  , party_type varchar(45)
  , address BIGINT CONSTRAINT fk_party2address REFERENCES address(address_id)
  , primary_phone_number varchar(20)
  , email_address varchar(100)
);
									  
CREATE TABLE interest(
        interest_id 		BIGSERIAL
   ,    address_id  		BIGINT CONSTRAINT fk_interest2phyprop REFERENCES address(address_id)
   ,    interest_name     	varchar(56)
   ,    descrptn 			VARCHAR(2000)
   ,    interest_type     	varchar(40)
   ,    from_dt  			date
   ,    to_dt    			date
   ,    current_value       NUMERIC
   ,    last_estimated_val  NUMERIC
   ,    last_valuation_dt   DATE
   ,    CONSTRAINT pk_interest_id PRIMARY KEY(interest_id,address_id)
);									  
	
CREATE TABLE interest_owner(
     interest_id     BIGINT 
  ,  address_id BIGINT
  ,  party_id        VARCHAR(50) CONSTRAINT fk_owner2party REFERENCES party(party_id)
  ,  party_share     NUMERIC
  ,  ownership_type  VARCHAR(100) DEFAULT 'Joint Ownership'
  ,  CONSTRAINT fk_owner2interest FOREIGN KEY(interest_id,address_id) REFERENCES interest(interest_id,address_id)
);												

CREATE TABLE ownership_history as select * from interest_owner where 1 = 2;	
												
CREATE TABLE estate_professional(
        license                VARCHAR(50) CONSTRAINT pk_estateprof PRIMARY KEY
    ,   party_id                varchar(50) CONSTRAINT fk_estprof2party REFERENCES party(party_id)   
    ,   professional_title      VARCHAR(50)
    ,   professional_specilization   VARCHAR(50)
);												

CREATE TABLE valuation(
        address_id          bigint 
   ,    interest_id         BIGINT
   ,    valued_on           DATE
   ,    valuer_license     VARCHAR(50) CONSTRAINT fk4val2estprof REFERENCES estate_professional(license)
   ,    amount              NUMERIC
   ,    basis               VARCHAR(100)
   ,    purpose             VARCHAR(500)
   ,    val_method              VARCHAR(100)
	,  CONSTRAINT fk_valuation2interest FOREIGN KEY(interest_id,address_id) REFERENCES interest(interest_id,address_id)
);

CREATE TABLE sales_history(
     interest_id        BIGINT
   , address_id         BIGINT
   , sales_dt           TIMESTAMP
   , sales_amount       numeric
   , circumstances      VARCHAR(100) DEFAULT 'Normal'
   , taxpaid            numeric
   , seller_agent_id    varchar(50)
   , buyer_agent_id     varchar(50)
   , escrow_agent_id    varchar(50)
   , CONSTRAINT pk_intsalesdt PRIMARY KEY(interest_id,address_id,sales_dt)
   , CONSTRAINT fk_sales2interest FOREIGN KEY(interest_id,address_id) REFERENCES interest(interest_id,address_id)
);

ALTER TABLE sales_history 
ADD CONSTRAINT fk_salehistsi2estprof FOREIGN KEY(seller_agent_id) REFERENCES estate_professional(license);

ALTER TABLE sales_history 
ADD CONSTRAINT fk_salehistbi2estprof FOREIGN KEY(buyer_agent_id)  REFERENCES estate_professional(license);

ALTER TABLE sales_history
ADD CONSTRAINT fk_salehistei2estprof FOREIGN KEY(escrow_agent_id) REFERENCES estate_professional(license);

ALTER TABLE sales_history ADD valuation_id NUMBER CONSTRAINT fk2valution REFERENCES valuation(valuation_id);
												
												
												
												
												
												
												