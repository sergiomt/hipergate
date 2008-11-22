CREATE PROCEDURE k_get_term_from_text (IdDomain INT, TxTerm VARCHAR(200), OUT GuTerm CHAR(32))
BEGIN
  SET GuTerm=NULL;
  SELECT gu_term INTO GuTerm FROM k_thesauri WHERE id_domain=IdDomain AND (tx_term=TxTerm OR tx_term2=TxTerm) LIMIT 1;
END
GO;