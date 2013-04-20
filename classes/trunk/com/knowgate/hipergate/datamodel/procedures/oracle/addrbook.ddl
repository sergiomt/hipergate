CREATE OR REPLACE PROCEDURE k_sp_del_meeting (MeetingId CHAR) IS
BEGIN
  UPDATE k_activities SET gu_meeting=NULL WHERE gu_meeting=MeetingId;
  DELETE k_x_meeting_contact WHERE gu_meeting=MeetingId;
  DELETE k_x_meeting_fellow WHERE gu_meeting=MeetingId;
  DELETE k_x_meeting_room WHERE gu_meeting=MeetingId;
  DELETE k_meetings WHERE gu_meeting=MeetingId;
END k_sp_del_meeting;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_fellow (FellowId CHAR) IS
  MeetingId CHAR(32);
  CURSOR meetings(id CHAR) IS SELECT gu_meeting FROM k_x_meeting_fellow WHERE gu_fellow=id;
BEGIN
  OPEN meetings(FellowId);
    LOOP
      FETCH meetings INTO MeetingId;
      EXIT WHEN meetings%NOTFOUND;
      k_sp_del_meeting (MeetingId);
    END LOOP;
  CLOSE meetings;

  DELETE k_x_duty_resource WHERE nm_resource=FellowId;
  DELETE k_fellows_attach WHERE gu_fellow=FellowId;
  DELETE k_fellows WHERE gu_fellow=FellowId;
END k_sp_del_fellow;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_room (RoomNm VARCHAR2, WorkAreaId CHAR) IS
BEGIN
  DELETE k_rooms WHERE nm_room=RoomNm AND gu_workarea=WorkAreaId;
END k_sp_del_room;
GO;
