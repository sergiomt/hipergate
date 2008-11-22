CREATE SEQUENCE seq_k_job_atoms INCREMENT 1 MINVALUE 1 START 1;

CREATE FUNCTION k_sp_del_job (CHAR) RETURNS INTEGER AS '
BEGIN
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
BEGIN
  SELECT tx_email INTO EMailTx FROM k_job_atoms WHERE gu_job=$1 AND pg_atom=$2;
  IF FOUND THEN
    SELECT gu_company,gu_contact,tx_email,tx_name,tx_surname,tx_salutation,nm_commercial,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,nm_country,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box INTO CompGu,ContGu,EMailTx,NameTx,SurnTx,SalutTx,CommNm,StreetTp,StreetNm,StreetNu,Addr1Tx,Addr2Tx,CountryNm,StateNm,CityNm,Zipcde,WorkPhone,DirectPhone,HomePhone,MobilePhone,FaxPhone,OtherPhone,PoBox FROM k_member_address WHERE gu_workarea=$3 AND tx_email=EMailTx LIMIT 1;
    IF FOUND THEN
      UPDATE k_job_atoms SET gu_company=CompGu,gu_contact=ContGu,tx_name=NameTx,tx_surname=SurnTx,
             tx_salutation=SalutTx,nm_commercial=CommNm,tp_street=StreetTp,nm_street=StreetNm,nu_street=StreetNu,tx_addr1=Addr1Tx,tx_addr2=Addr2Tx,
             nm_country=CountryNm,nm_state=StateNm,mn_city=CityNm,zipcode=Zipcde,work_phone=WorkPhone,direct_phone=DirectPhone,
             home_phone=HomePhone,mov_phone=MobilePhone,fax_phone=FaxPhone,other_phone=OtherPhone,po_box=PoBox WHERE gu_job=$1 AND pg_atom=$2;
    END IF;
  END IF;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_resolve_atoms (CHAR) RETURNS INTEGER AS '
DECLARE
  WrkAGu CHAR(32);
  AtomPg INTEGER ;
  Atoms CURSOR (id CHAR(32)) FOR SELECT pg_atom FROM k_job_atoms WHERE gu_job=id;
BEGIN
  SELECT gu_workarea INTO WrkAGu FROM k_jobs WHERE gu_job=$1;
  OPEN Atoms($1);
    LOOP
      FETCH Atoms INTO AtomPg;
      EXIT WHEN NOT FOUND;
      PERFORM k_sp_resolve_atom ($1,AtomPg,WrkAGu);
    END LOOP;
  CLOSE Atoms;      
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;
