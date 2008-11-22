/* Convert a single character encoded as UTF-8 to an HTML entity */<BR>
<PRE>
CREATE FUNCTION k_utf8_to_ent (bytea) RETURNS VARCHAR AS '
DECLARE
  mbs  INTEGER;
  ret  VARCHAR(8);
BEGIN
  mbs := octet_length($1);
 
  IF mbs=1 THEN
    ret:=''&#x''||to_hex(get_byte($1,0))||'';'';
  ELSIF mbs=2 THEN
    ret:=''&#x''|| to_hex(((get_byte($1,0)&31)*64)+(get_byte($1,1)&63))||'';'';
  ELSIF mbs=3 THEN
    ret:=''&#x''|| to_hex(((get_byte($1,0)&15)*64*64) + ((get_byte($1,1)&63)*64) + (get_byte($1,2)&63))||'';'';
  END IF;
  
  RETURN ret;
END;
' LANGUAGE 'plpgsql';
 
CREATE FUNCTION k_utf8_to_html (VARCHAR) RETURNS VARCHAR AS '
DECLARE
  len  INTEGER;
  ret  VARCHAR(1024);
  utf  VARCHAR(8);
BEGIN
  CREATE CAST (text as bytea) WITHOUT FUNCTION;
  len := char_length($1);
  ret := '''';
  FOR i IN 1 .. len LOOP
    SELECT k_utf8_to_ent(CAST(substring($1 from i for 1) AS bytea)) INTO utf;
    ret:=ret||utf;
  END LOOP;
  DROP CAST (text as bytea);  
  RETURN ret;
END;
' LANGUAGE 'plpgsql';
 