CREATE SEQUENCE seq_k_job_atoms INCREMENT BY 1 START WITH 1
GO;

CREATE TRIGGER k_sp_ins_job_atom BEFORE INSERT ON k_job_atoms FOR EACH ROW WHEN (new.pg_atom IS NULL)
BEGIN
  SELECT seq_k_job_atoms.NEXTVAL INTO :new.pg_atom FROM dual;
END k_sp_ins_job_atom;
GO;


CREATE OR REPLACE PROCEDURE k_sp_del_job (IdJob CHAR) IS
BEGIN
  DELETE k_jobs_atoms_by_agent WHERE gu_job=IdJob;
  DELETE k_jobs_atoms_by_hour WHERE gu_job=IdJob;
  DELETE k_jobs_atoms_by_day WHERE gu_job=IdJob;
  DELETE k_job_atoms_clicks WHERE gu_job=IdJob;
  DELETE k_job_atoms_tracking WHERE gu_job=IdJob;
  DELETE k_job_atoms_archived WHERE gu_job=IdJob;
  DELETE k_job_atoms WHERE gu_job=IdJob;
  DELETE k_jobs WHERE gu_job=IdJob;
END k_sp_del_job;
GO;

CREATE OR REPLACE PROCEDURE k_sp_resolve_atom (IdJob CHAR, AtomPg NUMBER, GuWrkA CHAR) IS
  AddrGu        CHAR(32);
  CompGu        CHAR(32);
  ContGu        CHAR(32);
  EMailTx       VARCHAR2(100);
  NameTx        VARCHAR2(200);
  SurnTx        VARCHAR2(200);
  SalutTx       VARCHAR2(16) ;
  CommNm        VARCHAR2(70) ;
  StreetTp      VARCHAR2(16) ;
  StreetNm      VARCHAR2(100);
  StreetNu      VARCHAR2(16) ;
  Addr1Tx       VARCHAR2(100);
  Addr2Tx       VARCHAR2(100);
  CountryNm     VARCHAR2(50) ;
  StateNm       VARCHAR2(30) ;
  CityNm	VARCHAR2(50) ;
  Zipcode	VARCHAR2(30) ;
  WorkPhone     VARCHAR2(16) ;
  DirectPhone   VARCHAR2(16) ;
  HomePhone     VARCHAR2(16) ;
  MobilePhone   VARCHAR2(16) ;
  FaxPhone      VARCHAR2(16) ;
  OtherPhone    VARCHAR2(16) ;
  PoBox         VARCHAR2(50) ;
BEGIN
  SELECT tx_email INTO EMailTx FROM k_job_atoms WHERE gu_job=IdJob AND pg_atom=AtomPg;
  SELECT gu_company,gu_contact,tx_email,tx_name,tx_surname,tx_salutation,nm_commercial,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,nm_country,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box
    INTO CompGu,ContGu,EMailTx,NameTx,SurnTx,SalutTx,CommNm,StreetTp,StreetNm,StreetNu,Addr1Tx,Addr2Tx,CountryNm,StateNm,CityNm	,Zipcode,WorkPhone,DirectPhone,HomePhone,MobilePhone,FaxPhone,OtherPhone,PoBox
    FROM k_member_address WHERE gu_workarea=GuWrkA AND tx_email=EMailTx AND ROWNUM=1;
    UPDATE k_job_atoms SET gu_company=CompGu,gu_contact=ContGu,tx_name=NameTx,tx_surname=SurnTx,tx_salutation=SalutTx,nm_commercial=CommNm,tp_street=StreetTp,nm_street=StreetNm,nu_street=StreetNu,tx_addr1=Addr1Tx,tx_addr2=Addr2Tx,nm_country=CountryNm,nm_state=StateNm,mn_city=CityNm,zipcode=Zipcode,work_phone=WorkPhone,direct_phone=DirectPhone,home_phone=HomePhone,mov_phone=MobilePhone,fax_phone=FaxPhone,other_phone=OtherPhone,po_box=PoBox
     WHERE gu_job=IdJob AND pg_atom=AtomPg;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    EMailTx := NULL;
END k_sp_resolve_atom;
GO;

CREATE PROCEDURE k_sp_resolve_atoms (IdJob CHAR) IS
  WrkAGu CHAR(32);
  AtomPg NUMBER(11);
  CURSOR Atoms IS SELECT pg_atom FROM k_job_atoms WHERE gu_job=IdJob AND id_status<>3;
BEGIN
  SELECT gu_workarea INTO WrkAGu FROM k_jobs WHERE gu_job=IdJob;
  OPEN Atoms;
    LOOP
      FETCH Atoms INTO AtomPg;
      EXIT WHEN Atoms%NOTFOUND;
      k_sp_resolve_atom(IdJob,AtomPg,WrkAGu);
    END LOOP;
  CLOSE Atoms;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    WrkAGu := NULL;
END k_sp_resolve_atoms;
GO;


