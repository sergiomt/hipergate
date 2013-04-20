CREATE PROCEDURE k_sp_del_job @IdJob CHAR(32) AS
  DELETE FROM k_jobs_atoms_by_agent WHERE gu_job=@IdJob
  DELETE FROM k_jobs_atoms_by_hour WHERE gu_job=@IdJob
  DELETE FROM k_jobs_atoms_by_day WHERE gu_job=@IdJob
  DELETE FROM k_job_atoms_clicks WHERE gu_job=@IdJob
  DELETE FROM k_job_atoms_tracking WHERE gu_job=@IdJob
  DELETE FROM k_job_atoms_archived WHERE gu_job=@IdJob
  DELETE k_job_atoms WHERE gu_job=@IdJob
  DELETE k_jobs WHERE gu_job=@IdJob
GO;

CREATE PROCEDURE k_sp_resolve_atom @IdJob CHAR(32), @AtomPg INTEGER, @GuWrkA CHAR(32) AS
  DECLARE @AddrGu        CHAR(32)     
  DECLARE @CompGu        CHAR(32)     
  DECLARE @ContGu        CHAR(32)     
  DECLARE @EMailTx       VARCHAR(100)
  DECLARE @NameTx        NVARCHAR(200) 
  DECLARE @SurnTx        NVARCHAR(200) 
  DECLARE @SalutTx       NVARCHAR(16)  
  DECLARE @CommNm        NVARCHAR(70)  
  DECLARE @StreetTp      NVARCHAR(16)  
  DECLARE @StreetNm      NVARCHAR(100) 
  DECLARE @StreetNu      NVARCHAR(16)  
  DECLARE @Addr1Tx       NVARCHAR(100) 
  DECLARE @Addr2Tx       NVARCHAR(100) 
  DECLARE @CountryNm     NVARCHAR(50)  
  DECLARE @StateNm       NVARCHAR(30)  
  DECLARE @CityNm	 NVARCHAR(50) 
  DECLARE @Zipcode	 NVARCHAR(30)  
  DECLARE @WorkPhone     NVARCHAR(16)  
  DECLARE @DirectPhone   NVARCHAR(16)  
  DECLARE @HomePhone     NVARCHAR(16)  
  DECLARE @MobilePhone   NVARCHAR(16)  
  DECLARE @FaxPhone      NVARCHAR(16)  
  DECLARE @OtherPhone    NVARCHAR(16)  
  DECLARE @PoBox         NVARCHAR(50)  

  SET @EMailTx=NULL
  SELECT @EMailTx=tx_email FROM k_job_atoms WHERE gu_job=@IdJob AND pg_atom=@AtomPg
  IF @EMailTx IS NOT NULL
    BEGIN
      SET @AddrGu=NULL
      SELECT TOP 1 @AddrGu=gu_address,@CompGu=gu_company,@ContGu=gu_contact,@NameTx=tx_name,@SurnTx=tx_surname,@SalutTx=tx_salutation,@CommNm=nm_commercial,@StreetTp=tp_street,@StreetNm=nm_street,@StreetNu=nu_street,@Addr1Tx=tx_addr1,@Addr2Tx=tx_addr2,@CountryNm=nm_country,@StateNm=nm_state,@CityNm	=mn_city,@Zipcode=zipcode,@WorkPhone=work_phone,@DirectPhone=direct_phone,@HomePhone=home_phone,@MobilePhone=mov_phone,@FaxPhone=fax_phone,@OtherPhone=other_phone,@PoBox=po_box
             FROM k_member_address WHERE gu_workarea=@GuWrkA AND tx_email=@EMailTx
      IF @AddrGu IS NOT NULL
        UPDATE k_job_atoms SET gu_company=@CompGu,gu_contact=@ContGu,tx_name=@NameTx,tx_surname=@SurnTx,tx_salutation=@SalutTx,nm_commercial=@CommNm,tp_street=@StreetTp,nm_street=@StreetNm,nu_street=@StreetNu,tx_addr1=@Addr1Tx,tx_addr2=@Addr2Tx,nm_country=@CountryNm,nm_state=@StateNm,mn_city	=@CityNm,zipcode	=@Zipcode,work_phone=@WorkPhone,direct_phone=@DirectPhone,home_phone=@HomePhone,mov_phone=@MobilePhone,fax_phone=@FaxPhone,other_phone=@OtherPhone,po_box=@PoBox
               WHERE gu_job=@IdJob AND pg_atom=@AtomPg
    END
GO;

CREATE PROCEDURE k_sp_resolve_atoms @IdJob CHAR(32) AS
  DECLARE @WrkAGu CHAR(32)
  DECLARE @AtomPg INTEGER
  DECLARE Atoms CURSOR LOCAL STATIC FOR SELECT pg_atom FROM k_job_atoms WHERE gu_job = @IdJob AND id_status<>3

  SET @WrkAGu=NULL
  SELECT @WrkAGu=gu_workarea FROM k_jobs WHERE gu_job=@IdJob
  OPEN Atoms
    FETCH NEXT FROM Atoms INTO @AtomPg
    WHILE @@FETCH_STATUS = 0
      BEGIN
        EXECUTE k_sp_resolve_atom @IdJob
        FETCH NEXT FROM Atoms INTO @AtomPg
      END
  CLOSE Atoms
  DEALLOCATE Atoms
GO;