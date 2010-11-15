CREATE OR REPLACE PROCEDURE k_sp_read_microsite (IdMicrosite CHAR, IdApp OUT NUMBER, NmMicrosite OUT VARCHAR2, Path OUT VARCHAR2, IdWorkArea OUT CHAR) IS
BEGIN
  SELECT id_app,nm_microsite,path_metadata,gu_workarea INTO IdApp,NmMicrosite,Path,IdWorkArea FROM k_microsites WHERE gu_microsite=IdMicrosite;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IdApp:=NULL;
    NmMicrosite:=NULL;
    Path:=NULL;
END k_sp_read_microsite;
GO;

CREATE OR REPLACE PROCEDURE k_sp_read_pageset (IdPageSet CHAR, IdMicrosite OUT CHAR, NmMicrosite OUT VARCHAR2, IdWorkArea OUT CHAR, NmPageSet OUT VARCHAR2, VsStamp OUT VARCHAR2, IdLanguage OUT CHAR, DtModified OUT DATE, PathData OUT VARCHAR2, IdStatus OUT VARCHAR2, PathMetaData OUT VARCHAR2, TxComments OUT VARCHAR2, GuCompany OUT CHAR, GuProject OUT CHAR, TxEmailFrom OUT VARCHAR2,TxEmailReply OUT VARCHAR2, NmFrom OUT VARCHAR2, TxSubject OUT VARCHAR2) IS
BEGIN
  SELECT m.nm_microsite,m.gu_microsite,p.gu_workarea,p.nm_pageset,p.vs_stamp,p.id_language,p.dt_modified,p.path_data,p.id_status,m.path_metadata,p.tx_comments,p.gu_company,p.gu_project,p.tx_email_from,p.tx_email_reply,p.nm_from,p.tx_subject INTO NmMicrosite,IdMicrosite,IdWorkArea,NmPageSet,VsStamp,IdLanguage,DtModified,PathData,IdStatus,PathMetaData,TxComments,GuCompany,GuProject,TxEmailFrom,TxEmailReply,NmFrom,TxSubject FROM k_pagesets p, k_microsites m WHERE p.gu_pageset=IdPageSet AND p.gu_microsite(+)=m.gu_microsite;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NmMicrosite:=NULL;
    IdMicrosite:=NULL;
    IdWorkArea :=NULL;
    NmPageSet  :=NULL;
    DtModified :=NULL;
    GuCompany  :=NULL;
    GuProject  :=NULL;
    NmFrom     :=NULL;
    TxSubject  :=NULL;    
    TxEmailFrom:=NULL;
    TxEmailReply:=NULL;
END k_sp_read_pageset;
GO;
