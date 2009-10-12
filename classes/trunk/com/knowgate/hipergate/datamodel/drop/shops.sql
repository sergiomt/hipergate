DROP VIEW v_warehouses;
DROP VIEW v_sale_points;
DROP VIEW v_invoices;
DROP VIEW v_despatch_advices;
DROP VIEW v_orders;

ALTER TABLE k_x_orders_invoices DROP CONSTRAINT f2_x_orders_invoices;

ALTER TABLE k_invoice_lines DROP CONSTRAINT f1_invoice_lines;

ALTER TABLE k_invoices_lookup DROP CONSTRAINT f1_invoices_lookup;

ALTER TABLE k_invoices DROP CONSTRAINT f1_invoices;
ALTER TABLE k_invoices DROP CONSTRAINT f2_invoices;
ALTER TABLE k_invoices DROP CONSTRAINT f3_invoices;
ALTER TABLE k_invoices DROP CONSTRAINT f4_invoices;
ALTER TABLE k_invoices DROP CONSTRAINT f5_invoices;
ALTER TABLE k_invoices DROP CONSTRAINT f6_invoices;
ALTER TABLE k_invoices DROP CONSTRAINT f7_invoices;
ALTER TABLE k_invoices DROP CONSTRAINT f8_invoices;

ALTER TABLE k_x_orders_despatch DROP CONSTRAINT f2_x_orders_despatch;

ALTER TABLE k_despatch_lines DROP CONSTRAINT f1_despatch_lines;

ALTER TABLE k_x_orders_despatch DROP CONSTRAINT f1_x_orders_despatch;
ALTER TABLE k_x_orders_invoices DROP CONSTRAINT f1_x_orders_invoices;

ALTER TABLE k_order_lines DROP CONSTRAINT f1_order_lines;

ALTER TABLE k_orders_lookup DROP CONSTRAINT f1_orders_lookup;

ALTER TABLE k_orders DROP CONSTRAINT f1_orders;
ALTER TABLE k_orders DROP CONSTRAINT f2_orders;
ALTER TABLE k_orders DROP CONSTRAINT f3_orders;
ALTER TABLE k_orders DROP CONSTRAINT f4_orders;
ALTER TABLE k_orders DROP CONSTRAINT f5_orders;
ALTER TABLE k_orders DROP CONSTRAINT f6_orders;
ALTER TABLE k_orders DROP CONSTRAINT f7_orders;

ALTER TABLE k_shops DROP CONSTRAINT f1_shops;
ALTER TABLE k_shops DROP CONSTRAINT f2_shops;
ALTER TABLE k_shops DROP CONSTRAINT f3_shops;

DROP TABLE k_quotations_next;
DROP TABLE k_x_quotations_orders;
DROP TABLE k_quotation_lines;
DROP TABLE k_quotations;
DROP TABLE k_x_orders_invoices;
DROP TABLE k_invoice_payments;
DROP TABLE k_invoice_lines;
DROP TABLE k_invoices_lookup;
DROP TABLE k_returned_invoices;
DROP TABLE k_invoices;
DROP TABLE k_invoice_schedules;
DROP TABLE k_invoices_next;
DROP TABLE k_x_orders_despatch;
DROP TABLE k_despatch_lines;
DROP TABLE k_despatch_advices_lookup;
DROP TABLE k_despatch_advices;
DROP TABLE k_despatch_next;
DROP TABLE k_orders_lookup;
DROP TABLE k_order_lines;
DROP TABLE k_orders;
DROP TABLE k_warehouses;
DROP TABLE k_sale_points;
DROP TABLE k_shops;
DROP TABLE k_business_states;
DROP TABLE k_lu_business_states;
