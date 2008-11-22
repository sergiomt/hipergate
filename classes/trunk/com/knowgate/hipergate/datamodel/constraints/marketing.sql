ALTER TABLE k_campaigns ADD CONSTRAINT f1_campaign FOREIGN KEY (gu_workarea) REFERENCES k_workareas (gu_workarea);

ALTER TABLE k_x_campaign_lists ADD CONSTRAINT f1_campaign_list FOREIGN KEY (gu_campaign) REFERENCES k_campaigns (gu_campaign);

ALTER TABLE k_campaign_targets ADD CONSTRAINT f1_campaign_target FOREIGN KEY (gu_campaign) REFERENCES k_campaigns (gu_campaign);
ALTER TABLE k_campaign_targets ADD CONSTRAINT f2_campaign_target FOREIGN KEY (gu_geozone) REFERENCES k_thesauri (gu_term);
ALTER TABLE k_campaign_targets ADD CONSTRAINT f3_campaign_target FOREIGN KEY (gu_product) REFERENCES k_products (gu_product);



