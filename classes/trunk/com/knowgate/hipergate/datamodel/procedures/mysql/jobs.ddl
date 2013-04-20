
CREATE PROCEDURE k_sp_del_job (IdJob CHAR(32))
BEGIN
  DELETE FROM k_jobs_atoms_by_agent WHERE gu_job=IdJob;
  DELETE FROM k_jobs_atoms_by_hour WHERE gu_job=IdJob;
  DELETE FROM k_jobs_atoms_by_day WHERE gu_job=IdJob;
  DELETE FROM k_job_atoms_clicks WHERE gu_job=IdJob;
  DELETE FROM k_job_atoms_tracking WHERE gu_job=IdJob;
  DELETE FROM k_job_atoms_archived WHERE gu_job=IdJob;
  DELETE FROM k_job_atoms WHERE gu_job=IdJob;
  DELETE FROM k_jobs WHERE gu_job=IdJob;
END
GO;

CREATE PROCEDURE k_sp_resolve_atom (IdJob CHAR(32), AtomPg INT, GuWrkA CHAR(32))
BEGIN
  DECLARE AddrGu        CHAR(32);
  DECLARE CompGu        CHAR(32);
  DECLARE ContGu        CHAR(32);
  DECLARE NameTx        VARCHAR(200);
  DECLARE SurnTx        VARCHAR(200);
  DECLARE SalutTx       VARCHAR(16) ;
  DECLARE CommNm        VARCHAR(70) ;
  DECLARE StreetTp      VARCHAR(16) ;
  DECLARE StreetNm      VARCHAR(100);
  DECLARE StreetNu      VARCHAR(16) ;
  DECLARE Addr1Tx       VARCHAR(100);
  DECLARE Addr2Tx       VARCHAR(100);
  DECLARE CountryNm     VARCHAR(50) ;
  DECLARE StateNm       VARCHAR(30) ;
  DECLARE CityNm	VARCHAR(50) ;
  DECLARE Zipcode	VARCHAR(30) ;
  DECLARE WorkPhone     VARCHAR(16) ;
  DECLARE DirectPhone   VARCHAR(16) ;
  DECLARE HomePhone     VARCHAR(16) ;
  DECLARE MobilePhone   VARCHAR(16) ;
  DECLARE FaxPhone      VARCHAR(16) ;
  DECLARE OtherPhone    VARCHAR(16) ;
  DECLARE PoBox         VARCHAR(50) ;
  DECLARE EMailTx       VARCHAR(100) DEFAULT NULL;
  
  SELECT tx_email INTO EMailTx FROM k_job_atoms WHERE gu_job=IdJob AND pg_atom=AtomPg;
  IF EMailTx IS NOT NULL THEN
    SELECT gu_company,gu_contact,tx_email,tx_name,tx_surname,tx_salutation,nm_commercial,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,nm_country,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box
      INTO CompGu,ContGu,EMailTx,NameTx,SurnTx,SalutTx,CommNm,StreetTp,StreetNm,StreetNu,Addr1Tx,Addr2Tx,CountryNm,StateNm,CityNm	,Zipcode,WorkPhone,DirectPhone,HomePhone,MobilePhone,FaxPhone,OtherPhone,PoBox
      FROM k_member_address WHERE gu_workarea=GuWrkA AND tx_email=EMailTx LIMIT 0,1;
    UPDATE k_job_atoms SET gu_company=CompGu,gu_contact=ContGu,tx_name=NameTx,tx_surname=SurnTx,tx_salutation=SalutTx,nm_commercial=CommNm,tp_street=StreetTp,nm_street=StreetNm,nu_street=StreetNu,tx_addr1=Addr1Tx,tx_addr2=Addr2Tx,nm_country=CountryNm,nm_state=StateNm,mn_city=CityNm,zipcode=Zipcode,work_phone=WorkPhone,direct_phone=DirectPhone,home_phone=HomePhone,mov_phone=MobilePhone,fax_phone=FaxPhone,other_phone=OtherPhone,po_box=PoBox
     WHERE gu_job=IdJob AND pg_atom=AtomPg;
  END IF;
END 
GO;

CREATE PROCEDURE k_sp_resolve_atoms (IdJob CHAR(32))
BEGIN
  DECLARE AtomPg INT;
  DECLARE WrkAGu CHAR(32) DEFAULT NULL;
  DECLARE Done INT DEFAULT 0;
  DECLARE Atoms CURSOR FOR SELECT pg_atom FROM k_job_atoms WHERE gu_job=IdJob AND id_status<>3;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET Done=1;
  SELECT gu_workarea INTO WrkAGu FROM k_jobs WHERE gu_job=IdJob;
  OPEN Atoms;
    REPEAT
      FETCH Atoms INTO AtomPg;
      IF Done=0 THEN
        CALL k_sp_resolve_atom(IdJob,AtomPg,WrkAGu);
      END IF;
    UNTIL Done=1 END REPEAT;
  CLOSE Atoms;
END
GO;
