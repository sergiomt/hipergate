/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

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
