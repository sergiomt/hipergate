CREATE INDEX i1_pagesets ON k_pagesets(dt_created);
CREATE INDEX i2_pagesets ON k_pagesets(gu_workarea);
CREATE INDEX i3_pagesets ON k_pagesets(gu_microsite);
CREATE INDEX i4_pagesets ON k_pagesets(gu_company);
CREATE INDEX i5_pagesets ON k_pagesets(gu_project);

CREATE INDEX i1_pageset_pages ON k_pageset_pages(gu_pageset);

CREATE INDEX i1_pageset_answers ON k_pageset_answers(gu_datasheet);
CREATE INDEX i2_pageset_answers ON k_pageset_answers(gu_pageset);
CREATE INDEX i3_pageset_answers ON k_pageset_answers(gu_page);
CREATE INDEX i4_pageset_answers ON k_pageset_answers(gu_writer);



