package com.knowgate.hipermail;

import javax.mail.Authenticator;
import javax.mail.PasswordAuthentication;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class SilentAuthenticator extends Authenticator {
  private PasswordAuthentication oPwdAuth;

  public SilentAuthenticator(String sUserName, String sAuthStr) {
    oPwdAuth = new PasswordAuthentication(sUserName, sAuthStr);
  }

  protected PasswordAuthentication getPasswordAuthentication() {
    return oPwdAuth;
  }
}
