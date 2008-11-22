CREATE INDEX i1_newsgrp ON k_newsgroups(gu_workarea);

CREATE INDEX i1_newsmsgs ON k_newsmsgs(gu_thread_msg);

CREATE INDEX i2_newsmsgs ON k_newsmsgs(dt_start);

CREATE INDEX i3_newsmsgs ON k_newsmsgs(dt_expire);

CREATE INDEX i4_newsmsgs ON k_newsmsgs(nm_author);

CREATE INDEX i5_newsmsgs ON k_newsmsgs(id_status);

CREATE INDEX i6_newsmsgs ON k_newsmsgs(tx_subject);
