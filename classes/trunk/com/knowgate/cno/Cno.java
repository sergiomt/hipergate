package com.knowgate.cno;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;

import com.knowgate.misc.Gadgets;

public class Cno {

	private String entrada;
	private String salida;
	private String workarea;
	private String domain;
	
	public Cno(String entrada, String salida, String workarea,String domain)  {
		this.entrada = entrada;
		this.salida = salida;
		this.workarea = workarea;
		this.domain = domain;
	}
	public void generarSQL() throws FileNotFoundException{
		File archivo = null;
		FileReader fr = null;
		BufferedReader br = null;

		File archivo2 = null;
		FileWriter fw = null;
		BufferedWriter bw = null;

		try {
			// Apertura del fichero y creacion de BufferedReader para poder
			// hacer una lectura comoda (disponer del metodo readLine()).
			archivo = new File(entrada);
			fr = new FileReader(archivo);
			br = new BufferedReader(fr);
			
			archivo2 = new File(salida);
			fw = new FileWriter(archivo2);
			bw = new BufferedWriter(fw);

			// Lectura del fichero
			String linea;
			String guiRoot = "";
			String nivel1="";
			String guiNivel1="";
			String nivel2="";
			String guiNivel2="";
			String nivel3="";
			String guiNivel3="";
			String nivel4="";
			String guiNivel4="";
			
	
			String sqlRoot ="INSERT INTO k_thesauri_root (gu_rootterm,tx_term,id_scope,id_domain,gu_workarea) VALUES ('";
			String sqlNivel1 = "INSERT INTO k_thesauri (gu_rootterm,gu_term,id_language,bo_mainterm,tx_term,id_scope,id_domain,id_term0";
			String sqlNivel2 = sqlNivel1 + ",id_term1";
			String sqlNivel3 = sqlNivel2 + ",id_term2";
			String sqlNivel4 = sqlNivel3 + ",id_term3";
		
			while ((linea = br.readLine()) != null){
				String cadena[] = linea.split(",");
				if(cadena[0].length()==1 && isNumero(cadena[0])){ //nivel alto
					nivel1=cadena[0];
					guiRoot = Gadgets.generateUUID();
					System.gc();
					String nombre = cadena[1].toUpperCase();
					
					String query=sqlRoot + guiRoot + "','"+ nombre +"','cno',"+domain+",'"+workarea+"');\n";
					System.out.println(guiRoot);
					bw.write(query);
					guiNivel1 = Gadgets.generateUUID();
					System.gc();
					query = sqlNivel1 + ") VALUES ('"+ guiRoot + "','" + guiNivel1 + "','es',1,'" + nombre + "','cno',"+ domain + "," + nivel1 +");\n";
					System.out.println(guiNivel1); 
					bw.write(query);
				}
				
				if(cadena[0].length()==2){
					nivel2 = cadena[0];
					guiNivel2 = Gadgets.generateUUID();
					System.gc();
					String nombre = cadena[1].toUpperCase();
					
					String query = sqlNivel2 + ") VALUES ('"+ guiRoot + "','" + guiNivel2 + "','es',1,'" + nombre + "','cno',"+ domain + "," + nivel1 +"," + nivel2 + ");\n";
					System.out.println(guiNivel2);
					bw.write(query);
					
				}
				
				if(cadena[0].length()==3){
					nivel3 = cadena[0];
					guiNivel3 = Gadgets.generateUUID();
					System.gc();
					String nombre = cadena[1].toUpperCase();
					
					String query = sqlNivel3 + ") VALUES ('"+ guiRoot + "','" + guiNivel3 + "','es',1,'" + nombre + "','cno',"+ domain + "," + nivel1 +"," + nivel2 + "," + nivel3 + ");\n";
					System.out.println(guiNivel3);
					bw.write(query);
					
				}
				
				if(cadena[0].length()==4){
					nivel4 = cadena[0];
					guiNivel4 = Gadgets.generateUUID();
					System.gc();
					String nombre = cadena[1].toUpperCase();
					
					String query = sqlNivel4 + ") VALUES ('"+ guiRoot + "','" + guiNivel4 + "','es',1,'" + nombre + "','cno',"+ domain + "," + nivel1 +"," + nivel2 +"," + nivel3 +"," + nivel4 + ");\n";
					System.out.println(guiNivel4);
					bw.write(query);
					
				}
				
			
			}
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			// En el finally cerramos el fichero, para asegurarnos
			// que se cierra tanto si todo va bien como si salta
			// una excepcion.
			try {
				bw.flush();
				bw.close();
				
				if (null != fr) {
					fr.close();
				}
				if (null != fw) {
					fw.close();
				}

			} catch (Exception e2) {
				e2.printStackTrace();
			}
		}
	}

	
	public boolean isNumero(String cadena){
		try {
			Integer.parseInt(cadena);
			return true;
		} catch (NumberFormatException nfe){
			return false;
		}
	}
}
