package com.knowgate.storage;

public enum ErrorCode {

   SUCCESS                     (0),
   WORKAREA_MAY_NOT_BE_NULL    (1001),
   WORKAREA_MAY_NOT_BE_EMPTY   (1002),
   WORKAREA_ALREADY_REGISTERED (1003),
   WORKAREA_NOT_FOUND          (1004),
   PASSWORD_MAY_NOT_BE_NULL    (1005),
   PASSWORD_MAY_NOT_BE_EMPTY   (1006),
   PASSWORD_MISMATCH           (1007),
   EMAIL_MAY_NOT_BE_NULL       (1008),
   EMAIL_IS_NOT_VALID          (1009),
   EMAIL_ALREADY_EXISTS        (1010),
   USER_MAY_NOT_BE_NULL        (1011),
   USER_MAY_NOT_BE_EMPTY       (1012),   
   USER_ALREADY_EXISTS         (1013),
   USER_NOT_FOUND              (1014),
   SECURITYTOKEN_INVALID       (1015),
   CONFIRMATION_KEY_INVALID    (1016),
   ACCOUNT_DEACTIVATED         (1017),
   SESSION_EXPIRED             (1018),

   DATABASE_EXCEPTION          (8000),
   ILLEGALARGUMENT_EXCEPTION   (8001),
   IO_EXCEPTION      		   (8002),
   FILENOTFOUND_EXCEPTION      (8003),

   UNKNOWN_ERROR                (666);
   	   
   private final int iErrorCode;

   ErrorCode (int iErrCod) {
     iErrorCode = iErrCod;
   }

   public String toString() {
   	return String.valueOf(iErrorCode);
   }

   public final int intValue() {
   	return iErrorCode;
   }

}
