package com.knowgate.workareas;

public enum ApplicationModule {

   INCIDENTS_TRACKER (10),
   DUTY_MANAGER      (11),
   PROJECT_MANAGER   (12),
   MAIL_WIRE         (13),
   WEB_BUILDER       (14),
   VIRTUAL_DISK      (15),
   CONTACT_MANAGER   (16),
   COLLAB_TOOLS      (17),
   MARKETING_TOOLS   (18),
   DIRECTORY         (19),
   SHOP              (20),
   HIPERMAIL         (21),
   TRAINING          (22),
   WIKI              (23),
   PASSWORD_MANAGER  (24),
   SURVEYS           (25),
   CONFIGURATION     (30);
   	   
   private final int iInternalId;

   ApplicationModule (int nBitPosition) {
     iInternalId = 1<<nBitPosition;
    }

   public boolean available(int iUserAppMask) {
   	 return (iUserAppMask & iInternalId)!=0;
   }

   public boolean unavailable(int iUserAppMask) {
   	 return (iUserAppMask & iInternalId)==0;
   }

}
