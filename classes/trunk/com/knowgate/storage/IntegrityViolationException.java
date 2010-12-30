package com.knowgate.storage;

import com.knowgate.storage.Column;
import com.knowgate.storage.StorageException;

public class IntegrityViolationException extends StorageException {

  public IntegrityViolationException (Column c, Object v) {
  	super("Integrity constraint violation. Value '"+(v==null ? "null" : v)+"' of column "+c.getName()+" does not match constraint "+c.getConstraint());
  }

  public IntegrityViolationException (String sMsg) {
  	super(sMsg);
  }

}
