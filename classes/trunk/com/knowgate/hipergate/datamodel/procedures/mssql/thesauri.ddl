CREATE PROCEDURE k_get_term_from_text @IdDomain INTEGER, @TxTerm VARCHAR(200), @GuTerm CHAR(32) OUTPUT AS
  SET @GuTerm=NULL
  SELECT TOP 1 @GuTerm=gu_term FROM k_thesauri WITH (NOLOCK) WHERE id_domain=@IdDomain AND (tx_term=@TxTerm OR tx_term2=@TxTerm)
GO;
