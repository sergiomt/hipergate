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

package com.knowgate.hipergate;

import java.io.File;
import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.ByteArrayOutputStream;

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import java.net.URL;

import java.awt.MediaTracker;
import java.awt.RenderingHints;
import java.awt.Toolkit;
import java.awt.Frame;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.awt.image.RenderedImage;
import java.awt.image.ColorModel;
import java.awt.image.ComponentColorModel;
import java.awt.image.DataBuffer;
import java.awt.image.renderable.ParameterBlock;
import java.awt.color.ColorSpace;
import java.awt.Transparency;

import com.knowgate.debug.*;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Base64Decoder;
import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;

import com.sun.image.codec.jpeg.JPEGCodec;
import com.sun.image.codec.jpeg.JPEGImageEncoder;
import com.sun.image.codec.jpeg.JPEGEncodeParam;

/**
 * <p>Simple imaging transformations</p>
 * @author Sergio Montoro Ten
 * @version 2.1
 * @see com.knowgate.dataxslt.Image
 */

public class Image extends DBPersist {

  private int iImagingLibrary;

  private int iDimX;
  private int iDimY;

  private MediaTracker mediaTracker;

  private java.awt.Image oImg;

  /**
   * Create empty image, use AWT imaging routines.
   */
  public Image() {
    super(DB.k_images, "Image");
    iImagingLibrary = USE_AWT;
    mediaTracker = null;
  }

  /**
   * Create empty image.
   * @param iLibraryCode Imaging library to use. Either USE_AWT or USE_JAI.
   * @throws IllegalArgumentException
   */
  public Image(int iLibraryCode) throws IllegalArgumentException {
    super(DB.k_images, "Image");
    setImagingLibrary(iLibraryCode);
    mediaTracker = null;
  }

  /**
   * Load image properties from database.
   * @param oConn Database Connection.
   * @param sImageId Image GUID at k_images table.
   * @throws SQLException
   */
  public Image(JDCConnection oConn, String sImageId) throws SQLException {
    super(DB.k_images, "Image");

    iImagingLibrary = USE_AWT;
    mediaTracker = null;

    load(oConn, new Object[]{sImageId});
  }

  /**
   * Load Image directly from a Java AWT abstract Image
   * @param oAWTImage java.awt.Image object
   * @param sImagePath Optional. Path to image file name.
   * @param iLibraryCode Imaging library to use. Either USE_AWT or USE_JAI.
   */
  public Image(java.awt.Image oAWTImage, String sImagePath, int iLibrary) {
    super(DB.k_images, "Image");

    iImagingLibrary = iLibrary;
    mediaTracker = null;

    oImg = oAWTImage;

    if (null!=sImagePath)
      put(DB.path_image, sImagePath);
  }

  /**
   * <p>Load Image properties from database using file path as key.</p>
   * This method searched a file path into field path_image from k_images table.<br>
   * @param oConn Database Connection
   * @param oFile Image File Object
   * @param sFilePath Full path to Image File (as stored at k_images.path_image)
   * @throws SQLException
   */
  public Image(JDCConnection oConn, File oFile, String sFilePath) throws SQLException {
    super(DB.k_images, "Image");

    String sImageId;
    PreparedStatement oStmt;
    ResultSet oRSet;

    iImagingLibrary = USE_AWT;
    mediaTracker = null;

    if (DebugFile.trace) DebugFile.writeln("new Image([Conenction]," + oFile.getAbsolutePath() + "," + sFilePath);

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(SELECT " + DB.gu_image + " FROM " + DB.k_images + " WHERE " + DB.path_image + "='" + sFilePath + "'");

    oStmt = oConn.prepareStatement("SELECT " + DB.gu_image + " FROM " + DB.k_images + " WHERE " + DB.path_image + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, sFilePath);
    oRSet = oStmt.executeQuery();
    if (oRSet.next())
      sImageId = oRSet.getString(1);
    else
      sImageId = null;
    oRSet.close();
    oStmt.close();

    if (null==sImageId) {
      put(DB.gu_image, Gadgets.generateUUID());
    }
    else {
      put(DB.gu_image, sImageId);
    }

    put(DB.path_image, sFilePath);
    put(DB.len_file, new Long(oFile.length()).intValue());
  }

  //----------------------------------------------------------------------------

  /**
   * <p>Set imaging library to use.</p>
   * On many systems it is neccesary to have X-Windows started for being able to
   * use AWT imaging routines.<br>
   * @param iLibraryCode USE_AWT or USE_JAI
   * @see http://java.sun.com/products/java-media/jai/
   * @see http://java.sun.com/j2se/1.4.2/docs/api/
   */
  public void setImagingLibrary (int iLibraryCode) {

    if (DebugFile.trace) {
      switch (iLibraryCode) {
        case USE_AWT:
          DebugFile.writeln("Image.setImagingLibrary(USE_AWT)");
          break;
        case USE_JAI:
          DebugFile.writeln("Image.setImagingLibrary(USE_JAI)");
          break;
        default:
          DebugFile.writeln("Image.setImagingLibrary(" + String.valueOf(iLibraryCode) + ")");
      }
    }

    if (iLibraryCode!=USE_AWT && iLibraryCode!=USE_JAI)
      throw new IllegalArgumentException("Imaging library code must be Image.USE_AWT or Image.USE_JAI");

    iImagingLibrary = iLibraryCode;
  } // setImagingLibrary

  //----------------------------------------------------------------------------

  /**
   * <p>Get active imaging library.</p>
   * @return USE_AWT or USE_JAI
   */
  public int getImagingLibrary() {
    return iImagingLibrary;
  } // getImagingLibrary

  //----------------------------------------------------------------------------

  /**
   * <p>Store image properties at database.</p>
   * The image itself is kept as a disk file pointe by path_file field.<br>
   * On saving the Image a GUID is automatically assigned if one is not provided.<br>
   * Image file length, width and height are saved to len_file, dm_width and dm_height fields.<br>
   * Only GIF 89a and JPG/JPEG images are recognized for automatic dimensions computation.<br>
   * @param oConn Database Connection
   * @throws SQLException
   * @throws NoClassDefFoundError
   * @throws UnsatisfiedLinkError hen JAI native libraries (*_jai.so) are not
   * installed Sun JAI tries to use AWT which is slower but more compatible.
   * Some libraries of AWT are requiered. Particularly from Fedora Core 2:<br>
   * xorg-x11-devel (contains libXp.so, requiered by libawt.so),
   * fontconfig, fontconfig-devel, xorg-x11-libs, xorg-x11-libs-data, xorg-x11-Mesa-libGL
   */
  public boolean store(JDCConnection oConn)
    throws SQLException, UnsatisfiedLinkError, NoClassDefFoundError {
    File oFile;
    java.sql.Timestamp dtNow;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Image.store([Connection])");
      DebugFile.incIdent();
    }

    dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (!AllVals.containsKey(DB.gu_image))
      put(DB.gu_image, Gadgets.generateUUID());
    else
      replace(DB.dt_modified, dtNow);

    if (!AllVals.containsKey(DB.id_img_type))
      put(DB.id_img_type, getImageType());

    try {

      if (!AllVals.containsKey(DB.len_file)) {
        oFile = new File(getString(DB.path_image));
        put(DB.len_file, new Long(oFile.length()).intValue());
      } // fi (len_file)

      if (!AllVals.containsKey(DB.dm_width) && ! AllVals.containsKey(DB.dm_height)) {
        try {
          if (dimensions()) {
            put(DB.dm_width, iDimX);
            put(DB.dm_height, iDimY);
          } // fi (dimensions())
        }
        catch (NullPointerException e) {
          if (DebugFile.trace) DebugFile.writeln("Image.dimensions() - NullPointerException ");
          new ErrorHandler(e);
        }
      } // fi (dm_width && dm_height)

    }
    catch (FileNotFoundException fnf) {
      if (DebugFile.trace) DebugFile.writeln("FileNotFoundException:" + fnf.getMessage());
    }
    catch(IOException ioe) {
        if (DebugFile.trace) DebugFile.writeln("IOException:" + ioe.getMessage());
    }

    boolean bRetVal = super.store(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Image.store([Connection]) : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // store

  //----------------------------------------------------------------------------

  /**
   * Delete Image from database and from disk.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    boolean bRetVal;
    String sPath;
    File oFile;
    Statement oDlte;
    PreparedStatement oStmt;
    ResultSet oRSet;
    int iCount;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Image.delete([Connection])");
      DebugFile.incIdent();
      if (DebugFile.trace) DebugFile.writeln("Connection.executeUpdate(DELETE FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_object + "='" + getStringNull(DB.gu_image, "null") + "' AND " + DB.id_class + "=" + String.valueOf(Image.ClassId) + ")");
    }

    oDlte = oConn.createStatement();
    oDlte.executeUpdate("DELETE FROM " + DB.k_x_cat_objs + " WHERE " + DB.gu_object + "='" + getString(DB.gu_image) + "' AND " + DB.id_class + "=" + String.valueOf(Image.ClassId));
    oDlte.close();

    sPath = getString(DB.path_image);
    if (sPath.startsWith("file://")) sPath = sPath.substring(7);

    oFile = new File(sPath);

    if (oFile.exists() && oFile.isFile()) {
      oStmt = oConn.prepareStatement("SELECT COUNT(" + DB.gu_image + ") FROM " + DB.k_images + " WHERE " + DB.path_image + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, getString(DB.path_image));
      oRSet = oStmt.executeQuery();
      oRSet.next();
      iCount = oRSet.getInt(1);
      oRSet.close();
      oStmt.close();

      if (1==iCount)
        bRetVal = oFile.delete();
      else
        bRetVal = true;
    }
    else
      bRetVal = true;

    if (bRetVal)
      bRetVal = super.delete(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Image.delete([Connection]) : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete


  //----------------------------------------------------------------------------
  /**
   * <p>Get image file extension in lowercase.</p>
   */
  public String getImageType() {
    String sFilePath;;
    String sRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Image.getImageType()");
      DebugFile.incIdent();
    }

    sFilePath = getStringNull(DB.path_image,null);

    if (sFilePath==null) return null;

    int iDot = sFilePath.lastIndexOf(".");
    if (iDot>0)
      sRetVal = sFilePath.substring(++iDot).toLowerCase();
    else
      sRetVal = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Image.getImageType([Connection]) : " + (sRetVal!=null ? sRetVal : "null"));
    }
    return sRetVal;
  } // getImageType

  //----------------------------------------------------------------------------

  public String getImageCodec() {
    String sCodec;
    String sType = getImageType();

    if (sType.equalsIgnoreCase("jpg"))
      sCodec = "jpeg";
    else if (sType.equalsIgnoreCase("tif"))
      sCodec = "tiff";
    else
      sCodec = sType;

    return sCodec;
  }

  //----------------------------------------------------------------------------

  private int unsigned (byte by) {
    final byte MinusOne = -1;

    return (by<0) ? ((int) (by*MinusOne))+128 : (int) by;
  }

  // ----------------------------------------------------------

  private boolean dimensionsJAI()
    throws IOException, FileNotFoundException, NullPointerException {

    boolean bRetVal = false;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Image.dimensionsJAI()");
      DebugFile.incIdent();
    }

    RenderedImage oImg;
    com.sun.media.jai.codec.ImageDecoder oDecoder;

    if (DebugFile.trace) DebugFile.writeln("new FileInputStream(" + getStringNull(DB.path_image,"null") + ")");

    FileInputStream oInputStream = new FileInputStream(getString(DB.path_image));

    oDecoder = com.sun.media.jai.codec.ImageCodec.createImageDecoder(getImageCodec(), oInputStream, null);

    oImg = oDecoder.decodeAsRenderedImage();

    iDimX = oImg.getWidth();
    iDimY = oImg.getHeight();

    oInputStream.close();

    bRetVal = true;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Image.dimensionsJAI() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // dimensionsJAI

  // ----------------------------------------------------------

  /**
   * <p>Get image dimensions.</p>
   * Dimensions are stored at dm_width and dm_height properties.<br>
   * Only GIF 89a and JPG/JPEG images are supported
   * @return <b>true</b> if dimensions where successfully computed,
   * <b>false</b> if routine was unable to recognize file format.
   * @throws IOException
   * @throws FileNotFoundException
   * @throws ArrayIndexOutOfBoundsException
   * @throws NullPointerException
   * @throws UnsatisfiedLinkError When JAI native libraries (*_jai.so) are not
   * installed Sun JAI tries to use AWT which is slower but more compatible.
   * Some libraries of AWT are requiered. Particularly from Fedora Core 2:<br>
   * xorg-x11-devel (contains libXp.so, requiered by libawt.so),
   * fontconfig, fontconfig-devel, xorg-x11-libs, xorg-x11-libs-data, xorg-x11-Mesa-libGL
   */
  public boolean dimensions()
    throws IOException, FileNotFoundException, ArrayIndexOutOfBoundsException,
           UnsatisfiedLinkError, NullPointerException {

    boolean bRetVal;
    File oFile;
    FileInputStream oFileRead;
    String sType;
    int iFound;
    int iFileLen;
    byte byFile[];
    byte by;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Image.dimensions()");
      DebugFile.incIdent();
    }

    sType = getImageType();

    if (sType!=null) {

      if (USE_JAI==iImagingLibrary) {
        try {
          bRetVal = dimensionsJAI();
        }
          catch (IOException ioe) { if (DebugFile.trace) DebugFile.decIdent(); bRetVal = false; }
      }
      else
        bRetVal = false;

      if (!bRetVal) {
        sType = sType.toUpperCase();

        if (sType.equals("GIF")) {
          byFile = new byte[16];

          if (DebugFile.trace) DebugFile.writeln("new FileInputStream(" + getStringNull(DB.path_image,"null") + ")");

          oFileRead = new FileInputStream(getString(DB.path_image));
          oFileRead.read(byFile,0,16);
          oFileRead.close();

          iDimX = (unsigned(byFile[7]))*256 + (unsigned(byFile[6]));
          iDimY = (unsigned(byFile[9]))*256 + (unsigned(byFile[8]));

          if (DebugFile.trace) DebugFile.writeln("[width=" + String.valueOf(iDimX) + ",height=" + String.valueOf(iDimY) + "]");

          bRetVal = true;
        } // fi (sType==GIF)

        else if (sType.equals("JPG") || sType.equals("JPEG")) {

          if (DebugFile.trace) DebugFile.writeln("new File(" + getStringNull(DB.path_image,"null") + ")");

          oFile = new File(getString(DB.path_image));

          if (DebugFile.trace) DebugFile.writeln("filelen = " + String.valueOf(oFile.length()));

          iFileLen = new Long(oFile.length()).intValue();

          byFile = new byte[iFileLen];

          oFileRead = new FileInputStream(oFile);
          oFileRead.read(byFile, 0, iFileLen);
          oFileRead.close();

          iFound = 0;

          for (int iPos=21;
               iPos<iFileLen-10;
               iPos = (2 + iPos + (unsigned(byFile[iPos + 1]) * 256 + unsigned(byFile[iPos+2]))) ) {

            by = byFile[iPos];
            if ((by>=0xC0 && by<=0xC3) || (by>=0xC5 && by<=0xC7) || (by>=0xC9 && by<=0xCB) || (by>=0xCD && by<=0xCF)) {
              iFound = iPos;
              break;
            }
          } // next (iPos)

          if (0!=iFound) {
            iDimY = (unsigned(byFile[iFound + 4]) * 256 + unsigned(byFile[iFound + 5]));
            iDimX = (unsigned(byFile[iFound + 6]) * 256 + unsigned(byFile[iFound + 7]));

            if (DebugFile.trace) DebugFile.writeln("[width=" + String.valueOf(iDimX) + ",height=" + String.valueOf(iDimY) + "]");

            bRetVal = true;
          }
          else {
            if (DebugFile.trace) DebugFile.writeln("JPEG dimensions bytecodes not found");
            bRetVal = false;
          }
        }
        else
          bRetVal = false;
        }
      } // fi (sType)
      else
        bRetVal = false;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Image.dimensions() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // dimensions

  // ----------------------------------------------------------

  private void drawAWTImage(OutputStream outStr, int iThumbWidth, int iThumbHeight, float fQuality) throws IOException, InstantiationException, InterruptedException {

    String sInputURI;
    Frame awtFrame;
    JPEGImageEncoder encoder;
    JPEGEncodeParam param;
    BufferedImage thumbImage;
    Graphics2D graphics2D;
    URL oURI;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Image.drawAWTImage([OutputStream], " + String.valueOf(iThumbWidth) + "," + String.valueOf(iThumbHeight) + "," + String.valueOf(fQuality));
      DebugFile.incIdent();
    }

    sInputURI = getString(DB.path_image);

    if (sInputURI.startsWith("http://") || sInputURI.startsWith("https://")) {
      oURI = new URL(sInputURI);

      if (DebugFile.trace) DebugFile.writeln("java.awt.Toolkit.getDefaultToolkit().getImage([java.net.URL])");

      oImg = Toolkit.getDefaultToolkit().getImage(oURI);
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("java.awt.Toolkit.getDefaultToolkit().getImage(sInputURI)");

      oImg = Toolkit.getDefaultToolkit().getImage(sInputURI);
    }

    int iImageWidth = oImg.getWidth(null);
    int iImageHeight = oImg.getHeight(null);

    double thumbRatio = ((double) iThumbWidth) / ((double) iThumbHeight);
    double imageRatio = ((double) iImageWidth) / ((double) iImageHeight);

    if (thumbRatio < imageRatio)
      iImageHeight = (int)(iThumbWidth / imageRatio);
    else
      iThumbWidth = (int)(iThumbHeight * imageRatio);

    if (null==mediaTracker) {
      if (DebugFile.trace) DebugFile.writeln("new java.awt.;Frame()");

      try {
        awtFrame = new Frame();
      } catch (Exception e) { throw new InstantiationException("Cannot instantiate java.awt.Frame " + (e.getMessage()!=null ? e.getMessage() : "")); }

      if (DebugFile.trace) DebugFile.writeln("new MediaTracker([Frame])");

      mediaTracker = new MediaTracker(awtFrame);
    } // fi (mediaTracker)

    mediaTracker.addImage(oImg, 0);
    mediaTracker.waitForID(0);

    // draw original image to thumbnail image object and
    // scale it to the new size on-the-fly
    thumbImage = new BufferedImage(iThumbWidth, iThumbHeight, BufferedImage.TYPE_INT_RGB);

    if (DebugFile.trace) DebugFile.writeln("java.awt.Graphics2D = thumbImage.createGraphics()");

    graphics2D = thumbImage.createGraphics();
    graphics2D.setRenderingHint(RenderingHints.KEY_INTERPOLATION,RenderingHints.VALUE_INTERPOLATION_BILINEAR);
    graphics2D.drawImage(oImg, 0, 0, iThumbWidth, iThumbHeight, null);
    graphics2D.dispose();

    if (DebugFile.trace) DebugFile.writeln("com.sun.image.codec.jpeg.JPEGImageEncoder = JPEGCodec.createJPEGEncoder([OutputStream]);");

    encoder = JPEGCodec.createJPEGEncoder(outStr);
    param = encoder.getDefaultJPEGEncodeParam(thumbImage);

	javax.imageio.plugins.jpeg.JPEGHuffmanTable t;
	javax.imageio.plugins.jpeg.JPEGQTable q;
	
    fQuality = Math.max(0, Math.min(fQuality, 100));
    if (fQuality>1)
      param.setQuality(fQuality / 100.0f, false);
    else
      param.setQuality(fQuality, false);

    encoder.setJPEGEncodeParam(param);

    if (DebugFile.trace) DebugFile.writeln("JPEGImageEncoder.encode([BufferedImage]);");

    encoder.encode(thumbImage);

    thumbImage.flush();

    mediaTracker.removeImage(oImg, 0);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Image.drawAWTImage()");
    }
  } // drawAWTImage()


  // ----------------------------------------------------------

  private void drawJAIImage(OutputStream outStr, int iThumbWidth, int iThumbHeight, float fQuality)
    throws IOException, InterruptedException, NullPointerException, IllegalArgumentException {

    com.sun.media.jai.codec.ImageDecoder oDecoder;
    RenderedImage oRenderedImg;
    javax.media.jai.PlanarImage oPlI;
    javax.media.jai.PlanarImage oScI;
    ParameterBlock oBlk;
    com.sun.media.jai.codec.ImageEncoder oImgEnc;
    String sInputURI;
    InputStream oInputStream;
    URL oURI;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Image.drawJAIImage([OutputStream], " + String.valueOf(iThumbWidth) + "," + String.valueOf(iThumbHeight) + "," + String.valueOf(fQuality) + ")");
      DebugFile.incIdent();
    }

    sInputURI = getString(DB.path_image);

    if (sInputURI.startsWith("http://") || sInputURI.startsWith("https://")) {

      if (DebugFile.trace) DebugFile.writeln("new URL(" + sInputURI + ")");

      oURI = new URL(sInputURI);
      oInputStream = oURI.openStream();
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("new FileInputStream(" + sInputURI + ")");

      try {
        oInputStream = new FileInputStream(sInputURI);
      } catch (FileNotFoundException fnf) {
        if (DebugFile.trace) DebugFile.decIdent();
        throw new FileNotFoundException(fnf.getMessage());
      }
    }

    oDecoder = com.sun.media.jai.codec.ImageCodec.createImageDecoder(getImageCodec(), oInputStream, null);

    oRenderedImg = oDecoder.decodeAsRenderedImage();

    if (getImageType().equals("gif")) {
      // Increase color depth to 16M RGB
      try {
        javax.media.jai.ImageLayout layout = new javax.media.jai.ImageLayout();

        ColorModel cm = new ComponentColorModel (ColorSpace.getInstance(ColorSpace.CS_sRGB),
                                                 new int[] {8,8,8}, false, false,
                                                 Transparency.OPAQUE, DataBuffer.TYPE_BYTE);
        layout.setColorModel(cm);
        layout.setSampleModel(cm.createCompatibleSampleModel(oRenderedImg.getWidth(),oRenderedImg.getHeight()));
        RenderingHints hints = new RenderingHints(javax.media.jai.JAI.KEY_IMAGE_LAYOUT, layout);
        javax.media.jai.ParameterBlockJAI pb = new javax.media.jai.ParameterBlockJAI( "format" );
        pb.addSource( oRenderedImg );
        oRenderedImg = javax.media.jai.JAI.create( "format", pb, hints );
      } catch (IllegalArgumentException iae) {
        if (DebugFile.trace) DebugFile.writeln(iae.getMessage() + " " + oRenderedImg.getColorModel().getClass().getName() + " " + oRenderedImg.getSampleModel().getClass().getName());
      }
      // End increase color depth
    } // gif

    oPlI = javax.media.jai.PlanarImage.wrapRenderedImage(oRenderedImg);

    int iImageWidth = oPlI.getWidth();
    int iImageHeight = oPlI.getHeight();

    if (DebugFile.trace) DebugFile.writeln("image width " + String.valueOf(iImageWidth));
    if (DebugFile.trace) DebugFile.writeln("image height " + String.valueOf(iImageHeight));

    float thumbRatio = ((float) iThumbWidth) / ((float) iThumbHeight);

    if (DebugFile.trace) DebugFile.writeln("thumb ratio " + String.valueOf(thumbRatio));

    float imageRatio = ((float) iImageWidth) / ((float) iImageHeight);

    if (DebugFile.trace) DebugFile.writeln("image ratio " + String.valueOf(imageRatio));

    if (thumbRatio < imageRatio)
      iThumbHeight = (int)(iThumbWidth / imageRatio);
    else
      iThumbWidth = (int)(iThumbHeight * imageRatio);

    float scaleW = ((float) iThumbWidth) / ((float) iImageWidth);

    if (DebugFile.trace) DebugFile.writeln("scale width " + String.valueOf(scaleW));

    float scaleH = ((float) iThumbHeight) / ((float) iImageHeight);

    if (DebugFile.trace) DebugFile.writeln("scale height " + String.valueOf(scaleH));

    oBlk = new ParameterBlock();

    oBlk.addSource(oPlI);

    oBlk.add(scaleW);
    oBlk.add(scaleH);
    oBlk.add(0.0f);
    oBlk.add(0.0f);
    oBlk.add(new javax.media.jai.InterpolationBilinear());

    if (DebugFile.trace) DebugFile.writeln("JAI.create (\"scale\", [ParameterBlock], null)");

    oScI = javax.media.jai.JAI.create("scale", oBlk, null); // scale image NOW !

    if (DebugFile.trace) DebugFile.writeln("ImageCodec.createImageEncoder( \"jpeg\", [OutputStream], null )");

    oImgEnc = com.sun.media.jai.codec.ImageCodec.createImageEncoder( "jpeg", outStr, null );

    if (null==oImgEnc) {
      oInputStream.close();
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("Cannot create ImageEncoder for jpeg");
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("ImageEncoder.encode ([PlanarImage])");

      oImgEnc.encode( oScI ); // write encoded data to given output stream

      oImgEnc =null;

      oInputStream.close();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Image.drawJAIImage()");
    }
  } // drawJAIImage

  // ----------------------------------------------------------
  /**
   * <p>Resample image.</p>
   * @param iThumbWidth Desired width
   * @param iThumbHeight Desired height
   * @param fQuality JPG Quality [1..100]
   * @return Byte array holding the generated JPEG image
   * @throws NullPointerException
   * @throws IOException
   * @throws InterruptedException
   * @throws InstantiationException
   */
  public byte[] createThumbBitmap(int iThumbWidth, int iThumbHeight, float fQuality)
    throws NullPointerException, IOException, InterruptedException, InstantiationException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Image.createThumbBitmap(" + String.valueOf(iThumbWidth) + "," + String.valueOf(iThumbHeight) + "," + String.valueOf(fQuality) + ")");
      DebugFile.incIdent();
    }

    ByteArrayOutputStream outStr = new ByteArrayOutputStream(iThumbWidth*iThumbHeight*3+1024);

    if (USE_AWT==iImagingLibrary)
      drawAWTImage (outStr, iThumbWidth, iThumbHeight, fQuality);
    else
      drawJAIImage (outStr, iThumbWidth, iThumbHeight, fQuality);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Image.createThumbBitmap()");
    }

    return outStr.toByteArray();
  } // createThumbBitmap()

  // ----------------------------------------------------------
  /**
   * <p>Resample image.</p>
   * @param sOutputPath File path where generated JPEG shall be saved.
   * @param iThumbWidth Desired width
   * @param iThumbHeight Desired height
   * @param fQuality JPG Quality [1..100]
   * @throws NullPointerException
   * @throws IOException
   * @throws InstantiationException
   * @throws InterruptedException
   * @throws InstantiationException
   */

  public void createThumbFile(String sOutputPath, int iThumbWidth, int iThumbHeight, float fQuality)
    throws NullPointerException, InterruptedException, IOException, InstantiationException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Image.createThumbFile(" + sOutputPath + "," + String.valueOf(iThumbWidth) + "," + String.valueOf(iThumbHeight) + "," + String.valueOf(fQuality) + ")");
      DebugFile.incIdent();
    }

    FileOutputStream outStr = new FileOutputStream(sOutputPath);

    if (USE_AWT==iImagingLibrary)
      drawAWTImage (outStr, iThumbWidth, iThumbHeight, fQuality);
    else
      drawJAIImage (outStr, iThumbWidth, iThumbHeight, fQuality);

    outStr.close();
    outStr=null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Image.createThumbFile()");
    }
  } // createThumbFile()

  // ----------------------------------------------------------

  /**
   * <p>Encode Image and write it to an OutputStream</p>
   * @param oOut OutputStream
   * @throws NullPointerException If underlying java.awt.Image object is <b>null</b>
   * @throws IOException
   * @throws InstantiationException
   * @throws InterruptedException
   */
  public void write(OutputStream oOut)
    throws NullPointerException,IOException,InstantiationException,InterruptedException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Image.write([OutputStream])");
      DebugFile.incIdent();
    }

    if (null==oImg) {
      if (DebugFile.trace) DebugFile.incIdent();
      throw new NullPointerException("java.awt.Image is null");
    }

    com.sun.media.jai.codec.ImageEncoder oEnc = com.sun.media.jai.codec.ImageCodec.createImageEncoder(getImageCodec(), oOut, null);

    if (null==oEnc) {
      if (DebugFile.trace) DebugFile.incIdent();

      throw new InstantiationException("ImageCodec.createImageEncoder("+getImageCodec()+")");
    }
    if (USE_JAI==iImagingLibrary) {

      RenderedImage oRImg = javax.media.jai.JAI.create("awtimage", oImg);

      if (null==oEnc) {
        if (DebugFile.trace) DebugFile.incIdent();
        throw new InstantiationException("JAI.create(awtimage, "+oImg.getClass().getName()+")");
      }

      oEnc.encode(oRImg);
    }
    else {
      int iImageWidth = oImg.getWidth(null);
      int iImageHeight = oImg.getHeight(null);

      if (null==mediaTracker) {
        if (DebugFile.trace) DebugFile.writeln("new java.awt.Frame()");

        Frame awtFrame = null;
        try {
          awtFrame = new Frame();
        } catch (Exception e) { throw new InstantiationException("Cannot instantiate java.awt.Frame " + (e.getMessage()!=null ? e.getMessage() : "")); }

        if (DebugFile.trace) DebugFile.writeln("new MediaTracker([Frame])");

        mediaTracker = new MediaTracker(awtFrame);
      } // fi (mediaTracker)

      mediaTracker.addImage(oImg, 0);
      mediaTracker.waitForID(0);

      BufferedImage oBImg = new BufferedImage(iImageWidth, iImageHeight, BufferedImage.TYPE_INT_RGB);

      if (DebugFile.trace) DebugFile.writeln("java.awt.Graphics2D = thumbImage.createGraphics()");

      Graphics2D graphics2D = oBImg.createGraphics();
      graphics2D.drawImage(oImg, 0, 0, iImageWidth, iImageHeight, null);
      graphics2D.dispose();

      oEnc.encode(oBImg);

      mediaTracker.removeImage(oImg,0);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Image.write([OutputStream])");
    }
  }

  // ----------------------------------------------------------

  /**
   * <p>Get a transparent GIF image that can be served throught a JSP page</p>
   * Use code like
   * response.setContentType("image/gif");
   * OutputStream oOut = response.getOutputStream();
   * oOut.write(Image.blankGIF());
   * oOut.flush();
   * @since 3.0
   * @return byte[]
   */
  public static byte[] blankGIF() {
    return Base64Decoder.decodeToBytes("R0lGODlhAQABAJEAAAAAAP///////wAAACH5BAEAAAIALAAAAAABAAEAAAICVAEAOw==");
  }


  // **********************************************************
  // Static Methods

  private static void printUsage() {
     System.out.println("Usage:");
     System.out.println("com.knowgate.hipergate.Image [jai|awt] thumbnail path_original path_new_thumbnail int_thumb_width int_thumb_height float_quality");
     System.out.println("Options:");
     System.out.println("jai -> Use SUN Java Advanced Imaging (requires SUN's libraries");
     System.out.println("awt -> Use Abstract Windowing Toolkit (requires X-Windows or Win32)");
     System.out.println("path_original -> Full path to original .GIF or .JPEG image");
     System.out.println("path_new_thumbnail -> Full path to generated thumbnail");
     System.out.println("int_thumb_width -> Thumbnail width");
     System.out.println("int_thumb_height -> Thumbnail height");
     System.out.println("float_quality -> JPEG quality for thumbnail [0..100]");
  }

  /**
   * <p>Image command line interface</p>
   * @param argv [jai|awt] thumbnail <i>path_original</i> <i>path_new_thumbnail</i> <i>int_thumb_width</i> <i>int_thumb_height</i> <i>float_quality</i><br>
   * Options:<br>
   * jai -> Use SUN Java Advanced Imaging (requires SUN's libraries<br>
   * awt -> Use Abstract Windowing Toolkit (requires X-Windows or Win32)<br>
   * path_original -> Full path to original .GIF or .JPEG image<br>
   * path_new_thumbnail -> Full path to generated thumbnail<br>
   * int_thumb_width -> Thumbnail width");
   * int_thumb_height -> Thumbnail height<br>
   * float_quality -> JPEG quality for thumbnail [0..100]<br>
   * @throws NumberFormatException
   * @throws InstantiationException
   * @throws InterruptedException
   * @throws FileNotFoundException
   * @throws IOException
   */
  public static void main(String[] argv)
    throws NumberFormatException, InstantiationException, InterruptedException,
           FileNotFoundException, IOException {

    DBBind oDBB = new DBBind();

    Image oImg;

    if (argv.length<6 || argv.length>7) {
      System.out.println("");
      System.out.println("Invalid number of parameters");
      printUsage();
    }
    else if (!argv[0].equalsIgnoreCase("jai") && !argv[0].equalsIgnoreCase("awt")
          && !argv[0].equalsIgnoreCase("thumbnail")) {
      System.out.println("");
      System.out.println("Parameter 1 must be jai,awt or thumbnail");
      printUsage();
    }
    else if ((argv[0].equalsIgnoreCase("jai") || argv[0].equalsIgnoreCase("awt"))
         && !argv[1].equalsIgnoreCase("thumbnail")) {
      System.out.println("");
      System.out.println("Parameter 2 must be thumbnail");
      printUsage();
    }
    else {
      if (argv[0].equalsIgnoreCase("jai")) {
        oImg = new Image(USE_JAI);
        oImg.put(DB.path_image, argv[2]);
        oImg.createThumbFile(argv[3], Integer.parseInt(argv[4]), Integer.parseInt(argv[5]), Float.parseFloat(argv[6]));
        oImg = null;
      }
      else if (argv[0].equalsIgnoreCase("awt")) {
        oImg = new Image(USE_AWT);
        oImg.put(DB.path_image, argv[2]);
        oImg.createThumbFile(argv[3], Integer.parseInt(argv[4]), Integer.parseInt(argv[5]), Float.parseFloat(argv[6]));
        oImg = null;
      }
      else {
        oImg = new Image(USE_AWT);
        oImg.put(DB.path_image, argv[1]);
        oImg.createThumbFile(argv[2], Integer.parseInt(argv[3]), Integer.parseInt(argv[4]), Float.parseFloat(argv[5]));
        oImg = null;
      }
    }
    oDBB.close();

    if (argv.length==6)
      System.out.println("Thumbnail " + argv[2] + " successfully created");
    else
      System.out.println("Thumbnail " + argv[3] + " successfully created");

  } // main

  // **********************************************************
  // Public Constants

  public static final int USE_AWT = 0;
  public static final int USE_JAI = 1;

  public static final short ClassId = 13;

} // Image
