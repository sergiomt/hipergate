CREATE FUNCTION k_sp_del_meeting (CHAR) RETURNS INTEGER AS '
BEGIN
  UPDATE k_activities SET gu_meeting=NULL WHERE gu_meeting=$1;
  DELETE FROM k_x_meeting_contact WHERE gu_meeting=$1;
  DELETE FROM k_x_meeting_fellow WHERE gu_meeting=$1;
  DELETE FROM k_x_meeting_room WHERE gu_meeting=$1;
  DELETE FROM k_meetings WHERE gu_meeting=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_fellow (CHAR) RETURNS INTEGER AS '
DECLARE
  MeetingId CHAR(32);
  meetings CURSOR (id CHAR(32)) FOR SELECT gu_meeting FROM k_x_meeting_fellow WHERE gu_fellow=id;
BEGIN
  OPEN meetings($1);
    LOOP
      FETCH meetings INTO MeetingId;
      EXIT WHEN NOT FOUND;
      PERFORM k_sp_del_meeting (MeetingId);
    END LOOP;
  CLOSE meetings;

  DELETE FROM k_x_duty_resource WHERE nm_resource=$1;
  DELETE FROM k_fellows_attach WHERE gu_fellow=$1;
  DELETE FROM k_fellows WHERE gu_fellow=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_room (VARCHAR,CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_rooms WHERE nm_room=$1 AND gu_workarea=$2;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;
