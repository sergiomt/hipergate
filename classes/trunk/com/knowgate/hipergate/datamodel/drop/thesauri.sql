ALTER TABLE k_thesauri_root DROP CONSTRAINT f1_thesauri_root;
ALTER TABLE k_thesauri_root DROP CONSTRAINT f2_thesauri_root;

ALTER TABLE k_thesauri DROP CONSTRAINT f1_thesauri;
ALTER TABLE k_thesauri DROP CONSTRAINT f2_thesauri;
ALTER TABLE k_thesauri DROP CONSTRAINT f3_thesauri;
ALTER TABLE k_thesauri DROP CONSTRAINT f4_thesauri;

ALTER TABLE k_images DROP CONSTRAINT f1_images;
ALTER TABLE k_images DROP CONSTRAINT f2_images;

ALTER TABLE k_addresses_lookup DROP CONSTRAINT f1_addresses_lookup;

ALTER TABLE k_addresses DROP CONSTRAINT f1_addresses;
ALTER TABLE k_addresses DROP CONSTRAINT f2_addresses;

ALTER TABLE k_bank_accounts DROP CONSTRAINT f1_bank_accounts;

ALTER TABLE k_bank_accounts_lookup DROP CONSTRAINT f1_bank_accounts_lookup;

DROP TABLE k_urls;
DROP TABLE k_distances_cache;
DROP TABLE k_bank_accounts;
DROP TABLE k_bank_accounts_lookup;
DROP TABLE k_addresses_lookup;
DROP TABLE k_addresses;
DROP TABLE k_images;
DROP TABLE k_thesauri;
DROP TABLE k_thesauri_lookup;
DROP TABLE k_thesauri_root;
