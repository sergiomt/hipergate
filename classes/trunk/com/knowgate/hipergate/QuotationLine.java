/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
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

import java.math.BigDecimal;

import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DB;

/**
 * Quotation Line
 * @author Sergio Montoro Ten
 * @version 5.0
 */
//----------------------------------------------------------------------------

public class QuotationLine extends DBPersist {
    public QuotationLine() {
      super(DB.k_quotation_lines, "QuotationLine");
    }

    //--------------------------------------------------------------------------

    /**
     * <p>Store quotation line</p>
     * This method updated k_quotations.dt_modified to current datetime as a side effect
     * @param oConn JDCConnection
     * @return boolean
     * @throws SQLException
     */
    public boolean store (JDCConnection oConn) throws SQLException {
      PreparedStatement oStmt = oConn.prepareStatement("UPDATE "+DB.k_quotations+" SET "+DB.dt_modified+"="+DBBind.Functions.GETDATE+" WHERE "+DB.gu_quotation+"=?");
      oStmt.setObject(1, get(DB.gu_quotation), Types.CHAR);
      oStmt.executeUpdate();
      oStmt.close();
      return super.store(oConn);
    }

    //--------------------------------------------------------------------------

    /**
     * <p>Compute line total from base price, number of units and taxes</p>
     * If is_tax_included==1 Or is_tax_included is null Then pct_tax_rate is applied Else it is ignored
     * @return BigDecimal pr_sale * nu_quantity * pct_tax_rate
     */
    public BigDecimal computeTotal () {
      BigDecimal dTotal, dQuantity, dTax, dHundred = new BigDecimal(100), dOne = new BigDecimal(1);
      boolean bTaxIncluded = false;

      if (isNull(DB.pr_sale)) return null;

      if (isNull(DB.nu_quantity))
        dQuantity = new BigDecimal(1);
      else
        dQuantity = new BigDecimal(getFloat(DB.nu_quantity));

      if (isNull(DB.pct_tax_rate))
        dTotal = getDecimal(DB.pr_sale).multiply(dQuantity);
      else {
        dTotal = getDecimal(DB.pr_sale).multiply(dQuantity);
        if (!isNull(DB.is_tax_included))
          bTaxIncluded = (getShort(DB.is_tax_included)==(short)1);
        if (!bTaxIncluded) {
          if (getFloat(DB.pct_tax_rate)>1f)
            dTax = new BigDecimal(getFloat(DB.pct_tax_rate)/100f);
          else
            dTax = new BigDecimal(getFloat(DB.pct_tax_rate));
          dTotal = dTotal.add(dTotal.multiply(dTax));
        }
      }
      replace(DB.pr_total, dTotal);
      return dTotal;
  } // computeTotal
}
