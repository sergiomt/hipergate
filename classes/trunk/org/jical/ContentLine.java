package org.jical;

import java.util.Map;

public interface ContentLine {
    public String getName();
    public String getValue();
    public Map getParameters();

    public String getRawLine();
}
