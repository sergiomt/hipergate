package com.knowgate.jcifs.smb;

interface FileEntry {

    String getName();
    int getType();
    int getAttributes();
    long createTime();
    long lastModified();
    long length();
}
