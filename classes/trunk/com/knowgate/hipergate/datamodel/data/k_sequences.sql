CREATE TABLE k_sequences
(
nm_table    CHAR(18) NOT NULL,
nu_initial  INTEGER  NOT NULL,
nu_maxval   INTEGER  NOT NULL,
nu_increase INTEGER  NOT NULL,
nu_current  INTEGER  NOT NULL,

CONSTRAINT  pk_sequences PRIMARY KEY (nm_table)
)
;

INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_domains', 2049, 524288, 1, 2049);
INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_thesauri', 100000000, 999999999, 1, 100000000);
INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_mime_msgs', 1, 2147483647, 1, 1);
INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_job_atoms', 1, 2147483647, 1, 1);
INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_msg_votes', 1, 2147483647, 1, 1);
INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_webbeacons', 1, 2147483647, 1, 1);
INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_adhoc_mail', 1, 2147483647, 1, 1);
INSERT INTO k_sequences (nm_table,nu_initial,nu_maxval,nu_increase,nu_current) VALUES ('seq_k_bulkloads', 1, 2147483647, 1, 1);
