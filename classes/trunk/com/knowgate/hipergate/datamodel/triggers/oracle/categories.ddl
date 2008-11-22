CREATE OR REPLACE TRIGGER k_tr_categories BEFORE INSERT ON k_categories FOR EACH ROW
DECLARE
  DomOwner CHAR(32);
BEGIN
  SELECT gu_owner INTO DomOwner FROM k_domains WHERE nm_domain=:NEW.nm_category;

  IF DomOwner<>:NEW.gu_owner AND DomOwner IS NOT NULL THEN
    raise_application_error (-20001,'A category that has the same name as a Domain must both have the same owner');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
  DomOwner := NULL;
END k_tr_categories;
GO;

CREATE OR REPLACE TRIGGER k_tr_cat_tree BEFORE INSERT ON k_cat_tree FOR EACH ROW
DECLARE
  BoDescendant NUMBER(2);
BEGIN

  k_sp_cat_descendant (:NEW.gu_parent_cat, :NEW.gu_child_cat, BoDescendant);

  IF BoDescendant<>0 THEN
    raise_application_error (-20000,'Integrity constraint violation: Circular Reference');
  END IF;
END k_tr_cat_tree;
GO;

