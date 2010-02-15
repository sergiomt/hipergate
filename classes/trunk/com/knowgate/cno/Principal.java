package com.knowgate.cno;

import java.io.FileNotFoundException;

public class Principal {

	/**
	 * @param args
	 * @throws FileNotFoundException 
	 */
	public static void main(String[] args) throws FileNotFoundException {
		Cno c = new Cno("trunk/com/knowgate/cno/cno94-2.csv","trunk/com/knowgate/cno/salida.sql","ac1263a41235754c75c1000009a5fd79","2052");
		c.generarSQL();
	}

}
