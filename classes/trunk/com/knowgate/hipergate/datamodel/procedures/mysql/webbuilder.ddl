CREATE PROCEDURE k_sp_read_microsite (IdMicrosite CHAR(32), OUT IdApp INT, OUT NmMicrosite VARCHAR(128), OUT Path VARCHAR(254), OUT IdWorkArea CHAR(32))
BEGIN
  SELECT id_app,nm_microsite,path_metadata,gu_workarea INTO IdApp,NmMicrosite,Path,IdWorkArea FROM k_microsites WHERE gu_microsite=IdMicrosite;
END
GO;

CREATE PROCEDURE k_sp_read_pageset (IdPageSet CHAR(32), OUT IdMicrosite CHAR(32), OUT NmMicrosite VARCHAR(128), OUT IdWorkArea CHAR(32), OUT NmPageSet VARCHAR(100), OUT VsStamp VARCHAR(16), OUT IdLanguage CHAR(2), OUT DtModified TIMESTAMP, OUT PathData VARCHAR(254), OUT IdStatus VARCHAR(30), OUT PathMetaData VARCHAR(254), OUT TxComments VARCHAR(254), OUT GuCompany CHAR(32), OUT GuProject CHAR(32), OUT TxEmailFrom VARCHAR(254), OUT TxEmailReply VARCHAR(254), OUT NmFrom VARCHAR(254), OUT TxSubject VARCHAR(254))
BEGIN
  SELECT m.nm_microsite,m.gu_microsite,p.gu_workarea,p.nm_pageset,p.vs_stamp,p.id_language,p.dt_modified,p.path_data,p.id_status,m.path_metadata,p.tx_comments,p.gu_company,p.gu_project,p.tx_email_from,p.tx_email_reply,p.nm_from,p.tx_subject INTO NmMicrosite,IdMicrosite,IdWorkArea,NmPageSet,VsStamp,IdLanguage,DtModified,PathData,IdStatus,PathMetaData,TxComments,GuCompany,GuProject,TxEmailFrom,TxEmailReply,NmFrom,TxSubject FROM k_pagesets p LEFT OUTER JOIN k_microsites m ON p.gu_microsite=m.gu_microsite WHERE p.gu_pageset=IdPageSet;
END
GO;