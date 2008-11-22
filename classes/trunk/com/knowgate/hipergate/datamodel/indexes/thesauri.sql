CREATE UNIQUE INDEX it_thesauri_root ON k_thesauri_root(tx_term,id_scope,id_domain);

CREATE INDEX it_thesauri ON k_thesauri(tx_term,id_scope,id_domain);

CREATE INDEX i0_thesauri ON k_thesauri(id_term0);
CREATE INDEX i1_thesauri ON k_thesauri(id_term1);
CREATE INDEX i2_thesauri ON k_thesauri(id_term2);
CREATE INDEX i3_thesauri ON k_thesauri(id_term3);
CREATE INDEX i4_thesauri ON k_thesauri(id_term4);
CREATE INDEX i5_thesauri ON k_thesauri(id_term5);
CREATE INDEX i6_thesauri ON k_thesauri(id_term6);
CREATE INDEX i7_thesauri ON k_thesauri(id_term7);
CREATE INDEX i8_thesauri ON k_thesauri(id_term8);
CREATE INDEX i9_thesauri ON k_thesauri(id_term9);

CREATE INDEX is_thesauri ON k_thesauri(gu_synonym);

CREATE INDEX i1_images ON k_images(path_image);

CREATE INDEX i2_images ON k_images(gu_workarea);

CREATE INDEX i3_images ON k_images(gu_pageset);

CREATE INDEX i4_images ON k_images(gu_product);

CREATE INDEX i5_images ON k_images(nm_image);

CREATE INDEX i6_images ON k_images(dt_created);

CREATE INDEX i7_images ON k_images(gu_writer);
