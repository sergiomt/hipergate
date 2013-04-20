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

package com.knowgate.misc;

import com.knowgate.debug.*;

import java.awt.*;
import java.awt.image.*;

import javax.servlet.ServletOutputStream;

import com.sun.image.codec.jpeg.JPEGCodec;
import com.sun.image.codec.jpeg.JPEGImageEncoder;
import com.sun.image.codec.jpeg.JPEGEncodeParam;

/**
 * Create Image thumbnail
 * @deprecated Use com.knowgate.hipegate.Image
 */

public class Thumbnail {
 /* public static void main(String[] args) throws Exception {
    getThumb("c:\\prueba.jpg",System.out,"50","50","75");
  }*/
  public static synchronized void getThumb(String sInFile, ServletOutputStream sOutputStream, String sWidth, String sHeight, String sQuality) throws Exception {
    System.setProperty("java.awt.headless","true");
    if (DebugFile.trace)
      DebugFile.writeln("BEGIN getThumb");
    // load image from INFILE
    Image image = Toolkit.getDefaultToolkit().getImage(sInFile);
    if (DebugFile.trace)
      DebugFile.writeln("Image created");

    MediaTracker mediaTracker = new MediaTracker(new Frame());
    mediaTracker.addImage(image, 0);
    mediaTracker.waitForID(0);

    if (DebugFile.trace)
      DebugFile.writeln("Image loaded");

    // determine thumbnail size from WIDTH and HEIGHT
    int thumbWidth = Integer.parseInt(sWidth);
    int thumbHeight = Integer.parseInt(sHeight);
    double thumbRatio = (double)thumbWidth / (double)thumbHeight;
    int imageWidth = image.getWidth(null);
    int imageHeight = image.getHeight(null);
    double imageRatio = (double)imageWidth / (double)imageHeight;
    if (thumbRatio < imageRatio) {
      thumbHeight = (int)(thumbWidth / imageRatio);
    } else {
      thumbWidth = (int)(thumbHeight * imageRatio);
    }

    if (DebugFile.trace)
      DebugFile.writeln("Image resized");

    // draw original image to thumbnail image object and
    // scale it to the new size on-the-fly
    BufferedImage thumbImage = new BufferedImage(thumbWidth, thumbHeight, BufferedImage.TYPE_INT_RGB);
    Graphics2D graphics2D = thumbImage.createGraphics();
    graphics2D.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
      RenderingHints.VALUE_INTERPOLATION_BILINEAR);
    graphics2D.drawImage(image, 0, 0, thumbWidth, thumbHeight, null);

    if (DebugFile.trace)
      DebugFile.writeln("graphics2D created");

    // send thumbnail image to outputstream
    ServletOutputStream out = sOutputStream;
    JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(out);
    JPEGEncodeParam param = encoder.getDefaultJPEGEncodeParam(thumbImage);
    int quality = Integer.parseInt(sQuality);
    quality = Math.max(0, Math.min(quality, 100));
    param.setQuality((float)quality / 100.0f, false);
    encoder.setJPEGEncodeParam(param);
    encoder.encode(thumbImage);

    if (DebugFile.trace)
      DebugFile.writeln("Encode ended");
  }
}

