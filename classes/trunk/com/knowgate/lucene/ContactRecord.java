/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

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

package com.knowgate.lucene;

import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;

/**
 * @author Alfonso Marin 
 * @version 1.0
 */
public class ContactRecord {

	public static class CompareAuthor implements Comparator {
		public int compare(Object o1, Object o2) {
			if (((ContactRecord) o1).getAuthor() == null)
				return -1;
			return ((ContactRecord) o1).getAuthor().compareTo(
					((ContactRecord) o2).getAuthor());
		}
	}

	public static class CompareScore implements Comparator {
		public int compare(Object o1, Object o2) {
			ContactRecord c1 = (ContactRecord)o1;
			ContactRecord c2 = (ContactRecord)o2;
			if(c1.getScore()!=c2.getScore()) return -1;
			else return 0;
		}
	}
	
	public static final String COURSE = "course";
	public static final String DEGREE = "degree";
	public static final String LANGUAGE = "language";
	public static final String SCIENCE = "science";
	public static final String SEPARADOR_VALUE = ";";
	public static final String SEPARADOR_LEVEL = "-";
	
	
	private float score; //como habra distintos documents para cada usuario, podemos sumar sus scores.
	private String author;
	private String workarea;
	private String gui;
	private String value; //contendra los textos de los curso y la nota curso-nota;curso-nota
	
	public ContactRecord() {
	}


	public ContactRecord(Float score, String author, String workarea, String gui) {
		this(score,author,workarea,gui,"");
	}	
	public ContactRecord(Float score, String author, String workarea, String gui,String value) {
		if(score != null)
			this.score = score;
		this.author = author;
		this.workarea = workarea;
		this.gui = gui;
		this.value = value;
	}

	public float getScore() {
		return score;
	}

	public void setScore(float score) {
		this.score = score;
	}
	
	public void addScore(float score) {
		this.score += score;
	}
	
	public String getAuthor() {
		return author;
	}

	public void setAuthor(String author) {
		this.author = author;
	}

	public String getWorkarea() {
		return workarea;
	}

	public void setWorkarea(String workarea) {
		this.workarea = workarea;
	}

	public String getGui() {
		return gui;
	}

	public void setGui(String gui) {
		this.gui = gui;
	}
	
	public String getValue(){
		return value;
	}
	public Map<String,String> getValues(){
		Map<String,String> resultado = new HashMap<String,String>();
		String pares[] = value.split(SEPARADOR_VALUE);
		for(int i=0;i<pares.length;i++){
			String valor[] = pares[i].split(SEPARADOR_LEVEL);
			resultado.put(valor[0],valor[1]);
		}
		return resultado;
	}
	public void setValue(String value){
		this.value = value;
	}
	
	public void addValue(String value, String level){
		this.value += value + SEPARADOR_LEVEL + level + SEPARADOR_VALUE;
	}

	@Override
	public boolean equals(Object obj) {
		return gui.equals(obj);
	}

	@Override
	public int hashCode() {
		return gui.hashCode();
	}



}
