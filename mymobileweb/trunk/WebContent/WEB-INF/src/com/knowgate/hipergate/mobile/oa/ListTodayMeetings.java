package com.knowgate.hipergate.mobile.oa;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.sql.Types;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Date;
import java.util.GregorianCalendar;

import org.morfeo.tidmobile.context.Context;

import org.morfeo.tidmobile.server.oa.BasicApplicationOperation;
import org.morfeo.tidmobile.server.oa.OAException;

import com.knowgate.hipergate.mobile.ApplicationInitializer;
import com.knowgate.hipergate.mobile.UserProfileManager;

import com.knowgate.dataobjs.DB;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.acl.ACLUser;

public class ListTodayMeetings extends BasicApplicationOperation {

  public void execute(Context oCtx) throws OAException {

	JDCConnection oConn = null;
	PreparedStatement oStmt = null;
	ResultSet oRSet = null;
	List<Map<String,String>> oTableModel = new ArrayList<Map<String,String>>();
	GregorianCalendar oNow = new GregorianCalendar();
	GregorianCalendar oD00 = new GregorianCalendar(oNow.get(GregorianCalendar.YEAR),oNow.get(GregorianCalendar.MONTH), oNow.get(GregorianCalendar.DAY_OF_MONTH), 0, 0, 0);
	GregorianCalendar oD23 = new GregorianCalendar(oNow.get(GregorianCalendar.YEAR),oNow.get(GregorianCalendar.MONTH), oNow.get(GregorianCalendar.DAY_OF_MONTH), 23, 59, 59);
	
	try {
		oConn = ApplicationInitializer.getConnection("ListTodayMeetings.execute");
		ACLUser oUsrP = UserProfileManager.getUserProfile(oCtx);
		oStmt = oConn.prepareStatement("SELECT m."+DB.gu_meeting+",m."+DB.dt_start+",m."+DB.dt_end+",m."+DB.tx_meeting+
				                       " FROM "+DB.k_meetings+" m,"+DB.k_x_meeting_fellow+" x WHERE m."+
				                       DB.gu_meeting+"=x."+DB.gu_meeting+" AND m."+DB.gu_workarea+"=? AND m."+DB.dt_start+" BETWEEN ? AND ? AND x."+DB.gu_fellow+"=?");
		oStmt.setObject (1, oUsrP.get(DB.gu_workarea), Types.CHAR);
		oStmt.setTimestamp(2, new Timestamp(oD00.getTimeInMillis()), oD00);
		oStmt.setTimestamp(3, new Timestamp(oD23.getTimeInMillis()), oD23);
		oStmt.setObject (4, oUsrP.get(DB.gu_user), Types.CHAR);
		oRSet = oStmt.executeQuery();
		while (oRSet.next()) {
			Map<String,String> oRow = new HashMap<String,String>();
			oRow.put("guid",oRSet.getString(1));
			Date oDts = oRSet.getDate(2);
			Date oDte = oRSet.getDate(3);
			String sTx = oRSet.getString(4);
			if (oRSet.wasNull()) sTx = "";
			oRow.put("title",String.valueOf(oDts.getHours())+":"+String.valueOf(oDts.getMinutes())+"-"+
					         String.valueOf(oDte.getHours())+":"+String.valueOf(oDte.getMinutes())+" "+
					         sTx);
			oTableModel.add(oRow);			
		} // wend
		oRSet.close();
		oStmt.close();
		oConn.close("ListTodayMeetings.execute");
	} catch (SQLException sqle) {
		if (null!=oConn) try { oConn.close("ListTodayMeetings.execute"); } catch (SQLException ignore) {}
		throw new OAException(sqle.getMessage(), sqle);
	}
	oCtx.setElement("dataTable", oTableModel);		
  } // execute

}
