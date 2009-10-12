ALTER TABLE k_newsgroups DROP CONSTRAINT f1_newsgroups;
ALTER TABLE k_newsgroups DROP CONSTRAINT f2_newsgroups;

ALTER TABLE k_newsmsgs DROP CONSTRAINT f1_newsmsgs;
ALTER TABLE k_newsmsgs DROP CONSTRAINT f2_newsmsgs;
ALTER TABLE k_newsmsgs DROP CONSTRAINT f3_newsmsgs;

DROP TABLE k_newsgroup_subscriptions;
DROP TABLE k_newsmsg_tags;
DROP TABLE k_newsgroup_tags;
DROP TABLE k_newsmsg_vote;
DROP TABLE k_newsmsgs;
DROP TABLE k_newsgroups;
