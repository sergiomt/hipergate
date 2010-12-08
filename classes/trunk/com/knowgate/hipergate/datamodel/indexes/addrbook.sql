CREATE INDEX i1_fellows ON k_fellows(gu_workarea);

CREATE INDEX i2_fellows ON k_fellows(tx_name);

CREATE INDEX i3_fellows ON k_fellows(tx_surname);

CREATE INDEX i4_fellows ON k_fellows(tx_email);

CREATE INDEX i1_meetings ON k_meetings(gu_fellow);

CREATE INDEX i2_meetings ON k_meetings(dt_start);

CREATE INDEX i3_meetings ON k_meetings(dt_end);

CREATE INDEX i4_meetings ON k_meetings(id_icalendar);

CREATE INDEX i1_phone_calls ON k_phone_calls (gu_workarea);

CREATE INDEX i2_phone_calls ON k_phone_calls (gu_user);

CREATE INDEX i3_phone_calls ON k_phone_calls (gu_contact);

CREATE INDEX i4_phone_calls ON k_phone_calls (gu_bug);

CREATE INDEX i1_to_do ON k_to_do (gu_workarea);

CREATE INDEX i2_to_do ON k_to_do (gu_user);

CREATE INDEX i3_to_do ON k_to_do (tl_to_do);

CREATE INDEX i4_to_do ON k_to_do (od_priority);



