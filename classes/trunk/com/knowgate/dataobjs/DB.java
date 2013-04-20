/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

package com.knowgate.dataobjs;

/**
 * <p>Static final variables for table and field names</p>
 * @version 7.0
 */

public final class DB {

  public DB() {
  }

  public static final String TABLE_PREFIX ="k_";

  /***************/
  /* TABLE NAMES */
  /***************/

  public static final String k_version = "k_version";

  // Look up tables
  public static final String k_lu_currencies = "k_lu_currencies";
  public static final String k_lu_currencies_history = "k_lu_currencies_history";
  public static final String k_lu_languages = "k_lu_languages";
  public static final String k_lu_countries = "k_lu_countries";
  public static final String k_lu_states = "k_lu_states";
  public static final String k_lu_meta_attrs = "k_lu_meta_attrs";
  public static final String k_lu_prod_types = "k_lu_prod_types";

  // Main tables
  public static final String k_accounts = "k_accounts";
  public static final String k_acl_groups = "k_acl_groups";
  public static final String k_addresses = "k_addresses";
  public static final String k_addresses_lookup = "k_addresses_lookup";
  public static final String k_bulkloads = "k_bulkloads";
  public static final String k_distances_cache = "k_distances_cache";
  public static final String k_thesauri_root = "k_thesauri_root";
  public static final String k_thesauri = "k_thesauri";
  public static final String k_thesauri_lookup = "k_thesauri_lookup";
  public static final String k_bank_accounts = "k_bank_accounts";
  public static final String k_bank_accounts_lookup = "k_bank_accounts_lookup";
  public static final String k_urls = "k_urls";
  public static final String k_cat_labels = "k_cat_labels";
  public static final String k_cat_root = "k_cat_root";
  public static final String k_cat_tree = "k_cat_tree";
  public static final String k_categories = "k_categories";
  public static final String k_domains = "k_domains";
  public static final String k_images = "k_images";
  public static final String k_keywords = "k_keywords";
  public static final String k_paragraphs = "k_paragraphs";
  public static final String k_x_addr_user = "k_x_addr_user";
  public static final String k_x_cat_key = "k_x_cat_key";
  public static final String k_x_cat_tree = "k_x_cat_tree";
  public static final String k_x_cat_objs = "k_x_cat_objs";
  public static final String k_cat_expand = "k_cat_expand";
  public static final String k_x_cat_group_acl = "k_x_cat_group_acl";
  public static final String k_x_group_user ="k_x_group_user";
  public static final String k_x_cat_user_acl = "k_x_cat_user_acl";
  public static final String k_users = "k_users";
  public static final String k_user_mail = "k_user_mail";
  public static final String k_user_pwd = "k_user_pwd";
  public static final String k_user_accounts = "k_user_accounts";
  public static final String k_apps = "k_apps";
  public static final String k_workareas = "k_workareas";
  public static final String k_x_app_workarea = "k_x_app_workarea";
  public static final String k_x_portlet_user = "k_x_portlet_user";
  public static final String k_products = "k_products";
  public static final String k_prod_locats = "k_prod_locats";
  public static final String k_prod_fares = "k_prod_fares";
  public static final String k_prod_fares_lookup = "k_prod_fares_lookup";
  public static final String k_prod_attr = "k_prod_attr";
  public static final String k_prod_attrs = "k_prod_attrs";
  public static final String k_prod_keywords = "k_prod_keywords";
  public static final String k_shops = "k_shops";
  public static final String k_quotations = "k_quotations";
  public static final String k_quotation_lines = "k_quotation_lines";
  public static final String k_x_quotations_orders = "k_x_quotations_orders";
  public static final String k_quotations_next = "k_quotations_next";
  public static final String k_orders = "k_orders";
  public static final String k_order_lines = "k_order_lines";
  public static final String k_orders_lookup = "k_orders_lookup";
  public static final String k_despatch_advices = "k_despatch_advices";
  public static final String k_despatch_advices_lookup = "k_despatch_advices_lookup";
  public static final String k_despatch_lines = "k_despatch_lines";
  public static final String k_x_orders_despatch = "k_x_orders_despatch";
  public static final String k_despatch_next = "k_despatch_next";
  public static final String k_invoices = "k_invoices";
  public static final String k_returned_invoices = "k_returned_invoices";
  public static final String k_x_orders_invoices = "k_x_orders_invoices";
  public static final String k_invoice_lines = "k_invoice_lines";
  public static final String k_invoices_lookup = "k_invoices_lookup";
  public static final String k_invoices_next = "k_invoices_next";
  public static final String k_invoice_schedules = "k_invoice_schedules";
  public static final String k_invoice_payments = "k_invoice_payments";
  public static final String k_sale_points = "k_sale_points";
  public static final String k_warehouses = "k_warehouses";

  public static final String k_business_states = "k_business_states";
  public static final String k_lu_business_states = "k_lu_business_states";

  public static final String k_containers_def = "k_containers_def";
  public static final String k_documents_def = "k_documents_def";
  public static final String k_blocks_def = "k_blocks_def";
  public static final String k_x_cont_block_def = "k_x_cont_block_def";
  public static final String k_x_cont_doc_def = "k_x_cont_doc_def";
  public static final String k_doc_instances = "k_doc_instances";
  public static final String k_block_instances = "k_block_instances";

  public static final String k_queries = "k_queries";
  public static final String k_lists = "k_lists";
  public static final String k_list_members = "k_list_members";
  public static final String k_x_list_members = "k_x_list_members";
  public static final String k_grey_list = "k_grey_list";
  public static final String k_global_black_list = "k_global_black_list";
  public static final String k_list_jobs = "k_list_jobs";
  public static final String k_member_address = "k_member_address";

  public static final String k_bugs = "k_bugs";
  public static final String k_bugs_changelog = "k_bugs_changelog";
  public static final String k_bugs_track = "k_bugs_track";
  public static final String k_duties = "k_duties";
  public static final String k_duties_lookup = "k_duties_lookup";
  public static final String k_duties_attach = "k_duties_attach";
  public static final String k_duties_workreports = "k_duties_workreports";
  public static final String k_x_duty_resource = "k_x_duty_resource";
  public static final String k_bugs_lookup = "k_bugs_lookup";
  public static final String k_bugs_attach = "k_bugs_attach";

  public static final String k_projects = "k_projects";
  public static final String k_projects_lookup = "k_projects_lookup";
  public static final String k_project_expand = "k_project_expand";
  public static final String k_project_costs = "k_project_costs";
  public static final String k_project_snapshots = "k_project_snapshots";

  public static final String k_sales_men = "k_sales_men";
  public static final String k_sales_men_lookup = "k_sales_men_lookup";
  public static final String k_sales_objectives = "k_sales_objectives";
  public static final String k_companies = "k_companies";
  public static final String k_companies_lookup = "k_companies_lookup";
  public static final String k_companies_attrs = "k_companies_attrs";
  public static final String k_companies_recent = "k_companies_recent";
  public static final String k_x_group_company = "k_x_group_company";
  public static final String k_x_company_addr = "k_x_company_addr";
  public static final String k_x_company_bank = "k_x_company_bank";
  public static final String k_x_company_prods = "k_x_company_prods";
  public static final String k_contacts = "k_contacts";
  public static final String k_contact_attachs = "k_contact_attachs";
  public static final String k_contact_notes = "k_contact_notes";
  public static final String k_contacts_attrs = "k_contacts_attrs";
  public static final String k_contacts_lookup = "k_contacts_lookup";
  public static final String k_contacts_recent = "k_contacts_recent";
  public static final String k_x_group_contact = "k_x_group_contact";
  public static final String k_x_contact_addr = "k_x_contact_addr";
  public static final String k_x_contact_bank = "k_x_contact_bank";
  public static final String k_x_contact_prods = "k_x_contact_prods";
  public static final String k_oportunities = "k_oportunities";
  public static final String k_oportunities_lookup = "k_oportunities_lookup";
  public static final String k_oportunities_attrs = "k_oportunities_attrs";
  public static final String k_x_oportunity_contacts = "k_x_oportunity_contacts";
  public static final String k_welcome_packs = "k_welcome_packs";
  public static final String k_welcome_packs_lookup = "k_welcome_packs_lookup";
  public static final String k_welcome_packs_changelog = "k_welcome_packs_changelog";
  public static final String k_suppliers = "k_suppliers";
  public static final String k_suppliers_lookup = "k_suppliers_lookup";
  public static final String k_prod_suppliers = "k_prod_suppliers";

  public static final String k_campaigns = "k_campaigns";
  public static final String k_x_campaign_lists = "k_x_campaign_lists";
  public static final String k_campaign_targets = "k_campaign_targets";
  
  public static final String k_activities = "k_activities";
  public static final String k_x_activity_audience = "k_x_activity_audience";
  public static final String k_activity_audience_lookup = "k_activity_audience_lookup";
  public static final String k_activity_attachs = "k_activity_attachs";
  public static final String k_activity_tags = "k_activity_tags";
  public static final String k_syndfeeds = "k_syndfeeds";
  public static final String k_syndfeeds_info_cache = "k_syndfeeds_info_cache";
  public static final String k_syndentries = "k_syndentries";
  public static final String k_syndreferers = "k_syndreferers";
  public static final String k_syndsearches = "k_syndsearches";
  public static final String k_syndsearch_run = "k_syndsearch_run";
  public static final String k_syndsearch_request = "k_syndsearch_request";
  	
  public static final String k_microsites = "k_microsites";
  public static final String k_pagesets = "k_pagesets";
  public static final String k_pagesets_lookup = "k_pagesets_lookup";
  public static final String k_x_pageset_list = "k_x_pageset_list";
  public static final String k_pageset_pages = "k_pageset_pages";
  public static final String k_pageset_datasheets = "k_pageset_datasheets";
  public static final String k_pageset_answers = "k_pageset_answers";
  public static final String k_datasheets_lookup = "k_datasheets_lookup";

  public static final String k_events = "k_events";
  public static final String k_jobs = "k_jobs";
  public static final String k_job_atoms = "k_job_atoms";
  public static final String k_job_atoms_archived = "k_job_atoms_archived";
  public static final String k_job_atoms_clicks = "k_job_atoms_clicks";
  public static final String k_jobs_atoms_by_day = "k_jobs_atoms_by_day";
  public static final String k_jobs_atoms_by_hour = "k_jobs_atoms_by_hour";
  public static final String k_jobs_atoms_by_agent = "k_jobs_atoms_by_agent";
  public static final String k_lu_job_commands = "k_lu_job_commands";
  public static final String k_lu_job_status = "k_lu_job_status";
  public static final String k_job_atoms_tracking = "k_job_atoms_tracking";
  public static final String k_job_clicks = "k_job_clicks";

  public static final String k_fellows = "k_fellows";
  public static final String k_fellows_attach = "k_fellows_attach";
  public static final String k_fellows_lookup = "k_fellows_lookup";
  public static final String k_lu_fellow_titles = "k_lu_fellow_titles";
  public static final String k_rooms = "k_rooms";
  public static final String k_rooms_lookup = "k_rooms_lookup";
  public static final String k_meetings = "k_meetings";
  public static final String k_meetings_lookup = "k_meetings_lookup";
  public static final String k_x_meeting_room = "k_x_meeting_room";
  public static final String k_x_meeting_fellow = "k_x_meeting_fellow";
  public static final String k_x_meeting_contact = "k_x_meeting_contact";
  public static final String k_phone_calls = "k_phone_calls";
  public static final String k_to_do = "k_to_do";
  public static final String k_to_do_lookup = "k_to_do_lookup";
  public static final String k_working_calendar = "k_working_calendar";
  public static final String k_working_time = "k_working_time";

  public static final String k_newsgroups = "k_newsgroups";
  public static final String k_newsgroup_tags = "k_newsgroup_tags";
  public static final String k_newsgroup_subscriptions = "k_newsgroup_subscriptions";
  public static final String k_newsmsgs = "k_newsmsgs";
  public static final String k_newsmsg_vote = "k_newsmsg_vote";
  public static final String k_newsmsg_tags = "k_newsmsg_tags";

  public static final String k_mime_msgs = "k_mime_msgs";
  public static final String k_inet_addrs = "k_inet_addrs";
  public static final String k_adhoc_mailings = "k_adhoc_mailings";
  public static final String k_x_adhoc_mailing_list = "k_x_adhoc_mailing_list";
  public static final String k_adhoc_mailings_lookup = "k_adhoc_mailings_lookup";
  public static final String k_mime_parts = "k_mime_parts";

  public static final String k_courses = "k_courses";
  public static final String k_academic_courses = "k_academic_courses";
  public static final String k_courses_lookup = "k_courses_lookup";
  public static final String k_subjects = "k_subjects";
  public static final String k_subjects_lookup = "k_subjects_lookup";
  public static final String k_x_user_acourse = "k_x_user_acourse";
  public static final String k_x_course_alumni = "k_x_course_alumni";
  public static final String k_x_course_subject = "k_x_course_subject";
  public static final String k_x_course_bookings = "k_x_course_bookings";
  public static final String k_evaluations = "k_evaluations";
  public static final String k_absentisms = "k_absentisms";
  public static final String k_absentisms_lookup = "k_absentisms_lookup";
  public static final String k_education_institutions = "k_education_institutions";
  public static final String k_education_degree = "k_education_degree";
  public static final String k_education_degree_lookup = "k_education_degree_lookup";
  public static final String k_contact_education = "k_contact_education";

  /**i2e 15-12-2009**/
  public static final String k_contact_short_courses = "k_contact_short_courses";
  public static final String k_contact_computer_science = "k_contact_computer_science";
  public static final String k_contact_computer_science_lookup = "k_contact_computer_science_lookup";
  public static final String k_contact_languages = "k_contact_languages";
  public static final String k_contact_languages_lookup = "k_contact_languages_lookup";
  public static final String k_contact_experience = "k_contact_experience";
  
  /**Fin i2e **/
  
  public static final String k_sms_msisdn = "k_sms_msisdn";
  public static final String k_sms_audit = "k_sms_audit";

  /**i2e 20-01-2010**/
  public static final String k_admission = "k_admission";
  public static final String k_admission_lookup = "k_admission_lookup";
  /**fin**/
  
  /**i2e 01-02-2010**/
  public static final String k_registrations = "k_registrations";
  public static final String k_registrations_lookup = "k_registrations_lookup";
  /**fin**/
  
  /***************/
  /* VIEW NAMES  */
  /***************/

  public static final String v_prod_cat = "v_prod_cat";
  public static final String v_cat_tree_labels = "v_cat_tree_labels";
  public static final String v_company_address = "v_company_address";
  public static final String v_contact_address = "v_contact_address";
  public static final String v_contact_address_title = "v_contact_address_title";
  public static final String v_contact_list = "v_contact_list";
  public static final String v_contact_company = "v_contact_company";
  public static final String v_contact_company_all = "v_contact_company_all";
  public static final String v_duty_resource = "v_duty_resource";
  public static final String v_duty_project = "v_duty_project";
  public static final String v_attach_locat = "v_attach_locat";
  public static final String v_member_address = "v_member_address";
  public static final String v_jobs = "v_jobs";
  public static final String v_active_courses = "v_active_courses";
  public static final String v_campaign_contacts = "v_campaign_contacts";
  public static final String v_sale_points = "v_sale_points";
  public static final String v_warehouses = "v_warehouses";
  public static final String v_contact_education_degree = "v_contact_education_degree";
  public static final String v_activity_locat = "v_activity_locat";
  
  /***************/
  /* FIELD NAMES */
  /***************/

  // k_version
  public static final String bo_register = "bo_register";
  public static final String bo_allow_stats = "bo_allow_stats";
  public static final String gu_support = "gu_support";
  	
  // k_lu_currencies
  public static final String alpha_code = "alpha_code";
  public static final String alpha_code_from = "alpha_code_from";
  public static final String alpha_code_to = "alpha_code_to";
  public static final String numeric_code = "numeric_code";
  public static final String char_code = "char_code";
  public static final String nm_entity = "nm_entity";
  public static final String id_entity = "id_entity";
  public static final String nu_conversion = "nu_conversion";
  public static final String tr_currency_ = "tr_currency_";
  public static final String dt_stamp = "dt_stamp";

  // k_lu_countries
  public static final String id_country = "id_country";
  public static final String tr_country_ = "tr_country_";
  public static final String tr_country_en = "tr_country_en";
  public static final String tr_country_es = "tr_country_es";
  public static final String tr_country_fr = "tr_country_fr";
  public static final String tr_country_de = "tr_country_de";
  public static final String tr_country_it = "tr_country_it";
  public static final String tr_country_pt = "tr_country_pt";
  public static final String tr_country_ca = "tr_country_ca";
  public static final String tr_country_eu = "tr_country_eu";
  public static final String tr_country_ja = "tr_country_ja";
  public static final String tr_country_cn = "tr_country_cn";
  public static final String tr_country_tw = "tr_country_tw";
  public static final String tr_country_fi = "tr_country_fi";
  public static final String tr_country_ru = "tr_country_ru";
  public static final String tr_country_pl = "tr_country_pl";
  public static final String tr_country_nl = "tr_country_nl";
  public static final String tr_country_th = "tr_country_th";
  public static final String tr_country_cs = "tr_country_cs";
  public static final String tr_country_uk = "tr_country_uk";
  public static final String tr_country_no = "tr_country_no";

  // k_lu_meta_attrs
  public static final String nm_table = "nm_table";
  public static final String tp_attr = "tp_attr";
  public static final String pg_attr = "pg_attr";
  public static final String max_len = "max_len";
  public static final String nm_attr = "nm_attr";
  public static final String vl_attr = "vl_attr";
  public static final String gu_object = "gu_object";

  // k_domains
  public static final String id_domain = "id_domain";
  public static final String nm_domain = "nm_domain";
  public static final String bo_active = "bo_active";
  public static final String dt_created = "dt_created";
  public static final String gu_owner = "gu_owner";
  public static final String gu_admins = "gu_admins";
  public static final String gu_writer = "gu_writer";
  public static final String bo_private = "bo_private";

  // k_users
  public static final String gu_user = "gu_user";
  public static final String nm_user = "nm_user";
  public static final String tx_surname1 = "tx_surname1";
  public static final String tx_surname2 = "tx_surname2";
  public static final String tx_challenge = "tx_challenge";
  public static final String tx_reply = "tx_reply";
  public static final String nm_company = "nm_company";
  public static final String de_title = "de_title";
  public static final String id_gender = "id_gender";
  public static final String dt_birth = "dt_birth";
  public static final String ny_age = "ny_age";
  public static final String sn_passport = "sn_passport";
  public static final String tp_passport = "tp_passport";
  public static final String sn_drivelic = "sn_drivelic";
  public static final String dt_drivelic = "dt_drivelic";
  public static final String tx_comments = "tx_comments";
  public static final String tx_nickname = "tx_nickname";
  public static final String tx_pwd = "tx_pwd";
  public static final String bo_searchable = "bo_searchable";
  public static final String bo_change_pwd = "bo_change_pwd";
  public static final String tx_main_email = "tx_main_email";
  public static final String tx_alt_email = "tx_alt_email";
  public static final String full_name = "full_name";
  public static final String len_quota = "len_quota";
  public static final String max_quota = "max_quota";
  public static final String dt_last_visit = "dt_last_visit";
  public static final String marital_status = "marital_status";
  public static final String tx_education = "tx_education";
  public static final String icq_id = "icq_id";
  public static final String tx_pwd_sign = "tx_pwd_sign";
  public static final String dt_pwd_expires = "dt_pwd_expires";
  public static final String nu_login_attempts = "nu_login_attempts";
  public static final String bo_admin = "bo_admin";
  public static final String bo_user = "bo_user";

  // k_user_mail
  public static final String gu_account = "gu_account";
  public static final String tl_account = "tl_account";
  public static final String bo_default = "bo_default";
  public static final String bo_synchronize = "bo_synchronize";
  public static final String tx_reply_email = "tx_reply_email";
  public static final String incoming_protocol = "incoming_protocol";
  public static final String incoming_account = "incoming_account";
  public static final String incoming_password = "incoming_password";
  public static final String incoming_server = "incoming_server";
  public static final String incoming_spa = "incoming_spa";
  public static final String incoming_ssl = "incoming_ssl";
  public static final String incoming_port = "incoming_port";
  public static final String outgoing_protocol = "outgoing_protocol";
  public static final String outgoing_account = "outgoing_account";
  public static final String outgoing_password = "outgoing_password";
  public static final String outgoing_server = "outgoing_server";
  public static final String outgoing_spa = "outgoing_spa";
  public static final String outgoing_ssl = "outgoing_ssl";
  public static final String outgoing_port = "outgoing_port";

  // k_user_pwd
  public static final String gu_pwd = "gu_pwd";
  public static final String tl_pwd = "tl_pwd";
  public static final String tp_pwd = "tp_pwd";
  public static final String id_enc_method = "id_enc_method";
  public static final String id_pwd = "id_pwd";
  public static final String tx_account = "tx_account";
  public static final String tx_prk = "tx_prk";
  public static final String tx_pbk = "tx_pbk";
  public static final String bin_key = "bin_key";
  public static final String tx_lines = "tx_lines";

  // k_groups
  public static final String gu_acl_group = "gu_acl_group";
  public static final String nm_acl_group = "nm_acl_group";
  public static final String acl_mask = "acl_mask";
  public static final String de_acl_group = "de_acl_group";

  // k_workareas
  public static final String gu_workarea = "gu_workarea";
  public static final String nm_workarea = "nm_workarea";
  public static final String path_files = "path_files";
  public static final String path_logo = "path_logo";
  public static final String gu_powusers = "gu_powusers";
  public static final String gu_users = "gu_users";
  public static final String gu_guests = "gu_guests";
  public static final String gu_other = "gu_other";
  public static final String id_locale = "id_locale";
  public static final String tx_date_format = "tx_date_format";
  public static final String tx_number_format = "tx_number_format";
  public static final String bo_allcaps = "bo_allcaps";
  public static final String bo_dup_id_docs = "bo_dup_id_docs";
  public static final String bo_cnt_autoref = "bo_cnt_autoref";
  public static final String bo_acrs_oprt = "bo_acrs_oprt";

  // k_queries
  public static final String gu_query = "gu_query";
  public static final String tl_query = "tl_query";
  public static final String nm_queryspec = "nm_queryspec";

  // k_lists
  public static final String gu_list = "gu_list";
  public static final String tp_list = "tp_list";
  public static final String de_list = "de_list";
  public static final String tx_sender = "tx_sender";
  public static final String tx_from = "tx_from";
  public static final String tx_subject = "tx_subject";
  public static final String tp_member = "tp_member";
  public static final String gu_member = "gu_member";
  public static final String id_format = "id_format";
  public static final String tx_info = "tx_info";

  // k_categories
  public static final String gu_category = "gu_category";
  public static final String nm_category = "nm_category";
  public static final String id_doc_status = "id_doc_status";
  public static final String gu_parent_cat = "gu_parent_cat";
  public static final String gu_child_cat = "gu_child_cat";
  public static final String nm_icon = "nm_icon";
  public static final String nm_icon2 = "nm_icon2";
  public static final String id_class = "id_class";
  public static final String bi_attribs = "bi_attribs";
  public static final String od_position = "od_position";
  public static final String gu_rootcat = "gu_rootcat";
  public static final String len_size = "len_size";

  // k_lookups
  public static final String id_section = "id_section";
  public static final String pg_lookup = "pg_lookup";
  public static final String vl_lookup = "vl_lookup";
  public static final String tp_lookup = "tp_lookup";
  public static final String tr_ = "tr_";

  // k_images
  public static final String gu_image = "gu_image";
  public static final String path_image = "path_image";
  public static final String gu_block = "gu_block";
  public static final String id_img_type = "id_img_type";
  public static final String dm_width = "dm_width";
  public static final String dm_height = "dm_height";
  public static final String nm_image = "nm_image";
  public static final String tl_image = "tl_image";
  public static final String tp_image = "tp_image";

  // k_paragraphs
  public static final String gu_paragraph = "gu_paragraph";
  public static final String nm_paragraph = "nm_paragraph";
  public static final String tx_memo = "tx_memo";

  // k_products
  public static final String gu_product = "gu_product";
  public static final String nm_product = "nm_product";
  public static final String de_product = "de_product";
  public static final String is_compound = "is_compound";
  public static final String id_prod_type = "id_prod_type";
  public static final String de_prod_type = "de_prod_type";
  public static final String pr_list = "pr_list";
  public static final String pr_sale = "pr_sale";
  public static final String pr_discount = "pr_discount";
  public static final String pr_purchase = "pr_purchase";
  public static final String id_currency = "id_currency";
  public static final String pct_tax_rate = "pct_tax_rate";
  public static final String is_tax_included = "is_tax_included";
  public static final String tag_product = "tag_product";
  public static final String gu_blockedby = "gu_blockedby";

  // k_prod_fares
  public static final String id_fare = "id_fare";
  public static final String tp_fare = "tp_fare";

  // k_prod_locats
  public static final String gu_location = "gu_location";
  public static final String pg_prod_locat = "pg_prod_locat";
  public static final String de_prod_locat = "de_prod_locat";
  public static final String tag_prod_locat = "tag_prod_locat";
  public static final String len_file = "len_file";
  public static final String vs_stamp = "vs_stamp";
  public static final String mime_type = "mime_type";
  public static final String status = "status";
  public static final String nu_current_stock = "nu_current_stock";
  public static final String nu_min_stock = "nu_min_stock";

  // k_prod_attr
  public static final String author = "author";
  public static final String pages = "pages";
  public static final String subject = "subject";
  public static final String words = "words";

  // k_prod_keywords
  public static final String tx_keywords = "tx_keywords";

  // k_shops
  public static final String gu_shop = "gu_shop";
  public static final String nm_shop = "nm_shop";
  public static final String gu_root_cat = "gu_root_cat";
  public static final String gu_bundles_cat = "gu_bundles_cat";

  // k_quotations
  public static final String gu_quotation = "gu_quotation";
  public static final String pg_quotation = "pg_quotation";

  // k_orders
  public static final String gu_order = "gu_order";
  public static final String gu_item = "gu_item";
  public static final String de_order = "de_order";
  public static final String pg_order = "pg_order";
  public static final String pg_line = "pg_line";
  public static final String nm_client = "nm_client";
  public static final String nu_quantity = "nu_quantity";
  public static final String id_unit = "id_unit";
  public static final String pr_total = "pr_total";
  public static final String tx_promotion = "tx_promotion";
  public static final String tx_options = "tx_options";
  public static final String id_pay_status ="id_pay_status";
  public static final String id_ship_method ="id_ship_method";
  public static final String gu_ship_addr = "gu_ship_addr";
  public static final String gu_bill_addr = "gu_bill_addr";
  public static final String dt_payment ="dt_payment";
  public static final String im_subtotal ="im_subtotal";
  public static final String im_taxes = "im_taxes";
  public static final String im_shipping = "im_shipping";
  public static final String im_discount = "im_discount";
  public static final String im_total = "im_total";
  public static final String im_paid = "im_paid";
  public static final String tx_ship_notes = "tx_ship_notes";
  public static final String dt_promised = "dt_promised";
  public static final String dt_delivered = "dt_delivered";

  // k_despatch_notes
  public static final String gu_despatch = "gu_despatch";
  public static final String pg_despatch = "pg_despatch";
  public static final String de_despatch = "de_despatch";

  // k_invoices
  public static final String gu_invoice = "gu_invoice";
  public static final String pg_invoice = "pg_invoice";
  public static final String bo_approved = "bo_approved";
  public static final String  bo_template = "bo_template";
  public static final String  gu_schedule = "gu_schedule";
  public static final String  gu_sale_point = "gu_sale_point";
  public static final String  gu_warehouse = "gu_warehouse";
  public static final String  dt_invoiced = "dt_invoiced";
  public static final String  dt_printed = "dt_printed";
  public static final String  dt_paid = "dt_paid";
  public static final String  dt_cancel = "dt_cancel";
  public static final String  nu_cvv2 = "nu_cvv2";
  public static final String  tx_email_to = "tx_email_to";
  public static final String  pg_payment = "pg_payment";
  public static final String  id_transact = "id_transact";

  // k_returned_invoices
  public static final String gu_returned = "gu_returned";
  public static final String dt_returned = "dt_returned";

  //  k_sale_points
  public static final String nm_sale_point = "nm_sale_point";

  // k_warehouses
  public static final String nm_warehouse = "nm_warehouse";

  // k_addresses
  public static final String gu_address = "gu_address";
  public static final String ix_address = "ix_address";
  public static final String tp_location = "tp_location";
  public static final String tp_street = "tp_street";
  public static final String nm_street = "nm_street";
  public static final String nu_street = "nu_street";
  public static final String tx_addr1 = "tx_addr1";
  public static final String tx_addr2 = "tx_addr2";
  public static final String nm_country = "nm_country";
  public static final String id_state = "id_state";
  public static final String nm_state = "nm_state";
  public static final String mn_city = "mn_city";
  public static final String zipcode = "zipcode";
  public static final String work_phone = "work_phone";
  public static final String direct_phone = "direct_phone";
  public static final String home_phone = "home_phone";
  public static final String mov_phone = "mov_phone";
  public static final String fax_phone = "fax_phone";
  public static final String other_phone = "other_phone";
  public static final String po_box = "po_box";
  public static final String tx_email = "tx_email";
  public static final String tx_email_alt = "tx_email_alt";
  public static final String coord_x = "coord_x";
  public static final String coord_y = "coord_y";
  public static final String contact_person = "contact_person";
  public static final String tx_salutation = "tx_salutation";
  public static final String tx_remarks = "tx_remarks";
  public static final String zip_code = "zip_code";

  // k_distances_cache
  public static final String lo_from = "lo_from";
  public static final String lo_to = "lo_to";
  public static final String nu_km = "nu_km";

  // k_thesauri
  public static final String gu_rootterm = "gu_rootterm";
  public static final String gu_term = "gu_term";
  public static final String bo_mainterm = "bo_mainterm";
  public static final String tx_term = "tx_term";
  public static final String gu_synonym = "gu_synonym";
  public static final String de_term = "de_term";
  public static final String id_scope = "id_scope";
  public static final String id_term = "id_term";

  // k_urls
  public static final String gu_url = "gu_url";
  public static final String de_url = "de_url";
  public static final String tx_title = "tx_title";

  // k_pagesets
  public static final String gu_pageset = "gu_pageset";
  public static final String path_template = "path_template";
  public static final String url_addr = "url_addr";

  // k_pageset_pages
  public static final String gu_page = "gu_page";
  public static final String pg_page = "pg_page";
  public static final String tl_page = "tl_page";
  public static final String path_page = "path_page";
  public static final String path_publish = "path_publish";
  public static final String nm_page = "nm_page";
  public static final String nm_zone = "nm_zone";

  // k_pageset_datasheets
  public static final String id_segment = "id_segment";
  public static final String tx_politics = "tx_politics";
  public static final String pr_mortgage = "pr_mortgage";
  public static final String nu_income = "nu_income";
  public static final String tp_home = "tp_home";
  public static final String nu_children = "nu_children";
  public static final String bo_wantchilds = "bo_wantchilds";
  public static final String bo_native = "bo_native";

  public static final String id_key = "id_key";
  public static final String id_status = "id_status";
  public static final String id_old_status = "id_old_status";
  public static final String id_new_status = "id_new_status";
  public static final String id_cont_type = "id_cont_type";

  public static final String cat_prod_score = "cat_prod_score";
  public static final String surname1 = "surname1";
  public static final String surname2 = "surname2";
  public static final String email = "email";
  public static final String email_alt = "email_alt";
  public static final String change_pwd = "change_pwd";
  public static final String pwd_text = "pwd_text";
  public static final String tr_category = "tr_category";
  public static final String de_category = "de_category";
  public static final String url_category = "url_category";
  public static final String dt_modified = "dt_modified";
  public static final String dt_expire = "dt_expire";
  public static final String dt_uploaded = "dt_uploaded";
  public static final String dt_last_update = "dt_last_update";
  public static final String id_language = "id_language";
  public static final String tr_lang_ = "tr_lang_";
  public static final String tr_lang_en = "tr_lang_en";
  public static final String tr_lang_es = "tr_lang_es";
  public static final String tr_lang_fr = "tr_lang_fr";
  public static final String tr_lang_de = "tr_lang_de";
  public static final String tr_lang_it = "tr_lang_it";
  public static final String tr_lang_ja = "tr_lang_ja";
  public static final String tr_lang_pt = "tr_lang_pt";
  public static final String tr_lang_ca = "tr_lang_ca";
  public static final String tr_lang_eu = "tr_lang_eu";
  public static final String tr_lang_cn = "tr_lang_cn";
  public static final String tr_lang_tw = "tr_lang_tw";
  public static final String tr_lang_fi = "tr_lang_fi";
  public static final String tr_lang_ru = "tr_lang_ru";
  public static final String tr_lang_pl = "tr_lang_pl";
  public static final String tr_lang_nl = "tr_lang_nl";
  public static final String tr_lang_th = "tr_lang_th";
  public static final String tr_lang_cs = "tr_lang_cs";
  public static final String tr_lang_uk = "tr_lang_uk";
  public static final String tr_lang_no = "tr_lang_no";
  public static final String tr_lang_ko = "tr_lang_ko";
  public static final String tr_lang_vn = "tr_lang_vn";

  public static final String xprotocol = "xprotocol";
  public static final String xport = "xport";
  public static final String xhost = "xhost";
  public static final String xpath = "xpath";
  public static final String xfile = "xfile";
  public static final String xoriginalfile = "xoriginalfile";
  public static final String xanchor = "xanchor";

  // k_projects
  public static final String gu_project = "gu_project";
  public static final String nm_project = "nm_project";
  public static final String id_parent= "id_parent";
  public static final String dt_start = "dt_start";
  public static final String dt_end = "dt_end";
  public static final String dt_scheduled = "dt_scheduled";
  public static final String id_dept = "id_dept";
  public static final String de_project = "de_project";

  // k_project_expand
  public static final String gu_rootprj = "gu_rootprj";
  public static final String od_level = "od_level";
  public static final String od_walk = "od_walk";
  public static final String gu_parent = "gu_parent";

  // k_project_costs
  public static final String gu_cost = "gu_cost";
  public static final String dt_cost = "dt_cost";
  public static final String tp_cost = "tp_cost";
  public static final String tl_cost = "tl_cost";
  public static final String de_cost = "de_cost";
  
  // k_project_snapshots
  public static final String gu_snapshot = "gu_snapshot";
  public static final String tl_snapshot = "tl_snapshot";
  public static final String tx_snapshot = "tx_snapshot";

  // k_bugs
  public static final String gu_bug = "gu_bug";
  public static final String pg_bug = "pg_bug";
  public static final String pg_bug_track = "pg_bug_track";
  public static final String tl_bug = "tl_bug";
  public static final String tp_bug = "tp_bug";
  public static final String gu_bug_ref = "gu_bug_ref";
  public static final String dt_since = "dt_since";
  public static final String dt_closed = "dt_closed";
  public static final String dt_verified = "dt_verified";
  public static final String nu_times = "nu_times";
  public static final String vs_found = "vs_found";
  public static final String vs_closed = "vs_closed";
  public static final String od_severity = "od_severity";
  public static final String od_priority = "od_priority";
  public static final String tx_status = "tx_status";
  public static final String nm_reporter = "nm_reporter";
  public static final String tx_rep_mail = "tx_rep_mail";
  public static final String nm_assigned = "nm_assigned";
  public static final String nm_inspector = "nm_inspector";
  public static final String tx_bug_brief = "tx_bug_brief";
  public static final String tx_bug_info = "tx_bug_info";
  public static final String id_client = "id_client";
  public static final String tx_bug_track = "tx_bug_track";

  // k_bugs_changelog
  public static final String nm_column = "nm_column";
  public static final String tx_oldvalue = "tx_oldvalue";

  // k_bugs_attach
  public static final String tx_file = "tx_file";
  public static final String bin_file = "bin_file";

  // k_duties
  public static final String gu_duty = "gu_duty";
  public static final String nm_duty = "nm_duty";
  public static final String de_duty = "de_duty";
  public static final String tp_duty = "tp_duty";
  public static final String nm_resource = "nm_resource";
  public static final String pct_complete = "pct_complete";
  public static final String pct_time = "pct_time";
  public static final String pr_cost = "pr_cost";
  public static final String ti_duration = "ti_duration";

  // k_duties_workreports
  public static final String gu_workreport = "gu_workreport";
  public static final String de_workreport = "de_workreport";
  public static final String tl_workreport = "tl_workreport";
  public static final String tx_workreport = "tx_workreport";

  // k_contatcs
  public static final String gu_contact = "gu_contact";
  public static final String id_ref = "id_ref";
  public static final String tx_name = "tx_name";
  public static final String tx_surname = "tx_surname";
  public static final String tx_dept = "tx_dept";
  public static final String tx_division = "tx_division";
  public static final String nu_notes = "nu_notes";
  public static final String nu_attachs = "nu_attachs";
  public static final String id_nationality = "id_nationality";
  public static final String url_facebook = "url_facebook";
  public static final String url_linkedin = "url_linkedin";
  public static final String url_twitter = "url_twitter";

  // k_sales_men
  public static final String gu_sales_man = "gu_sales_man";
  public static final String id_sales_group = "id_sales_group";
  public static final String tx_year = "tx_year";

  // k_companies
  public static final String gu_company = "gu_company";
  public static final String id_company = "id_company";
  public static final String nm_legal = "nm_legal";
  public static final String id_legal = "id_legal";
  public static final String nm_commercial = "nm_commercial";
  public static final String id_sector = "id_sector";
  public static final String de_company = "de_company";
  public static final String tp_company = "tp_company";
  public static final String nu_employees = "nu_employees";
  public static final String dt_founded = "dt_founded";
  public static final String tx_productline = "tx_productline";
  public static final String gu_geozone = "gu_geozone";
  public static final String tx_franchise = "tx_franchise";
  public static final String bo_restricted = "bo_restricted";

  // k_oportunities
  public static final String gu_oportunity = "gu_oportunity";
  public static final String tl_oportunity = "tl_oportunity";
  public static final String tp_oportunity = "tp_oportunity";
  public static final String tx_contact = "tx_contact";
  public static final String tx_company = "tx_company";
  public static final String tx_user = "tx_user";
  public static final String dt_next_action = "dt_next_action";
  public static final String dt_last_call = "dt_last_call";
  public static final String tp_origin = "tp_origin";
  public static final String tx_cause = "tx_cause";
  public static final String id_objetive = "id_objetive";
  public static final String tx_note = "tx_note";
  public static final String im_revenue = "im_revenue";
  public static final String im_cost = "im_cost";
  public static final String nu_elapsed = "nu_elapsed";
  public static final String lv_interest = "lv_interest";
  public static final String nu_oportunities = "nu_oportunities";
  public static final String tp_relation = "tp_relation";

  // k_contact_notes
  public static final String gu_note = "gu_note";
  public static final String pg_note = "pg_note";
  public static final String tl_note = "tl_note";
  public static final String tx_fullname = "tx_fullname";

  // k_contact_attachs
  public static final String gu_attachment = "gu_attachment";
  public static final String pg_product = "pg_product";

  // k_welcome_packs
  public static final String gu_pack = "gu_pack";
  public static final String ix_pack = "ix_pack";
  public static final String id_courier = "id_courier";

  // k_suppliers
  public static final String gu_supplier = "gu_supplier";
  public static final String tp_supplier = "tp_supplier";
  public static final String de_supplier = "de_supplier";

  // k_campaigns
  public static final String gu_campaign = "gu_campaign";
  public static final String nm_campaign = "nm_campaign";
  public static final String gu_campaign_target = "gu_campaign_target";
  public static final String nu_planned = "nu_planned";
  public static final String nu_achieved = "nu_achieved";

  // k_activities
  public static final String gu_activity = "gu_activity";
  public static final String pg_activity = "pg_activity";
  public static final String tl_activity = "tl_activity";
  public static final String de_activity = "de_activity";
  public static final String nu_capacity = "nu_capacity";
  public static final String bo_allows_ads = "bo_allows_ads";
  public static final String bo_urgent = "bo_urgent";
  public static final String bo_reminder = "bo_reminder";
  public static final String gu_mailing = "gu_mailing";
  public static final String dt_mailing = "dt_mailing";
  public static final String url_activity = "url_activity";  	
  public static final String tp_tag = "tp_tag";
  public static final String nm_tag = "nm_tag";
  
  // k_microsites
  public static final String gu_microsite = "gu_microsite";
  public static final String id_app = "id_app";
  public static final String nm_app = "nm_app";
  public static final String nm_microsite = "nm_microsite";
  public static final String tp_microsite = "tp_microsite";
  public static final String path_metadata = "path_metadata";

  // k_pagesets
  public static final String nm_pageset = "nm_pageset";
  public static final String path_data = "path_data";

  // k_pageset_datasheets
  public static final String gu_datasheet = "gu_datasheet";
  public static final String tx_datasheet = "tx_datasheet";

  // k_pageset_answers
  public static final String pg_answer = "pg_answer";
  public static final String tp_answer = "tp_answer";
  public static final String nm_answer = "nm_answer";
  public static final String tx_answer = "tx_answer";

  // k_events
  public static final String id_event = "id_event";
  public static final String de_event = "de_event";
  public static final String fixed_rate = "fixed_rate";

  // k_jobs
  public static final String gu_job = "gu_job";
  public static final String tl_job = "tl_job";
  public static final String gu_job_group = "gu_job_group";
  public static final String id_command = "id_command";
  public static final String tx_parameters = "tx_parameters";
  public static final String pg_atom = "pg_atom";
  public static final String tx_log = "tx_log";
  public static final String dt_execution = "dt_execution";
  public static final String dt_hour = "dt_hour";
  public static final String dt_finished = "dt_finished";
  public static final String dt_action = "dt_action";
  public static final String nu_sent = "nu_sent";
  public static final String nu_opened = "nu_opened";
  public static final String nu_clicks = "nu_clicks";
  public static final String nu_unique = "nu_unique";
  public static final String id_agent = "id_agent";

  // k_lu_job_commands
  public static final String tx_command = "tx_command";
  public static final String nm_class = "nm_class";

  // k_fellows
  public static final String gu_fellow = "gu_fellow";
  public static final String tx_location = "tx_location";
  public static final String ext_phone = "ext_phone";
  public static final String id_title = "id_title";
  public static final String tp_title = "tp_title";
  public static final String id_boss = "id_boss";
  public static final String im_salary_max = "im_salary_max";
  public static final String im_salary_min = "im_salary_min";
  public static final String tx_timezone = "tx_timezone";

  // k_rooms
  public static final String nm_room = "nm_room";
  public static final String bo_available = "bo_available";
  public static final String tp_room = "tp_room";

  // k_meetings
  public static final String gu_meeting = "gu_meeting";
  public static final String df_before = "df_before";
  public static final String tp_meeting = "tp_meeting";
  public static final String tx_meeting = "tx_meeting";
  public static final String de_meeting = "de_meeting";
  public static final String id_icalendar = "id_icalendar";

  // k_phone_calls
  public static final String gu_phonecall = "gu_phonecall";
  public static final String tp_phonecall = "tp_phonecall";
  public static final String tx_phone = "tx_phone";

  // k_to_do
  public static final String gu_to_do = "gu_to_do";
  public static final String tl_to_do = "tl_to_do";
  public static final String tp_to_do = "tp_to_do";
  public static final String tx_to_do = "tx_to_do";

  // k_working_calendar
  public static final String gu_calendar = "gu_calendar";
  public static final String nm_calendar = "nm_calendar";
  public static final String dt_day = "dt_day";
  public static final String bo_working_time = "bo_working_time";
  public static final String hh_start1 = "hh_start1";
  public static final String mi_start1 = "mi_start1";
  public static final String hh_start2 = "hh_start2";
  public static final String mi_start2 = "mi_start2";
  public static final String hh_end1 = "hh_end1";
  public static final String mi_end1 = "mi_end1";
  public static final String hh_end2 = "hh_end2";
  public static final String mi_end2 = "mi_end2";
  public static final String de_day = "de_day";

  // k_newsgroups
  public static final String gu_newsgrp = "gu_newsgrp";
  public static final String de_newsgrp = "de_newsgrp";
  public static final String bo_binaries = "bo_binaries";
  public static final String gu_msg = "gu_msg";
  public static final String tx_msg = "tx_msg";
  public static final String id_msg_type = "id_msg_type";
  public static final String gu_parent_msg = "gu_parent_msg";
  public static final String gu_thread_msg = "gu_thread_msg";
  public static final String nm_author = "nm_author";
  public static final String gu_validator = "gu_validator";
  public static final String dt_published = "dt_published";
  public static final String dt_validated = "dt_validated";
  public static final String nu_thread_msgs = "nu_thread_msgs";
  public static final String tp_subscrip = "tp_subscrip";
  public static final String pg_vote = "pg_vote";
  public static final String tx_vote = "tx_vote";
  public static final String nu_votes = "nu_votes";
  public static final String od_score = "od_score";
  public static final String ip_addr = "ip_addr";
  public static final String gu_tag = "gu_tag";
  public static final String od_tag = "od_tag";
  public static final String tl_tag = "tl_tag";
  public static final String de_tag = "de_tag";
  public static final String tx_tags = "tx_tags";
  public static final String nu_msgs = "nu_msgs";
  public static final String dt_trackback = "dt_trackback";
  public static final String url_trackback = "url_trackback";
  public static final String bo_incoming_ping = "bo_incoming_ping";
  public static final String tx_journal = "tx_journal";

  // k_accounts
  public static final String id_account = "id_account";
  public static final String tp_account = "tp_account";
  public static final String max_users = "max_users";
  public static final String tp_billing = "tp_billing";
  public static final String gu_billing_addr = "gu_billing_addr";
  public static final String gu_contact_addr = "gu_contact_addr";
  public static final String tx_addr = "tx_addr";
  public static final String nu_bank = "nu_bank";
  public static final String nm_bank = "nm_bank";
  public static final String nu_card = "nu_card";
  public static final String tp_card = "tp_card";
  public static final String tx_expire = "tx_expire";
  public static final String nu_pin = "nu_pin";
  public static final String nm_cardholder = "nm_cardholder";
  public static final String nu_bank_acc = "nu_bank_acc";
  public static final String im_credit_limit = "im_credit_limit";
  public static final String de_bank_acc = "de_bank_acc";

  // k_mime_msgs
  public static final String gu_mimemsg = "gu_mimemsg";
  public static final String dt_sent = "dt_sent";
  public static final String dt_readed = "dt_readed";
  public static final String dt_received = "dt_received";
  public static final String id_type = "id_type";
  public static final String id_priority = "id_priority";
  public static final String id_message = "id_message";
  public static final String pg_message = "pg_message";
  public static final String de_mimemsg = "de_mimemsg";
  public static final String len_mimemsg = "len_mimemsg";
  public static final String nu_position = "nu_position";
  public static final String nu_offset = "nu_offset";
  public static final String id_content = "id_content";
  public static final String by_content = "by_content";
  public static final String id_encoding = "id_encoding";
  public static final String tx_encoding = "tx_encoding";
  public static final String id_disposition = "id_disposition";
  public static final String id_compression = "id_compression";
  public static final String tx_md5 = "tx_md5";
  public static final String tx_email_from = "tx_email_from";
  public static final String tx_email_reply = "tx_email_reply";
  public static final String tx_personal = "tx_personal";
  public static final String tp_recipient = "tp_recipient";
  public static final String nm_from = "nm_from";
  public static final String nm_to = "nm_to";
  public static final String bo_answered = "bo_answered";
  public static final String bo_deleted = "bo_deleted";
  public static final String bo_draft = "bo_draft";
  public static final String bo_flagged = "bo_flagged";
  public static final String bo_readed = "bo_readed";
  public static final String bo_recent = "bo_recent";
  public static final String bo_seen = "bo_seen";
  public static final String bo_spam = "bo_spam";
  public static final String file_name = "file_name";
  public static final String dt_displayed = "dt_displayed";
  public static final String user_agent = "user_agent";

  // k_mime_parts
  public static final String id_part = "id_part";
  public static final String de_part = "de_part";
  public static final String len_part = "len_part";
  
  // k_adhoc_mailings
  public static final String pg_mailing = "pg_mailing";
  public static final String nm_mailing = "nm_mailing";
  public static final String bo_html_part = "bo_html_part";
  public static final String bo_plain_part = "bo_plain_part";
  public static final String bo_attachments = "bo_attachments";
  public static final String tx_allow_regexp = "tx_allow_regexp";
  public static final String tx_deny_regexp = "tx_deny_regexp";

  // k_x_portlet_user
  public static final String nm_portlet = "nm_portlet";

  // k_courses
  public static final String gu_course = "gu_course";
  public static final String nm_course = "nm_course";
  public static final String nm_acourse = "nm_acourse";
  public static final String id_course = "id_course";
  public static final String id_acourse = "id_acourse";
  public static final String de_course = "de_course";
  public static final String de_acourse = "de_acourse";
  public static final String tx_area = "tx_area";
  public static final String nu_credits = "nu_credits";

  // k_academic_courses
  public static final String gu_acourse = "gu_acourse";
  public static final String pr_acourse = "pr_acourse";
  public static final String pr_booking = "pr_booking";
  public static final String pr_payment = "pr_payment";
  public static final String nu_payments = "nu_payments";
  public static final String bo_confirmed = "bo_confirmed";
  public static final String dt_confirmed = "dt_confirmed";
  public static final String bo_paid = "bo_paid";
  public static final String bo_went = "bo_went";
  public static final String bo_waiting = "bo_waiting";
  public static final String bo_canceled = "bo_canceled";
  public static final String tx_start = "tx_start";
  public static final String tx_end = "tx_end";
  public static final String nm_tutor = "nm_tutor";
  public static final String tx_tutor_email = "tx_tutor_email";
  public static final String gu_alumni = "gu_alumni";
  public static final String tp_register = "tp_register";
  public static final String id_classroom = "id_classroom";
  public static final String gu_absentism = "gu_absentism";
  public static final String nu_max_alumni = "nu_max_alumni";

  // k_subjects
  public static final String gu_subject = "gu_subject";
  public static final String nm_subject = "nm_subject";
  public static final String id_subject = "id_subject";
  public static final String de_subject = "de_subject";
  public static final String nm_short = "nm_short";
  public static final String tm_start = "tm_start";
  public static final String tm_end = "tm_end";

  // k_absentisms
  public static final String bo_wholeday = "bo_wholeday";
  public static final String dt_from = "dt_from";
  public static final String dt_to = "dt_to";
  public static final String tp_absentism = "tp_absentism";

  // k_education_institutions
  public static final String gu_institution = "gu_institution";
  public static final String nm_institution = "nm_institution";
  public static final String nm_center = "nm_center";

  // k_education_degree
  public static final String gu_degree = "gu_degree";
  public static final String nm_degree = "nm_degree";
  public static final String tp_degree = "tp_degree";
  public static final String id_degree = "id_degree";
  public static final String ix_degree = "ix_degree";

  // k_contact_education
  public static final String bo_completed = "bo_completed";
  public static final String lv_language_spoken = "lv_language_spoken";
  public static final String lv_language_written = "lv_language_written";
  
  /**i2e 15-12-2009**/
  //k_contact_short_courses
  public static final String gu_scourse = "gu_scourse";
  public static final String ix_scourse = "ix_scourse";
  
  //k_contact_computer_science
  public static final String gu_ccsskill = "gu_ccsskill";
  public static final String nm_skill = "nm_skill";
  public static final String lv_skill = "lv_skill";
  
  //k_contact_languages
  public static final String lv_language_degree = "lv_language_degree";

  //k_contact_experience
  public static final String gu_experience = "gu_experience";
  public static final String bo_current_job = "bo_current_job";
  
  /**fin i2e**/

  // k_sms_audit
  public static final String id_sms = "id_sms";
  public static final String nu_msisdn = "nu_msisdn";
  public static final String pg_part = "pg_part";
  public static final String bo_validated = "bo_validated";
  
  /**i2e 20-01-2010**/
  //k_admission
  public static final String gu_admission = "gu_admission";
  public static final String id_objetive_1 = "id_objetive_1";
  public static final String id_objetive_2 = "id_objetive_2";
  public static final String id_objetive_3 = "id_objetive_3";
  public static final String dt_target = "dt_target";
  public static final String is_call = "is_call";
  public static final String id_place = "id_place";
  public static final String id_interviewer = "id_interviewer";
  public static final String dt_interview = "dt_interview";
  public static final String dt_admision_test = "dt_admision_test";
  public static final String is_grant = "is_grant";
  public static final String nu_grant = "nu_grant";
  public static final String nu_interview = "nu_interview";
  public static final String nu_vips = "nu_vips";
  public static final String nu_nips = "nu_nips";
  public static final String nu_elp = "nu_elp";
  public static final String nu_total = "nu_total";
  public static final String id_test_result = "id_test_result";
  /**fin i2e**/

  /**i2e 01-02-2010**/
  //k_registrations
  public static final String id_institution = "id_institution";
  public static final String dt_reserve = "dt_reserve";
  public static final String dt_registration = "dt_registration";
  public static final String dt_drop = "dt_drop";
  public static final String id_drop_cause = "id_drop_cause";
  /**fin i2e**/

  // k_syndsearches
  public static final String tx_sought = "tx_sought";
  public static final String dt_run = "dt_run";
  public static final String dt_last_run = "dt_last_run";
  public static final String nu_runs = "nu_runs";
  public static final String nu_requests = "nu_requests";
  public static final String nu_results = "nu_results";

  // k_syndentries
  public static final String nu_influence = "nu_influence";
  public static final String gu_feed = "gu_feed";
  public static final String tx_query = "tx_query";
  public static final String uri_entry = "uri_entry";
  public static final String tl_entry = "tl_entry";
  public static final String de_entry = "de_entry";
  public static final String bin_entry = "bin_entry";
  public static final String url_domain = "url_domain";
  public static final String url_author = "url_author";
  public static final String nu_entries = "nu_entries";
  public static final String id_syndref = "id_syndref";
  public static final String id_acalias = "id_acalias";
  public static final String nm_service = "nm_service";
  public static final String nm_alias = "nm_alias";
  
}
