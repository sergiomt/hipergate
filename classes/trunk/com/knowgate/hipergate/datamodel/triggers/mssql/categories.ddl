CREATE TRIGGER k_tr_categories ON k_categories FOR INSERT AS
  DECLARE @DomOwner    CHAR(32)
  DECLARE @CatOwner    CHAR(32)
  DECLARE @NmCategory VARCHAR(100)

  SET @NmCategory=NULL
  SELECT @NmCategory=nm_category,@CatOwner=gu_owner FROM inserted
  SET @DomOwner=NULL
  SELECT @DomOwner=gu_owner FROM k_domains WHERE nm_domain=@NmCategory
    
  IF @DomOwner<>@CatOwner AND @DomOwner IS NOT NULL
    BEGIN
      RAISERROR ('A category that has the same name as a Domain must both have the same owner', 16, 1)
      ROLLBACK TRANSACTION
    END  
GO;


CREATE TRIGGER k_tr_cat_tree ON k_cat_tree FOR INSERT AS
  DECLARE @BoDescendant SMALLINT,
  	  @IdParent CHAR(32),
  	  @IdChild  CHAR(32)
  
  SELECT @IdParent=gu_parent_cat, @IdChild=gu_child_cat FROM inserted
  
  EXECUTE k_sp_cat_descendant @IdParent, @IdChild, @BoDescendant OUTPUT
  
  IF (@BoDescendant<>0)
    RAISERROR ('Integrity constraint violation: Circular Reference', 16, 1)
GO;