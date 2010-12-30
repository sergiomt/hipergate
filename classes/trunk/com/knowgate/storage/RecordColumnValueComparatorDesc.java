package com.knowgate.storage;

public class RecordColumnValueComparatorDesc extends RecordColumnValueComparatorAsc {

    public RecordColumnValueComparatorDesc(String sColumnName) {
      super(sColumnName);
    }

    public int compare(Record r1, Record r2) {
      return super.compare(r2,r1);
    }    
}
