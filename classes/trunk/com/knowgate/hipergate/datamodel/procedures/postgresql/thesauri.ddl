CREATE FUNCTION k_get_term_from_text (INTEGER, VARCHAR) RETURNS CHAR AS '
DECLARE
  GuTerm CHAR(32);
BEGIN
  GuTerm:=NULL;
  SELECT gu_term INTO GuTerm FROM k_thesauri WHERE id_domain=$1 AND (tx_term=$2 OR tx_term2=$2) LIMIT 1;
  RETURN GuTerm;
END;
' LANGUAGE 'plpgsql';
GO;
