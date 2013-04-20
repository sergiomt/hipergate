INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('SMS','SEND SMS PUSH TEXT MESSAGE','com.knowgate.scheduler.jobs.SMSSender');
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('NTFY','NOTIFY BY E-MAIL','com.knowgate.scheduler.events.NotifyByMail');
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('SEND','SEND MIME MESSAGES BY SMTP','com.knowgate.scheduler.jobs.MimeSender');
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('MAIL','SEND MAIL TEMPLATE BY SMTP','com.knowgate.scheduler.jobs.EmailSender');
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('SAVE','SAVE DOCUMENTS TO DISK','com.knowgate.scheduler.jobs.FileDumper');
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('FAX' ,'SEND DOCUMENTS BY FAX','com.knowgate.scheduler.jobs.FaxSender');
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('FTP' ,'SAVE DOCUMENTS TO FTP','com.knowgate.scheduler.jobs.FTPPublisher');
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('DUMY','DUMMY TESTING JOB','com.knowgate.scheduler.jobs.DummyJob');

INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('VOID','DO NOTHING','com.knowgate.scheduler.events.DoNothing');
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('NOPO','NEW OPORTUNITY','com.knowgate.scheduler.events.ExecuteBeanShell');
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('MOPO','MODIFY OPORTUNITY','com.knowgate.scheduler.events.ExecuteBeanShell');
INSERT INTO k_lu_job_commands (id_command,tx_command,nm_class) VALUES ('BEAN','EXECUTE BEAN SHELL SCRIPT','com.knowgate.scheduler.events.ExecuteBeanShell');
