
CREATE FUNCTION k_ob_conn_str () RETURNS VARCHAR AS '
BEGIN
  RETURN ''hostaddr=127.0.0.1 port=5432 dbname=ob2eoi1 user=tad password=OBTadPwd'';
END;
' LANGUAGE 'plpgsql'
GO;

SELECT k_ob_write_company ('ac1263a412371d760ff100015f6ab3e2')

CREATE OR REPLACE FUNCTION k_ob_write_company (CHAR) RETURNS VARCHAR AS '
DECLARE
  C_Company_ID CHAR(32);
  C_BPartner_ID VARCHAR(32);
  AD_Client_ID VARCHAR(32);
  AD_Org_ID VARCHAR(32);
  C_BP_Group_ID VARCHAR(32);
  Created TIMESTAMP;
  CreatedBy VARCHAR(32);
  Updated TIMESTAMP;
  UpdatedBy VARCHAR(32);
  Value VARCHAR(70);
  Name VARCHAR(70);
  Name2 VARCHAR(70);
  Description VARCHAR(255);
  ReferenceNo VARCHAR(50);
  ExecStatus VARCHAR;
  Y CHAR(1);
  N CHAR(1);
BEGIN
  SELECT gu_company,id_bpartner,NULL,NULL,dt_created,NULL,dt_modified,NULL,substr(nm_legal,1,40),substr(nm_legal,1,60),substr(nm_commercial,1,60),de_company,id_ref INTO C_Company_ID,C_BPartner_ID,AD_Client_ID,AD_Org_ID,Created,CreatedBy,Updated,UpdatedBy,Value,Name,Name2,Description,ReferenceNo FROM k_companies WHERE gu_company=$1;
  AD_Client_ID := ''0'';
  AD_Org_ID := ''0'';
  CreatedBy := ''0'';
  UpdatedBy := ''0'';
  C_BP_Group_ID := ''1000003'';
  Y := ''Y'';
  N := ''N'';
  PERFORM dblink_connect(k_ob_conn_str());
  IF C_BPartner_ID IS NULL THEN
    C_BPartner_ID := C_Company_ID;
    SELECT dblink_exec(''INSERT INTO C_BPartner (C_BPartner_ID,AD_Client_ID,AD_Org_ID,IsActive,Created,CreatedBy,Updated,UpdatedBy,Value,Name,Name2,Description,IsSummary,C_BP_Group_ID,IsOneTime,IsProspect,IsVendor,IsCustomer,IsEmployee,IsSalesRep,ReferenceNo) VALUES (''||
    quote_literal(C_BPartner_ID)||'',''||
    quote_literal(AD_Client_ID) ||'',''||
    quote_literal(AD_Org_ID)    ||'',''||
    quote_literal(Y)            ||'',CURRENT_TIMESTAMP,''||
    quote_literal(CreatedBy)    ||'',CURRENT_TIMESTAMP,''||
    quote_literal(UpdatedBy)    ||'',''||
    quote_literal(Value)        ||'',''||
    quote_literal(Name)         ||'',''||
    COALESCE(quote_literal(Name2),''NULL'')||'',''||
    COALESCE(quote_literal(Description),''NULL'')||'',''||
    quote_literal(N)            ||'',''||
    quote_literal(C_BP_Group_ID)||'',''||
    quote_literal(Y)            ||'',''||
    quote_literal(N)            ||'',''||
    quote_literal(N)            ||'',''||
    quote_literal(Y)            ||'',''||
    quote_literal(N)            ||'',''||
    quote_literal(N)            ||'',''||
    COALESCE(quote_literal(ReferenceNo),''NULL'')||'')'') INTO ExecStatus;
    UPDATE k_companies SET id_bpartner=C_BPartner_ID WHERE gu_company=$1;
  ELSE
    SELECT dblink_exec(''UPDATE C_BPartner SET ''||
		''Updated=CURRENT_TIMESTAMP,''||
		''UpdatedBy=''||quote_literal(UpdatedBy)||
		''Value=''||quote_literal(Value)||
		''Name=''||quote_literal(Name)||
		''Name2=''||COALESCE(quote_literal(Name2),''NULL'')||
		''Description=''||COALESCE(quote_literal(Description),''NULL'')||
		''ReferenceNo=''||COALESCE(quote_literal(ReferenceNo),''NULL'')||
    '' WHERE C_BPartner_ID=''||quote_literal(C_BPartner_ID)) INTO ExecStatus;
  END IF;
  PERFORM dblink_disconnect();
  RETURN ExecStatus;
END;
' LANGUAGE 'plpgsql'
GO;