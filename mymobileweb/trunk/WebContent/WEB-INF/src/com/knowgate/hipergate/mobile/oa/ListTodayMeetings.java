package com.knowgate.hipergate.mobile.oa;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.morfeo.tidmobile.context.Context;
import org.morfeo.tidmobile.server.oa.BasicApplicationOperation;
import org.morfeo.tidmobile.server.oa.OAException;

public class ListTodayMeetings extends BasicApplicationOperation {

  public void execute(Context oCtx) throws OAException {

	List<Map<String,String>> oTableModel = new ArrayList<Map<String,String>>();

	for (int j = 0; j < 5; j++) {
	  Map<String,String> oRow = new HashMap<String,String>();
	  oRow.put("title","Reunión Nº " + String.valueOf(j));			
	  oRow.put("guid","G-" + String.valueOf(j));
	  oTableModel.add(oRow);
	} // next

	oCtx.setElement("dataTable", oTableModel);		
  } // execute

}
