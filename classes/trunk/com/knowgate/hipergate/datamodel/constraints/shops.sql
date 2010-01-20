ALTER TABLE k_shops ADD CONSTRAINT f1_shops FOREIGN KEY (gu_workarea) REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_shops ADD CONSTRAINT f2_shops FOREIGN KEY (id_domain) REFERENCES k_domains(id_domain);
ALTER TABLE k_shops ADD CONSTRAINT f3_shops FOREIGN KEY (gu_root_cat) REFERENCES k_categories(gu_category);

ALTER TABLE k_orders ADD CONSTRAINT f1_orders FOREIGN KEY (gu_company)    REFERENCES k_companies(gu_company);
ALTER TABLE k_orders ADD CONSTRAINT f2_orders FOREIGN KEY (gu_contact)    REFERENCES k_contacts(gu_contact);
ALTER TABLE k_orders ADD CONSTRAINT f3_orders FOREIGN KEY (gu_ship_addr)  REFERENCES k_addresses(gu_address);
ALTER TABLE k_orders ADD CONSTRAINT f4_orders FOREIGN KEY (gu_bill_addr)  REFERENCES k_addresses(gu_address);
ALTER TABLE k_orders ADD CONSTRAINT f5_orders FOREIGN KEY (gu_shop)       REFERENCES k_shops(gu_shop);
ALTER TABLE k_orders ADD CONSTRAINT f6_orders FOREIGN KEY (gu_sale_point) REFERENCES k_sale_points(gu_sale_point);
ALTER TABLE k_orders ADD CONSTRAINT f7_orders FOREIGN KEY (gu_warehouse)  REFERENCES k_warehouses(gu_warehouse);

ALTER TABLE k_orders_lookup ADD CONSTRAINT f1_orders_lookup  FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_order_lines ADD CONSTRAINT f1_order_lines FOREIGN KEY (gu_order) REFERENCES k_orders(gu_order);

ALTER TABLE k_invoices ADD CONSTRAINT f1_invoices FOREIGN KEY (gu_company)    REFERENCES k_companies(gu_company);
ALTER TABLE k_invoices ADD CONSTRAINT f2_invoices FOREIGN KEY (gu_contact)    REFERENCES k_contacts(gu_contact);
ALTER TABLE k_invoices ADD CONSTRAINT f3_invoices FOREIGN KEY (gu_ship_addr)  REFERENCES k_addresses(gu_address);
ALTER TABLE k_invoices ADD CONSTRAINT f4_invoices FOREIGN KEY (gu_bill_addr)  REFERENCES k_addresses(gu_address);
ALTER TABLE k_invoices ADD CONSTRAINT f5_invoices FOREIGN KEY (gu_shop)       REFERENCES k_shops(gu_shop);
ALTER TABLE k_invoices ADD CONSTRAINT f6_invoices FOREIGN KEY (gu_sale_point) REFERENCES k_sale_points(gu_sale_point);
ALTER TABLE k_invoices ADD CONSTRAINT f7_invoices FOREIGN KEY (gu_warehouse)  REFERENCES k_warehouses(gu_warehouse);
ALTER TABLE k_invoices ADD CONSTRAINT f8_invoices FOREIGN KEY (gu_schedule)   REFERENCES k_invoice_schedules(gu_schedule);
ALTER TABLE k_invoices ADD CONSTRAINT f9_invoices FOREIGN KEY (gu_workarea)    REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_returned_invoices ADD CONSTRAINT f1_returned_invoices FOREIGN KEY (gu_invoice)    REFERENCES k_invoices(gu_invoice);
ALTER TABLE k_returned_invoices ADD CONSTRAINT f2_returned_invoices FOREIGN KEY (gu_workarea)   REFERENCES k_workareas(gu_workarea);
ALTER TABLE k_returned_invoices ADD CONSTRAINT f3_returned_invoices FOREIGN KEY (gu_company)    REFERENCES k_companies(gu_company);
ALTER TABLE k_returned_invoices ADD CONSTRAINT f4_returned_invoices FOREIGN KEY (gu_contact)    REFERENCES k_contacts(gu_contact);
ALTER TABLE k_returned_invoices ADD CONSTRAINT f5_returned_invoices FOREIGN KEY (gu_bill_addr)  REFERENCES k_addresses(gu_address);
ALTER TABLE k_returned_invoices ADD CONSTRAINT f6_returned_invoices FOREIGN KEY (gu_shop)       REFERENCES k_shops(gu_shop);

ALTER TABLE k_invoices_lookup ADD CONSTRAINT f1_invoices_lookup  FOREIGN KEY(gu_owner) REFERENCES k_workareas(gu_workarea);

ALTER TABLE k_invoice_lines ADD CONSTRAINT f1_invoice_lines FOREIGN KEY (gu_invoice) REFERENCES k_invoices(gu_invoice);

ALTER TABLE k_x_orders_invoices ADD CONSTRAINT f1_x_orders_invoices FOREIGN KEY (gu_order) REFERENCES k_orders(gu_order);
ALTER TABLE k_x_orders_invoices ADD CONSTRAINT f2_x_orders_invoices FOREIGN KEY (gu_invoice) REFERENCES k_invoices(gu_invoice);

ALTER TABLE k_despatch_lines ADD CONSTRAINT f1_despatch_lines FOREIGN KEY (gu_despatch) REFERENCES k_despatch_advices(gu_despatch);

ALTER TABLE k_x_orders_despatch ADD CONSTRAINT f1_x_orders_despatch FOREIGN KEY (gu_order) REFERENCES k_orders(gu_order);
ALTER TABLE k_x_orders_despatch ADD CONSTRAINT f2_x_orders_despatch FOREIGN KEY (gu_despatch) REFERENCES k_despatch_advices(gu_despatch);

ALTER TABLE k_warehouses ADD CONSTRAINT f1_warehouses FOREIGN KEY (gu_address) REFERENCES k_addresses(gu_address);

ALTER TABLE k_sale_points ADD CONSTRAINT u2_warehouses UNIQUE (gu_address);

ALTER TABLE k_sale_points ADD CONSTRAINT f1_sale_points FOREIGN KEY (gu_address) REFERENCES k_addresses(gu_address);

