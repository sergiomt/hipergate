CREATE INDEX i1_shops ON k_shops(gu_workarea);

CREATE UNIQUE INDEX i1_orders ON k_orders(gu_workarea,pg_order);

CREATE INDEX i2_orders ON k_orders(gu_workarea);
CREATE INDEX i3_orders ON k_orders(gu_company);
CREATE INDEX i4_orders ON k_orders(gu_contact);
CREATE INDEX i5_orders ON k_orders(dt_payment);
CREATE INDEX i6_orders ON k_orders(gu_shop);

CREATE UNIQUE INDEX u1_invoices ON k_invoices (gu_workarea,pg_invoice);
CREATE UNIQUE INDEX u2_invoices ON k_invoices (gu_shop,pg_invoice);

CREATE INDEX i2_invoices ON k_invoices(gu_workarea);
CREATE INDEX i3_invoices ON k_invoices(gu_company);
CREATE INDEX i4_invoices ON k_invoices(gu_contact);
CREATE INDEX i5_invoices ON k_invoices(dt_payment);
CREATE INDEX i6_invoices ON k_invoices(dt_paid);
CREATE INDEX i7_invoices ON k_invoices(dt_invoiced);
CREATE INDEX i8_invoices ON k_invoices(id_legal);
CREATE INDEX i9_invoices ON k_invoices(im_total);



