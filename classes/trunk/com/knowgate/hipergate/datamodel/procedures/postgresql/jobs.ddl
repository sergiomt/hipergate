CREATE SEQUENCE seq_k_job_atoms INCREMENT 1 MINVALUE 1 START 1;

CREATE FUNCTION k_sp_del_job (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_jobs_atoms_by_agent WHERE gu_job=$1;
  DELETE FROM k_jobs_atoms_by_hour WHERE gu_job=$1;
  DELETE FROM k_jobs_atoms_by_day WHERE gu_job=$1;
  DELETE FROM k_job_atoms_clicks WHERE gu_job=$1;
  DELETE FROM k_job_atoms_tracking WHERE gu_job=$1;
  DELETE FROM k_job_atoms_archived WHERE gu_job=$1;
  DELETE FROM k_job_atoms WHERE gu_job=$1;
  DELETE FROM k_jobs WHERE gu_job=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_resolve_atom (CHAR,INTEGER,CHAR) RETURNS INTEGER AS '
DECLARE
  AddrGu        CHAR(32);
  CompGu        CHAR(32);
  ContGu        CHAR(32);
  EMailTx       VARCHAR(100);
  NameTx        VARCHAR(200);
  SurnTx        VARCHAR(200);
  SalutTx       VARCHAR(16) ;
  CommNm        VARCHAR(70) ;
  StreetTp      VARCHAR(16) ;
  StreetNm      VARCHAR(100);
  StreetNu      VARCHAR(16) ;
  Addr1Tx       VARCHAR(100);
  Addr2Tx       VARCHAR(100);
  CountryNm     VARCHAR(50) ;
  StateNm       VARCHAR(30) ;
  CityNm	    VARCHAR(50) ;
  Zipcde	    VARCHAR(30) ;
  WorkPhone     VARCHAR(16) ;
  DirectPhone   VARCHAR(16) ;
  HomePhone     VARCHAR(16) ;
  MobilePhone   VARCHAR(16) ;
  FaxPhone      VARCHAR(16) ;
  OtherPhone    VARCHAR(16) ;
  PoBox         VARCHAR(50) ;
  UrlAddr       VARCHAR(254);
  Resolved      INTEGER;
BEGIN
  SELECT tx_email INTO EMailTx FROM k_job_atoms WHERE gu_job=$1 AND pg_atom=$2;
  IF FOUND THEN
    SELECT gu_company,gu_contact,tx_email,tx_name,tx_surname,tx_salutation,nm_commercial,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,nm_country,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,url_addr INTO CompGu,ContGu,EMailTx,NameTx,SurnTx,SalutTx,CommNm,StreetTp,StreetNm,StreetNu,Addr1Tx,Addr2Tx,CountryNm,StateNm,CityNm,Zipcde,WorkPhone,DirectPhone,HomePhone,MobilePhone,FaxPhone,OtherPhone,PoBox,UrlAddr FROM k_member_address WHERE gu_workarea=$3 AND tx_email=EMailTx LIMIT 1;
    IF FOUND THEN
      UPDATE k_job_atoms SET gu_company=CompGu,gu_contact=ContGu,tx_name=NameTx,tx_surname=SurnTx,
             tx_salutation=SalutTx,nm_commercial=CommNm,tp_street=StreetTp,nm_street=StreetNm,nu_street=StreetNu,tx_addr1=Addr1Tx,tx_addr2=Addr2Tx,
             nm_country=CountryNm,nm_state=StateNm,mn_city=CityNm,zipcode=Zipcde,work_phone=WorkPhone,direct_phone=DirectPhone,
             home_phone=HomePhone,mov_phone=MobilePhone,fax_phone=FaxPhone,other_phone=OtherPhone,po_box=PoBox WHERE gu_job=$1 AND pg_atom=$2;
      Resolved:=1;
    ELSE
      Resolved:=0;
    END IF;
  ELSE
    Resolved:=0;
  END IF;
  RETURN Resolved;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_resolve_atoms (CHAR) RETURNS INTEGER AS '
DECLARE
  WrkAGu CHAR(32);
  Atoms INTEGER[] := ARRAY(SELECT pg_atom FROM k_job_atoms WHERE gu_job=$1 AND id_status<>3);
  NAtms INTEGER := array_upper(Atoms, 1);
  NResv INTEGER := 0;
  IResv INTEGER;
BEGIN
  IF NAtms IS NOT NULL THEN
    SELECT gu_workarea INTO WrkAGu FROM k_jobs WHERE gu_job=$1;
    FOR a IN 1..NAtms LOOP
      SELECT k_sp_resolve_atom ($1,Atoms[a],WrkAGu) INTO IResv;
      NResv := NResv + IResv;
    END LOOP;  
  END IF;
  RETURN NResv;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_ins_atom() RETURNS OPAQUE AS '
DECLARE
  TxEMail VARCHAR(100);
BEGIN
  IF NEW.tx_email IS NOT NULL AND NEW.id_status IN (1,2,3) THEN
	  SELECT bl.tx_email INTO TxEMail FROM k_global_black_list bl WHERE bl.tx_email=NEW.tx_email AND bl.gu_workarea IN (SELECT gu_workarea FROM k_jobs WHERE gu_job=NEW.gu_job);
    IF FOUND THEN
      RAISE EXCEPTION ''Could not insert e-mail: % at k_job_atoms because it is blacklisted'', TxEMail USING ERRCODE = ''23514'';
    END IF;
  END IF;
RETURN NEW;
END;
' LANGUAGE 'plpgsql'
GO;

CREATE TRIGGER k_tr_ins_atom BEFORE INSERT ON k_job_atoms FOR EACH ROW EXECUTE PROCEDURE k_sp_ins_atom();
GO;

CREATE FUNCTION k_sp_del_test_jobs () RETURNS INTEGER AS '
DECLARE
  Jobs  NO SCROLL CURSOR FOR SELECT gu_job FROM k_jobs;
  Atoms NO SCROLL CURSOR (j CHAR(32)) FOR SELECT pg_atom FROM k_job_atoms_archived WHERE gu_job=j LIMIT 15;
  GuJob CHAR(32);
  PgAtm INTEGER;
  RowCount INTEGER;
  Deleted INTEGER;
BEGIN
  Deleted:=0;
  OPEN Jobs;
  LOOP
    FETCH Jobs INTO GuJob;
    EXIT WHEN NOT FOUND;
    RowCount:=0;
    OPEN Atoms(GuJob);
    LOOP
      FETCH Atoms INTO PgAtm;
      EXIT WHEN NOT FOUND OR RowCount>10;
      RowCount:=RowCount+1;
    END LOOP;
    CLOSE Atoms;
    IF RowCount<10 THEN
      PERFORM k_sp_del_job(GuJob);
      Deleted:=Deleted+1;
    END IF;
  END LOOP;
  CLOSE Jobs;
  RETURN Deleted;
END;
' LANGUAGE 'plpgsql';
GO;