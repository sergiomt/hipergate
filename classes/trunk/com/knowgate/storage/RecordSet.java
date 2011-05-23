package com.knowgate.storage;

import java.util.List;

public interface RecordSet extends List<Record> {

  public int find (String sColumnName, Object oValue);

  public void sort(String sColumnName) throws ArrayIndexOutOfBoundsException;

  public String json(String sName, String sIdentifier, String sLabel) throws ArrayIndexOutOfBoundsException;

}
