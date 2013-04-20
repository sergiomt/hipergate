CREATE PROCEDURE k_sp_del_meeting (MeetingId CHAR(32))
BEGIN
  UPDATE k_activities SET gu_meeting=NULL WHERE gu_meeting=MeetingId;
  DELETE FROM k_x_meeting_contact WHERE gu_meeting=MeetingId;
  DELETE FROM k_x_meeting_fellow WHERE gu_meeting=MeetingId;
  DELETE FROM k_x_meeting_room WHERE gu_meeting=MeetingId;
  DELETE FROM k_meetings WHERE gu_meeting=MeetingId;
END
GO;

CREATE PROCEDURE k_sp_del_fellow (FellowId CHAR(32))
BEGIN
  DECLARE Done INT DEFAULT 0;
  DECLARE MeetingId CHAR(32);
  DECLARE meetings CURSOR FOR SELECT gu_meeting FROM k_x_meeting_fellow WHERE gu_fellow=FellowId;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET Done=1;
  OPEN meetings;
    REPEAT
      FETCH meetings INTO MeetingId;
      IF Done=0 THEN
        CALL k_sp_del_meeting (MeetingId);
      END IF;
    UNTIL Done=1 END REPEAT;
  CLOSE meetings;

  DELETE FROM k_x_duty_resource WHERE nm_resource=FellowId;
  DELETE FROM k_fellows_attach WHERE gu_fellow=FellowId;
  DELETE FROM k_fellows WHERE gu_fellow=FellowId;
END
GO;

CREATE PROCEDURE k_sp_del_room (RoomNm VARCHAR(50), WorkAreaId CHAR(32))
BEGIN
  DELETE FROM k_rooms WHERE nm_room=RoomNm AND gu_workarea=WorkAreaId;
END
GO;
