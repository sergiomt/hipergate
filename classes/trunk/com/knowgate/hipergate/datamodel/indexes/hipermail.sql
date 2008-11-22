CREATE INDEX i1_inet_addrs ON k_inet_addrs(gu_mimemsg);
CREATE INDEX i2_inet_addrs ON k_inet_addrs(tx_email);
CREATE INDEX i3_inet_addrs ON k_inet_addrs(tp_recipient);
CREATE INDEX i4_inet_addrs ON k_inet_addrs(tx_personal);
CREATE INDEX i5_inet_addrs ON k_inet_addrs(id_message);
CREATE INDEX i6_inet_addrs ON k_inet_addrs(pg_message);


CREATE INDEX i1_mime_msgs ON k_mime_msgs(gu_workarea);
CREATE INDEX i2_mime_msgs ON k_mime_msgs(gu_category);
CREATE INDEX i3_mime_msgs ON k_mime_msgs(id_message);
CREATE INDEX i4_mime_msgs ON k_mime_msgs(tx_subject);

