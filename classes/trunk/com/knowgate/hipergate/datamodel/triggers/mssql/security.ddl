CREATE TRIGGER k_tr_newdomain ON k_domains FOR INSERT AS
  DECLARE @NmDomain VARCHAR(30)
  DECLARE @GuCategory CHAR(32)

  SELECT @NmDomain=nm_domain FROM inserted

  SET @GuCategory=NULL
  SELECT @GuCategory=gu_category FROM k_categories WHERE nm_category=@NmDomain
  
  IF @GuCategory IS NOT NULL
    BEGIN
      RAISERROR ('No se puede crear el dominio porque existe una categoría que tiene justamente el mismo nombre', 16, 1)
      ROLLBACK TRANSACTION
    END
GO
  
CREATE TRIGGER k_tr_domains ON k_domains FOR UPDATE AS
  DECLARE @IdDomain INTEGER
  DECLARE @GuOwner CHAR(32)
  DECLARE @GuAdmins CHAR(32)
  DECLARE @GuUser CHAR(32)
  DECLARE @GuGroup CHAR(32)
  SELECT @IdDomain=id_domain, @GuOwner=gu_owner, @GuAdmins=gu_admins FROM inserted
  
  IF @GuOwner IS NOT NULL
    BEGIN
      SET @GuUser=NULL
      SELECT @GuUser=gu_user from k_users WHERE gu_user=@GuOwner AND id_domain=@IdDomain
      IF @GuUser IS NULL
        BEGIN
          RAISERROR ('El propietario del dominio debe ser un miembro del mismo', 16, 1)
          ROLLBACK TRANSACTION
        END
    END
  
  IF @GuAdmins IS NOT NULL
    BEGIN    
      SET @GuGroup=NULL
      SELECT @GuGroup=gu_acl_group FROM k_acl_groups WHERE gu_acl_group=@GuAdmins AND id_domain=@IdDomain
      IF @GuGroup IS NULL
        BEGIN
          RAISERROR ('El grupo de administradores del dominio debe pertenecer al mismo', 16, 1)
          ROLLBACK TRANSACTION
        END
    END
GO

