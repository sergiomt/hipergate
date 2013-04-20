CREATE PROCEDURE k_sp_del_meeting @MeetingId CHAR(32) AS
  UPDATE k_activities SET gu_meeting=NULL WHERE gu_meeting=@MeetingId
  DELETE k_x_meeting_contact WHERE gu_meeting=@MeetingId
  DELETE k_x_meeting_fellow WHERE gu_meeting=@MeetingId
  DELETE k_x_meeting_room WHERE gu_meeting=@MeetingId
  DELETE k_meetings WHERE gu_meeting=@MeetingId
GO;

CREATE PROCEDURE k_sp_del_fellow @FellowId CHAR(32) AS
  DECLARE @MeetingId CHAR(32)
  DECLARE meetings CURSOR LOCAL STATIC FOR SELECT gu_meeting FROM k_x_meeting_fellow WITH (NOLOCK) WHERE gu_fellow=@FellowId
  
  OPEN meetings
    FETCH NEXT FROM meetings INTO @MeetingId
    WHILE @@FETCH_STATUS = 0
      BEGIN
        EXECUTE k_sp_del_meeting @MeetingId
        FETCH NEXT FROM meetings INTO @MeetingId
      END
  CLOSE meetings

  DELETE k_x_duty_resource WHERE nm_resource=@FellowId
  DELETE k_fellows_attach WHERE gu_fellow=@FellowId
  DELETE k_fellows WHERE gu_fellow=@FellowId  
GO;

CREATE PROCEDURE k_sp_del_room @RoomNm NVARCHAR(50), @WorkAreaId CHAR(32) AS
  DELETE k_rooms WHERE nm_room=@RoomNm AND gu_workarea=@WorkAreaId
GO;
