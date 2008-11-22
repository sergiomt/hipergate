CREATE PROCEDURE k_sp_nextval (NMTable CHAR(18), OUT NextVal INT)
BEGIN
  SELECT GET_LOCK(NMTable,60);
  UPDATE k_sequences SET nu_current=nu_current+1 WHERE nm_table=NMTable;
  IF ROW_COUNT()=0 THEN
    SET NextVal = 1;
    INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES (NMTable,1,2147483647,1,NextVal);
  ELSE
    SELECT nu_current INTO NextVal FROM k_sequences WHERE nm_table=NMTable;
  END IF;
  SELECT RELEASE_LOCK(NMTable);
END
GO;

CREATE PROCEDURE k_sp_currval (NMTable CHAR(18), OUT NextVal INT)
BEGIN
  SELECT nu_current INTO NextVal FROM k_sequences WHERE nm_table=NMTable;
END
GO;
