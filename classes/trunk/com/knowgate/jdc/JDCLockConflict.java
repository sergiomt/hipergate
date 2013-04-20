package com.knowgate.jdc;

/**
 * @author Sergio Montoro Ten
 * @version 5.5
 */
public class JDCLockConflict {

	private int iCurrentPID;
	private int iWaitingOnPID;
	private String sCurrentQuery;
	private String sWaitingOnQuery;

    public JDCLockConflict(int iPID, int iWaitOnPID, String sQry, String sWaitOnQry) {
		iCurrentPID = iPID;
		iWaitingOnPID = iWaitOnPID;
		sCurrentQuery = sQry;
		sWaitingOnQuery = sWaitOnQry;
    }

	public int getPID() {
		return iCurrentPID;
	}

	public int getWaitingOnPID() {
		return iWaitingOnPID;
	}

	public String getQuery() {
		return sCurrentQuery;
	}

	public String getWaitingOnQuery() {
		return sWaitingOnQuery;
	}

}
