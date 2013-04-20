ALTER TABLE k_microsites ADD CONSTRAINT f1_microsites FOREIGN KEY (id_app) REFERENCES k_apps(id_app);
ALTER TABLE k_microsites ADD CONSTRAINT f2_microsites FOREIGN KEY (gu_workarea) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_pagesets ADD CONSTRAINT f1_pagesets FOREIGN KEY(gu_microsite) REFERENCES k_microsites(gu_microsite);
ALTER TABLE k_pagesets ADD CONSTRAINT f2_pagesets FOREIGN KEY(gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_pagesets ADD CONSTRAINT f3_pagesets FOREIGN KEY(id_language) REFERENCES k_lu_languages(id_language);
ALTER TABLE k_pagesets ADD CONSTRAINT f4_pagesets FOREIGN KEY(gu_company) REFERENCES k_companies(gu_company);
ALTER TABLE k_pagesets ADD CONSTRAINT f5_pagesets FOREIGN KEY(gu_project) REFERENCES k_projects(gu_project);

ALTER TABLE k_pagesets_lookup ADD CONSTRAINT f1_pagesets_lookup  FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_pageset_pages ADD CONSTRAINT f1_pageset_pages FOREIGN KEY(gu_pageset) REFERENCES k_pagesets(gu_pageset);

ALTER TABLE k_pageset_answers ADD CONSTRAINT f1_pageset_answers FOREIGN KEY(gu_page) REFERENCES k_pageset_pages(gu_page);
ALTER TABLE k_pageset_answers ADD CONSTRAINT f2_pageset_answers FOREIGN KEY(gu_pageset) REFERENCES k_pagesets(gu_pageset);
ALTER TABLE k_pageset_answers ADD CONSTRAINT f3_pageset_answers FOREIGN KEY(gu_writer) REFERENCES k_users(gu_user);
ALTER TABLE k_pageset_answers ADD CONSTRAINT f4_pageset_answers FOREIGN KEY(gu_datasheet) REFERENCES k_pageset_datasheets(gu_datasheet);

ALTER TABLE k_datasheets_lookup ADD CONSTRAINT f1_datasheets_lookup  FOREIGN KEY(gu_owner) REFERENCES k_pagesets(gu_pageset);

ALTER TABLE k_x_pageset_list ADD CONSTRAINT f1_x_pageset_list FOREIGN KEY(gu_list) REFERENCES k_lists(gu_list);
ALTER TABLE k_x_pageset_list ADD CONSTRAINT f2_x_pageset_list FOREIGN KEY(gu_pageset) REFERENCES k_pagesets(gu_pageset);
