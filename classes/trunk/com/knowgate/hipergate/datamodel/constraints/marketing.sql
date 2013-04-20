ALTER TABLE k_campaigns ADD CONSTRAINT f1_campaign FOREIGN KEY (gu_workarea) REFERENCES k_workareas (gu_workarea);

ALTER TABLE k_oportunities ADD CONSTRAINT f4_oportunities FOREIGN KEY (gu_campaign) REFERENCES k_campaigns(gu_campaign);

ALTER TABLE k_x_campaign_lists ADD CONSTRAINT f1_campaign_list FOREIGN KEY (gu_campaign) REFERENCES k_campaigns (gu_campaign);

ALTER TABLE k_campaign_targets ADD CONSTRAINT f1_campaign_target FOREIGN KEY (gu_campaign) REFERENCES k_campaigns (gu_campaign);
ALTER TABLE k_campaign_targets ADD CONSTRAINT f2_campaign_target FOREIGN KEY (gu_geozone) REFERENCES k_thesauri (gu_term);
ALTER TABLE k_campaign_targets ADD CONSTRAINT f3_campaign_target FOREIGN KEY (gu_product) REFERENCES k_products (gu_product);

ALTER TABLE k_activities ADD CONSTRAINT f1_activities FOREIGN KEY (gu_workarea) REFERENCES k_workareas (gu_workarea);
ALTER TABLE k_activities ADD CONSTRAINT f2_activities FOREIGN KEY (gu_address) REFERENCES k_addresses (gu_address);
ALTER TABLE k_activities ADD CONSTRAINT f3_activities FOREIGN KEY (gu_campaign) REFERENCES k_campaigns (gu_campaign);
ALTER TABLE k_activities ADD CONSTRAINT f4_activities FOREIGN KEY (gu_list) REFERENCES k_lists (gu_list);
ALTER TABLE k_activities ADD CONSTRAINT f5_activities FOREIGN KEY (gu_writer) REFERENCES k_users (gu_user);
ALTER TABLE k_activities ADD CONSTRAINT f6_activities FOREIGN KEY (gu_meeting) REFERENCES k_meetings (gu_meeting);
ALTER TABLE k_activities ADD CONSTRAINT f7_activities FOREIGN KEY (gu_pageset) REFERENCES k_pagesets (gu_pageset);
ALTER TABLE k_activities ADD CONSTRAINT f8_activities FOREIGN KEY (gu_mailing) REFERENCES k_adhoc_mailings (gu_mailing);

ALTER TABLE k_activity_tags ADD CONSTRAINT f1_activity_tags FOREIGN KEY (gu_activity) REFERENCES k_activities (gu_activity);

ALTER TABLE k_x_activity_audience ADD CONSTRAINT f1_x_activity_audience FOREIGN KEY (gu_activity) REFERENCES k_activities (gu_activity);
ALTER TABLE k_x_activity_audience ADD CONSTRAINT f2_x_activity_audience FOREIGN KEY (gu_address) REFERENCES k_addresses (gu_address);
ALTER TABLE k_x_activity_audience ADD CONSTRAINT f3_x_activity_audience FOREIGN KEY (gu_contact) REFERENCES k_contacts (gu_contact);
ALTER TABLE k_x_activity_audience ADD CONSTRAINT f4_x_activity_audience FOREIGN KEY (gu_list) REFERENCES k_lists (gu_list);
ALTER TABLE k_x_activity_audience ADD CONSTRAINT f5_x_activity_audience FOREIGN KEY (gu_writer) REFERENCES k_users (gu_user);

ALTER TABLE k_syndentries ADD CONSTRAINT f1_syndentries FOREIGN KEY (id_domain) REFERENCES k_domains (id_domain);
ALTER TABLE k_syndentries ADD CONSTRAINT f2_syndentries FOREIGN KEY (gu_workarea) REFERENCES k_workareas (gu_workarea);
ALTER TABLE k_syndentries ADD CONSTRAINT f3_syndentries FOREIGN KEY (gu_contact) REFERENCES k_contacts (gu_contact);
