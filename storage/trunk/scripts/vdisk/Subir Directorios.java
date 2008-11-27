/**
  * Sube una estructura completa de directorios bajo una categoría
**/

  import java.io.IOException;
  import java.sql.SQLException;
  import java.sql.Connection;
    
  import com.knowgate.hipergate.Category;
  import com.knowgate.misc.Environment;
  
  // Parametros de la Categoría Base y el Directorio a Subir
  String BaseCategoryName = "TEST1_administrador_favs";
  String IdWorkArea = "f7f055ca39854673b17518ec5f87de3b";
  String SourcePath = "file:///tmp/links";
  String Language = "es";

  String Protocol = Environment.getProfileVar("hipergate", "fileprotocol");
  String Server = Environment.getProfileVar("hipergate", "fileserver");
  String WrkAPut = Environment.getProfileVar("hipergate", "workareasput");
  String sCatId;          
  try {
    Category oBaseCategory = new Category(DefaultConnection, Category.getIdFromName(DefaultConnection, BaseCategoryName));
    
    DefaultConnection.setAutoCommit (false);

    oBaseCategory.uploadDirectory(DefaultConnection, SourcePath, Protocol, Server,
    				  WrkAPut + "/" + IdWorkArea + "/" + oBaseCategory.getPath(DefaultConnection),
    				  Language);
			  
  }

  catch (SQLException e) {  
    ReturnValue = "ERROR: " + e.getMessage();
  }
  catch (IOException e) {  
    ReturnValue = "ERROR: " + e.getMessage();
  }

