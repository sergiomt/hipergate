
ALTER TABLE k_lu_fellow_titles DROP CONSTRAINT f1_lu_fellow_titles;

ALTER TABLE k_fellows DROP CONSTRAINT f1_fellows;
ALTER TABLE k_fellows DROP CONSTRAINT f2_fellows;
ALTER TABLE k_fellows DROP CONSTRAINT f3_fellows;

ALTER TABLE k_fellows_attach DROP CONSTRAINT f1_fellows_attach;

ALTER TABLE k_fellows_lookup DROP CONSTRAINT f1_fellows_lookup;

ALTER TABLE k_rooms DROP CONSTRAINT f1_rooms;
ALTER TABLE k_rooms DROP CONSTRAINT f2_rooms;

ALTER TABLE k_rooms_lookup DROP CONSTRAINT f1_rooms_lookup;

ALTER TABLE k_meetings DROP CONSTRAINT f1_meeting;
ALTER TABLE k_meetings DROP CONSTRAINT f2_meeting;
ALTER TABLE k_meetings DROP CONSTRAINT f3_meeting;

ALTER TABLE k_x_meeting_room DROP CONSTRAINT f1_x_meeting_room;

ALTER TABLE k_x_meeting_fellow DROP CONSTRAINT f1_x_meeting_fellow;

ALTER TABLE k_x_meeting_contact DROP CONSTRAINT f1_x_meeting_contact;

DROP TABLE k_to_do;

DROP TABLE k_to_do_lookup;

DROP TABLE k_phone_calls;

DROP TABLE k_x_meeting_contact;

DROP TABLE k_x_meeting_fellow;

DROP TABLE k_x_meeting_room;

DROP TABLE k_meetings_lookup;

DROP TABLE k_meetings;

DROP TABLE k_rooms_lookup;

DROP TABLE k_rooms;

DROP TABLE k_fellows_lookup;

DROP TABLE k_fellows_attach;

DROP TABLE k_fellows;

DROP TABLE k_lu_fellow_titles;

DROP TABLE k_working_time;

DROP TABLE k_working_calendar;
