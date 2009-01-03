package com.knowgate.hipergate.mobile;

import com.knowgate.debug.DebugFile;

import org.morfeo.tidmobile.context.ApplicationContextNode;
import org.morfeo.tidmobile.server.ApplInitializer;

import com.knowgate.dataobjs.DBBind;

public class ApplicationInitializer implements ApplInitializer {

	public void intialize(ApplicationContextNode oAppCtxNode) throws Throwable {
		
		if (DebugFile.trace) DebugFile.writeln("ApplicationInitializer.intialize(ApplicationContextNode)");

		oAppCtxNode.setElement("dbmobile", new DBBind());
	}

}
