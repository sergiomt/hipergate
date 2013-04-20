package com.knowgate.storage;

import java.util.List;

public interface RecordSet extends List<Record> {

  public int find (final String sColumnName, final Object oValue);

  public void sort(final String sColumnName) throws ArrayIndexOutOfBoundsException;

  public void sortDesc(final String sColumnName) throws ArrayIndexOutOfBoundsException;

  public String json(final String sName, final String sIdentifier, final String sLabel) throws ArrayIndexOutOfBoundsException;

}
