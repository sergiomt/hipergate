
package com.knowgate.cache;

import java.util.Hashtable;

/**
 * AttributedExpireableCache.java
 *
 *
 * Created: Tue Apr 25 14:57:22 2000
 *
 * @author Sebastian Schaffert
 * @version
 */
public class AttributedExpireableCache extends ExpireableCache {

    protected Hashtable attributes;

    public AttributedExpireableCache(int capacity, float expire_factor) {
	super(capacity);
	attributes=new Hashtable(capacity);
    }

    public AttributedExpireableCache(int capacity) {
	super(capacity);
	attributes=new Hashtable(capacity);
    }

    public synchronized void put(Object id, Object object, Object attribs) {
	attributes.put(id,attribs);
	super.put(id,object);
    }

    public Object getAttributes(Object key) {
	return attributes.get(key);
    }

    public synchronized void remove(Object key) {
	attributes.remove(key);
	super.remove(key);
    }
} // AttributedExpireableCache
