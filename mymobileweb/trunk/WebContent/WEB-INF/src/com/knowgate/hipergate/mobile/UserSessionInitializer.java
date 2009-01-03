package com.knowgate.hipergate.mobile;

import com.knowgate.debug.DebugFile;

import org.morfeo.tidmobile.context.Context;
import org.morfeo.tidmobile.server.SessionInitializer;

public class UserSessionInitializer implements SessionInitializer {

	@Override
	public void initializeSession(Context oCtx) throws Throwable {
		if (DebugFile.trace) DebugFile.writeln("UserSessionInitializer.initializeSession(Context)");

		oCtx.setSessionElement("authenticated", new Boolean(false));
	}

}
