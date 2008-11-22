CREATE FUNCTION k_sp_ins_answer (CHAR,CHAR,INTEGER,INTEGER,CHAR,VARCHAR,CHAR,VARCHAR,VARCHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_pageset_answers WHERE gu_datasheet=$1 AND (nm_answer=$6 OR (pg_answer=$4 AND (gu_page=$2 OR pg_page=$3)));
  INSERT INTO k_pageset_answers (gu_datasheet,gu_page,pg_page,pg_answer,gu_pageset,nm_answer,dt_modified,gu_writer,tp_answer,tx_answer) VALUES ($1,$2,$3,$4,$5,$6,CURRENT_TIMESTAMP,$7,$8,$9);
  RETURN 1;
END;
' LANGUAGE 'plpgsql';
GO;
