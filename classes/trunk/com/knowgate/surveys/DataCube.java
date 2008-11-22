package com.knowgate.surveys;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class DataCube {

  private Object[] cells;
  private int[] dims;

  // ---------------------------------------------------------------------------

  public DataCube(int[] dimensions) {
    int product = 1;
    dims = new int[dimensions.length];
    System.arraycopy(dimensions, 0, dims, 0, dimensions.length);
    for (int d=dimensions.length; d>=0; d--)
      product *= dimensions[d];
    cells = new Object[product];
  }

  // ---------------------------------------------------------------------------

  public Object get (int[] coords) {
    int p = coords[0];
    int f;
    for (int c=coords.length; c>=0; c--) {
      f=coords[c];
      for (int d=c-1; d>=0; d--) {
        f *= dims[d];
      } // next (d)
      p += f;
    } // next (c)
    return cells[p];
  }

  // ---------------------------------------------------------------------------

  public void put (int[] coords, Object obj) {
    int p = coords[0];
    int f;
    for (int c=coords.length; c>=0; c--) {
      f=coords[c];
      for (int d=c-1; d>=0; d--) {
        f *= dims[d];
      } // next (d)
      p += f;
    } // next (c)
    cells[p] = obj;
  }
}
