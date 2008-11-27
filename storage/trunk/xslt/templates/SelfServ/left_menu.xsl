<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template name="leftmenu">

	<td class="leftColumn" width="220px" nowrap="nowrap">
      <img src="http://www.fundacioncomillasweb.com/dms/comillas3/img/bolo_menu_dos/bolo_menu_dos.gif"/>&#160;<a target="_top" href="http://www.fundacioncomillasweb.com/es/publico/servicios/laFundacion/informacion.html">La&#160;Fundacion&#160;Campus&#160;Comillas</a><br/>
      <img src="http://www.fundacioncomillasweb.com/dms/comillas3/img/bolo_menu_dos/bolo_menu_dos.gif"/>&#160;<a target="_top" href="http://www.fundacioncomillasweb.com/es/publico/servicios/patrocinioyMecenazgo.html">Patrocinio&#160;y&#160;Mecenazgo</a><br/>
      <img src="http://www.fundacioncomillasweb.com/dms/comillas3/img/bolo_menu_dos/bolo_menu_dos.gif"/>&#160;<a target="_top" href="http://www.fundacioncomillasweb.com/es/publico/servicios/amigos.html">Club&#160;de&#160;amigos&#160;de&#160;la&#160;Fundacion&#160;&#160;</a><br/>
      <img src="http://www.fundacioncomillasweb.com/dms/comillas3/img/bolo_menu_dos/bolo_menu_dos.gif"/>&#160;<a target="_top" href="http://www.fundacioncomillasweb.com/es/publico/servicios/multimedia.html">Imagenes&#160;y&#160;multimedia</a><br/>
      <img src="http://www.fundacioncomillasweb.com/dms/comillas3/img/bolo_menu_dos/bolo_menu_dos.gif"/>&#160;<a target="_top" href="http://www.fundacioncomillasweb.com/es/publico/servicios/informacionAcademica.html">Informacion&#160;Academica</a><br/>
      <img src="http://www.fundacioncomillasweb.com/dms/comillas3/img/bolo_menu_dos/bolo_menu_dos.gif"/>&#160;<a target="_top" href="http://www.fundacioncomillasweb.com/es/publico/servicios/vidaComunitaria.html">Vida&#160;Comunitaria</a><br/>
      <img src="http://www.fundacioncomillasweb.com/dms/comillas3/img/bolo_menu_dos/bolo_menu_dos.gif"/>&#160;<a target="_top" href="http://www.fundacioncomillasweb.com/es/publico/servicios/situacionyEntorno.html">Situacion&#160;y&#160;entorno</a><br/>

      <div id="login_box" class="area_personal_home">
        <h2 class="conpestaniadetras"><span class="negro">&Aacute;rea</span> personal</h2>
        <form action="http://extranet.fundacioncomillasweb.com/login.jsp" name="login_home" id="login_home" method="post">
          <input type="hidden" name="redirect" value="/foros.jsp" />
          <label for="nombre_usuario">Usuario</label> <input type="text" value="usuario" name="nombre_usuario" id="nombre_usuario" class="campo_texto" /> 
          <label for="password">Contrase&ntilde;a</label> <input type="password" value="1234" name="password" id="password" class="campo_texto" /> 
          <br/>
          <input type="image" alt="Entrar" value="Entrar" src="http://www.fundacioncomillasweb.com/dms/comillas3/img/btn_entrar/btn_entrar.gif" name="btn_entrar_login" id="btn_entrar_login" class="btn" />
        </form>
      </div> 
  </td>
</xsl:template>	
</xsl:stylesheet>