ALTER TABLE k_newsgroup_subscriptions ADD CONSTRAINT f1_newsgroup_subscriptions FOREIGN KEY (gu_newsgrp)  REFERENCES k_newsgroups(gu_newsgrp);
ALTER TABLE k_newsgroup_subscriptions ADD CONSTRAINT f2_newsgroup_subscriptions FOREIGN KEY (gu_user)  REFERENCES k_users(gu_user);

ALTER TABLE k_newsgroups ADD CONSTRAINT f1_newsgroups FOREIGN KEY (id_domain)  REFERENCES k_domains(id_domain);
ALTER TABLE k_newsgroups ADD CONSTRAINT f2_newsgroups FOREIGN KEY (gu_newsgrp) REFERENCES k_categories(gu_category);

ALTER TABLE k_newsmsgs ADD CONSTRAINT f1_newsmsgs FOREIGN KEY (gu_product) REFERENCES k_products(gu_product);
ALTER TABLE k_newsmsgs ADD CONSTRAINT f2_newsmsgs FOREIGN KEY (gu_writer) REFERENCES k_users(gu_user);
ALTER TABLE k_newsmsgs ADD CONSTRAINT f3_newsmsgs FOREIGN KEY (gu_validator) REFERENCES k_users(gu_user);

ALTER TABLE k_newsgroup_tags ADD CONSTRAINT f1_newsgroup_tags FOREIGN KEY (gu_newsgrp) REFERENCES k_newsgroups(gu_newsgrp);

ALTER TABLE k_newsmsg_vote ADD CONSTRAINT f1_newsmsg_vote FOREIGN KEY (gu_msg) REFERENCES k_newsmsgs(gu_msg);

ALTER TABLE k_newsmsg_tags ADD CONSTRAINT f1_newsmsg_tags FOREIGN KEY (gu_msg) REFERENCES k_newsmsgs(gu_msg);
ALTER TABLE k_newsmsg_tags ADD CONSTRAINT f2_newsmsg_tags FOREIGN KEY (gu_tag) REFERENCES k_newsgroup_tags(gu_tag);
