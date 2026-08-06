SET session_replication_role = replica;

--
-- PostgreSQL database dump
--

-- \restrict 9EVMenw2vYWox8SOGU1PcrbDctAeDFU76lG1OOMBrvs7WXefHC6qqbObsg1QFrg

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."audit_log_entries" ("instance_id", "id", "payload", "created_at", "ip_address") VALUES
	('00000000-0000-0000-0000-000000000000', '73e0ce42-568f-4f44-8d12-0a8f6b60c113', '{"action":"user_signedup","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"team","traits":{"provider":"email"}}', '2026-05-14 13:27:45.628084+00', ''),
	('00000000-0000-0000-0000-000000000000', 'e0f2147b-ba0d-402c-b41b-a619f16590db', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-05-14 13:27:45.657242+00', ''),
	('00000000-0000-0000-0000-000000000000', '2680741c-0c9f-4b4f-be15-34cc1933a907', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-05-14 14:07:55.284864+00', ''),
	('00000000-0000-0000-0000-000000000000', 'f604b5bb-4159-495f-a6f6-faf716a66115', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-05-14 15:06:55.823749+00', ''),
	('00000000-0000-0000-0000-000000000000', 'e8b51265-6ea0-4a9f-980d-c1844266c035', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-05-14 15:06:55.827864+00', ''),
	('00000000-0000-0000-0000-000000000000', '4da74c57-786d-429b-9e8c-b0801f156ce7', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-05-14 15:36:49.138792+00', ''),
	('00000000-0000-0000-0000-000000000000', '84340f66-a15c-4e20-b7eb-8d1257b79e6a', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-05-14 18:11:10.585254+00', '');


--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."users" ("instance_id", "id", "aud", "role", "email", "encrypted_password", "email_confirmed_at", "invited_at", "confirmation_token", "confirmation_sent_at", "recovery_token", "recovery_sent_at", "email_change_token_new", "email_change", "email_change_sent_at", "last_sign_in_at", "raw_app_meta_data", "raw_user_meta_data", "is_super_admin", "created_at", "updated_at", "phone", "phone_confirmed_at", "phone_change", "phone_change_token", "phone_change_sent_at", "email_change_token_current", "email_change_confirm_status", "banned_until", "reauthentication_token", "reauthentication_sent_at", "is_sso_user", "deleted_at", "is_anonymous") VALUES
	('00000000-0000-0000-0000-000000000000', '3b3df1db-8109-4414-b451-6b9e22435254', 'authenticated', 'authenticated', 'samuel@mey.com', '$2a$10$Ce1e3SmBUW6/GGfsMqQQVOnokaOlAr65t3bf.XJIzhi4e7A5jTVJm', '2026-05-14 13:27:45.632871+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-05-14 18:11:10.667293+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "3b3df1db-8109-4414-b451-6b9e22435254", "name": "Samuel Parra", "email": "samuel@mey.com", "email_verified": true, "phone_verified": false}', NULL, '2026-05-14 13:27:45.596125+00', '2026-05-14 18:11:11.16974+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."identities" ("provider_id", "user_id", "identity_data", "provider", "last_sign_in_at", "created_at", "updated_at", "id") VALUES
	('3b3df1db-8109-4414-b451-6b9e22435254', '3b3df1db-8109-4414-b451-6b9e22435254', '{"sub": "3b3df1db-8109-4414-b451-6b9e22435254", "name": "Samuel Parra", "email": "samuel@mey.com", "email_verified": false, "phone_verified": false}', 'email', '2026-05-14 13:27:45.612431+00', '2026-05-14 13:27:45.613398+00', '2026-05-14 13:27:45.613398+00', '48b77e38-0452-4e1a-b3dc-6373632add56');


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."sessions" ("id", "user_id", "created_at", "updated_at", "factor_id", "aal", "not_after", "refreshed_at", "user_agent", "ip", "tag", "oauth_client_id", "refresh_token_hmac_key", "refresh_token_counter", "scopes") VALUES
	('9f3694bc-c35a-492d-a948-dd7e06b6ce3a', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 13:27:45.659582+00', '2026-05-14 13:27:45.659582+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36', '172.19.0.1', NULL, NULL, NULL, NULL, NULL),
	('abdd39c6-45fc-42f5-b916-6e4f68126b09', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:07:55.297911+00', '2026-05-14 15:06:55.849713+00', NULL, 'aal1', NULL, '2026-05-14 15:06:55.849554', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36', '172.19.0.1', NULL, NULL, NULL, NULL, NULL),
	('af5c23e4-11e8-480d-ac5e-b295b2e1596e', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:36:49.153007+00', '2026-05-14 15:36:49.153007+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36', '172.19.0.1', NULL, NULL, NULL, NULL, NULL),
	('f8b5f836-fc33-4e32-b2c7-bc649acdd0d3', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:11:10.667663+00', '2026-05-14 18:11:10.667663+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36', '172.19.0.1', NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."mfa_amr_claims" ("session_id", "created_at", "updated_at", "authentication_method", "id") VALUES
	('9f3694bc-c35a-492d-a948-dd7e06b6ce3a', '2026-05-14 13:27:45.673434+00', '2026-05-14 13:27:45.673434+00', 'password', '6d33adb0-7a22-45b3-a248-3108e01d265d'),
	('abdd39c6-45fc-42f5-b916-6e4f68126b09', '2026-05-14 14:07:55.349444+00', '2026-05-14 14:07:55.349444+00', 'password', '2b46af83-b2aa-426f-8d0c-5b7d8e10e073'),
	('af5c23e4-11e8-480d-ac5e-b295b2e1596e', '2026-05-14 15:36:49.211066+00', '2026-05-14 15:36:49.211066+00', 'password', '95ff1457-8139-402e-a481-c03d0301e2bc'),
	('f8b5f836-fc33-4e32-b2c7-bc649acdd0d3', '2026-05-14 18:11:11.240626+00', '2026-05-14 18:11:11.240626+00', 'password', '1f81052f-9b1b-4c84-9e6c-6f26e6398036');


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."refresh_tokens" ("instance_id", "id", "token", "user_id", "revoked", "created_at", "updated_at", "parent", "session_id") VALUES
	('00000000-0000-0000-0000-000000000000', 1, 'wzdvzt2all7b', '3b3df1db-8109-4414-b451-6b9e22435254', false, '2026-05-14 13:27:45.669002+00', '2026-05-14 13:27:45.669002+00', NULL, '9f3694bc-c35a-492d-a948-dd7e06b6ce3a'),
	('00000000-0000-0000-0000-000000000000', 2, '34obnjrzv4i6', '3b3df1db-8109-4414-b451-6b9e22435254', true, '2026-05-14 14:07:55.316671+00', '2026-05-14 15:06:55.829274+00', NULL, 'abdd39c6-45fc-42f5-b916-6e4f68126b09'),
	('00000000-0000-0000-0000-000000000000', 3, 'e5ilufvyburr', '3b3df1db-8109-4414-b451-6b9e22435254', false, '2026-05-14 15:06:55.835384+00', '2026-05-14 15:06:55.835384+00', '34obnjrzv4i6', 'abdd39c6-45fc-42f5-b916-6e4f68126b09'),
	('00000000-0000-0000-0000-000000000000', 4, 'eo6uqilce4rm', '3b3df1db-8109-4414-b451-6b9e22435254', false, '2026-05-14 15:36:49.179824+00', '2026-05-14 15:36:49.179824+00', NULL, 'af5c23e4-11e8-480d-ac5e-b295b2e1596e'),
	('00000000-0000-0000-0000-000000000000', 5, 'crvcjdiirzfc', '3b3df1db-8109-4414-b451-6b9e22435254', false, '2026-05-14 18:11:11.049736+00', '2026-05-14 18:11:11.049736+00', NULL, 'f8b5f836-fc33-4e32-b2c7-bc649acdd0d3');


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: webauthn_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."customers" ("id", "name", "ein", "address", "phone", "email", "created_at", "updated_at") VALUES
	('60b276ab-ff50-4432-b7e0-03c5a02452a6', 'Fred Parra', '11-22344', 'Barrancas', '(434) 321-1111', 'fred@parra.ve', '2026-05-11 13:02:26.32688+00', '2026-05-11 13:02:26.32688+00');


--
-- Data for Name: labor_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."labor_roles" ("id", "description", "hourly_rate", "created_at", "updated_at") VALUES
	('4f2b630b-8cc4-49be-ac5e-77be4b103d3a', 'SUPERVISOR', 45.00, '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00'),
	('c1aa1bb2-a2ab-40b8-9219-d2898153758e', 'Excavator Operator', 35.00, '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00'),
	('fe520365-87c8-4a42-ae6a-9c2e989f1ef0', 'Shaper Class B', 32.00, '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00'),
	('e5092833-858d-4912-9815-89ada6e99a22', 'Laborer', 20.00, '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00'),
	('15584be2-4d8f-4748-96ba-5684a56a7d74', 'TRUCK OPERATOR', 39, '2026-03-09 18:00:46.516704+00', '2026-05-05 02:35:18.727393+00'),
	('626d5dab-2200-4680-961f-f71069db1b94', 'CONSTRUCTION SUPERINTENDENT', 65, '2026-03-09 17:59:37.6127+00', '2026-05-05 02:36:10.381341+00'),
	('e5046e4c-eb0c-45cb-8efd-6377a8d24ea1', 'SKILL LABOR', 35, '2026-04-24 17:44:09.129335+00', '2026-05-05 02:36:34.928976+00'),
	('da849f21-3558-472d-b242-01cb999dd1d5', 'SHAPER CLASS B', 55, '2026-03-09 17:59:54.115408+00', '2026-05-05 02:36:58.657214+00'),
	('5b896dcb-f674-4e43-81b3-d66c23a928c1', 'SCRAPER OPERATOR', 39, '2026-03-09 18:00:06.688295+00', '2026-05-05 02:37:29.559587+00'),
	('91da0a23-74b8-4c6d-a546-363c123a18e0', 'LABOR', 30, '2026-04-14 19:02:27.165683+00', '2026-05-05 02:38:34.73764+00'),
	('453c550e-47f4-4f27-ad81-f9f5b71bc3ba', 'BUNKER SHAPER', 42, '2026-03-09 18:00:28.655183+00', '2026-05-05 02:39:33.577967+00'),
	('a6c2c442-0aab-47d1-8dd6-fbd27d96c73a', 'GREEN SHAPER', 42, '2026-04-24 17:44:59.4694+00', '2026-05-05 02:40:19.95771+00'),
	('36694df2-8660-4b05-914f-1aaab0928209', 'TEE SHAPER', 42, '2026-05-05 02:40:50.390438+00', '2026-05-05 02:40:50.390438+00'),
	('832d504d-40a5-447e-8efc-5ba3f9f51456', 'FAIRWAY FINISHER', 42, '2026-05-05 02:41:19.018029+00', '2026-05-05 02:41:19.018029+00'),
	('933d77e9-f844-4716-a48e-ff1e01c043ab', 'SHAPER CLASS A', 65, '2026-05-05 02:41:52.707573+00', '2026-05-05 02:41:52.707573+00'),
	('c0c2df7e-0a1c-4fe1-9f5d-fe2ab5f9042c', 'SHAPER CLASS C', 45, '2026-05-05 02:42:19.467635+00', '2026-05-05 02:42:19.467635+00'),
	('5719ff0e-f9a6-417f-bf23-46c82a5b09d6', 'CONSTRUCTION FORMAN', 55, '2026-05-05 02:43:30.401888+00', '2026-05-05 02:43:30.401888+00'),
	('d26ac548-d73a-45a9-9f70-6ba979729ed6', 'IRRIGATION FORMAN', 55, '2026-05-05 02:43:52.371018+00', '2026-05-05 02:43:52.371018+00'),
	('118fae00-7497-491c-a8fe-cb7ca7468535', 'IRRIGATION SUPERINTENDENT', 65, '2026-05-05 02:44:22.568849+00', '2026-05-05 02:44:22.568849+00');


--
-- Data for Name: quotes; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."quotes" ("id", "company_id", "title", "status", "created_at", "updated_at", "client_name", "total_amount", "quote_date", "project_name", "quote_type") VALUES
	('41d5ac82-e7bd-4f91-bdb3-a00027296792', NULL, 'Project Golf 2 - Baseline Test', 'Accepted', '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00', NULL, 0, '2026-05-14', NULL, 'standard'),
	('969bc610-e72e-493d-8cdf-516d355a1650', NULL, 'Ejemplo Cotizacion', 'draft', '2026-03-06 03:22:45.641975+00', '2026-03-05 23:17:38.731+00', NULL, 0, '2026-03-09', NULL, 'standard'),
	('ea9d39e0-5191-4288-b9a3-1696d87812dd', NULL, 'Prueba 2', 'draft', '2026-03-09 18:35:43.987783+00', '2026-03-09 17:05:44.696+00', 'Mey', 341488.74375, '2026-03-09', NULL, 'standard'),
	('c9ec01d4-77f5-49f0-b608-2653c420bbe0', NULL, 'Golfe Proyects', 'draft', '2026-03-09 14:50:58.243276+00', '2026-03-09 18:56:57.337+00', '', 2621509.55, '2026-03-09', NULL, 'standard'),
	('c8120856-74fa-403f-8d1a-04c8c7fb8000', NULL, 'Prueba 3', 'draft', '2026-03-12 14:36:45.495131+00', '2026-03-12 16:29:38.196+00', 'Golf Team', 1645974.875, '2026-03-12', NULL, 'standard'),
	('9aa91162-6d4a-4136-9d01-c0ea31cdeed0', NULL, '3 Bridges', 'draft', '2026-03-30 17:56:37.562061+00', '2026-03-30 14:06:57.967+00', 'Landscapes UnlimetedLLC', 104500, '2026-03-30', NULL, 'standard'),
	('237b459b-f70e-4bc1-9472-ab2a32392180', NULL, 'Prueba estimacion 1', 'draft', '2026-04-07 18:09:56.534442+00', '2026-04-07 18:09:56.534442+00', 'Fred', 582326.976, '2026-04-07', NULL, 'standard'),
	('2a80a936-90fb-42ed-b750-abd59078d297', NULL, 'Prueba Estimacion con materiales', 'draft', '2026-04-14 18:24:32.921115+00', '2026-04-14 18:24:32.921115+00', 'Claudio Ortiz', 263708.63306666666, '2026-04-14', NULL, 'standard'),
	('0b200319-ae70-4d5b-a385-2c8e271e2622', NULL, 'kettle forge', 'draft', '2026-04-14 19:37:49.606769+00', '2026-04-14 19:37:49.606769+00', 'harritage', 32291153.37861111, '2026-04-14', NULL, 'standard'),
	('aa5e6f53-a783-4946-954e-4876f31ebc5e', NULL, 'Prueba de Servicios', 'draft', '2026-04-17 22:39:37.3095+00', '2026-04-17 22:39:37.3095+00', 'Noel', 173086.40616296296, '2026-04-17', NULL, 'standard'),
	('db229097-0c24-4e7e-82cd-b7d97295f448', NULL, 'TPC Deer Run', 'draft', '2026-04-24 17:46:49.588831+00', '2026-04-24 17:46:49.588831+00', 'Landscapes Unlimited LLC', 56925, '2026-04-24', NULL, 'standard'),
	('56e06c10-d0c0-46a5-a7ff-84422bd62187', NULL, '3 Bridges', 'draft', '2026-04-27 18:39:35.529878+00', '2026-04-27 14:06:27.851+00', 'Haritage', 22421450.52125, '2026-04-27', NULL, 'standard'),
	('e80c65fe-942e-414d-9bd8-167288e80b5e', NULL, 'Prueba de creación de proyecto', 'accepted', '2026-05-11 13:05:50.994026+00', '2026-05-11 13:05:50.994026+00', 'Fred Parra', 629342.4072, '2026-05-11', NULL, 'standard');


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."projects" ("id", "quote_id", "title", "client_name", "status", "start_date", "end_date", "created_at", "updated_at", "project_type") VALUES
	('cdf91e17-ce7a-47bd-bb79-4f49cee6bd67', '41d5ac82-e7bd-4f91-bdb3-a00027296792', 'Execution Golf 2 - Phase 1', NULL, 'active', NULL, NULL, '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00', 'standard'),
	('37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '56e06c10-d0c0-46a5-a7ff-84422bd62187', '3 Bridges', 'Haritage', 'active', '2026-05-08 19:15:18.094+00', NULL, '2026-05-08 23:15:18.974226+00', '2026-05-08 23:15:18.974226+00', 'standard'),
	('24d128a9-5591-4cd2-b218-2fdfc93bb18f', 'e80c65fe-942e-414d-9bd8-167288e80b5e', 'Prueba de creación de proyecto', 'Fred Parra', 'active', '2026-05-11 09:07:06.39+00', NULL, '2026-05-11 13:07:06.713533+00', '2026-05-11 13:07:06.713533+00', 'standard');


--
-- Data for Name: quote_services; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."quote_services" ("id", "quote_id", "service_number", "name", "unit_of_measure", "quantity", "overhead_percentage", "profit_percentage", "created_at", "fuel_price", "per_diem_cost", "labor_hours_per_month", "direct_cost") VALUES
	('2f92671f-af81-4417-97a4-cd7b26adc409', '41d5ac82-e7bd-4f91-bdb3-a00027296792', NULL, 'BULK EXCAVATION', 'CY', 5000, 0, 0, '2026-05-14 13:17:03.392091+00', 0, 0, 0, 0),
	('6e17c7fb-31b7-48b2-ad78-76efc53ab08c', '41d5ac82-e7bd-4f91-bdb3-a00027296792', NULL, 'FINISH GRADING', 'SQFT', 45000, 0, 0, '2026-05-14 13:17:03.392091+00', 0, 0, 0, 0),
	('e512195f-c8cd-4bd1-848d-90c30c46f5ad', '969bc610-e72e-493d-8cdf-516d355a1650', NULL, 'CUT-FILL TOP LOADING', 'CYS', 674000, 0, 14, '2026-03-06 03:23:19.217178+00', 0, 0, 0, 0),
	('d02c020a-a0de-48e9-8682-fafe05f47509', 'ea9d39e0-5191-4288-b9a3-1696d87812dd', NULL, 'CUT-FILL TOP LOADING', 'Qty', 674000, 10, 35, '2026-03-09 23:05:46.924385+00', 0, 0, 0, 0),
	('552cbb0a-55d8-4307-a807-82b9548c50e7', 'ea9d39e0-5191-4288-b9a3-1696d87812dd', NULL, 'CLEARING', 'AC', 45, 10, 35, '2026-03-09 23:05:48.395862+00', 0, 0, 0, 0),
	('5380d563-d6ac-4231-976c-1579d74b4b52', 'c9ec01d4-77f5-49f0-b608-2653c420bbe0', NULL, 'CUT-FILL TOP LOADING', 'CYS', 674000, 10, 25, '2026-03-10 00:56:58.586984+00', 0, 0, 0, 0),
	('e5fbd5bb-1139-4335-8f23-b3a12d105520', 'c9ec01d4-77f5-49f0-b608-2653c420bbe0', NULL, 'CLEARING', 'AC', 5000, 10, 35, '2026-03-10 00:57:00.469011+00', 0, 0, 0, 0),
	('81513bd9-fae6-4e55-97c8-152f788409e5', 'c9ec01d4-77f5-49f0-b608-2653c420bbe0', NULL, 'Rough Shaping', 'EA', 20, 10, 35, '2026-03-10 00:57:00.821677+00', 0, 0, 0, 0),
	('ee7f93a9-96c4-4335-a021-eb5372fa064a', 'c8120856-74fa-403f-8d1a-04c8c7fb8000', NULL, 'CUT-FILL TOP LOADING', 'Qty', 700000, 0, 15, '2026-03-12 20:29:39.79247+00', 0, 0, 0, 0),
	('f513c717-b218-4e7b-b6c1-f8d00660e746', '9aa91162-6d4a-4136-9d01-c0ea31cdeed0', NULL, 'CUT-FILL TOP LOADING', 'CY', 125000, 0, 0, '2026-03-30 19:06:58.62335+00', 0, 0, 0, 0),
	('fad4ea94-045a-454a-8789-b5709e388ac1', '237b459b-f70e-4bc1-9472-ab2a32392180', NULL, 'GREEN CONSTRUCTION', 'SF', 800000, 2, 12, '2026-04-07 18:09:56.697186+00', 0, 0, 0, 0),
	('ac7593d3-c6f5-47ef-bb8b-730c75c421e5', '2a80a936-90fb-42ed-b750-abd59078d297', NULL, 'GREEN CONSTRUCTION', 'SF', 16000, 2, 12, '2026-04-14 18:24:33.252958+00', 0, 0, 0, 0),
	('de2a4696-52de-4318-bbfb-002fe45e0ae0', '0b200319-ae70-4d5b-a385-2c8e271e2622', NULL, 'GREEN CONSTRUCTION', 'SF', 201560, 10, 30, '2026-04-14 19:37:49.858333+00', 0, 0, 0, 0),
	('ef62baf8-66a5-4d4b-8d2f-60ed6aad0e77', '0b200319-ae70-4d5b-a385-2c8e271e2622', NULL, 'BUNKER CONSTRUCTION', 'sf', 180000, 10, 30, '2026-04-14 19:37:52.250472+00', 0, 0, 0, 0),
	('22055dba-b9af-426f-89de-bedd62f536b1', '0b200319-ae70-4d5b-a385-2c8e271e2622', NULL, 'Tee Costruction', 'sf', 120000, 10, 30, '2026-04-14 19:37:52.461744+00', 0, 0, 0, 0),
	('6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', '0b200319-ae70-4d5b-a385-2c8e271e2622', NULL, 'CLEARING', 'AC', 45, 10, 30, '2026-04-14 19:37:53.329261+00', 0, 0, 0, 0),
	('61de1e83-a430-4de6-8ef6-5b851d489e1d', '0b200319-ae70-4d5b-a385-2c8e271e2622', NULL, 'drainage', 'lf', 15000, 10, 30, '2026-04-14 19:37:55.450837+00', 0, 0, 0, 0),
	('96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', 'aa5e6f53-a783-4946-954e-4876f31ebc5e', NULL, 'GREEN CONSTRUCTION', 'SF', 20000, 2, 12, '2026-04-17 22:39:38.011369+00', 0, 0, 0, 0),
	('0f1ecc41-859d-4927-933a-2367702cd35d', 'db229097-0c24-4e7e-82cd-b7d97295f448', NULL, 'Mobilization', 'EA', 1, 0, 0, '2026-04-24 17:46:53.164858+00', 0, 0, 0, 0),
	('5cffaaa8-5e06-4a4f-86f0-daee894497b4', 'db229097-0c24-4e7e-82cd-b7d97295f448', NULL, 'Shaper B+', 'EA', 1, 0, 0, '2026-04-24 17:46:54.840906+00', 0, 0, 0, 0),
	('6e3b35aa-aa09-498b-9357-f9c44c1512e9', 'db229097-0c24-4e7e-82cd-b7d97295f448', NULL, 'Multi Equipment Operator', 'EA', 3, 0, 0, '2026-04-24 17:46:59.537317+00', 0, 0, 0, 0),
	('b6335445-15c1-4d64-8f71-a88855e2f5b2', 'db229097-0c24-4e7e-82cd-b7d97295f448', NULL, 'Skill Labor', 'EA', 1, 0, 0, '2026-04-24 17:47:02.774726+00', 0, 0, 0, 0),
	('fe54b6a4-4dd7-447b-8f5b-b3a4eef18d45', '56e06c10-d0c0-46a5-a7ff-84422bd62187', NULL, '4" solid pipe', 'LF', 20000, 10, 35, '2026-04-27 19:06:28.540857+00', 0, 0, 0, 0),
	('c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', '56e06c10-d0c0-46a5-a7ff-84422bd62187', NULL, 'CUT-FILL TOP LOADING', 'CY', 500000, 10, 35, '2026-04-27 19:06:29.718178+00', 0, 0, 0, 0),
	('d6ff2701-828c-4cb6-b693-05268ade668c', '56e06c10-d0c0-46a5-a7ff-84422bd62187', NULL, 'GREEN CONSTRUCTION', 'SF', 201000, 10, 35, '2026-04-27 19:06:31.025913+00', 0, 0, 0, 0),
	('584281a5-4f51-4722-9f88-95d94842b380', '56e06c10-d0c0-46a5-a7ff-84422bd62187', NULL, 'CLEARING', 'AC', 55, 10, 35, '2026-04-27 19:06:32.396651+00', 0, 0, 0, 0),
	('3d08f851-b15e-46a6-bf68-ac823bce1f45', 'e80c65fe-942e-414d-9bd8-167288e80b5e', NULL, 'TOPSOIL MANAGEMENT', 'CY', 500000, 2, 4, '2026-05-11 13:05:51.277616+00', 0, 0, 0, 0);


--
-- Data for Name: quote_service_machineries; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."quote_service_machineries" ("id", "quote_service_id", "machine_name", "months_to_use", "monthly_rent_cost", "quantity", "gallons_per_hour", "gallon_cost", "created_at", "delivery_cost", "parent_machinery_id", "is_primary", "is_primary_mover", "parent_machine_name") VALUES
	('caff098a-ef44-4ac4-8e85-dd7fae5cca82', 'ee7f93a9-96c4-4335-a021-eb5372fa064a', 'JD 460P', 3.6, 20000, 4, 7, 5.25, '2026-03-12 20:29:39.929387+00', 300, NULL, true, true, NULL),
	('b6b15047-ac49-4acd-986b-26ea9aebd088', 'ee7f93a9-96c4-4335-a021-eb5372fa064a', 'Cat K-teck 1236 scraper', 3.9, 15500, 2, 7, 5.25, '2026-03-12 20:29:40.063514+00', 300, NULL, true, true, NULL),
	('2bb4f120-04dd-4af2-8609-d0ddc4663224', 'e512195f-c8cd-4bd1-848d-90c30c46f5ad', 'JD 950 S/U BLADE  4WAY', 1, 15000, 1, 7, 5.25, '2026-03-06 03:23:19.31711+00', 0, NULL, true, true, NULL),
	('1ac07bce-8c40-4615-af8c-e99b620a4ac1', 'e512195f-c8cd-4bd1-848d-90c30c46f5ad', 'JD 850 L/P LPG W/GPS NO RIPPER', 3, 12450, 2, 7, 5.25, '2026-03-06 03:23:19.415659+00', 0, NULL, true, true, NULL),
	('5b4ad0c4-ffac-41a0-83f5-773aedc7090c', 'ee7f93a9-96c4-4335-a021-eb5372fa064a', 'JD 510P - W/GPS.', 3.9, 14000, 4, 7, 5.25, '2026-03-12 20:29:40.194122+00', 600, NULL, true, true, NULL),
	('5b5eb10f-0fba-4bd7-9624-cc5db9758ad3', 'ee7f93a9-96c4-4335-a021-eb5372fa064a', 'JD 410P', 3.6, 15000, 2, 7, 5.25, '2026-03-12 20:29:40.339471+00', 700, NULL, true, true, NULL),
	('6cbf01c0-a510-4405-a71b-75ff7e480165', 'd02c020a-a0de-48e9-8682-fafe05f47509', 'JD 950 S/U BLADE  4WAY', 1, 10000, 1, 7, 5.25, '2026-03-09 23:05:47.344826+00', 600, NULL, true, true, NULL),
	('e77ae83b-efe6-4562-8405-b617532de806', 'd02c020a-a0de-48e9-8682-fafe05f47509', 'JD 750L - LPG W/GPS', 1, 12450, 1, 7, 3.25, '2026-03-09 23:05:47.574723+00', 600, NULL, true, true, NULL),
	('200e4bb4-b074-4b3e-8e17-7ecf2cad4e8d', 'f513c717-b218-4e7b-b6c1-f8d00660e746', 'JD 850 L/P LPG W/GPS NO RIPPER', 0.4, 0, 1, 7, 5.25, '2026-03-30 19:06:58.756709+00', 0, NULL, true, true, NULL),
	('506170b3-a2bc-4d1f-88ec-3c47daebc357', 'f513c717-b218-4e7b-b6c1-f8d00660e746', 'JD 510P - W/GPS.', 0.4, 0, 1, 7, 5.25, '2026-03-30 19:06:58.834679+00', 0, NULL, true, true, NULL),
	('3773e8fd-bb6d-4ee0-bd82-edbc2f4315b8', 'f513c717-b218-4e7b-b6c1-f8d00660e746', 'JD 460P', 0.4, 0, 4, 7, 5.25, '2026-03-30 19:06:58.891759+00', 0, NULL, true, true, NULL),
	('221d35ed-9c1f-45ec-9995-599f6df1680e', 'f513c717-b218-4e7b-b6c1-f8d00660e746', 'Cat K-teck 1236 scraper', 0.4, 0, 4, 7, 5.25, '2026-03-30 19:06:58.975063+00', 0, NULL, true, true, NULL),
	('2369572c-2ea3-48d5-9692-90d411847c04', 'fad4ea94-045a-454a-8789-b5709e388ac1', 'JD 460P', 3.8, 0, 4, 7, 5.25, '2026-04-07 18:09:56.831198+00', 0, NULL, true, true, NULL),
	('773e990e-2eb7-4148-bb68-2c2e57f38ae0', 'fad4ea94-045a-454a-8789-b5709e388ac1', 'TOYOTA TUNDRA PLATEUM', 3.8, 0, 1, 2, 5.25, '2026-04-07 18:09:56.961562+00', 0, NULL, true, false, 'JD 460P'),
	('57e4fc09-162d-4359-942a-fbd77c49e230', 'fad4ea94-045a-454a-8789-b5709e388ac1', 'POLARIS RANGER 1000', 3.8, 0, 1, 2, 5.25, '2026-04-07 18:09:57.083209+00', 0, NULL, true, false, 'JD 460P'),
	('91c4cc17-2b19-461b-bb8c-73044e2c5010', 'fad4ea94-045a-454a-8789-b5709e388ac1', 'Cat K-teck 1236 scraper', 3.8, 0, 2, 7, 5.25, '2026-04-07 18:09:57.204073+00', 0, NULL, true, true, NULL),
	('10585f4a-b4a5-4d34-9b41-d46f0f0b74d9', 'fad4ea94-045a-454a-8789-b5709e388ac1', 'JD 950 S/U BLADE  4WAY', 3.8, 0, 1, 7, 5.25, '2026-04-07 18:09:57.327779+00', 0, NULL, true, false, 'Cat K-teck 1236 scraper'),
	('f4c5f799-3373-41b5-8395-8b932d965060', 'fad4ea94-045a-454a-8789-b5709e388ac1', 'JD 510P - W/GPS.', 3.8, 0, 1, 7, 5.25, '2026-04-07 18:09:57.458667+00', 0, NULL, true, false, 'Cat K-teck 1236 scraper'),
	('d4acd861-f12a-443b-8917-9838f3299c6a', '5380d563-d6ac-4231-976c-1579d74b4b52', 'JD 850 L/P LPG W/GPS NO RIPPER', 3, 10000, 2, 7, 5.25, '2026-03-10 00:56:58.735611+00', 1000, NULL, true, true, NULL),
	('919dcbff-cb61-4ca8-9871-dbdd4dcfdb84', '5380d563-d6ac-4231-976c-1579d74b4b52', 'JD 950 S/U BLADE  4WAY', 3, 15000, 1, 7, 5.25, '2026-03-10 00:56:58.884265+00', 1500, NULL, true, true, NULL),
	('3e0f7deb-bf7e-4a4d-b802-edd99bfc4ec8', '5380d563-d6ac-4231-976c-1579d74b4b52', 'JD 750L - LPG W/GPS', 3, 7500, 1, 4, 5.25, '2026-03-10 00:56:59.101765+00', 600, NULL, true, true, NULL),
	('40da23f1-f81a-4f20-b3dd-6da6b20103a4', '5380d563-d6ac-4231-976c-1579d74b4b52', 'JD 410P', 3, 12000, 4, 7, 5.25, '2026-03-10 00:56:59.30082+00', 4000, NULL, true, true, NULL),
	('39d83480-09e6-4926-aa65-2a82a7130ba7', '5380d563-d6ac-4231-976c-1579d74b4b52', 'JD 510P - W/GPS.', 3, 17000, 1, 7, 5.25, '2026-03-10 00:56:59.427843+00', 2000, NULL, true, true, NULL),
	('2ea218fb-79c5-42ba-892f-639e4e7b2a9d', '5380d563-d6ac-4231-976c-1579d74b4b52', 'Cat K-teck 1236 scraper', 3, 45000, 2, 20, 5.25, '2026-03-10 00:56:59.565166+00', 6000, NULL, true, true, NULL),
	('ea2faf07-969b-48d6-9500-1a29beb1e204', '81513bd9-fae6-4e55-97c8-152f788409e5', 'JD 850 L/P LPG W/GPS NO RIPPER', 3, 10000, 2, 7, 5.25, '2026-03-10 00:57:00.957078+00', 800, NULL, true, true, NULL),
	('d1aceddf-dec4-4688-bc2d-63c009dc302d', '81513bd9-fae6-4e55-97c8-152f788409e5', 'JD 750L - LPG W/GPS', 3, 7500, 1, 4, 5.25, '2026-03-10 00:57:01.326938+00', 300, NULL, true, true, NULL),
	('b670a32b-376e-4872-8d9b-c22201d63651', 'ac7593d3-c6f5-47ef-bb8b-730c75c421e5', 'JD 350P W/THUMB', 2.7, 15000, 1, 7, 5.25, '2026-04-14 18:24:33.470149+00', 700, NULL, true, true, NULL),
	('a399d89a-6c37-49cd-9768-dbbe9c022a06', 'ac7593d3-c6f5-47ef-bb8b-730c75c421e5', 'TOYOTA TUNDRA PLATEUM', 2.7, 5000, 1, 2, 5.25, '2026-04-14 18:24:33.601681+00', 100, NULL, true, false, 'JD 350P W/THUMB'),
	('849878df-e703-41ca-824a-76ea2c3007ed', 'ac7593d3-c6f5-47ef-bb8b-730c75c421e5', 'POLARIS RANGER 1000', 2.7, 2000, 1, 2, 5.25, '2026-04-14 18:24:33.722926+00', 80, NULL, true, false, 'JD 350P W/THUMB'),
	('de8cfd92-70a3-4986-9fad-8a070f109735', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', 'JD 350P W/THUMB', 14.1, 4500, 1, 7, 5.25, '2026-04-14 19:37:50.031725+00', 350, NULL, true, true, NULL),
	('4335df78-e06a-4ce1-8a62-e4fc546f1fea', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', 'POLARIS RANGER 1000', 14.1, 1300, 1, 2, 5.25, '2026-04-14 19:37:50.185973+00', 250, NULL, true, false, 'JD 350P W/THUMB'),
	('70e1114e-78a1-42be-898a-2f133e4ebb2d', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', 'JD 750L - LPG W/GPS', 14.1, 6500, 1, 0, 5.25, '2026-04-14 19:37:50.31655+00', 450, NULL, true, false, 'JD 350P W/THUMB'),
	('30d79a68-1641-475a-9829-3554bf4c3de4', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', '5-6 Yd Dump Truck', 14.1, 5500, 4, 4, 5.25, '2026-04-14 19:37:50.44887+00', 3500, NULL, true, false, 'JD 350P W/THUMB'),
	('1415ebb6-7096-485e-987e-4ec3d517dbe3', '22055dba-b9af-426f-89de-bedd62f536b1', '5-6 Yd Dump Truck', 119.9, 0, 4, 4, 5.25, '2026-04-14 19:37:52.575305+00', 0, NULL, true, true, NULL),
	('65c485c4-0d92-43eb-86bf-2b2d74eebece', '22055dba-b9af-426f-89de-bedd62f536b1', 'JD 750L - LPG W/GPS', 119.9, 0, 1, 0, 5.25, '2026-04-14 19:37:52.682382+00', 0, NULL, true, false, '5-6 Yd Dump Truck'),
	('800070b9-4596-4149-b5d8-db43b679e534', '6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', 'JD 850 L/P LPG W/GPS NO RIPPER', 0, 0, 1, 7, 5.25, '2026-04-14 19:37:53.481061+00', 0, NULL, true, true, NULL),
	('be724d10-7633-4f39-8510-83ad8f57ca2b', '6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', 'JD 410P', 0, 0, 2, 7, 5.25, '2026-04-14 19:37:53.674392+00', 0, NULL, true, true, NULL),
	('4d21645b-6dac-4ff2-904e-e2336c1b4c04', '6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', 'JD 350P W/THUMB', 0, 0, 1, 7, 5.25, '2026-04-14 19:37:53.823673+00', 0, NULL, true, true, NULL),
	('f0017506-e96b-4a38-984c-9b428dc69afb', '61de1e83-a430-4de6-8ef6-5b851d489e1d', 'JD 350P W/THUMB', 119.9, 0, 1, 7, 5.25, '2026-04-14 19:37:55.556181+00', 0, NULL, true, true, NULL),
	('a3218b7a-09f9-46f2-acbd-16917a39ba16', '61de1e83-a430-4de6-8ef6-5b851d489e1d', 'POLARIS RANGER 1000', 119.9, 0, 1, 2, 5.25, '2026-04-14 19:37:55.679359+00', 0, NULL, true, false, 'JD 350P W/THUMB'),
	('d2c14d22-740d-4ec2-9b2f-fddcb00add60', '61de1e83-a430-4de6-8ef6-5b851d489e1d', 'JD 750L - LPG W/GPS', 119.9, 0, 1, 0, 5.25, '2026-04-14 19:37:55.811252+00', 0, NULL, true, false, 'JD 350P W/THUMB'),
	('7790eaee-4a96-46aa-9e17-299372e164d7', '61de1e83-a430-4de6-8ef6-5b851d489e1d', '5-6 Yd Dump Truck', 119.9, 0, 2, 4, 5.25, '2026-04-14 19:37:55.925863+00', 0, NULL, true, false, 'JD 350P W/THUMB'),
	('1c74f9d0-20e5-4649-9b53-585d246294d6', '96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', 'JD 350P W/THUMB', 1.4, 10000, 2, 7, 5.25, '2026-04-17 22:39:38.577311+00', 300, NULL, true, true, NULL),
	('0926c712-842b-42bf-b86f-5c65f1781aa5', '96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', 'POLARIS RANGER 1000', 1.4, 2000, 1, 2, 5.25, '2026-04-17 22:39:38.929847+00', 100, NULL, true, false, 'JD 350P W/THUMB'),
	('ea1fe340-4653-4f86-900b-aca9750fb9c1', '96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', 'JD 750L - LPG W/GPS', 1.4, 5000, 1, 0, 5.25, '2026-04-17 22:39:39.269877+00', 400, NULL, true, false, 'JD 350P W/THUMB'),
	('9371ece8-4b7b-4802-8879-a8176f6c447d', 'fe54b6a4-4dd7-447b-8f5b-b3a4eef18d45', 'JD 350P W/THUMB', 1, 2500, 1, 7, 5.25, '2026-04-27 19:06:28.669804+00', 300, NULL, true, true, NULL),
	('66b1730d-b6f4-4b58-aac6-8e12ed025f71', 'fe54b6a4-4dd7-447b-8f5b-b3a4eef18d45', '5-6 Yd Dump Truck', 1, 5000, 2, 4, 5.25, '2026-04-27 19:06:28.762081+00', 300, NULL, true, false, 'JD 350P W/THUMB'),
	('641654bf-715f-474a-9977-d788e480b8b6', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', 'JD 460P', 2.5, 12000, 4, 7, 5.25, '2026-04-27 19:06:29.801028+00', 800, NULL, true, true, NULL),
	('73d7fad1-ccc4-4dba-8dd6-5e24db2c9cac', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', 'JD 510P - W/GPS.', 2.5, 15000, 1, 7, 5.25, '2026-04-27 19:06:29.907352+00', 1000, NULL, true, false, 'JD 460P'),
	('ed5b8093-f797-4204-8ce9-892d0eaa2767', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', 'Cat K-teck 1236 scraper', 2.5, 30000, 1, 7, 5.25, '2026-04-27 19:06:29.985911+00', 3000, NULL, true, true, NULL),
	('bfa9150c-4974-4198-a5d5-ae81cfd2e1b1', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', 'JD 950 L W/GPS', 2.5, 12000, 1, 7, 5.25, '2026-04-27 19:06:30.091717+00', 800, NULL, true, false, 'Cat K-teck 1236 scraper'),
	('9b6a4f7e-35dd-41cd-a724-07d0267029ed', 'd6ff2701-828c-4cb6-b693-05268ade668c', '5-6 Yd Dump Truck', 119.9, 0, 4, 4, 5.25, '2026-04-27 19:06:31.110679+00', 0, NULL, true, true, NULL),
	('bd468858-3e70-48a9-9e29-be5e42720a32', 'd6ff2701-828c-4cb6-b693-05268ade668c', 'JD 750L - LPG W/GPS', 119.9, 0, 1, 0, 5.25, '2026-04-27 19:06:31.218368+00', 0, NULL, true, false, '5-6 Yd Dump Truck'),
	('a0405072-5281-4b18-b013-f4b67e651c86', 'd6ff2701-828c-4cb6-b693-05268ade668c', 'JD 350P W/THUMB', 119.9, 0, 1, 7, 5.25, '2026-04-27 19:06:31.309352+00', 0, NULL, true, false, '5-6 Yd Dump Truck'),
	('0f501b05-0e02-40e5-81a3-e0a8e7f07597', '584281a5-4f51-4722-9f88-95d94842b380', 'JD 350P W/THUMB', 1.1, 7500, 1, 7, 5.25, '2026-04-27 19:06:32.510846+00', 500, NULL, true, true, NULL),
	('52be2a1c-41e1-420c-b749-1674ef1df026', '584281a5-4f51-4722-9f88-95d94842b380', 'JD 410P', 1.1, 5000, 2, 7, 5.25, '2026-04-27 19:06:32.610262+00', 300, NULL, true, false, 'JD 350P W/THUMB'),
	('3bb25ac4-87ac-4ab0-966a-8a456731a419', '3d08f851-b15e-46a6-bf68-ac823bce1f45', 'JD 460P', 3.3, 12000, 4, 7, 5.25, '2026-05-11 13:05:51.497465+00', 300, NULL, true, true, NULL),
	('1c272b16-81c0-4926-ac3d-086d2dbb9cb1', '3d08f851-b15e-46a6-bf68-ac823bce1f45', 'POLARIS RANGER 1000', 3.3, 2000, 1, 2, 5.25, '2026-05-11 13:05:51.645401+00', 100, NULL, true, false, 'JD 460P'),
	('74f1ff6d-edaa-45ac-8245-8cef5fed6280', '3d08f851-b15e-46a6-bf68-ac823bce1f45', 'JD 950 S/U BLADE  4WAY', 3.3, 2000, 1, 7, 5.25, '2026-05-11 13:05:51.782252+00', 100, NULL, true, false, 'JD 460P');


--
-- Data for Name: project_machinery; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."project_machinery" ("id", "project_id", "quote_service_machinery_id", "machinery_name", "expected_quantity", "received_quantity", "created_at", "updated_at", "start_date", "end_date", "is_principal", "parent_machinery_id", "is_unplanned", "unplanned_cost", "quote_service_id", "calculation_metadata") VALUES
	('7cc9e734-0a52-40e4-9c5e-db8b670d2c6c', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '641654bf-715f-474a-9977-d788e480b8b6', 'JD 460P', 4, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL),
	('2133a6b5-d447-42a8-bd81-fa1d09aa1a7c', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '73d7fad1-ccc4-4dba-8dd6-5e24db2c9cac', 'JD 510P - W/GPS.', 1, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL),
	('4af16f0f-38d1-4ecd-916d-b4daae9c7226', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', 'ed5b8093-f797-4204-8ce9-892d0eaa2767', 'Cat K-teck 1236 scraper', 1, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL),
	('6bbfe786-c963-48ea-a319-8a6e77a4968e', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', 'bfa9150c-4974-4198-a5d5-ae81cfd2e1b1', 'JD 950 L W/GPS', 1, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL),
	('e1def78c-54b6-4f2f-b212-52798d85d68a', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '9b6a4f7e-35dd-41cd-a724-07d0267029ed', '5-6 Yd Dump Truck', 4, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL),
	('20241ec0-4418-4fdd-8245-dae8851cdbb9', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', 'bd468858-3e70-48a9-9e29-be5e42720a32', 'JD 750L - LPG W/GPS', 1, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL),
	('0521e7a4-1861-4cf4-af1f-aed73670d8df', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', 'a0405072-5281-4b18-b013-f4b67e651c86', 'JD 350P W/THUMB', 1, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL),
	('50d94b16-6041-44f2-81e7-6882e46cb3ce', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '0f501b05-0e02-40e5-81a3-e0a8e7f07597', 'JD 350P W/THUMB', 1, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL),
	('3c177279-991b-44d9-9359-5e2b4b1ea538', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '52be2a1c-41e1-420c-b749-1674ef1df026', 'JD 410P', 2, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL),
	('9cb47185-fce9-4c94-b02d-70619d3cea4f', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '9371ece8-4b7b-4802-8879-a8176f6c447d', 'JD 350P W/THUMB', 1, 1, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL),
	('799148bb-1231-446e-9f0c-ea62b4f5eb46', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '66b1730d-b6f4-4b58-aac6-8e12ed025f71', '5-6 Yd Dump Truck', 2, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', '2026-05-12', '2026-06-15', false, NULL, false, 0, NULL, NULL),
	('9f17f068-b736-41fd-a2db-d2a53135998d', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', '1c272b16-81c0-4926-ac3d-086d2dbb9cb1', 'POLARIS RANGER 1000', 1, 1, '2026-05-11 13:07:07.038181+00', '2026-05-11 13:07:07.038181+00', NULL, NULL, false, NULL, false, 0, NULL, NULL),
	('d89dc86f-b674-4091-8e6e-3b822d509946', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', '74f1ff6d-edaa-45ac-8245-8cef5fed6280', 'JD 950 S/U BLADE  4WAY', 1, 1, '2026-05-11 13:07:07.038181+00', '2026-05-11 13:07:07.038181+00', NULL, NULL, false, NULL, false, 0, NULL, NULL),
	('0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', '3bb25ac4-87ac-4ab0-966a-8a456731a419', 'JD 460P', 4, 4, '2026-05-11 13:07:07.038181+00', '2026-05-11 13:07:07.038181+00', NULL, NULL, false, NULL, false, 0, NULL, NULL);


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."roles" ("id", "name", "description", "created_at", "updated_at") VALUES
	('e60d9b43-5906-41ea-bc83-d9889ea8931a', 'Admin', 'Full access to all features', '2026-05-14 13:17:01.914005+00', '2026-05-14 13:17:01.914005+00'),
	('48f9f843-64b6-425a-a666-ebf80486ab3c', 'Employee', 'Standard employee access', '2026-05-14 13:17:01.914005+00', '2026-05-14 13:17:01.914005+00');


--
-- Data for Name: quote_service_labors; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."quote_service_labors" ("id", "quote_service_id", "role_id", "months_to_work", "employees_quantity", "hourly_rate", "per_diem", "created_at", "role_name") VALUES
	('ea02c218-9a18-4eef-a7d0-4cc0b52545f2', 'fe54b6a4-4dd7-447b-8f5b-b3a4eef18d45', NULL, 1, 1, 39, 0, '2026-04-27 19:06:28.872953+00', 'Excavator Operator'),
	('b34b06e1-de9b-4ced-a0a6-7ded5d8b2d68', 'fe54b6a4-4dd7-447b-8f5b-b3a4eef18d45', NULL, 1, 2, 35, 0, '2026-04-27 19:06:28.954705+00', 'Truck Operator'),
	('9ea54c4c-4a14-46ad-90a6-88a394207d1c', 'e512195f-c8cd-4bd1-848d-90c30c46f5ad', NULL, 4, 1, 73, 0, '2026-03-06 03:23:19.508991+00', NULL),
	('664dff19-fa19-44d3-8905-debb7f25b274', 'e512195f-c8cd-4bd1-848d-90c30c46f5ad', NULL, 4, 3, 55, 0, '2026-03-06 03:23:19.604437+00', NULL),
	('10f962bc-4871-4c43-8302-5bd31b5b5feb', 'fe54b6a4-4dd7-447b-8f5b-b3a4eef18d45', NULL, 1, 4, 20, 0, '2026-04-27 19:06:29.055768+00', 'labor'),
	('42dcbcb4-bdf7-4bee-9ca6-3ddca7d25c64', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', NULL, 2.5, 4, 35, 0, '2026-04-27 19:06:30.169127+00', 'Truck Operator'),
	('ca00edcd-e764-42f7-b02c-452f89c0ecb4', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', NULL, 2.5, 1, 39, 0, '2026-04-27 19:06:30.293075+00', 'Scraper operator'),
	('bb8106cd-8a49-4246-a3d5-179e6d97c2dd', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', NULL, 2.5, 1, 39, 0, '2026-04-27 19:06:30.370195+00', 'Excavator Operator'),
	('0dce68ff-49c8-442e-8acc-cf73c71a2ee3', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', NULL, 2.5, 1, 55, 0, '2026-04-27 19:06:30.477532+00', 'Shaper Class B'),
	('a2102a9d-437a-4ea5-b616-7db9b2fd7fff', 'd6ff2701-828c-4cb6-b693-05268ade668c', NULL, 119.9, 4, 35, 0, '2026-04-27 19:06:31.43901+00', 'Truck Operator'),
	('a83d08d1-5159-43ea-b86f-4ba08ee5719e', 'd6ff2701-828c-4cb6-b693-05268ade668c', NULL, 119.9, 1, 55, 0, '2026-04-27 19:06:31.536993+00', 'Shaper Class B'),
	('192cc750-a07a-4015-b80c-f8a077338e01', 'd6ff2701-828c-4cb6-b693-05268ade668c', NULL, 119.9, 1, 39, 0, '2026-04-27 19:06:31.69935+00', 'Excavator Operator'),
	('02a3dfb6-70b0-4b78-9712-9770f5fa781f', 'd02c020a-a0de-48e9-8682-fafe05f47509', NULL, 1, 2, 45, 7, '2026-03-09 23:05:47.903421+00', NULL),
	('25cb6026-27fb-46bc-af0f-d7e01fefe479', 'd02c020a-a0de-48e9-8682-fafe05f47509', NULL, 4, 4, 39, 7, '2026-03-09 23:05:48.116302+00', NULL),
	('5a04cfb5-1fb3-4eb0-88e5-bd4684e0b138', 'd6ff2701-828c-4cb6-b693-05268ade668c', NULL, 119.9, 6, 20, 0, '2026-04-27 19:06:31.780497+00', 'labor'),
	('73371454-927d-40f8-a8f2-162ca4c6c2fb', '584281a5-4f51-4722-9f88-95d94842b380', NULL, 1.1, 1, 39, 0, '2026-04-27 19:06:32.716255+00', 'Excavator Operator'),
	('facf8f01-3f06-4786-81cf-527e7933d18f', '584281a5-4f51-4722-9f88-95d94842b380', NULL, 1.1, 2, 35, 0, '2026-04-27 19:06:32.798348+00', 'Truck Operator'),
	('21956692-ad85-4b5e-9f99-830c36961975', '5380d563-d6ac-4231-976c-1579d74b4b52', NULL, 3, 4, 35, 7, '2026-03-10 00:56:59.703589+00', NULL),
	('3df16a45-6f6e-4697-8fe9-fb6bd86320de', '5380d563-d6ac-4231-976c-1579d74b4b52', NULL, 3, 1, 73, 7, '2026-03-10 00:56:59.859696+00', NULL),
	('0ccca807-e264-4d1e-a0d5-d1a6f91fdb81', '5380d563-d6ac-4231-976c-1579d74b4b52', NULL, 3, 1, 55, 7, '2026-03-10 00:57:00.010967+00', NULL),
	('9e74f0c8-ab24-43e6-8c21-d1cf9d571b64', '5380d563-d6ac-4231-976c-1579d74b4b52', NULL, 3, 2, 39, 7, '2026-03-10 00:57:00.164968+00', NULL),
	('946e8728-1126-4c98-bd59-f79fe4ecd9a3', '5380d563-d6ac-4231-976c-1579d74b4b52', NULL, 3, 4, 39, 7, '2026-03-10 00:57:00.336624+00', NULL),
	('e798f3b3-e8ba-405a-9c25-4e70f89a7540', '81513bd9-fae6-4e55-97c8-152f788409e5', NULL, 3, 3, 55, 7, '2026-03-10 00:57:01.461462+00', NULL),
	('5a223f92-0b4a-4c53-a607-219f65b32517', 'ee7f93a9-96c4-4335-a021-eb5372fa064a', NULL, 3, 1, 73, 4, '2026-03-12 20:29:40.474977+00', 'SUPERVISOR'),
	('daefb73b-d121-4dc7-88d2-81f2fcdfa1b6', 'f513c717-b218-4e7b-b6c1-f8d00660e746', NULL, 1, 4, 35, 0, '2026-03-30 19:06:59.082773+00', 'Truck Operator'),
	('e5d126e0-08d1-48a4-9b42-4cb56e952cfb', 'f513c717-b218-4e7b-b6c1-f8d00660e746', NULL, 1, 2, 55, 0, '2026-03-30 19:06:59.154617+00', 'Shaper Class B'),
	('89778eae-6c24-4c73-ba7b-1ca687aa97fa', 'f513c717-b218-4e7b-b6c1-f8d00660e746', NULL, 1, 2, 39, 0, '2026-03-30 19:06:59.218258+00', 'Scraper operator'),
	('10a4fca5-ce00-4e77-8219-e64a1833b3fa', 'fad4ea94-045a-454a-8789-b5709e388ac1', NULL, 4, 8, 35, 0, '2026-04-07 18:09:57.648125+00', 'Truck Operator'),
	('f5c10f3a-d3aa-47ca-96fc-b2e867112d35', 'ac7593d3-c6f5-47ef-bb8b-730c75c421e5', NULL, 2.7, 1, 39, 0, '2026-04-14 18:24:33.918863+00', 'Excavator Operator'),
	('9fd1188e-0d01-4e60-bf7b-cbfd55d88ccc', 'ac7593d3-c6f5-47ef-bb8b-730c75c421e5', NULL, 2.7, 2, 73, 0, '2026-04-14 18:24:34.057111+00', 'SUPERVISOR'),
	('2f9ffe5f-fb2f-407f-85e2-ae9345c881cd', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', NULL, 14.1, 1, 39, 0, '2026-04-14 19:37:50.63357+00', 'Excavator Operator'),
	('8e11cec2-1117-4532-bea0-a89642b52165', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', NULL, 14.1, 1, 73, 0, '2026-04-14 19:37:50.853859+00', 'SUPERVISOR'),
	('c166dde8-4090-4d77-80ae-97ff25650213', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', NULL, 14.1, 1, 55, 0, '2026-04-14 19:37:50.986974+00', 'Shaper Class B'),
	('5217d2bf-8c82-4a6a-b271-183fd2be0fb0', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', NULL, 14.1, 4, 35, 0, '2026-04-14 19:37:51.106934+00', 'Truck Operator'),
	('f7742d17-d14a-4011-82dc-6346971b6c05', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', NULL, 14, 4, 20, 0, '2026-04-14 19:37:51.207601+00', ''),
	('a92f68ee-ad7a-42bf-8458-332686642e9c', '22055dba-b9af-426f-89de-bedd62f536b1', NULL, 119.9, 4, 35, 0, '2026-04-14 19:37:52.794835+00', 'Truck Operator'),
	('0c6f6d93-f52e-4e9d-8973-6d0edc1a7c9b', '22055dba-b9af-426f-89de-bedd62f536b1', NULL, 119.9, 1, 55, 0, '2026-04-14 19:37:52.900587+00', 'Shaper Class B'),
	('91ef3e94-838d-4d9f-8992-b73fd7a87e8c', '6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', NULL, 0, 1, 55, 0, '2026-04-14 19:37:53.981613+00', 'Shaper Class B'),
	('c90a4e7d-9dd6-4adc-9eac-e0d41b55f57e', '6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', NULL, 0, 2, 35, 0, '2026-04-14 19:37:54.219667+00', 'Truck Operator'),
	('dd0bd1da-02da-45d6-afe2-f863a671f4f8', '6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', NULL, 0, 1, 39, 0, '2026-04-14 19:37:54.425315+00', 'Excavator Operator'),
	('d2f701d2-8bee-45fe-b207-33aaa075b94d', '61de1e83-a430-4de6-8ef6-5b851d489e1d', NULL, 119.9, 1, 39, 0, '2026-04-14 19:37:56.029327+00', 'Excavator Operator'),
	('50f94b4b-653a-41e4-8d96-b31ff85dfb38', '61de1e83-a430-4de6-8ef6-5b851d489e1d', NULL, 119.9, 1, 73, 0, '2026-04-14 19:37:56.167747+00', 'SUPERVISOR'),
	('271a6bec-5d63-46f7-8771-ac1cd76eaa75', '61de1e83-a430-4de6-8ef6-5b851d489e1d', NULL, 119.9, 1, 55, 0, '2026-04-14 19:37:56.285574+00', 'Shaper Class B'),
	('ca00123a-275b-4c13-9d07-3626f5d921ac', '61de1e83-a430-4de6-8ef6-5b851d489e1d', NULL, 119.9, 2, 35, 0, '2026-04-14 19:37:56.467008+00', 'Truck Operator'),
	('0e736a9b-9404-4149-81d0-e6ecbb14e445', '96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', NULL, 1.4, 2, 39, 2, '2026-04-17 22:39:39.817112+00', 'Excavator Operator'),
	('374fc027-8587-4c9d-ae8f-86e7dcfbd91c', '96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', NULL, 1.4, 1, 73, 2, '2026-04-17 22:39:40.4907+00', 'SUPERVISOR'),
	('668937a1-3d45-4f49-b2f3-a36c14a2b2d3', '96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', NULL, 1.4, 1, 55, 2, '2026-04-17 22:39:40.856288+00', 'Shaper Class B'),
	('6120c093-f949-4313-abb9-feb02e0123d3', '5cffaaa8-5e06-4a4f-86f0-daee894497b4', NULL, 1.25, 1, 55, 0, '2026-04-24 17:46:57.939594+00', 'Shaper Class B'),
	('f7415edc-4616-4156-a814-79d4dfc43f86', '6e3b35aa-aa09-498b-9357-f9c44c1512e9', NULL, 1.25, 3, 39, 0, '2026-04-24 17:47:01.147237+00', 'Multi Equipment Operator'),
	('8af96e1d-004f-4a56-a7b2-f8bcfc9f828c', 'b6335445-15c1-4d64-8f71-a88855e2f5b2', NULL, 1.25, 1, 35, 0, '2026-04-24 17:47:04.487795+00', 'Skill Labor'),
	('ebb4d747-f6a5-4d01-b9ed-e2cf2f730573', '3d08f851-b15e-46a6-bf68-ac823bce1f45', NULL, 3.3, 4, 39, 3, '2026-05-11 13:05:51.989048+00', 'TRUCK OPERATOR'),
	('73fa80a8-8616-4475-b503-4612ed11efd6', '3d08f851-b15e-46a6-bf68-ac823bce1f45', NULL, 3.3, 1, 65, 3, '2026-05-11 13:05:52.25669+00', 'CONSTRUCTION SUPERINTENDENT'),
	('768515b7-7d4f-4560-9977-0e7d40737300', '3d08f851-b15e-46a6-bf68-ac823bce1f45', NULL, 3.3, 1, 55, 5, '2026-05-11 13:05:52.389179+00', 'SHAPER CLASS B');


--
-- Data for Name: project_labor; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."project_labor" ("id", "project_id", "quote_service_labor_id", "role_name", "expected_employees", "active_employees", "created_at", "is_unplanned", "linked_machinery_id", "unplanned_cost", "quote_service_id", "calculation_metadata") VALUES
	('2270af13-2b01-4614-ac79-e7eef29a7ed5', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', 'ebb4d747-f6a5-4d01-b9ed-e2cf2f730573', 'TRUCK OPERATOR', 4, 0, '2026-05-11 13:07:07.202078+00', false, NULL, 0, NULL, NULL),
	('912f31c3-aaf8-4eea-966d-ed48a4df3bd6', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', '73fa80a8-8616-4475-b503-4612ed11efd6', 'CONSTRUCTION SUPERINTENDENT', 1, 0, '2026-05-11 13:07:07.202078+00', false, NULL, 0, NULL, NULL),
	('a9effc2f-b241-4829-a5fd-62dd53ff9218', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', '768515b7-7d4f-4560-9977-0e7d40737300', 'SHAPER CLASS B', 1, 0, '2026-05-11 13:07:07.202078+00', false, NULL, 0, NULL, NULL);


--
-- Data for Name: project_tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."project_tasks" ("id", "project_id", "quote_service_id", "name", "description", "status", "estimated_hours", "actual_hours", "created_at") VALUES
	('a9d57768-0155-49a8-9b2e-e7d11a362ae7', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', '3d08f851-b15e-46a6-bf68-ac823bce1f45', 'TOPSOIL MANAGEMENT', NULL, 'pending', 0, 0, '2026-05-11 13:07:07.376558+00');


--
-- Data for Name: workers; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."workers" ("id", "id_number", "full_name", "hire_date", "phone", "email", "status", "role_id", "created_at", "updated_at") VALUES
	('a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', '11950787', 'Fred Parra', '2026-04-08', '(456) 455-5555', 'fred@fred.ve', 'Active', '626d5dab-2200-4680-961f-f71069db1b94', '2026-04-08 20:00:29.509787+00', '2026-04-08 20:00:29.509787+00'),
	('d356e711-a989-4ac6-8a0e-b352596f0524', '11223344', 'Albert Parra', '2026-05-05', '(555) 888-4888', 'albert@fff.com', 'Active', '15584be2-4d8f-4748-96ba-5684a56a7d74', '2026-05-05 15:22:36.60714+00', '2026-05-05 15:22:36.60714+00'),
	('38dbe85c-a6f8-48ea-a6f2-2816031b064a', '34556876', 'gilberto navarro', '2026-05-05', '(088) 652-468', 'gilber@ggh.com', 'Active', '15584be2-4d8f-4748-96ba-5684a56a7d74', '2026-05-05 15:23:31.919982+00', '2026-05-05 15:23:31.919982+00'),
	('af647f93-7be5-47ec-83d5-4627eb3393b8', '68264828', 'Santi barbosa', '2026-05-05', '(555) 111-6401', 'santi@jjmc.com', 'Active', '15584be2-4d8f-4748-96ba-5684a56a7d74', '2026-05-05 15:26:42.404074+00', '2026-05-05 15:26:42.404074+00'),
	('533e90cb-43fa-4b6b-91e4-de27f0dcd216', '56432189', 'miranda fosil', '2026-05-05', '(222) 364-8031', 'miran@jjj.com', 'Active', '15584be2-4d8f-4748-96ba-5684a56a7d74', '2026-05-05 15:24:02.326564+00', '2026-05-05 15:27:02.535096+00'),
	('6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', '222671936', 'Ana delgado', '2026-05-05', '(222) 316-480', 'ana@jjj.com', 'Active', 'da849f21-3558-472d-b242-01cb999dd1d5', '2026-05-05 15:28:27.489587+00', '2026-05-05 15:28:27.489587+00'),
	('07685c96-3506-4464-b94c-3bb363bb41c7', '777625518', 'victoria cumares', '2026-05-05', '(111) 136-4093', 'cuma@jjj.com', 'Active', 'da849f21-3558-472d-b242-01cb999dd1d5', '2026-05-05 15:29:57.270722+00', '2026-05-05 15:29:57.270722+00'),
	('b926c60c-96d3-41a7-90f1-3e01f7c69e01', '66638927', 'yandel alejandro', '2026-05-05', '(555) 466-4888', 'ale@jjj.com', 'Active', 'da849f21-3558-472d-b242-01cb999dd1d5', '2026-05-05 15:30:58.455271+00', '2026-05-05 15:30:58.455271+00'),
	('8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', '444277819', 'susy medina', '2026-05-05', '(333) 468-4961', 'susa@hhh.com', 'Active', 'da849f21-3558-472d-b242-01cb999dd1d5', '2026-05-05 15:31:42.051728+00', '2026-05-05 15:31:42.051728+00'),
	('7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', '34678987', 'dubrasca luciana', '2026-05-05', '(111) 234-678', 'luci@ggg.com', 'Active', 'da849f21-3558-472d-b242-01cb999dd1d5', '2026-05-05 15:32:54.162642+00', '2026-05-05 15:32:54.162642+00');


--
-- Data for Name: labor_checkins; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: logistics_applications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."logistics_applications" ("id", "name", "created_at") VALUES
	('d57a9120-618b-4443-914e-3d63321fe726', 'Medidas', '2026-05-14 14:50:12.622913+00'),
	('5836847f-311b-478f-91e7-5e9f26588af6', 'Compactar', '2026-05-14 14:50:20.709746+00'),
	('03b6f504-efaf-4417-afa8-ceaa153cbe26', 'Calibración', '2026-05-14 14:50:30.356858+00'),
	('3aef1ade-d3ee-4a4c-98b5-757a6486c876', 'Administrativo', '2026-05-14 14:51:29.305847+00');


--
-- Data for Name: logistics_equipment; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."logistics_equipment" ("id", "description", "photo_url", "associated_service_ids", "applications", "created_at", "updated_at") VALUES
	('abd60776-f441-45d9-b571-e514259db597', 'JUPING JACK', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778770141403_Juping_Jack.png', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4}', '{}', '2026-05-14 14:49:01.597819+00', '2026-05-14 14:49:01.597819+00'),
	('34e7cedc-52b1-4f4a-9f52-45d5110867fe', 'GPS-Topcon', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778770244467_GPS-Topcon.png', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd}', '{Medidas,Compactar,Calibración}', '2026-05-14 14:50:44.862481+00', '2026-05-14 14:50:44.862481+00'),
	('077301f2-f8d2-4ab4-9dd5-e4534bce0494', '500 GL FUEL TANK', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778770300105_500_GL_FUEL_TANK.png', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd}', '{Administrativo}', '2026-05-14 14:51:40.332473+00', '2026-05-14 14:51:40.332473+00'),
	('9c6fc789-ee0a-4fb7-9c2d-28333ed4730f', '40" CONEX STORAGE', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778770355145_40_conex_Office_-_Storage.png', '{7ff1fd8a-485b-4eea-bf27-077726ef6bbd,fba9ad4f-880d-477d-b7c8-0f791b04fcc4}', '{Administrativo}', '2026-05-14 14:52:35.432856+00', '2026-05-14 14:52:35.432856+00'),
	('74367a52-059f-4593-9aad-e15eb47120aa', '40" CONEX OFFICE', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778770400033_40_conex_Office_-_Storage.png', '{7ff1fd8a-485b-4eea-bf27-077726ef6bbd,fba9ad4f-880d-477d-b7c8-0f791b04fcc4}', '{Administrativo}', '2026-05-14 14:53:20.364765+00', '2026-05-14 14:53:20.364765+00');


--
-- Data for Name: machinery; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."machinery" ("id", "description", "photo_url", "capacity", "created_at", "updated_at", "delivery_cost", "default_trips_per_day", "fuel_gallons", "capacity_yards", "trips_per_day", "yards_per_day", "machinery_type", "associated_service_ids", "applications", "machinery_category", "operator_role_id") VALUES
	('01276ae3-42a3-4635-a4dc-e312e9ff7e8c', 'JD 1050 S/U 4WAY -W/RIPPER', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782882160_JD_1050-950-850.png', '30', '2026-05-14 14:37:32.307618+00', '2026-05-14 18:21:22.41911+00', 0, 60, 4, 4, 1, 4, 'production', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,f745f151-0412-4f79-b674-586887eb7af3,d56ff5ce-10c6-4133-addb-6049586c1b7e,d19dc987-5732-467c-be8e-65b7e97338d1,9ac9166c-7392-4a13-84a8-f36882846d88,ab8649a9-4741-42b3-9f9a-57953ccb5787,2502bcd5-bf39-48bc-b003-9a0f973405f9,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,896f786e-baee-4230-91f9-ffce2f4c9e8f,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a}', '{}', 'support', 'da849f21-3558-472d-b242-01cb999dd1d5'),
	('f6fa790b-b2c5-43a8-8a0c-2cb76d3a7a50', 'TOYOTA TUNDRA PLATEUM', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782333241_Toyota_Tundra_Plateum.png', '11', '2026-05-14 14:17:00.33496+00', '2026-05-14 18:12:13.655165+00', 0, 60, 2, 0, 0, 0, 'support', '{dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,e9621dbc-11ab-45d8-bd6a-ef20aa2faca6,09af766a-7110-4d29-acca-f49eb364617f,6f5994cb-d499-41ba-9b11-fa90a67f5b7c,7d778fdf-3ea7-4693-a957-949b651869dc,8bf3ea6e-94ab-4991-b8cf-99f1a54734f7,d623a601-ff3a-4fd3-a928-90fb397c9806,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,97b21602-1dc0-4684-aa9f-ae5772a22bdd,ce3b3780-a114-4240-a7a3-c87f264a6ea0,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,f745f151-0412-4f79-b674-586887eb7af3,d56ff5ce-10c6-4133-addb-6049586c1b7e,d19dc987-5732-467c-be8e-65b7e97338d1,fba9ad4f-880d-477d-b7c8-0f791b04fcc4,9ac9166c-7392-4a13-84a8-f36882846d88,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,ab8649a9-4741-42b3-9f9a-57953ccb5787,2502bcd5-bf39-48bc-b003-9a0f973405f9,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,896f786e-baee-4230-91f9-ffce2f4c9e8f,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a}', '{}', 'support', '626d5dab-2200-4680-961f-f71069db1b94'),
	('5d00a2a7-737f-46c8-9868-d89e18abc81b', 'POLARIS RANGER 1000', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782374671_Polaris_Ranger.png', '11', '2026-05-14 14:20:44.617701+00', '2026-05-14 18:12:54.959848+00', 0, 60, 2, 0, 0, 0, 'support', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,e9621dbc-11ab-45d8-bd6a-ef20aa2faca6,09af766a-7110-4d29-acca-f49eb364617f,6f5994cb-d499-41ba-9b11-fa90a67f5b7c,7d778fdf-3ea7-4693-a957-949b651869dc,ce3b3780-a114-4240-a7a3-c87f264a6ea0,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d}', '{}', 'support', '626d5dab-2200-4680-961f-f71069db1b94'),
	('e2d5d145-b6fc-45d2-a9b4-05146c72e968', 'JD 950 S/U BLADE  4WAY', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782432525_JD_1050-950-850.png', '30', '2026-05-14 14:24:17.239812+00', '2026-05-14 18:13:52.861529+00', 0, 60, 7, 6, 1, 6, 'production', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,f745f151-0412-4f79-b674-586887eb7af3,9ac9166c-7392-4a13-84a8-f36882846d88,2502bcd5-bf39-48bc-b003-9a0f973405f9,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,5855e5ac-013c-46b4-8efd-f0ab533ef854}', '{}', 'support', 'da849f21-3558-472d-b242-01cb999dd1d5'),
	('bfc62521-5d00-47af-9a6d-8b35961f0c83', 'JD 950 L W/GPS', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782484707_JD_1050-950-850.png', '30', '2026-05-14 14:25:37.951535+00', '2026-05-14 18:14:44.963156+00', 0, 60, 7, 8, 1, 8, 'production', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,6f5994cb-d499-41ba-9b11-fa90a67f5b7c,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,ce3b3780-a114-4240-a7a3-c87f264a6ea0,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d,f745f151-0412-4f79-b674-586887eb7af3,d19dc987-5732-467c-be8e-65b7e97338d1,2502bcd5-bf39-48bc-b003-9a0f973405f9,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,5855e5ac-013c-46b4-8efd-f0ab533ef854}', '{}', 'support', 'fe520365-87c8-4a42-ae6a-9c2e989f1ef0'),
	('797daaee-8b31-4ae5-a35b-3606b22dc83e', 'JD 850 L/P LPG W/GPS NO RIPPER', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782532974_JD_1050-950-850.png', '30', '2026-05-14 14:27:49.578806+00', '2026-05-14 18:15:33.235757+00', 0, 60, 7, 9, 1, 9, 'production', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,6f5994cb-d499-41ba-9b11-fa90a67f5b7c,09af766a-7110-4d29-acca-f49eb364617f,7d778fdf-3ea7-4693-a957-949b651869dc,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,2502bcd5-bf39-48bc-b003-9a0f973405f9}', '{}', 'support', 'da849f21-3558-472d-b242-01cb999dd1d5'),
	('960c1212-4f45-42ac-8966-6fa405fe3fbf', 'JD 750L - LPG W/GPS', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782579585_JD_750L.png', '39', '2026-05-14 14:29:43.836244+00', '2026-05-14 18:16:19.795533+00', 0, 60, 5, 0, 0, 0, 'production', '{dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,09af766a-7110-4d29-acca-f49eb364617f,8bf3ea6e-94ab-4991-b8cf-99f1a54734f7,7d778fdf-3ea7-4693-a957-949b651869dc,97b21602-1dc0-4684-aa9f-ae5772a22bdd,9ac9166c-7392-4a13-84a8-f36882846d88,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,d19dc987-5732-467c-be8e-65b7e97338d1,fba9ad4f-880d-477d-b7c8-0f791b04fcc4,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,2502bcd5-bf39-48bc-b003-9a0f973405f9,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,1751df49-b41e-4ba0-8319-cec920b373fb,042b71dd-2910-49ed-b75b-5f955649f27a,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a}', '{}', 'support', 'da849f21-3558-472d-b242-01cb999dd1d5'),
	('456999ca-274f-406d-9896-d8236d1de8a3', 'JD 510P - W/GPS.', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782652535_JD_510-350.png', '30', '2026-05-14 14:31:24.117903+00', '2026-05-14 18:17:32.860585+00', 0, 60, 7, 1, 1, 1, 'production', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,7d778fdf-3ea7-4693-a957-949b651869dc,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,97b21602-1dc0-4684-aa9f-ae5772a22bdd,ce3b3780-a114-4240-a7a3-c87f264a6ea0,2502bcd5-bf39-48bc-b003-9a0f973405f9,ab8649a9-4741-42b3-9f9a-57953ccb5787,5855e5ac-013c-46b4-8efd-f0ab533ef854,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,3239afc7-e942-482e-a095-18911c9695e7,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a}', '{}', 'support', '453c550e-47f4-4f27-ad81-f9f5b71bc3ba'),
	('17b24170-9b73-4c7b-928f-74f4692a741b', 'JD 460P', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782704764_JD_460-410.png', '30', '2026-05-14 14:32:53.618498+00', '2026-05-14 18:18:25.035974+00', 0, 60, 7, 30, 60, 1800, 'hauling', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,f745f151-0412-4f79-b674-586887eb7af3,d56ff5ce-10c6-4133-addb-6049586c1b7e,d19dc987-5732-467c-be8e-65b7e97338d1,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,9ac9166c-7392-4a13-84a8-f36882846d88,ab8649a9-4741-42b3-9f9a-57953ccb5787,2502bcd5-bf39-48bc-b003-9a0f973405f9,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,896f786e-baee-4230-91f9-ffce2f4c9e8f,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a}', '{}', 'support', '15584be2-4d8f-4748-96ba-5684a56a7d74'),
	('1a298eed-6ae3-4c40-828a-01f16160a32a', 'JD 410P', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782752335_JD_460-410.png', '30', '2026-05-14 13:44:33.520912+00', '2026-05-14 18:19:12.558506+00', 0, 60, 7, 30, 60, 1800, 'hauling', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,e9621dbc-11ab-45d8-bd6a-ef20aa2faca6,09af766a-7110-4d29-acca-f49eb364617f,6f5994cb-d499-41ba-9b11-fa90a67f5b7c,7d778fdf-3ea7-4693-a957-949b651869dc,8bf3ea6e-94ab-4991-b8cf-99f1a54734f7,d623a601-ff3a-4fd3-a928-90fb397c9806,ee85328b-30fc-40b3-921c-e45508374379,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,97b21602-1dc0-4684-aa9f-ae5772a22bdd,ce3b3780-a114-4240-a7a3-c87f264a6ea0,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,f745f151-0412-4f79-b674-586887eb7af3,d56ff5ce-10c6-4133-addb-6049586c1b7e,d19dc987-5732-467c-be8e-65b7e97338d1,9ac9166c-7392-4a13-84a8-f36882846d88,ab8649a9-4741-42b3-9f9a-57953ccb5787,2502bcd5-bf39-48bc-b003-9a0f973405f9,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,896f786e-baee-4230-91f9-ffce2f4c9e8f,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a}', '{}', 'support', '15584be2-4d8f-4748-96ba-5684a56a7d74'),
	('e4611099-ac80-4013-814f-e42a898dba34', 'JD 350P W/THUMB', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782819926_JD_510-350.png', '30', '2026-05-14 14:36:05.328293+00', '2026-05-14 18:20:20.176943+00', 0, 60, 7, 1, 1, 1, 'production', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,09af766a-7110-4d29-acca-f49eb364617f,6f5994cb-d499-41ba-9b11-fa90a67f5b7c,7d778fdf-3ea7-4693-a957-949b651869dc,8bf3ea6e-94ab-4991-b8cf-99f1a54734f7,d623a601-ff3a-4fd3-a928-90fb397c9806,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,ce3b3780-a114-4240-a7a3-c87f264a6ea0,97b21602-1dc0-4684-aa9f-ae5772a22bdd,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,f745f151-0412-4f79-b674-586887eb7af3,d56ff5ce-10c6-4133-addb-6049586c1b7e,d19dc987-5732-467c-be8e-65b7e97338d1,ab8649a9-4741-42b3-9f9a-57953ccb5787,9ac9166c-7392-4a13-84a8-f36882846d88,2502bcd5-bf39-48bc-b003-9a0f973405f9,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,896f786e-baee-4230-91f9-ffce2f4c9e8f,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,e9621dbc-11ab-45d8-bd6a-ef20aa2faca6}', '{}', 'support', '453c550e-47f4-4f27-ad81-f9f5b71bc3ba'),
	('4fbf20c3-f135-4e66-8830-86e31464501f', 'Cat K-teck 1236 scraper', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782930889_Cat_K-Teck_1236_scraper.png', '33', '2026-05-14 13:44:33.520912+00', '2026-05-14 18:22:11.162831+00', 0, 60, 7, 30, 80, 2400, 'hauling', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,5855e5ac-013c-46b4-8efd-f0ab533ef854}', '{}', 'support', '5b896dcb-f674-4e43-81b3-d66c23a928c1'),
	('3aa3bbe9-61cc-4220-8168-c519f4c050c3', '5-6 Yd Dump Truck', 'http://127.0.0.1:56421/storage/v1/object/public/equipment/1778782998243_5-6_Yd_Dump_Truck.png', '11', '2026-05-14 13:17:03.392091+00', '2026-05-14 18:23:18.538341+00', 0, 60, 4, 10, 80, 800, 'hauling', '{7ff1fd8a-485b-4eea-bf27-077726ef6bbd,fba9ad4f-880d-477d-b7c8-0f791b04fcc4,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,fea56364-4b5a-4470-86cf-dd55a0814151,e9621dbc-11ab-45d8-bd6a-ef20aa2faca6,16557aec-e8bb-4041-9b9a-b48150b1211d,7d778fdf-3ea7-4693-a957-949b651869dc,8bf3ea6e-94ab-4991-b8cf-99f1a54734f7,d623a601-ff3a-4fd3-a928-90fb397c9806,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,97b21602-1dc0-4684-aa9f-ae5772a22bdd,ce3b3780-a114-4240-a7a3-c87f264a6ea0,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d,f745f151-0412-4f79-b674-586887eb7af3,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,d19dc987-5732-467c-be8e-65b7e97338d1,9ac9166c-7392-4a13-84a8-f36882846d88,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,896f786e-baee-4230-91f9-ffce2f4c9e8f,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136}', '{}', 'support', '15584be2-4d8f-4748-96ba-5684a56a7d74');


--
-- Data for Name: machinery_applications; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: machinery_inspections; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."machinery_inspections" ("id", "project_machinery_id", "internal_code", "brand_model", "ownership_type", "provider_name", "hour_meter_start", "condition_status", "evidence_photos", "observations", "received_at", "received_by") VALUES
	('4b72e766-afd2-4ef6-8193-e7710a31e4bb', '9f17f068-b736-41fd-a2db-d2a53135998d', '1212', 'POLARIS RANGER 1000', 'owned', NULL, 4545, 'operational', '["http://127.0.0.1:56421/storage/v1/object/public/machinery_evidence/24d128a9-5591-4cd2-b218-2fdfc93bb18f/9f17f068-b736-41fd-a2db-d2a53135998d/1778771019095_GPS-Topcon.png"]', 'ok', '2026-05-14 15:03:39.273306+00', '3b3df1db-8109-4414-b451-6b9e22435254'),
	('c35518e4-0ef3-4ce8-b356-35f2822e8bb7', 'd89dc86f-b674-4091-8e6e-3b822d509946', '3234234', 'JD 950 S/U BLADE  4WAY', 'owned', NULL, 45, 'operational', '["http://127.0.0.1:56421/storage/v1/object/public/machinery_evidence/24d128a9-5591-4cd2-b218-2fdfc93bb18f/d89dc86f-b674-4091-8e6e-3b822d509946/1778771043987_Juping_Jack.png"]', '', '2026-05-14 15:04:04.126334+00', '3b3df1db-8109-4414-b451-6b9e22435254'),
	('31ffefe3-ad48-43d5-9793-881e79a5ac01', '0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01', 'ewew', 'JD 460P', 'owned', NULL, 34, 'operational', '["http://127.0.0.1:56421/storage/v1/object/public/machinery_evidence/24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771070470_500_GL_FUEL_TANK.png"]', '1', '2026-05-14 15:04:30.621932+00', '3b3df1db-8109-4414-b451-6b9e22435254'),
	('091ec225-7817-4a66-840f-8ad484e24e28', '0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01', '222', 'JD 460P', 'owned', NULL, 43, 'operational', '["http://127.0.0.1:56421/storage/v1/object/public/machinery_evidence/24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771092714_500_GL_FUEL_TANK.png"]', '2', '2026-05-14 15:04:52.921777+00', '3b3df1db-8109-4414-b451-6b9e22435254'),
	('0029cb82-97ad-4180-8980-d280ad41046c', '0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01', '21', 'JD 460P', 'owned', NULL, 333, 'operational', '["http://127.0.0.1:56421/storage/v1/object/public/machinery_evidence/24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771110904_500_GL_FUEL_TANK.png"]', '3', '2026-05-14 15:05:11.044847+00', '3b3df1db-8109-4414-b451-6b9e22435254'),
	('597fd086-6584-4302-9603-3155b7994225', '0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01', '12', 'JD 460P', 'owned', NULL, 32, 'operational', '["http://127.0.0.1:56421/storage/v1/object/public/machinery_evidence/24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771131104_500_GL_FUEL_TANK.png"]', '4', '2026-05-14 15:05:31.237364+00', '3b3df1db-8109-4414-b451-6b9e22435254');


--
-- Data for Name: materials; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."materials" ("id", "description", "unit", "yield_factor", "associated_service_ids", "created_at", "updated_at") VALUES
	('4a0ec654-150f-4f77-ac85-364b7f0cffee', 'Liner Polimérico', 'FT', 1, '{2502bcd5-bf39-48bc-b003-9a0f973405f9}', '2026-05-14 14:41:46.750134+00', '2026-05-14 14:41:46.750134+00'),
	('766b3099-3892-4a6f-a62f-58ace99b67df', 'HDPE Perforada 4"', 'LF', 1.05, '{d6aadd2b-b0f1-4570-8597-a590d7ef1eb5}', '2026-05-14 14:42:54.65032+00', '2026-05-14 14:42:54.65032+00'),
	('c0c89647-e1ce-4c59-8d94-6540af64e4ed', 'Grava 1/4"', 'CY', 1, '{d6aadd2b-b0f1-4570-8597-a590d7ef1eb5}', '2026-05-14 14:43:27.288302+00', '2026-05-14 14:43:27.288302+00'),
	('9681fbcd-1cc8-4c29-9c22-2dfb8401d840', 'Conectores (Tees, Elbows, Caps)Conectores (Tees, Elbows, Caps)', 'UN', 0.02, '{d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,2502bcd5-bf39-48bc-b003-9a0f973405f9}', '2026-05-14 14:44:22.237613+00', '2026-05-14 14:44:22.237613+00'),
	('1e5ee343-05b9-46f3-8574-562e6780e9fd', 'Bunker Sand (White)', 'TON', 1, '{2502bcd5-bf39-48bc-b003-9a0f973405f9}', '2026-05-14 14:45:04.413192+00', '2026-05-14 14:45:04.413192+00'),
	('d5bb132c-8c4c-4a9c-8663-92b211f7b5ad', 'Arena Rootzone', 'CY', 1, '{d6aadd2b-b0f1-4570-8597-a590d7ef1eb5}', '2026-05-14 14:45:55.459523+00', '2026-05-14 14:45:55.459523+00');


--
-- Data for Name: quote_service_materials; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: project_materials; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: material_receptions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."profiles" ("id", "name", "email", "phone", "role", "avatar_url", "updated_at") VALUES
	('3b3df1db-8109-4414-b451-6b9e22435254', 'Samuel Parra', 'samuel@mey.com', NULL, 'Employee', NULL, '2026-05-14 13:27:45.594981+00');


--
-- Data for Name: quote_service_instruments; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: project_instruments; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: project_labor_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: quote_service_estimations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: quote_service_estimation_resources; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."services" ("id", "description", "unit", "created_at", "updated_at") VALUES
	('dd661c15-1693-4091-a108-7ea4bc19f1b8', 'TOPSOIL STRIPPING', 'CY', '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00'),
	('5855e5ac-013c-46b4-8efd-f0ab533ef854', 'BULK EXCAVATION', 'CY', '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00'),
	('97b21602-1dc0-4684-aa9f-ae5772a22bdd', 'FINISH GRADING', 'SQFT', '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00'),
	('fea56364-4b5a-4470-86cf-dd55a0814151', 'SUBGRADE PREP', 'SQFT', '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00'),
	('3239afc7-e942-482e-a095-18911c9695e7', 'BASE COURSE', 'CY', '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00'),
	('7ff1fd8a-485b-4eea-bf27-077726ef6bbd', 'CLEARING', 'AC', '2026-03-09 18:08:12.150698+00', '2026-03-09 18:08:37.050806+00'),
	('d6aadd2b-b0f1-4570-8597-a590d7ef1eb5', 'GREEN CONSTRUCTION', 'SF', '2026-03-30 19:12:05.778948+00', '2026-03-30 19:12:05.778948+00'),
	('2502bcd5-bf39-48bc-b003-9a0f973405f9', 'BUNKER CONSTRUCTION', 'SF', '2026-03-30 19:13:17.045904+00', '2026-03-30 19:13:17.045904+00'),
	('fba9ad4f-880d-477d-b7c8-0f791b04fcc4', 'CUT-FILL TOP LOADING', 'CY', '2026-03-09 18:06:30.690952+00', '2026-04-14 18:22:13.174688+00'),
	('09af766a-7110-4d29-acca-f49eb364617f', 'SELECTCLEARING', 'AC', '2026-05-05 02:14:17.604424+00', '2026-05-05 02:14:17.604424+00'),
	('bdcc0905-6040-4561-8c99-9bd7bd8dbcd2', 'TOPSOIL MANAGEMENT', 'CY', '2026-05-05 02:14:56.426834+00', '2026-05-05 02:14:56.426834+00'),
	('e9621dbc-11ab-45d8-bd6a-ef20aa2faca6', 'SILT FENCE', 'LF', '2026-05-05 02:15:34.725215+00', '2026-05-05 02:15:34.725215+00'),
	('9ac9166c-7392-4a13-84a8-f36882846d88', 'CONSTRUCTION ENTRANCE', 'EA', '2026-05-05 02:16:41.119738+00', '2026-05-05 02:16:41.119738+00'),
	('a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44', 'EROSION DUST PREVENTION', 'MO', '2026-05-05 02:18:06.896262+00', '2026-05-05 02:18:06.896262+00'),
	('f745f151-0412-4f79-b674-586887eb7af3', 'EROSION CONTROL REMOVAL', 'LS', '2026-05-05 02:18:54.476903+00', '2026-05-05 02:18:54.476903+00'),
	('ce3b3780-a114-4240-a7a3-c87f264a6ea0', 'FINE SHAPING', 'LS', '2026-05-05 02:19:41.191723+00', '2026-05-05 02:19:41.191723+00'),
	('16557aec-e8bb-4041-9b9a-b48150b1211d', 'TEE CONSTRUCTION', 'SF', '2026-05-05 02:20:16.333272+00', '2026-05-05 02:20:16.333272+00'),
	('5c5fafd4-5bd0-4cdd-8206-47ed4ae20136', 'BUNKER CONCRETE BUNKER LINER', 'SF', '2026-05-05 02:21:09.989+00', '2026-05-05 02:21:09.989+00'),
	('ab8649a9-4741-42b3-9f9a-57953ccb5787', 'CARTPATH PREP', 'LF', '2026-05-05 02:21:32.177177+00', '2026-05-05 02:21:32.177177+00'),
	('2c6dbea5-e9b0-4268-b0d9-80dc6e47242d', 'FINE GRADING & SEEDBED PREP', 'AC', '2026-05-05 02:22:20.988559+00', '2026-05-05 02:22:20.988559+00'),
	('6f5994cb-d499-41ba-9b11-fa90a67f5b7c', 'SEEDBED PREP ROUGH PREP, NO HAND WORK', 'AC', '2026-05-05 02:23:29.856173+00', '2026-05-05 02:23:29.856173+00'),
	('7d778fdf-3ea7-4693-a957-949b651869dc', 'ROCK PICKING', 'AC', '2026-05-05 02:24:06.140311+00', '2026-05-05 02:24:06.140311+00'),
	('8bf3ea6e-94ab-4991-b8cf-99f1a54734f7', 'NATIVE FINE FESCUE -MECHANICAL SEEDING', 'AC', '2026-05-05 02:25:47.971704+00', '2026-05-05 02:25:47.971704+00'),
	('d623a601-ff3a-4fd3-a928-90fb397c9806', 'NATIVE FESCUE -5 ACRES- SEED & EC BLANKET', 'SF', '2026-05-05 02:27:15.486327+00', '2026-05-05 02:27:15.486327+00'),
	('d19dc987-5732-467c-be8e-65b7e97338d1', 'EROSION CONTROL  BLANKET', 'AC', '2026-05-05 02:28:01.476212+00', '2026-05-05 02:28:01.476212+00'),
	('d56ff5ce-10c6-4133-addb-6049586c1b7e', 'EROSION CONTROL MAINTENANCE', 'LS', '2026-05-05 02:28:52.065674+00', '2026-05-05 02:28:52.065674+00'),
	('ee85328b-30fc-40b3-921c-e45508374379', 'MOBILIZATION', 'LS', '2026-05-05 02:29:31.140356+00', '2026-05-05 02:29:31.140356+00'),
	('1751df49-b41e-4ba0-8319-cec920b373fb', '4" SOLID PIPE', 'LF', '2026-05-05 02:31:11.928044+00', '2026-05-05 02:31:11.928044+00'),
	('042b71dd-2910-49ed-b75b-5f955649f27a', '6" SOLID PIPE', 'LF', '2026-05-05 02:31:35.002224+00', '2026-05-05 02:31:35.002224+00'),
	('896f786e-baee-4230-91f9-ffce2f4c9e8f', '8" SOLID PIPE', 'LF', '2026-05-05 02:31:52.872686+00', '2026-05-05 02:31:52.872686+00'),
	('e92da126-0e97-4934-b87d-405d5a65eb0e', '12" SOLID PIPE', 'LF', '2026-05-05 02:32:20.845678+00', '2026-05-05 02:32:20.845678+00'),
	('fa947699-257b-4033-8bc5-599db0f25308', '24" SOLID PIPE', 'LF', '2026-05-05 02:33:06.540123+00', '2026-05-05 02:33:06.540123+00'),
	('62b12119-f67b-4d5e-944e-6980c560208a', '12" PIPE RISER', 'LF', '2026-05-05 02:33:46.437594+00', '2026-05-05 02:33:46.437594+00');


--
-- Data for Name: worker_role_history; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

INSERT INTO "storage"."buckets" ("id", "name", "owner", "created_at", "updated_at", "public", "avif_autodetection", "file_size_limit", "allowed_mime_types", "owner_id", "type") VALUES
	('equipment', 'equipment', NULL, '2026-05-14 13:17:02.073669+00', '2026-05-14 13:17:02.073669+00', true, false, NULL, NULL, NULL, 'STANDARD'),
	('machinery_evidence', 'machinery_evidence', NULL, '2026-05-14 13:17:02.679476+00', '2026-05-14 13:17:02.679476+00', true, false, NULL, NULL, NULL, 'STANDARD');


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: iceberg_namespaces; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: iceberg_tables; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

INSERT INTO "storage"."objects" ("id", "bucket_id", "name", "owner", "created_at", "updated_at", "last_accessed_at", "metadata", "version", "owner_id", "user_metadata") VALUES
	('eed3d703-0dc7-429d-93b7-17dbbf4e2575', 'equipment', '1778768215979_Toyota_Tundra_Plateum.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:16:59.551573+00', '2026-05-14 14:16:59.551573+00', '2026-05-14 14:16:59.551573+00', '{"eTag": "\"347d3e4368d8e0e5027a3e411634da4d\"", "size": 301626, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:16:59.321Z", "contentLength": 301626, "httpStatusCode": 200}', 'c12d7cc5-aed0-41d9-8f7d-a3e5f8e78c6d', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('c1bcaa17-4a73-41c3-9d54-32939f0c392a', 'equipment', '1778768443575_Polaris_Ranger.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:20:44.322827+00', '2026-05-14 14:20:44.322827+00', '2026-05-14 14:20:44.322827+00', '{"eTag": "\"f90434204edaddf683f325d831275480\"", "size": 3135464, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:20:43.877Z", "contentLength": 3135464, "httpStatusCode": 200}', '94c2ce8f-dd81-400c-bf5d-51a3a7ea553e', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('7039be0b-0d6a-4f4a-ac1c-95a0cb7732ee', 'equipment', '1778768656708_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:24:16.886611+00', '2026-05-14 14:24:16.886611+00', '2026-05-14 14:24:16.886611+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:24:16.866Z", "contentLength": 109635, "httpStatusCode": 200}', '790a8b66-9d52-4d8b-989d-81eafccb043d', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('bcaae435-27c4-448e-8eb5-3fb41cbdf5a8', 'equipment', '1778768737633_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:25:37.723866+00', '2026-05-14 14:25:37.723866+00', '2026-05-14 14:25:37.723866+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:25:37.716Z", "contentLength": 109635, "httpStatusCode": 200}', '0f5aa25e-b7bd-4004-8543-47231a6a1785', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('63733e35-9dd4-4197-9e18-1243b219c88c', 'equipment', '1778768869313_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:27:49.389704+00', '2026-05-14 14:27:49.389704+00', '2026-05-14 14:27:49.389704+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:27:49.381Z", "contentLength": 109635, "httpStatusCode": 200}', '7ec16c14-420d-448e-8e50-e07ea17842aa', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('ad4bdfac-3711-4526-9279-9df29ac99039', 'equipment', '1778768983343_JD_750L.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:29:43.498786+00', '2026-05-14 14:29:43.498786+00', '2026-05-14 14:29:43.498786+00', '{"eTag": "\"a3b5c5e7f404215c7c36ab214acda101\"", "size": 212297, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:29:43.485Z", "contentLength": 212297, "httpStatusCode": 200}', 'aebeac7e-6d27-4189-95b4-9b1f6cab1edd', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('5f0c575b-534e-47d0-92aa-38b187f8071b', 'equipment', '1778769083671_JD_510-350.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:31:23.877791+00', '2026-05-14 14:31:23.877791+00', '2026-05-14 14:31:23.877791+00', '{"eTag": "\"95c1c49e84ededf5653ad3942bcaf1c3\"", "size": 114653, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:31:23.854Z", "contentLength": 114653, "httpStatusCode": 200}', 'd9b8a1f8-4272-430e-bfb9-dbe36c471624', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('f2137f25-9c3c-4a22-b869-6d311072dec6', 'equipment', '1778769173191_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:32:53.358151+00', '2026-05-14 14:32:53.358151+00', '2026-05-14 14:32:53.358151+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:32:53.344Z", "contentLength": 108816, "httpStatusCode": 200}', '9c394882-65af-4e48-8fb1-a97cf56e9d2f', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('58691c5e-59b0-44d6-8cd0-8c4dd3fc3865', 'equipment', '1778769282202_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:34:42.302854+00', '2026-05-14 14:34:42.302854+00', '2026-05-14 14:34:42.302854+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:34:42.292Z", "contentLength": 108816, "httpStatusCode": 200}', '71b1992c-fc77-4bfd-996c-17296d9d45ff', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('e905cdd5-eb90-4db8-9a55-39fc5e2f60d8', 'equipment', '1778769365033_JD_510-350.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:36:05.08884+00', '2026-05-14 14:36:05.08884+00', '2026-05-14 14:36:05.08884+00', '{"eTag": "\"95c1c49e84ededf5653ad3942bcaf1c3\"", "size": 114653, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:36:05.081Z", "contentLength": 114653, "httpStatusCode": 200}', '34228282-8b17-483c-b52c-cacbe312a358', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('b79883a6-a83e-4556-912d-862f48e48f1b', 'equipment', '1778769451977_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:37:32.048095+00', '2026-05-14 14:37:32.048095+00', '2026-05-14 14:37:32.048095+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:37:32.043Z", "contentLength": 109635, "httpStatusCode": 200}', '56b48672-ff2a-4217-84fb-26c4a9e45752', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('e50fef5b-2e08-4dd7-8848-3deb5e9b5fd3', 'equipment', '1778769529952_Cat_K-Teck_1236_scraper.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:38:50.021745+00', '2026-05-14 14:38:50.021745+00', '2026-05-14 14:38:50.021745+00', '{"eTag": "\"a36b2ec3bf70a375897261ade118a9bc\"", "size": 27619, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:38:50.015Z", "contentLength": 27619, "httpStatusCode": 200}', '5a2040b0-1519-4ed6-bac8-394a2801ef08', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('209120ba-8911-4c37-95e2-1af56bf46983', 'equipment', '1778769616676_5-6_Yd_Dump_Truck.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:40:16.744263+00', '2026-05-14 14:40:16.744263+00', '2026-05-14 14:40:16.744263+00', '{"eTag": "\"4bcafd13afb233cc4d60cc6f32e8cc16\"", "size": 72998, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:40:16.736Z", "contentLength": 72998, "httpStatusCode": 200}', 'abec80de-cc82-46a5-8bb1-66726ef5d23c', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('651324ec-88ff-4a66-9632-6fa08fc25e3d', 'equipment', '1778770141403_Juping_Jack.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:49:01.481349+00', '2026-05-14 14:49:01.481349+00', '2026-05-14 14:49:01.481349+00', '{"eTag": "\"22ebea29730f5ac41f333075b9bb2079\"", "size": 91840, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:49:01.476Z", "contentLength": 91840, "httpStatusCode": 200}', '7ac267bd-a5ec-4a85-b17b-45fc74577771', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('cda48b0f-3c98-4f32-8519-f0b073078b9b', 'equipment', '1778770244467_GPS-Topcon.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:50:44.577821+00', '2026-05-14 14:50:44.577821+00', '2026-05-14 14:50:44.577821+00', '{"eTag": "\"5d04a090b76337db9de6fe657e589043\"", "size": 28137, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:50:44.567Z", "contentLength": 28137, "httpStatusCode": 200}', '7accdd80-ba4d-42dc-a6bb-c27627178a4f', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('579dd9ad-7f51-4795-8f5e-154a051f8bc9', 'equipment', '1778770300105_500_GL_FUEL_TANK.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:51:40.16481+00', '2026-05-14 14:51:40.16481+00', '2026-05-14 14:51:40.16481+00', '{"eTag": "\"524a2e8b6159570221ef02489e6390ca\"", "size": 104345, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:51:40.158Z", "contentLength": 104345, "httpStatusCode": 200}', 'bcca837e-1103-4fa7-a5ad-cd176c35d54a', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('ec34b05b-2ca4-4ea7-83c2-0d21297b8975', 'equipment', '1778770355145_40_conex_Office_-_Storage.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:52:35.213722+00', '2026-05-14 14:52:35.213722+00', '2026-05-14 14:52:35.213722+00', '{"eTag": "\"f3befee1387abfb35914d7561fc89248\"", "size": 94071, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:52:35.206Z", "contentLength": 94071, "httpStatusCode": 200}', '206c9905-7e06-468a-91c5-6ac70d08b7ad', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('bb5b835a-0661-48f3-bf4b-867d9fdee4ff', 'equipment', '1778770400033_40_conex_Office_-_Storage.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:53:20.115131+00', '2026-05-14 14:53:20.115131+00', '2026-05-14 14:53:20.115131+00', '{"eTag": "\"f3befee1387abfb35914d7561fc89248\"", "size": 94071, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:53:20.107Z", "contentLength": 94071, "httpStatusCode": 200}', '8734d794-271e-4ea0-97a3-1e05f5525682', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('e80c6d3f-4cc0-4530-b156-5465d68bc6a4', 'machinery_evidence', '24d128a9-5591-4cd2-b218-2fdfc93bb18f/9f17f068-b736-41fd-a2db-d2a53135998d/1778771019095_GPS-Topcon.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:03:39.175279+00', '2026-05-14 15:03:39.175279+00', '2026-05-14 15:03:39.175279+00', '{"eTag": "\"5d04a090b76337db9de6fe657e589043\"", "size": 28137, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T15:03:39.171Z", "contentLength": 28137, "httpStatusCode": 200}', 'a2fcf504-933f-4b9f-befb-3c53a17a3ee7', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('246af230-6a97-4a9a-a7e5-05a55ed0c0eb', 'machinery_evidence', '24d128a9-5591-4cd2-b218-2fdfc93bb18f/d89dc86f-b674-4091-8e6e-3b822d509946/1778771043987_Juping_Jack.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:04:04.041809+00', '2026-05-14 15:04:04.041809+00', '2026-05-14 15:04:04.041809+00', '{"eTag": "\"22ebea29730f5ac41f333075b9bb2079\"", "size": 91840, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T15:04:04.035Z", "contentLength": 91840, "httpStatusCode": 200}', '2728fc1e-46b2-48b3-9b04-1ecb7fd52a23', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('7408022a-5bb0-47cf-96ba-f99a82db8e88', 'machinery_evidence', '24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771070470_500_GL_FUEL_TANK.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:04:30.520875+00', '2026-05-14 15:04:30.520875+00', '2026-05-14 15:04:30.520875+00', '{"eTag": "\"524a2e8b6159570221ef02489e6390ca\"", "size": 104345, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T15:04:30.516Z", "contentLength": 104345, "httpStatusCode": 200}', '79c7a6bc-5c1b-4354-aba7-a4a775494bed', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('90301b25-4e6f-447f-9d02-41e463e203ab', 'machinery_evidence', '24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771092714_500_GL_FUEL_TANK.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:04:52.775743+00', '2026-05-14 15:04:52.775743+00', '2026-05-14 15:04:52.775743+00', '{"eTag": "\"524a2e8b6159570221ef02489e6390ca\"", "size": 104345, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T15:04:52.766Z", "contentLength": 104345, "httpStatusCode": 200}', '3db7ac67-5828-4e10-8e91-365a113f730b', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('9d79effb-913c-4fdf-b1c3-fdcbee0aabdc', 'machinery_evidence', '24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771110904_500_GL_FUEL_TANK.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:05:10.954857+00', '2026-05-14 15:05:10.954857+00', '2026-05-14 15:05:10.954857+00', '{"eTag": "\"524a2e8b6159570221ef02489e6390ca\"", "size": 104345, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T15:05:10.950Z", "contentLength": 104345, "httpStatusCode": 200}', 'e3b2f9c0-309f-4949-ab81-c8bf3a835713', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('401e7fe6-4279-4936-971e-509a66d96611', 'machinery_evidence', '24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771131104_500_GL_FUEL_TANK.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:05:31.154914+00', '2026-05-14 15:05:31.154914+00', '2026-05-14 15:05:31.154914+00', '{"eTag": "\"524a2e8b6159570221ef02489e6390ca\"", "size": 104345, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T15:05:31.146Z", "contentLength": 104345, "httpStatusCode": 200}', 'db0e8ab0-f59c-41eb-88d4-5ca866266298', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('9d13e849-a5e8-464d-9e7e-0962b3ecff71', 'equipment', '1778782333241_Toyota_Tundra_Plateum.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:12:13.43106+00', '2026-05-14 18:12:13.43106+00', '2026-05-14 18:12:13.43106+00', '{"eTag": "\"347d3e4368d8e0e5027a3e411634da4d\"", "size": 301626, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:12:13.409Z", "contentLength": 301626, "httpStatusCode": 200}', '6b523881-b00f-44e0-bd06-ecfc4e3d9cf9', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('acf8fddb-fcad-482f-bb56-23f48fa5eb2c', 'equipment', '1778782374671_Polaris_Ranger.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:12:54.836586+00', '2026-05-14 18:12:54.836586+00', '2026-05-14 18:12:54.836586+00', '{"eTag": "\"f90434204edaddf683f325d831275480\"", "size": 3135464, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:12:54.809Z", "contentLength": 3135464, "httpStatusCode": 200}', '9b4fedef-218c-4a6c-b46c-c556156f9df4', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('9db2e111-4f7f-4b2b-9a8e-4125dc7b4146', 'equipment', '1778782432525_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:13:52.594289+00', '2026-05-14 18:13:52.594289+00', '2026-05-14 18:13:52.594289+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:13:52.582Z", "contentLength": 109635, "httpStatusCode": 200}', 'ee45322e-0d6c-40db-90b4-9b68948ae10a', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('ebf7e3a3-570f-4a2c-9ae3-577b70c2bd41', 'equipment', '1778782484707_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:14:44.760285+00', '2026-05-14 18:14:44.760285+00', '2026-05-14 18:14:44.760285+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:14:44.751Z", "contentLength": 109635, "httpStatusCode": 200}', '348756f7-c020-4676-92a3-80099f30c6b2', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('f909fc7a-148e-4b01-b1db-91ff69feb101', 'equipment', '1778782532974_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:15:33.046695+00', '2026-05-14 18:15:33.046695+00', '2026-05-14 18:15:33.046695+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:15:33.037Z", "contentLength": 109635, "httpStatusCode": 200}', '570b39cc-c523-4984-8aa2-f0b4b77792e4', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('96ba4247-04cd-4b6f-8b6c-374b525ac3c9', 'equipment', '1778782579585_JD_750L.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:16:19.643777+00', '2026-05-14 18:16:19.643777+00', '2026-05-14 18:16:19.643777+00', '{"eTag": "\"a3b5c5e7f404215c7c36ab214acda101\"", "size": 212297, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:16:19.634Z", "contentLength": 212297, "httpStatusCode": 200}', '63dec7f3-1514-4eb0-92e2-5019b93493bb', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('a4105928-22cd-43a2-b207-31b2bbc2d3bd', 'equipment', '1778782652535_JD_510-350.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:17:32.621309+00', '2026-05-14 18:17:32.621309+00', '2026-05-14 18:17:32.621309+00', '{"eTag": "\"95c1c49e84ededf5653ad3942bcaf1c3\"", "size": 114653, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:17:32.614Z", "contentLength": 114653, "httpStatusCode": 200}', '12eb3c54-4706-4047-a64e-9d3ce1b79f8d', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('a8afaf20-2f6c-41a1-89c6-875ce4204e61', 'equipment', '1778782704764_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:18:24.837715+00', '2026-05-14 18:18:24.837715+00', '2026-05-14 18:18:24.837715+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:18:24.829Z", "contentLength": 108816, "httpStatusCode": 200}', 'acf84b04-b330-483c-991e-cfd236e285e8', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('b3376a25-bc9d-46a7-82b9-6dcf4ec938f0', 'equipment', '1778782752335_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:19:12.384234+00', '2026-05-14 18:19:12.384234+00', '2026-05-14 18:19:12.384234+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:19:12.380Z", "contentLength": 108816, "httpStatusCode": 200}', 'b8771d3c-3279-4fdd-a944-7f04c4b651ea', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('2052cac4-49e0-40df-b2ea-02f4c1affa14', 'equipment', '1778782819926_JD_510-350.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:20:19.995944+00', '2026-05-14 18:20:19.995944+00', '2026-05-14 18:20:19.995944+00', '{"eTag": "\"95c1c49e84ededf5653ad3942bcaf1c3\"", "size": 114653, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:20:19.986Z", "contentLength": 114653, "httpStatusCode": 200}', 'a067ec20-162f-4203-b9bc-e69e3ec20a28', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('13963a86-6394-4898-826a-73d9bd8abb29', 'equipment', '1778782882160_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:21:22.253992+00', '2026-05-14 18:21:22.253992+00', '2026-05-14 18:21:22.253992+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:21:22.246Z", "contentLength": 109635, "httpStatusCode": 200}', '40e17291-b0c3-4858-aef7-2d828986f0b7', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('b7a91fd7-e1bc-49ff-83fb-9f12de6fac84', 'equipment', '1778782930889_Cat_K-Teck_1236_scraper.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:22:10.93744+00', '2026-05-14 18:22:10.93744+00', '2026-05-14 18:22:10.93744+00', '{"eTag": "\"a36b2ec3bf70a375897261ade118a9bc\"", "size": 27619, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:22:10.928Z", "contentLength": 27619, "httpStatusCode": 200}', '44c0afae-896a-4856-853c-915d99474330', '3b3df1db-8109-4414-b451-6b9e22435254', '{}'),
	('324c1e8e-0747-4d94-b9ca-b160cbfc0d73', 'equipment', '1778782998243_5-6_Yd_Dump_Truck.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:23:18.320147+00', '2026-05-14 18:23:18.320147+00', '2026-05-14 18:23:18.320147+00', '{"eTag": "\"4bcafd13afb233cc4d60cc6f32e8cc16\"", "size": 72998, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:23:18.310Z", "contentLength": 72998, "httpStatusCode": 200}', '326c8a12-1225-4964-b5a6-2bf780db3561', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: hooks; Type: TABLE DATA; Schema: supabase_functions; Owner: supabase_functions_admin
--



--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('"auth"."refresh_tokens_id_seq"', 5, true);


--
-- Name: hooks_id_seq; Type: SEQUENCE SET; Schema: supabase_functions; Owner: supabase_functions_admin
--

SELECT pg_catalog.setval('"supabase_functions"."hooks_id_seq"', 1, false);


--
-- PostgreSQL database dump complete
--

-- \unrestrict 9EVMenw2vYWox8SOGU1PcrbDctAeDFU76lG1OOMBrvs7WXefHC6qqbObsg1QFrg

RESET ALL;
