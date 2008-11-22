CREATE OR REPLACE PROCEDURE k_get_term_from_text (IdDomain NUMBER, TxTerm VARCHAR2, GuTerm OUT VARCHAR2) IS
BEGIN
  SELECT gu_term INTO GuTerm FROM k_thesauri WHERE id_domain=IdDomain AND (tx_term=TxTerm OR tx_term2=TxTerm) AND ROWNUM=1;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    GuTerm:=NULL;
END k_get_term_from_text;
GO;
