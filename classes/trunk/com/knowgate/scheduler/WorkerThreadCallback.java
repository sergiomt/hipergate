package com.knowgate.scheduler;

/**
 * <p>Get information about what is happening inside each WorkerThread</p>
 * This an abstract base class than must be inherited in order to provide the
 * implementation for the call() method.
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public abstract class WorkerThreadCallback {
  private String sName;

  /**
   * @param sCallbackName Each callback instance must have a unique name
   */
  public WorkerThreadCallback(String sCallbackName) {
    sName = sCallbackName;
  }

  /**
   * @return Callback instance name
   */
  public String name() {
    return sName;
  }

  /**
   * <p>Provide information about thread execution milestones</p>
   * @param sThreadId String identifying the caller WorkerThread
   * @param iOpCode Operation code (see static constants)
   * @param sMessage Descriptive message
   * @param oXcpt Exception thrown by WorkerThread.<br>
   * This parameter is always null unless iOpCode is WT_EXCEPTION
   * @param oParam Object related to operation.<br>
   * Its class depends on the operation performed.<br>
   */
  public abstract void call(String sThreadId, int iOpCode, String sMessage, Exception oXcpt, Object oParam);

  /**
   * <p>Thread throwed and Exception</p>
   * <p>The throwed Exception will be in the 4th parameter of call() method</p>
   */
  public static final int WT_EXCEPTION = -1;

  /**
   * <p>Thread instantiated a Job subclass</p>
   * <p>A reference to the instantiated Job will be in the 5th parameter of call() method</p>
   */
  public static final int WT_JOB_INSTANTIATE = 1;

  /**
   * <p>Thread finished a Job execution</p>
   * <p>A reference to the finished Job will be in the 5th parameter of call() method</p>
   */
  public static final int WT_JOB_FINISH = 2;

  /**
   * <p>AtomConsumer for thread found no more pending Atoms</p>
   * <p>A reference to the AtomConsumer will be in the 5th parameter of call() method</p>
   */
  public static final int WT_ATOMCONSUMER_NOMORE = 3;

  /**
   * <p>Thread just got an Atom for its inmediate consumption.</p>
   * <p>Called before Atom is consumed.</p>
   * <p>A reference to the Atom will be in the 5th parameter of call() method</p>
   */
  public static final int WT_ATOM_GET = 4;

  /**
   * <p>Thread consumed an Atom.</p>
   * <p>Called after Atom is consumed.</p>
   * <p>A reference to the Atom will be in the 5th parameter of call() method</p>
   */
  public static final int WT_ATOM_CONSUME = 5;

} // WorkerThreadCallback