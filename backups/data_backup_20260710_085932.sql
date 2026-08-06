pg_dump: warning: there are circular foreign-key constraints on this table:
pg_dump: detail: quote_service_machineries
pg_dump: hint: You might not be able to restore the dump without using --disable-triggers or temporarily dropping the constraints.
pg_dump: hint: Consider using a full dump instead of a --data-only dump to avoid this problem.
pg_dump: warning: there are circular foreign-key constraints on this table:
pg_dump: detail: quote_service_estimation_resources
pg_dump: hint: You might not be able to restore the dump without using --disable-triggers or temporarily dropping the constraints.
pg_dump: hint: Consider using a full dump instead of a --data-only dump to avoid this problem.
pg_dump: warning: there are circular foreign-key constraints on this table:
pg_dump: detail: project_machinery
pg_dump: hint: You might not be able to restore the dump without using --disable-triggers or temporarily dropping the constraints.
pg_dump: hint: Consider using a full dump instead of a --data-only dump to avoid this problem.
--
-- PostgreSQL database dump
--

\restrict jM926k8dtrTyxNDef0gJsPQbeNxHZIyifWCIV39BjmghHKaP3lKDft39GbAQWcT

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
-- Data for Name: tenants; Type: TABLE DATA; Schema: _realtime; Owner: -
--

INSERT INTO _realtime.tenants (id, name, external_id, jwt_secret, max_concurrent_users, inserted_at, updated_at, max_events_per_second, postgres_cdc_default, max_bytes_per_second, max_channels_per_client, max_joins_per_second, suspend, jwt_jwks, notify_private_alpha, private_only, migrations_ran, broadcast_adapter, max_presence_events_per_second, max_payload_size_in_kb, max_client_presence_events_per_window, client_presence_window_ms, presence_enabled) VALUES ('cb973ee2-39f8-4993-b55d-49fdd63e6de3', 'realtime-dev', 'realtime-dev', 'iNjicxc4+llvc9wovDvqymwfnj9teWMlyOIbJ8Fh6j2WNU8CIJ2ZgjR6MUIKqSmeDmvpsKLsZ9jgXJmQPpwL8w==', 200, '2026-07-10 11:36:30', '2026-07-10 11:36:31', 100, 'postgres_cdc_rls', 100000, 100, 100, false, '{"keys": [{"x": "M5Sjqn5zwC9Kl1zVfUUGvv9boQjCGd45G8sdopBExB4", "y": "P6IXMvA2WYXSHSOMTBH2jsw_9rrzGy89FjPf6oOsIxQ", "alg": "ES256", "crv": "P-256", "ext": true, "kid": "b81269f1-21d8-4f2e-b719-c2240a840d90", "kty": "EC", "use": "sig", "key_ops": ["verify"]}, {"k": "c3VwZXItc2VjcmV0LWp3dC10b2tlbi13aXRoLWF0LWxlYXN0LTMyLWNoYXJhY3RlcnMtbG9uZw", "kty": "oct"}]}', false, false, 69, 'gen_rpc', 1000, 3000, NULL, NULL, false);


--
-- Data for Name: extensions; Type: TABLE DATA; Schema: _realtime; Owner: -
--

INSERT INTO _realtime.extensions (id, type, settings, tenant_external_id, inserted_at, updated_at) VALUES ('97c83c39-6f91-4a80-8ede-e85d9b66f6a3', 'postgres_cdc_rls', '{"region": "us-east-1", "db_host": "vkyLptM0HoLr0sr3bYAgbWFBZxTmAhW12RDwwLEetIQ=", "db_name": "sWBpZNdjggEPTQVlI52Zfw==", "db_port": "+enMDFi1J/3IrrquHHwUmA==", "db_user": "uxbEq/zz8DXVD53TOI1zmw==", "slot_name": "supabase_realtime_replication_slot", "db_password": "sWBpZNdjggEPTQVlI52Zfw==", "publication": "supabase_realtime", "ssl_enforced": false, "poll_interval_ms": 100, "poll_max_changes": 100, "poll_max_record_bytes": 1048576}', 'realtime-dev', '2026-07-10 11:36:30', '2026-07-10 11:36:30');


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: _realtime; Owner: -
--

INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20210706140551, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20220329161857, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20220410212326, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20220506102948, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20220527210857, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20220815211129, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20220815215024, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20220818141501, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20221018173709, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20221102172703, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20221223010058, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20230110180046, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20230810220907, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20230810220924, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20231024094642, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20240306114423, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20240418082835, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20240625211759, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20240704172020, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20240902173232, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20241106103258, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20250424203323, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20250613072131, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20250711044927, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20250811121559, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20250926223044, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20251204170944, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20251218000543, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20260209232800, '2026-06-27 20:07:11');
INSERT INTO _realtime.schema_migrations (version, inserted_at) VALUES (20260304000000, '2026-06-27 20:07:11');


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '56de61f5-1d50-41b0-972a-fde4be316388', '{"action":"user_signedup","actor_id":"0adb9f86-7d30-4c75-a431-b1f8e116978c","actor_username":"test@test.com","actor_via_sso":false,"log_type":"team","traits":{"provider":"email"}}', '2026-06-27 20:41:20.596151+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'e9b46b52-0559-47a9-99a5-f74f4dbb1a0d', '{"action":"login","actor_id":"0adb9f86-7d30-4c75-a431-b1f8e116978c","actor_username":"test@test.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-06-27 20:41:20.617864+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '73e0ce42-568f-4f44-8d12-0a8f6b60c113', '{"action":"user_signedup","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"team","traits":{"provider":"email"}}', '2026-05-14 13:27:45.628084+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'e0f2147b-ba0d-402c-b41b-a619f16590db', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-05-14 13:27:45.657242+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '2680741c-0c9f-4b4f-be15-34cc1933a907', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-05-14 14:07:55.284864+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'f604b5bb-4159-495f-a6f6-faf716a66115', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-05-14 15:06:55.823749+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'e8b51265-6ea0-4a9f-980d-c1844266c035', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-05-14 15:06:55.827864+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '4da74c57-786d-429b-9e8c-b0801f156ce7', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-05-14 15:36:49.138792+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '84340f66-a15c-4e20-b7eb-8d1257b79e6a', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-05-14 18:11:10.585254+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'c92a5e0f-0b69-483a-a43c-08024111351d', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-06-27 20:51:00.943847+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'cf013277-17a6-44b8-ba87-8c8e4707b79a', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-06-27 20:58:22.537462+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'a72a8e1b-48f4-4f48-aaea-9f83e14db8c9', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 13:10:58.07466+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '23f4a708-c326-48d0-bb78-7c49db236a8b', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 13:10:58.098781+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '661c8c8f-e718-427f-8bb2-bd783aadffcb', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-06-29 13:12:58.168116+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'c53d498e-bcd8-4983-828a-9a434c703b92', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-06-29 13:35:58.587363+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '02850158-1576-4c3f-b20a-eef951589642', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-06-29 14:32:12.45527+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '3457741d-5ff3-4a07-ba51-f1d3d17a5d4d', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 16:07:17.652079+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'b7d1d11e-7cff-45c3-86d3-dba1b4b7c6a4', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 16:07:17.680817+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '4aadaf68-a791-4451-964c-37b2ef3d866f', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-06-29 16:38:55.662632+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '6d210b1c-7b0c-4308-a4ff-6ef8a13513c7', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-06-29 16:52:15.11021+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '95e0258e-80f2-4eb0-bd44-b3c36cc92536', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 17:51:15.56204+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '62fa6248-2f15-4c32-9391-0cb75a0f7a9e', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 17:51:15.564355+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '1910c2b6-d4df-46e2-a7fe-54ad6e3ec0da', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 18:48:48.21292+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '92a189b2-d311-49c0-99bf-33f8322fed45', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 18:48:48.230198+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'c23debde-8988-4031-9858-5068307cf82e', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 19:47:48.515823+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '3b332e03-d0b3-41bb-9e72-a6e130dce2e0', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 19:47:48.526585+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'f63ec8c6-dc23-4af5-83b4-e35cbf0fd978', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 20:47:39.877607+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '9174e27f-bbb0-4c7c-a0ab-ed7fef0a1dcc', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 20:47:39.884286+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'c32d3b1d-541b-4207-ad0e-6d83c1c273c8', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 21:46:39.492844+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '951ac73e-f4ff-48ae-9a8a-76cb3b59144a', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 21:46:39.505767+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'e4a5b5f6-f019-43c5-95de-d5fcede94e8c', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 22:57:41.530118+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'e8657e85-90c8-43ad-a233-a6ba2d0aac89', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-29 22:57:41.547989+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '388ea2b4-4532-4730-9c4d-2bd069d83b60', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-06-30 16:15:35.014845+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '38d41c22-49bd-4005-aef6-0e2a034f5429', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-30 16:27:12.502757+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '7145cbd0-839f-4417-9b24-a0c96ed7a4e6', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-30 16:27:12.518177+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'e16a28c1-42e7-4a9b-9b6b-a4a9952182a7', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-06-30 16:27:40.748957+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '3ab16196-f2b4-4daf-82ae-2895f09178a7', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-30 17:26:40.214665+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '2fafc02c-d809-4ea1-92e1-7ecb3cd00149', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-06-30 17:26:40.234042+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'e4ab27a2-da95-4060-866d-348f2bb0c636', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-06-30 18:19:19.654297+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'e0cd8098-d746-4101-a4f1-6da016551ae0', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-02 15:15:13.353173+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'a887a42f-aac9-406f-8c86-15f468ab9128', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-02 16:02:44.806269+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '25c0502f-e006-4aba-8a9d-98f0c6ea9dcf', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-02 16:06:33.076154+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '28bb03c3-8744-4f35-9190-2f105866a23a', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-02 16:06:33.081105+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'e0b0cbd2-78fa-493c-870b-f9b4bdd80576', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-02 16:09:21.468108+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '059a65b3-3112-4de2-a2f2-433e09d53cee', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-02 16:27:29.780597+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '1925f05a-2864-4252-a181-a8999e737d1a', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-02 17:26:28.966299+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '110c0f04-63cf-476c-a6e6-c8f1418f7fb8', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-02 17:26:28.970587+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '1bc8e3d0-0d43-4688-8b7a-abf7a53e0927', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-02 18:25:28.471436+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'b5b863e8-6ada-4fd4-9e89-6a9a7f8c5438', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-02 18:25:28.474823+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '9483a234-eacd-4553-b8a7-ed10e541ec83', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-02 19:24:28.391145+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '1d56172e-1c84-4fad-9249-a2e6d7c2b6b8', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-02 19:24:28.394919+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'b5bab290-f902-4c2a-b074-5444ad8f320d', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-02 20:06:57.625107+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '39480ffa-82b1-429f-9ad4-9273c59232ea', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-02 21:05:56.892984+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '03cc71d2-45c7-46c3-8115-dc6f12a4b539', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-02 21:05:56.899744+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '07a2d6df-10b7-4a2e-a63a-93ead5da6660', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-03 13:42:00.957231+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '7cd09a4b-3e44-4026-9e89-d407f0d537c5', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-03 13:42:00.96603+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '86b647df-8df4-48a6-a7f2-c9efccb2efde', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-03 14:25:10.318082+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '3b243cbc-ae23-4a7f-a0d4-2b8d618a3286', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-03 14:44:28.675393+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '9e04dfa3-bf3b-41c9-8888-ed3541e107d6', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-03 14:44:28.67804+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '0090dd91-e918-4d19-8734-83fba0245e12', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-03 14:52:28.940041+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '0238eab3-7fe2-4ee1-a0a6-140a9f75a137', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-03 15:30:47.659704+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'cc446e8a-3e5b-4dc0-bfb5-ec6482db2e9d', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-03 18:24:29.738432+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '54c86736-2958-48a9-9e8b-cbe3942980f5', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-03 18:24:29.750399+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '30e019d7-902f-4e97-ae86-155cc32f1c56', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-03 18:24:43.164648+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '8b37a978-8d79-436b-9d0f-3a08c1af1d03', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-03 19:23:43.459845+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '2273dce1-e3ce-47c6-bf9c-45a33f114a4d', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-03 19:23:43.467117+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '10c44fdf-e5f9-4b23-878c-e589253c0ae0', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-03 19:36:25.400925+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '489a37c4-a09c-4fee-a583-74b2d9d6b3bf', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-03 19:56:28.228146+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '5af439e4-8b04-433a-ae94-316b88d43a48', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-03 20:18:11.60884+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '0accfbd6-7f6a-426f-904e-c241e34e146e', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-06 13:30:04.267614+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '33be00ac-7331-482c-b3ac-9260b3a9f7c5', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-06 13:30:04.276403+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'a5e863da-d7a5-4f2e-806f-e9e57927fb7e', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-06 13:30:19.983142+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '38241d6d-fb8f-4854-b506-daa88a39cf3a', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-06 14:27:44.655154+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '516eacd9-739b-465d-be17-ca8415a7770a', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-06 14:29:19.876508+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '233de15c-f5b6-4b4d-a5e1-b3d883981cf0', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-06 14:29:19.881172+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '70842ede-e2e7-4ac9-855e-ebd2760ff65d', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-06 14:31:30.236157+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'bc2c71bf-cb01-464d-b73c-b0e544ecce16', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-06 14:31:47.563151+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'cea936cc-effe-4b85-81f6-f0bf40b909e8', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-06 18:33:42.097199+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '0b504a4f-3058-43c0-b5c9-78bbb8d32a80', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-06 18:33:42.132894+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '615b40c0-a780-42ac-833e-7792466a8e04', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-06 18:39:36.177961+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '01171977-6ab6-476e-9978-b4ee02a08c38', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-06 19:04:23.395351+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '14312646-fb48-4a2b-97f3-dec588557230', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-06 19:04:58.643047+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '0d428ab6-c64c-40d1-9c2f-568d4491c285', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-06 19:20:59.798631+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '9374929f-9875-42b4-8ddd-14579c18e8b8', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-06 19:21:24.380906+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'a96c421d-2039-45a2-ae2e-2264806c94d9', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-06 19:37:41.806938+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'f71da1de-39e8-4161-8a22-9ebec6de962b', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-06 20:19:12.646505+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '0a27e253-c218-4908-9077-2dceb2f8159a', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-06 21:18:12.507275+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '6ef00375-c12c-43ca-96d5-d2580282687a', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-06 21:18:12.510591+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'a57114be-c726-41f1-bed5-ebde9947a90c', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-07 00:28:51.489653+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'fd87cfd3-a7b8-46f3-85ae-696e2303c063', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-07 00:28:51.497258+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '9dd6de17-c48f-43f2-82da-830fd5761361', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-07 00:29:10.844763+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'd419f031-1f96-4420-97ba-71757ef6db1d', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-07 01:28:09.689195+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'dfc527c1-fa21-44e8-a5ad-9a5dcf32f80b', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-07 01:28:09.692229+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '031779c2-033e-4635-8ea4-e49cc9ad7eea', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-07 02:27:09.213774+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '1f2a549d-7805-4c60-a2ba-abeb532ef295', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-07 02:27:09.224933+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '56ccdcda-4b24-411b-8338-8016ae074d50', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-07 12:16:26.128654+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '85f9d9ae-4886-4b04-b9b5-22dbfc1eef66', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-07 12:28:24.077277+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '0166af1d-79b6-4366-84a8-e6ebe7c87260', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-07 14:21:16.150406+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '3a2694d3-fa3d-4c59-baa9-14a128af4754', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-07 14:21:16.179325+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '3e7690f5-57e3-4291-ad66-0186b5a18b98', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-07 14:21:58.71791+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '96b1429a-b288-43d3-b012-34c8ae9549c2', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-07 16:57:24.144826+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '8cbde7b8-e48e-4fe0-b01b-2a81a44c84a4', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-07 16:58:00.308419+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '595f53cc-16e4-4c87-a201-3f9cc4c084b1', '{"action":"logout","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account"}', '2026-07-07 17:27:46.105403+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '44ed3a98-d5de-439e-9681-b1bdc640a7ec', '{"action":"user_signedup","actor_id":"097e8824-e345-46ae-b66d-8fb5452fd3c5","actor_username":"fred@gmail.com","actor_via_sso":false,"log_type":"team","traits":{"provider":"email"}}', '2026-07-07 17:29:01.746049+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '0c9bddde-5985-448f-bfd5-f87a7f119858', '{"action":"login","actor_id":"097e8824-e345-46ae-b66d-8fb5452fd3c5","actor_username":"fred@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-07 17:29:01.779047+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'bb872225-32cc-489c-9dc6-f4816faaf9e6', '{"action":"logout","actor_id":"097e8824-e345-46ae-b66d-8fb5452fd3c5","actor_username":"fred@gmail.com","actor_via_sso":false,"log_type":"account"}', '2026-07-07 17:34:54.892957+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'fd14653f-7879-4ba8-8d6f-1b8a7dcf74ff', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-07 17:35:02.245505+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '0905e698-97d7-4f4d-abea-f95fd9836b38', '{"action":"logout","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account"}', '2026-07-07 17:36:55.463408+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '0eb80819-4e33-49bd-8311-435acb4018e7', '{"action":"login","actor_id":"097e8824-e345-46ae-b66d-8fb5452fd3c5","actor_username":"fred@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-07 17:37:06.441345+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'ed84a40d-01aa-450d-abef-1459a1b2a45b', '{"action":"token_refreshed","actor_id":"097e8824-e345-46ae-b66d-8fb5452fd3c5","actor_username":"fred@gmail.com","actor_via_sso":false,"log_type":"token"}', '2026-07-09 15:47:47.084126+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '4d3eb299-f49a-4f3e-bc09-93fa5b5b5853', '{"action":"token_revoked","actor_id":"097e8824-e345-46ae-b66d-8fb5452fd3c5","actor_username":"fred@gmail.com","actor_via_sso":false,"log_type":"token"}', '2026-07-09 15:47:47.098918+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '3f2a4566-0e52-4ec4-b225-44b93961baf9', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-09 15:48:15.04059+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '31e7e0b7-0c7e-4e61-a005-cbfbab6c9d0c', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-09 16:47:15.57445+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '93b363c3-2a9a-42a0-b8ed-f73bb7361367', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-09 16:47:15.581592+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '39d1ae76-8b45-4d6c-ae44-a2088368e4ae', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-09 17:48:23.529661+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '6c466ef7-7bf9-410b-9f6c-d6b65c547d87', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-09 17:48:23.539172+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '6a4ab5ae-ec1f-4352-835b-f8678aa2a35b', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-09 18:47:23.500634+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'd881cb3e-77d6-4857-9abd-7147aff86712', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-09 18:47:23.50594+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'c1b0ab47-b77e-4482-93f1-a1221b6be988', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-09 23:59:13.808495+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '7b6b5a00-a6a7-4e1d-b52a-7d038cf5d6f4', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-09 23:59:13.823401+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'd712b7d1-38cb-4f2e-ac23-4db7b8dd0f66', '{"action":"token_refreshed","actor_id":"097e8824-e345-46ae-b66d-8fb5452fd3c5","actor_username":"fred@gmail.com","actor_via_sso":false,"log_type":"token"}', '2026-07-10 00:44:37.809598+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '44dcfb5f-f7fa-485e-9f64-da7dc6897702', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-10 00:45:14.910997+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '62775f0d-d3a9-4a6a-a091-c401e0ee36eb', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-10 01:27:52.88721+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '2fff1605-e1ce-4bca-b050-2c2f881d809f', '{"action":"token_refreshed","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-10 11:59:17.849063+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '520e4db6-328e-4546-ae92-0cda912061cf', '{"action":"token_revoked","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"token"}', '2026-07-10 11:59:17.856187+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '3cbfc559-6366-410c-9970-f382ff9db6fb', '{"action":"login","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-10 12:00:10.733151+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', 'a9b83741-47f8-4aed-9fe1-4ec8da333d21', '{"action":"logout","actor_id":"3b3df1db-8109-4414-b451-6b9e22435254","actor_username":"samuel@mey.com","actor_via_sso":false,"log_type":"account"}', '2026-07-10 12:20:19.408249+00', '');
INSERT INTO auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) VALUES ('00000000-0000-0000-0000-000000000000', '26fdf00a-d9a8-409b-98f9-ecaa2ea7de4b', '{"action":"login","actor_id":"097e8824-e345-46ae-b66d-8fb5452fd3c5","actor_username":"fred@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2026-07-10 12:20:30.21526+00', '');


--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '31c15950-da1a-4ff1-8081-66b137691628', 'authenticated', 'authenticated', 'admin@test.com', '$2a$06$PGneklLml6lX8.HtqKb.eO7usk3QcggEHFdfgbkvEpm4HRthIJIna', '2026-06-27 20:09:49.817432+00', NULL, NULL, '2026-06-27 20:09:49.817432+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"name": "Admin User"}', NULL, '2026-06-27 20:09:49.817432+00', '2026-06-27 20:09:49.817432+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '0adb9f86-7d30-4c75-a431-b1f8e116978c', 'authenticated', 'authenticated', 'test@test.com', '$2a$10$vnbTBaiiidQfyv92/LFwaOG8cGjh7eorn15CMuBg6WHj2/jLUvpTO', '2026-06-27 20:41:20.598825+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-06-27 20:41:20.619672+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "0adb9f86-7d30-4c75-a431-b1f8e116978c", "email": "test@test.com", "email_verified": true, "phone_verified": false}', NULL, '2026-06-27 20:41:20.559761+00', '2026-06-27 20:41:20.631343+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '3b3df1db-8109-4414-b451-6b9e22435254', 'authenticated', 'authenticated', 'samuel@mey.com', '$2a$10$Ce1e3SmBUW6/GGfsMqQQVOnokaOlAr65t3bf.XJIzhi4e7A5jTVJm', '2026-05-14 13:27:45.632871+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-07-10 12:00:10.735337+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "3b3df1db-8109-4414-b451-6b9e22435254", "name": "Samuel Parra", "email": "samuel@mey.com", "email_verified": true, "phone_verified": false}', NULL, '2026-05-14 13:27:45.596125+00', '2026-07-10 12:00:10.742739+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '097e8824-e345-46ae-b66d-8fb5452fd3c5', 'authenticated', 'authenticated', 'fred@gmail.com', '$2a$10$jU..9vGKnrwBK6rwhRG5luzSpBVYDIHDMhJm5zfmXGnGLkiEjybk6', '2026-07-07 17:29:01.747345+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-07-10 12:20:30.218024+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "097e8824-e345-46ae-b66d-8fb5452fd3c5", "name": "Fred Parra", "email": "fred@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-07-07 17:29:01.695602+00', '2026-07-10 12:20:30.225891+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('0adb9f86-7d30-4c75-a431-b1f8e116978c', '0adb9f86-7d30-4c75-a431-b1f8e116978c', '{"sub": "0adb9f86-7d30-4c75-a431-b1f8e116978c", "email": "test@test.com", "email_verified": false, "phone_verified": false}', 'email', '2026-06-27 20:41:20.58925+00', '2026-06-27 20:41:20.589292+00', '2026-06-27 20:41:20.589292+00', 'add6abb7-3a27-4df3-a06a-010cd71aa517');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('3b3df1db-8109-4414-b451-6b9e22435254', '3b3df1db-8109-4414-b451-6b9e22435254', '{"sub": "3b3df1db-8109-4414-b451-6b9e22435254", "name": "Samuel Parra", "email": "samuel@mey.com", "email_verified": false, "phone_verified": false}', 'email', '2026-05-14 13:27:45.612431+00', '2026-05-14 13:27:45.613398+00', '2026-05-14 13:27:45.613398+00', '48b77e38-0452-4e1a-b3dc-6373632add56');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('097e8824-e345-46ae-b66d-8fb5452fd3c5', '097e8824-e345-46ae-b66d-8fb5452fd3c5', '{"sub": "097e8824-e345-46ae-b66d-8fb5452fd3c5", "name": "Fred Parra", "email": "fred@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-07-07 17:29:01.735647+00', '2026-07-07 17:29:01.73577+00', '2026-07-07 17:29:01.73577+00', '8a3f5873-594c-41f4-a197-6b4a4729043a');


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('2ff59c84-aede-48c3-bb7e-ef857bce4ac6', '0adb9f86-7d30-4c75-a431-b1f8e116978c', '2026-06-27 20:41:20.619961+00', '2026-06-27 20:41:20.619961+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT; Windows NT 10.0; es-VE) WindowsPowerShell/5.1.26100.8655', '172.19.0.1', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('cb20ee79-4d3e-443e-b41b-bfacad9a0e61', '097e8824-e345-46ae-b66d-8fb5452fd3c5', '2026-07-07 17:37:06.442591+00', '2026-07-10 00:44:37.826971+00', NULL, 'aal1', NULL, '2026-07-10 00:44:37.826802', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36', '172.19.0.1', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('b224cad9-1084-4ef8-bcd0-ad3af9d18fdd', '097e8824-e345-46ae-b66d-8fb5452fd3c5', '2026-07-10 12:20:30.218204+00', '2026-07-10 12:20:30.218204+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '172.19.0.1', NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('2ff59c84-aede-48c3-bb7e-ef857bce4ac6', '2026-06-27 20:41:20.632824+00', '2026-06-27 20:41:20.632824+00', 'password', '8d7120ed-78f6-422b-af03-25f6d1226b05');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('cb20ee79-4d3e-443e-b41b-bfacad9a0e61', '2026-07-07 17:37:06.448707+00', '2026-07-07 17:37:06.448707+00', 'password', 'cdd7d893-19dd-4928-afbf-4834d42f53ba');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('b224cad9-1084-4ef8-bcd0-ad3af9d18fdd', '2026-07-10 12:20:30.227221+00', '2026-07-10 12:20:30.227221+00', 'password', '1b49d745-9d4b-4807-91a6-cb750e2e97c3');


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 1, '2h76l63a2zgw', '0adb9f86-7d30-4c75-a431-b1f8e116978c', false, '2026-06-27 20:41:20.626903+00', '2026-06-27 20:41:20.626903+00', NULL, '2ff59c84-aede-48c3-bb7e-ef857bce4ac6');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 68, 'yp6ej35aso2z', '097e8824-e345-46ae-b66d-8fb5452fd3c5', true, '2026-07-07 17:37:06.444484+00', '2026-07-09 15:47:47.100694+00', NULL, 'cb20ee79-4d3e-443e-b41b-bfacad9a0e61');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 69, 'bvf6evvmo7vr', '097e8824-e345-46ae-b66d-8fb5452fd3c5', false, '2026-07-09 15:47:47.112868+00', '2026-07-09 15:47:47.112868+00', 'yp6ej35aso2z', 'cb20ee79-4d3e-443e-b41b-bfacad9a0e61');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 79, 'eue7yzwvlcun', '097e8824-e345-46ae-b66d-8fb5452fd3c5', false, '2026-07-10 12:20:30.222142+00', '2026-07-10 12:20:30.222142+00', NULL, 'b224cad9-1084-4ef8-bcd0-ad3af9d18fdd');


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.schema_migrations (version) VALUES ('20171026211738');
INSERT INTO auth.schema_migrations (version) VALUES ('20171026211808');
INSERT INTO auth.schema_migrations (version) VALUES ('20171026211834');
INSERT INTO auth.schema_migrations (version) VALUES ('20180103212743');
INSERT INTO auth.schema_migrations (version) VALUES ('20180108183307');
INSERT INTO auth.schema_migrations (version) VALUES ('20180119214651');
INSERT INTO auth.schema_migrations (version) VALUES ('20180125194653');
INSERT INTO auth.schema_migrations (version) VALUES ('00');
INSERT INTO auth.schema_migrations (version) VALUES ('20210710035447');
INSERT INTO auth.schema_migrations (version) VALUES ('20210722035447');
INSERT INTO auth.schema_migrations (version) VALUES ('20210730183235');
INSERT INTO auth.schema_migrations (version) VALUES ('20210909172000');
INSERT INTO auth.schema_migrations (version) VALUES ('20210927181326');
INSERT INTO auth.schema_migrations (version) VALUES ('20211122151130');
INSERT INTO auth.schema_migrations (version) VALUES ('20211124214934');
INSERT INTO auth.schema_migrations (version) VALUES ('20211202183645');
INSERT INTO auth.schema_migrations (version) VALUES ('20220114185221');
INSERT INTO auth.schema_migrations (version) VALUES ('20220114185340');
INSERT INTO auth.schema_migrations (version) VALUES ('20220224000811');
INSERT INTO auth.schema_migrations (version) VALUES ('20220323170000');
INSERT INTO auth.schema_migrations (version) VALUES ('20220429102000');
INSERT INTO auth.schema_migrations (version) VALUES ('20220531120530');
INSERT INTO auth.schema_migrations (version) VALUES ('20220614074223');
INSERT INTO auth.schema_migrations (version) VALUES ('20220811173540');
INSERT INTO auth.schema_migrations (version) VALUES ('20221003041349');
INSERT INTO auth.schema_migrations (version) VALUES ('20221003041400');
INSERT INTO auth.schema_migrations (version) VALUES ('20221011041400');
INSERT INTO auth.schema_migrations (version) VALUES ('20221020193600');
INSERT INTO auth.schema_migrations (version) VALUES ('20221021073300');
INSERT INTO auth.schema_migrations (version) VALUES ('20221021082433');
INSERT INTO auth.schema_migrations (version) VALUES ('20221027105023');
INSERT INTO auth.schema_migrations (version) VALUES ('20221114143122');
INSERT INTO auth.schema_migrations (version) VALUES ('20221114143410');
INSERT INTO auth.schema_migrations (version) VALUES ('20221125140132');
INSERT INTO auth.schema_migrations (version) VALUES ('20221208132122');
INSERT INTO auth.schema_migrations (version) VALUES ('20221215195500');
INSERT INTO auth.schema_migrations (version) VALUES ('20221215195800');
INSERT INTO auth.schema_migrations (version) VALUES ('20221215195900');
INSERT INTO auth.schema_migrations (version) VALUES ('20230116124310');
INSERT INTO auth.schema_migrations (version) VALUES ('20230116124412');
INSERT INTO auth.schema_migrations (version) VALUES ('20230131181311');
INSERT INTO auth.schema_migrations (version) VALUES ('20230322519590');
INSERT INTO auth.schema_migrations (version) VALUES ('20230402418590');
INSERT INTO auth.schema_migrations (version) VALUES ('20230411005111');
INSERT INTO auth.schema_migrations (version) VALUES ('20230508135423');
INSERT INTO auth.schema_migrations (version) VALUES ('20230523124323');
INSERT INTO auth.schema_migrations (version) VALUES ('20230818113222');
INSERT INTO auth.schema_migrations (version) VALUES ('20230914180801');
INSERT INTO auth.schema_migrations (version) VALUES ('20231027141322');
INSERT INTO auth.schema_migrations (version) VALUES ('20231114161723');
INSERT INTO auth.schema_migrations (version) VALUES ('20231117164230');
INSERT INTO auth.schema_migrations (version) VALUES ('20240115144230');
INSERT INTO auth.schema_migrations (version) VALUES ('20240214120130');
INSERT INTO auth.schema_migrations (version) VALUES ('20240306115329');
INSERT INTO auth.schema_migrations (version) VALUES ('20240314092811');
INSERT INTO auth.schema_migrations (version) VALUES ('20240427152123');
INSERT INTO auth.schema_migrations (version) VALUES ('20240612123726');
INSERT INTO auth.schema_migrations (version) VALUES ('20240729123726');
INSERT INTO auth.schema_migrations (version) VALUES ('20240802193726');
INSERT INTO auth.schema_migrations (version) VALUES ('20240806073726');
INSERT INTO auth.schema_migrations (version) VALUES ('20241009103726');
INSERT INTO auth.schema_migrations (version) VALUES ('20250717082212');
INSERT INTO auth.schema_migrations (version) VALUES ('20250731150234');
INSERT INTO auth.schema_migrations (version) VALUES ('20250804100000');
INSERT INTO auth.schema_migrations (version) VALUES ('20250901200500');
INSERT INTO auth.schema_migrations (version) VALUES ('20250903112500');
INSERT INTO auth.schema_migrations (version) VALUES ('20250904133000');
INSERT INTO auth.schema_migrations (version) VALUES ('20250925093508');
INSERT INTO auth.schema_migrations (version) VALUES ('20251007112900');
INSERT INTO auth.schema_migrations (version) VALUES ('20251104100000');
INSERT INTO auth.schema_migrations (version) VALUES ('20251111201300');
INSERT INTO auth.schema_migrations (version) VALUES ('20251201000000');
INSERT INTO auth.schema_migrations (version) VALUES ('20260115000000');
INSERT INTO auth.schema_migrations (version) VALUES ('20260121000000');
INSERT INTO auth.schema_migrations (version) VALUES ('20260219120000');
INSERT INTO auth.schema_migrations (version) VALUES ('20260302000000');


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: webauthn_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: quotes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('165d916f-0f29-43a6-9780-f6937abb48eb', NULL, 'Project Golf 2 - Baseline Test', 'Accepted', '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00', NULL, 0, '2026-06-27', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('41d5ac82-e7bd-4f91-bdb3-a00027296792', NULL, 'Project Golf 2 - Baseline Test', 'Accepted', '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00', NULL, 0, '2026-05-14', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('969bc610-e72e-493d-8cdf-516d355a1650', NULL, 'Ejemplo Cotizacion', 'draft', '2026-03-06 03:22:45.641975+00', '2026-03-05 23:17:38.731+00', NULL, 0, '2026-03-09', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('ea9d39e0-5191-4288-b9a3-1696d87812dd', NULL, 'Prueba 2', 'draft', '2026-03-09 18:35:43.987783+00', '2026-03-09 17:05:44.696+00', 'Mey', 341488.74375, '2026-03-09', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('c9ec01d4-77f5-49f0-b608-2653c420bbe0', NULL, 'Golfe Proyects', 'draft', '2026-03-09 14:50:58.243276+00', '2026-03-09 18:56:57.337+00', '', 2621509.55, '2026-03-09', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('c8120856-74fa-403f-8d1a-04c8c7fb8000', NULL, 'Prueba 3', 'draft', '2026-03-12 14:36:45.495131+00', '2026-03-12 16:29:38.196+00', 'Golf Team', 1645974.875, '2026-03-12', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('9aa91162-6d4a-4136-9d01-c0ea31cdeed0', NULL, '3 Bridges', 'draft', '2026-03-30 17:56:37.562061+00', '2026-03-30 14:06:57.967+00', 'Landscapes UnlimetedLLC', 104500, '2026-03-30', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('237b459b-f70e-4bc1-9472-ab2a32392180', NULL, 'Prueba estimacion 1', 'draft', '2026-04-07 18:09:56.534442+00', '2026-04-07 18:09:56.534442+00', 'Fred', 582326.976, '2026-04-07', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('2a80a936-90fb-42ed-b750-abd59078d297', NULL, 'Prueba Estimacion con materiales', 'draft', '2026-04-14 18:24:32.921115+00', '2026-04-14 18:24:32.921115+00', 'Claudio Ortiz', 263708.63306666666, '2026-04-14', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('0b200319-ae70-4d5b-a385-2c8e271e2622', NULL, 'kettle forge', 'draft', '2026-04-14 19:37:49.606769+00', '2026-04-14 19:37:49.606769+00', 'harritage', 32291153.37861111, '2026-04-14', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('aa5e6f53-a783-4946-954e-4876f31ebc5e', NULL, 'Prueba de Servicios', 'draft', '2026-04-17 22:39:37.3095+00', '2026-04-17 22:39:37.3095+00', 'Noel', 173086.40616296296, '2026-04-17', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('db229097-0c24-4e7e-82cd-b7d97295f448', NULL, 'TPC Deer Run', 'draft', '2026-04-24 17:46:49.588831+00', '2026-04-24 17:46:49.588831+00', 'Landscapes Unlimited LLC', 56925, '2026-04-24', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('56e06c10-d0c0-46a5-a7ff-84422bd62187', NULL, '3 Bridges', 'draft', '2026-04-27 18:39:35.529878+00', '2026-04-27 14:06:27.851+00', 'Haritage', 22421450.52125, '2026-04-27', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('e80c65fe-942e-414d-9bd8-167288e80b5e', NULL, 'Prueba de creaci??n de proyecto', 'accepted', '2026-05-11 13:05:50.994026+00', '2026-05-11 13:05:50.994026+00', 'Fred Parra', 629342.4072, '2026-05-11', NULL, 'standard', NULL);
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('71148da8-e936-4909-9563-75ea918f7fde', NULL, 'Prueba para copiar', 'draft', '2026-06-27 21:29:08.949145+00', '2026-06-27 21:29:08.949145+00', 'Fred Parra', 337954.05, '2026-06-27', NULL, 'standard', 'Barrancas');
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('b938c145-e02c-4d89-9183-40326f32fca0', NULL, 'Prueba para Precio Estipulado', 'draft', '2026-06-29 13:39:54.421889+00', '2026-06-29 13:39:54.421889+00', 'Fred Parra', 297227.3472, '2026-06-29', NULL, 'standard', 'Barrancas');
INSERT INTO public.quotes (id, company_id, title, status, created_at, updated_at, client_name, total_amount, quote_date, project_name, quote_type, client_address) VALUES ('20e33a63-15d1-42e9-a95b-b65db4bc8f45', NULL, 'Prueba para Precio Estipulado', 'accepted', '2026-06-29 13:40:04.290389+00', '2026-06-29 15:20:49.008+00', 'Fred Parra', 449530.35008, '2026-06-29', NULL, 'standard', 'Barrancas');


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.projects (id, quote_id, title, client_name, status, start_date, end_date, created_at, updated_at, project_type, calculation_metadata, hourly_operating_cost) VALUES ('4c03065f-a79b-4086-bbcf-4b3e5c5467dd', '165d916f-0f29-43a6-9780-f6937abb48eb', 'Execution Golf 2 - Phase 1', NULL, 'active', NULL, NULL, '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00', 'standard', NULL, 0);
INSERT INTO public.projects (id, quote_id, title, client_name, status, start_date, end_date, created_at, updated_at, project_type, calculation_metadata, hourly_operating_cost) VALUES ('cdf91e17-ce7a-47bd-bb79-4f49cee6bd67', '41d5ac82-e7bd-4f91-bdb3-a00027296792', 'Execution Golf 2 - Phase 1', NULL, 'active', NULL, NULL, '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00', 'standard', NULL, 0);
INSERT INTO public.projects (id, quote_id, title, client_name, status, start_date, end_date, created_at, updated_at, project_type, calculation_metadata, hourly_operating_cost) VALUES ('37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '56e06c10-d0c0-46a5-a7ff-84422bd62187', '3 Bridges', 'Haritage', 'active', '2026-05-08 19:15:18.094+00', NULL, '2026-05-08 23:15:18.974226+00', '2026-05-08 23:15:18.974226+00', 'standard', NULL, 0);
INSERT INTO public.projects (id, quote_id, title, client_name, status, start_date, end_date, created_at, updated_at, project_type, calculation_metadata, hourly_operating_cost) VALUES ('24d128a9-5591-4cd2-b218-2fdfc93bb18f', 'e80c65fe-942e-414d-9bd8-167288e80b5e', 'Prueba de creaci??n de proyecto', 'Fred Parra', 'active', '2026-05-11 09:07:06.39+00', NULL, '2026-05-11 13:07:06.713533+00', '2026-05-11 13:07:06.713533+00', 'standard', NULL, 0);
INSERT INTO public.projects (id, quote_id, title, client_name, status, start_date, end_date, created_at, updated_at, project_type, calculation_metadata, hourly_operating_cost) VALUES ('1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '20e33a63-15d1-42e9-a95b-b65db4bc8f45', 'Prueba para Precio Estipulado', 'Fred Parra', 'active', '2026-06-29 15:29:37.528+00', NULL, '2026-06-29 19:29:37.535874+00', '2026-06-29 19:29:37.535874+00', 'standard', '{"baseline_total_days": 134, "baseline_latest_version": 1, "baseline_daily_burn_rate": 1500, "baseline_resources_count": 11, "baseline_latest_snapshot_id": "6674ca52-ae77-48e5-8264-67f4d4935587"}', 0);


--
-- Data for Name: change_orders; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: quote_services; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('d132154f-655b-4ad1-8321-9e4a7fae0706', '165d916f-0f29-43a6-9780-f6937abb48eb', NULL, 'BULK EXCAVATION', 'CY', 5000, 0, 0, '2026-06-27 20:07:25.641769+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('fa87a96a-9271-4ed4-a57a-148bd61f0a4e', '165d916f-0f29-43a6-9780-f6937abb48eb', NULL, 'FINISH GRADING', 'SQFT', 45000, 0, 0, '2026-06-27 20:07:25.641769+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('2f92671f-af81-4417-97a4-cd7b26adc409', '41d5ac82-e7bd-4f91-bdb3-a00027296792', NULL, 'BULK EXCAVATION', 'CY', 5000, 0, 0, '2026-05-14 13:17:03.392091+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('6e17c7fb-31b7-48b2-ad78-76efc53ab08c', '41d5ac82-e7bd-4f91-bdb3-a00027296792', NULL, 'FINISH GRADING', 'SQFT', 45000, 0, 0, '2026-05-14 13:17:03.392091+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('e512195f-c8cd-4bd1-848d-90c30c46f5ad', '969bc610-e72e-493d-8cdf-516d355a1650', NULL, 'CUT-FILL TOP LOADING', 'CYS', 674000, 0, 14, '2026-03-06 03:23:19.217178+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('d02c020a-a0de-48e9-8682-fafe05f47509', 'ea9d39e0-5191-4288-b9a3-1696d87812dd', NULL, 'CUT-FILL TOP LOADING', 'Qty', 674000, 10, 35, '2026-03-09 23:05:46.924385+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('552cbb0a-55d8-4307-a807-82b9548c50e7', 'ea9d39e0-5191-4288-b9a3-1696d87812dd', NULL, 'CLEARING', 'AC', 45, 10, 35, '2026-03-09 23:05:48.395862+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('5380d563-d6ac-4231-976c-1579d74b4b52', 'c9ec01d4-77f5-49f0-b608-2653c420bbe0', NULL, 'CUT-FILL TOP LOADING', 'CYS', 674000, 10, 25, '2026-03-10 00:56:58.586984+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('e5fbd5bb-1139-4335-8f23-b3a12d105520', 'c9ec01d4-77f5-49f0-b608-2653c420bbe0', NULL, 'CLEARING', 'AC', 5000, 10, 35, '2026-03-10 00:57:00.469011+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('81513bd9-fae6-4e55-97c8-152f788409e5', 'c9ec01d4-77f5-49f0-b608-2653c420bbe0', NULL, 'Rough Shaping', 'EA', 20, 10, 35, '2026-03-10 00:57:00.821677+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('ee7f93a9-96c4-4335-a021-eb5372fa064a', 'c8120856-74fa-403f-8d1a-04c8c7fb8000', NULL, 'CUT-FILL TOP LOADING', 'Qty', 700000, 0, 15, '2026-03-12 20:29:39.79247+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('f513c717-b218-4e7b-b6c1-f8d00660e746', '9aa91162-6d4a-4136-9d01-c0ea31cdeed0', NULL, 'CUT-FILL TOP LOADING', 'CY', 125000, 0, 0, '2026-03-30 19:06:58.62335+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('fad4ea94-045a-454a-8789-b5709e388ac1', '237b459b-f70e-4bc1-9472-ab2a32392180', NULL, 'GREEN CONSTRUCTION', 'SF', 800000, 2, 12, '2026-04-07 18:09:56.697186+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('ac7593d3-c6f5-47ef-bb8b-730c75c421e5', '2a80a936-90fb-42ed-b750-abd59078d297', NULL, 'GREEN CONSTRUCTION', 'SF', 16000, 2, 12, '2026-04-14 18:24:33.252958+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('de2a4696-52de-4318-bbfb-002fe45e0ae0', '0b200319-ae70-4d5b-a385-2c8e271e2622', NULL, 'GREEN CONSTRUCTION', 'SF', 201560, 10, 30, '2026-04-14 19:37:49.858333+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('ef62baf8-66a5-4d4b-8d2f-60ed6aad0e77', '0b200319-ae70-4d5b-a385-2c8e271e2622', NULL, 'BUNKER CONSTRUCTION', 'sf', 180000, 10, 30, '2026-04-14 19:37:52.250472+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('22055dba-b9af-426f-89de-bedd62f536b1', '0b200319-ae70-4d5b-a385-2c8e271e2622', NULL, 'Tee Costruction', 'sf', 120000, 10, 30, '2026-04-14 19:37:52.461744+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', '0b200319-ae70-4d5b-a385-2c8e271e2622', NULL, 'CLEARING', 'AC', 45, 10, 30, '2026-04-14 19:37:53.329261+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('61de1e83-a430-4de6-8ef6-5b851d489e1d', '0b200319-ae70-4d5b-a385-2c8e271e2622', NULL, 'drainage', 'lf', 15000, 10, 30, '2026-04-14 19:37:55.450837+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', 'aa5e6f53-a783-4946-954e-4876f31ebc5e', NULL, 'GREEN CONSTRUCTION', 'SF', 20000, 2, 12, '2026-04-17 22:39:38.011369+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('0f1ecc41-859d-4927-933a-2367702cd35d', 'db229097-0c24-4e7e-82cd-b7d97295f448', NULL, 'Mobilization', 'EA', 1, 0, 0, '2026-04-24 17:46:53.164858+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('5cffaaa8-5e06-4a4f-86f0-daee894497b4', 'db229097-0c24-4e7e-82cd-b7d97295f448', NULL, 'Shaper B+', 'EA', 1, 0, 0, '2026-04-24 17:46:54.840906+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('6e3b35aa-aa09-498b-9357-f9c44c1512e9', 'db229097-0c24-4e7e-82cd-b7d97295f448', NULL, 'Multi Equipment Operator', 'EA', 3, 0, 0, '2026-04-24 17:46:59.537317+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('b6335445-15c1-4d64-8f71-a88855e2f5b2', 'db229097-0c24-4e7e-82cd-b7d97295f448', NULL, 'Skill Labor', 'EA', 1, 0, 0, '2026-04-24 17:47:02.774726+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('fe54b6a4-4dd7-447b-8f5b-b3a4eef18d45', '56e06c10-d0c0-46a5-a7ff-84422bd62187', NULL, '4" solid pipe', 'LF', 20000, 10, 35, '2026-04-27 19:06:28.540857+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', '56e06c10-d0c0-46a5-a7ff-84422bd62187', NULL, 'CUT-FILL TOP LOADING', 'CY', 500000, 10, 35, '2026-04-27 19:06:29.718178+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('d6ff2701-828c-4cb6-b693-05268ade668c', '56e06c10-d0c0-46a5-a7ff-84422bd62187', NULL, 'GREEN CONSTRUCTION', 'SF', 201000, 10, 35, '2026-04-27 19:06:31.025913+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('584281a5-4f51-4722-9f88-95d94842b380', '56e06c10-d0c0-46a5-a7ff-84422bd62187', NULL, 'CLEARING', 'AC', 55, 10, 35, '2026-04-27 19:06:32.396651+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('3d08f851-b15e-46a6-bf68-ac823bce1f45', 'e80c65fe-942e-414d-9bd8-167288e80b5e', NULL, 'TOPSOIL MANAGEMENT', 'CY', 500000, 2, 4, '2026-05-11 13:05:51.277616+00', 0, 0, 0, 0, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('be323d33-83cc-40f2-b3e9-e514b3ad72e3', '71148da8-e936-4909-9563-75ea918f7fde', NULL, 'TOPSOIL STRIPPING', 'CY', 200000, 2, 5, '2026-06-27 21:29:09.006867+00', 0, 0, 0, 291672.92699999997, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('1153213f-84f6-4776-885f-9e8cab1f1ca8', '71148da8-e936-4909-9563-75ea918f7fde', NULL, 'CLEARING', 'AC', 80, 2, 5, '2026-06-27 21:29:09.136185+00', 0, 0, 0, 46281.123, 0);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', '20e33a63-15d1-42e9-a95b-b65db4bc8f45', NULL, 'TOPSOIL MANAGEMENT', 'CY', 250000, 2.2, 3.3, '2026-06-29 16:28:58.666873+00', 0, 0, 0, 419867.50883, 420000);
INSERT INTO public.quote_services (id, quote_id, service_number, name, unit_of_measure, quantity, overhead_percentage, profit_percentage, created_at, fuel_price, per_diem_cost, labor_hours_per_month, direct_cost, target_price) VALUES ('c55610c7-86d5-497a-9513-97b9a315c49f', '20e33a63-15d1-42e9-a95b-b65db4bc8f45', NULL, 'CLEARING', 'AC', 80, 3, 5, '2026-06-29 19:20:49.278431+00', 0, 0, 0, 29662.84125, 0);


--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('e56d2c29-274e-46b8-ab09-6038ab56c7fc', 'TOPSOIL STRIPPING', 'CY', '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('9a0cef8d-58b9-481d-9dbf-a3f2b1d5dde2', 'BULK EXCAVATION', 'CY', '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('52501a4e-7c59-4cc9-982a-a953300cdef0', 'FINISH GRADING', 'SQFT', '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('e82aac58-3cb5-4273-ae77-cb87700999ad', 'SUBGRADE PREP', 'SQFT', '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('e7b2e2c5-4d34-431a-b6c1-b4db9e38bd13', 'BASE COURSE', 'CY', '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('dd661c15-1693-4091-a108-7ea4bc19f1b8', 'TOPSOIL STRIPPING', 'CY', '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('5855e5ac-013c-46b4-8efd-f0ab533ef854', 'BULK EXCAVATION', 'CY', '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('97b21602-1dc0-4684-aa9f-ae5772a22bdd', 'FINISH GRADING', 'SQFT', '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('fea56364-4b5a-4470-86cf-dd55a0814151', 'SUBGRADE PREP', 'SQFT', '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('3239afc7-e942-482e-a095-18911c9695e7', 'BASE COURSE', 'CY', '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('7ff1fd8a-485b-4eea-bf27-077726ef6bbd', 'CLEARING', 'AC', '2026-03-09 18:08:12.150698+00', '2026-03-09 18:08:37.050806+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('d6aadd2b-b0f1-4570-8597-a590d7ef1eb5', 'GREEN CONSTRUCTION', 'SF', '2026-03-30 19:12:05.778948+00', '2026-03-30 19:12:05.778948+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('2502bcd5-bf39-48bc-b003-9a0f973405f9', 'BUNKER CONSTRUCTION', 'SF', '2026-03-30 19:13:17.045904+00', '2026-03-30 19:13:17.045904+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('fba9ad4f-880d-477d-b7c8-0f791b04fcc4', 'CUT-FILL TOP LOADING', 'CY', '2026-03-09 18:06:30.690952+00', '2026-04-14 18:22:13.174688+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('09af766a-7110-4d29-acca-f49eb364617f', 'SELECTCLEARING', 'AC', '2026-05-05 02:14:17.604424+00', '2026-05-05 02:14:17.604424+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('bdcc0905-6040-4561-8c99-9bd7bd8dbcd2', 'TOPSOIL MANAGEMENT', 'CY', '2026-05-05 02:14:56.426834+00', '2026-05-05 02:14:56.426834+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('e9621dbc-11ab-45d8-bd6a-ef20aa2faca6', 'SILT FENCE', 'LF', '2026-05-05 02:15:34.725215+00', '2026-05-05 02:15:34.725215+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('9ac9166c-7392-4a13-84a8-f36882846d88', 'CONSTRUCTION ENTRANCE', 'EA', '2026-05-05 02:16:41.119738+00', '2026-05-05 02:16:41.119738+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44', 'EROSION DUST PREVENTION', 'MO', '2026-05-05 02:18:06.896262+00', '2026-05-05 02:18:06.896262+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('f745f151-0412-4f79-b674-586887eb7af3', 'EROSION CONTROL REMOVAL', 'LS', '2026-05-05 02:18:54.476903+00', '2026-05-05 02:18:54.476903+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('ce3b3780-a114-4240-a7a3-c87f264a6ea0', 'FINE SHAPING', 'LS', '2026-05-05 02:19:41.191723+00', '2026-05-05 02:19:41.191723+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('16557aec-e8bb-4041-9b9a-b48150b1211d', 'TEE CONSTRUCTION', 'SF', '2026-05-05 02:20:16.333272+00', '2026-05-05 02:20:16.333272+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('5c5fafd4-5bd0-4cdd-8206-47ed4ae20136', 'BUNKER CONCRETE BUNKER LINER', 'SF', '2026-05-05 02:21:09.989+00', '2026-05-05 02:21:09.989+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('ab8649a9-4741-42b3-9f9a-57953ccb5787', 'CARTPATH PREP', 'LF', '2026-05-05 02:21:32.177177+00', '2026-05-05 02:21:32.177177+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('2c6dbea5-e9b0-4268-b0d9-80dc6e47242d', 'FINE GRADING & SEEDBED PREP', 'AC', '2026-05-05 02:22:20.988559+00', '2026-05-05 02:22:20.988559+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('6f5994cb-d499-41ba-9b11-fa90a67f5b7c', 'SEEDBED PREP ROUGH PREP, NO HAND WORK', 'AC', '2026-05-05 02:23:29.856173+00', '2026-05-05 02:23:29.856173+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('7d778fdf-3ea7-4693-a957-949b651869dc', 'ROCK PICKING', 'AC', '2026-05-05 02:24:06.140311+00', '2026-05-05 02:24:06.140311+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('8bf3ea6e-94ab-4991-b8cf-99f1a54734f7', 'NATIVE FINE FESCUE -MECHANICAL SEEDING', 'AC', '2026-05-05 02:25:47.971704+00', '2026-05-05 02:25:47.971704+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('d623a601-ff3a-4fd3-a928-90fb397c9806', 'NATIVE FESCUE -5 ACRES- SEED & EC BLANKET', 'SF', '2026-05-05 02:27:15.486327+00', '2026-05-05 02:27:15.486327+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('d19dc987-5732-467c-be8e-65b7e97338d1', 'EROSION CONTROL  BLANKET', 'AC', '2026-05-05 02:28:01.476212+00', '2026-05-05 02:28:01.476212+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('d56ff5ce-10c6-4133-addb-6049586c1b7e', 'EROSION CONTROL MAINTENANCE', 'LS', '2026-05-05 02:28:52.065674+00', '2026-05-05 02:28:52.065674+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('ee85328b-30fc-40b3-921c-e45508374379', 'MOBILIZATION', 'LS', '2026-05-05 02:29:31.140356+00', '2026-05-05 02:29:31.140356+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('1751df49-b41e-4ba0-8319-cec920b373fb', '4" SOLID PIPE', 'LF', '2026-05-05 02:31:11.928044+00', '2026-05-05 02:31:11.928044+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('042b71dd-2910-49ed-b75b-5f955649f27a', '6" SOLID PIPE', 'LF', '2026-05-05 02:31:35.002224+00', '2026-05-05 02:31:35.002224+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('896f786e-baee-4230-91f9-ffce2f4c9e8f', '8" SOLID PIPE', 'LF', '2026-05-05 02:31:52.872686+00', '2026-05-05 02:31:52.872686+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('e92da126-0e97-4934-b87d-405d5a65eb0e', '12" SOLID PIPE', 'LF', '2026-05-05 02:32:20.845678+00', '2026-05-05 02:32:20.845678+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('fa947699-257b-4033-8bc5-599db0f25308', '24" SOLID PIPE', 'LF', '2026-05-05 02:33:06.540123+00', '2026-05-05 02:33:06.540123+00');
INSERT INTO public.services (id, description, unit, created_at, updated_at) VALUES ('62b12119-f67b-4d5e-944e-6980c560208a', '12" PIPE RISER', 'LF', '2026-05-05 02:33:46.437594+00', '2026-05-05 02:33:46.437594+00');


--
-- Data for Name: change_order_details; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.customers (id, name, ein, address, phone, email, created_at, updated_at) VALUES ('60b276ab-ff50-4432-b7e0-03c5a02452a6', 'Fred Parra', '11-22344', 'Barrancas', '(434) 321-1111', 'fred@parra.ve', '2026-05-11 13:02:26.32688+00', '2026-05-11 13:02:26.32688+00');


--
-- Data for Name: daily_reports; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.daily_reports (id, project_id, report_date, supervisor_id, weather_condition, general_notes, evidence_photos, signature_data, status, approved_by, approved_at, created_at, updated_at, day_type, non_working_reason, stopped_at) VALUES ('0189c613-db85-44ce-a4e2-a76a35df777f', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '2026-07-01', '3b3df1db-8109-4414-b451-6b9e22435254', 'Sunny', NULL, '[]', NULL, 'approved', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-09 20:28:20.398+00', '2026-06-29 19:46:33.454956+00', '2026-07-10 00:28:20.412892+00', 'working', NULL, NULL);
INSERT INTO public.daily_reports (id, project_id, report_date, supervisor_id, weather_condition, general_notes, evidence_photos, signature_data, status, approved_by, approved_at, created_at, updated_at, day_type, non_working_reason, stopped_at) VALUES ('2b42c06c-c5b7-4a98-91db-e12128dfe7f4', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '2026-07-02', '3b3df1db-8109-4414-b451-6b9e22435254', 'Stormy', 'Condiciones de lluvia impiden trabajar, se presentaron los trabajadores y se considera pagar una hora de trabajo.', '[]', NULL, 'approved', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-09 20:28:21.881+00', '2026-07-02 19:32:31.816562+00', '2026-07-10 00:28:21.894395+00', 'working', 'Condiciones clim├íticas adversas', NULL);
INSERT INTO public.daily_reports (id, project_id, report_date, supervisor_id, weather_condition, general_notes, evidence_photos, signature_data, status, approved_by, approved_at, created_at, updated_at, day_type, non_working_reason, stopped_at) VALUES ('342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '2026-07-03', '3b3df1db-8109-4414-b451-6b9e22435254', 'Rainy', 'Pruebas', '[]', NULL, 'approved', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-09 20:28:23.163+00', '2026-07-02 20:57:08.330383+00', '2026-07-10 00:28:23.176252+00', 'partial', 'Adverse weather', '12:00:00');
INSERT INTO public.daily_reports (id, project_id, report_date, supervisor_id, weather_condition, general_notes, evidence_photos, signature_data, status, approved_by, approved_at, created_at, updated_at, day_type, non_working_reason, stopped_at) VALUES ('b759434d-c175-41ae-be7b-0d7b7b52185d', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '2026-07-04', '3b3df1db-8109-4414-b451-6b9e22435254', 'Cloudy', NULL, '[]', NULL, 'approved', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-09 20:28:24.461+00', '2026-07-03 18:25:14.596254+00', '2026-07-10 00:28:24.471855+00', 'working', NULL, NULL);
INSERT INTO public.daily_reports (id, project_id, report_date, supervisor_id, weather_condition, general_notes, evidence_photos, signature_data, status, approved_by, approved_at, created_at, updated_at, day_type, non_working_reason, stopped_at) VALUES ('722a010f-3fa9-486f-804a-9e90b9fa5203', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '2026-07-05', '3b3df1db-8109-4414-b451-6b9e22435254', 'Stormy', '12356', '[]', NULL, 'approved', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-09 20:28:25.465+00', '2026-07-03 18:47:42.870381+00', '2026-07-10 00:28:25.483755+00', 'non_working', 'Adverse weather', NULL);
INSERT INTO public.daily_reports (id, project_id, report_date, supervisor_id, weather_condition, general_notes, evidence_photos, signature_data, status, approved_by, approved_at, created_at, updated_at, day_type, non_working_reason, stopped_at) VALUES ('c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '2026-07-06', '3b3df1db-8109-4414-b451-6b9e22435254', 'Sunny', NULL, '[]', NULL, 'approved', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-09 20:28:28.144+00', '2026-07-06 13:49:03.981987+00', '2026-07-10 00:28:28.154223+00', 'working', NULL, NULL);
INSERT INTO public.daily_reports (id, project_id, report_date, supervisor_id, weather_condition, general_notes, evidence_photos, signature_data, status, approved_by, approved_at, created_at, updated_at, day_type, non_working_reason, stopped_at) VALUES ('d346d701-41a2-434b-bfe3-4b8b55f846bd', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '2026-04-07', '3b3df1db-8109-4414-b451-6b9e22435254', NULL, NULL, '[]', NULL, 'draft', NULL, NULL, '2026-07-10 00:28:43.246465+00', '2026-07-10 00:28:43.246465+00', 'working', NULL, NULL);
INSERT INTO public.daily_reports (id, project_id, report_date, supervisor_id, weather_condition, general_notes, evidence_photos, signature_data, status, approved_by, approved_at, created_at, updated_at, day_type, non_working_reason, stopped_at) VALUES ('f8dad96e-2e84-4b69-b3a9-793fef3a007a', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '2026-07-07', '3b3df1db-8109-4414-b451-6b9e22435254', 'Cloudy', NULL, '[]', NULL, 'approved', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-09 20:53:24.325+00', '2026-07-10 00:29:40.718907+00', '2026-07-10 00:53:24.32971+00', 'working', NULL, NULL);


--
-- Data for Name: deviation_reasons; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.deviation_reasons (id, code, description, category, created_at) VALUES ('8012ba30-0660-447c-a2f4-78eb19d65ec5', 'ABSENCE', 'Ausencia justificada del trabajador', 'labor', '2026-06-27 20:07:25.187129+00');
INSERT INTO public.deviation_reasons (id, code, description, category, created_at) VALUES ('f349e58f-1b0c-42f4-8c6d-c168989439ef', 'SUBSTITUTION', 'Sustituci├│n por enfermedad o emergencia', 'labor', '2026-06-27 20:07:25.187129+00');
INSERT INTO public.deviation_reasons (id, code, description, category, created_at) VALUES ('30b102a6-b6fc-4abc-80bc-eed957bec290', 'REINFORCEMENT', 'Refuerzo por retraso en la tarea', 'labor', '2026-06-27 20:07:25.187129+00');
INSERT INTO public.deviation_reasons (id, code, description, category, created_at) VALUES ('35938d3e-9df7-4225-9537-5c4761d62c56', 'BREAKDOWN', 'Aver├¡a de m├íquina titular', 'machinery', '2026-06-27 20:07:25.187129+00');
INSERT INTO public.deviation_reasons (id, code, description, category, created_at) VALUES ('07224961-078f-43c1-806a-74e24c2b6b97', 'TERRAIN', 'Condici├│n de terreno imprevista', 'machinery', '2026-06-27 20:07:25.187129+00');
INSERT INTO public.deviation_reasons (id, code, description, category, created_at) VALUES ('6d8d7850-8c86-416b-9442-5a414a74751e', 'URGENCY', 'Urgencia solicitada por el cliente', 'general', '2026-06-27 20:07:25.187129+00');
INSERT INTO public.deviation_reasons (id, code, description, category, created_at) VALUES ('e4d6d6a4-2001-453a-99a9-c607372a74a4', 'WEATHER', 'Condiciones clim├íticas adversas', 'general', '2026-06-27 20:07:25.187129+00');
INSERT INTO public.deviation_reasons (id, code, description, category, created_at) VALUES ('9866efeb-7149-4cf4-af42-f9c6647bbd7b', 'OTHER', 'Otro motivo (especificar en notas)', 'general', '2026-06-27 20:07:25.187129+00');


--
-- Data for Name: incident_categories; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.incident_categories (id, code, name, icon, color, active, created_at) VALUES ('a34c8109-b63b-4302-8c49-3cf938357112', 'MACHINERY_BREAKDOWN', 'Machinery Breakdown', 'engineering', '#EF4444', true, '2026-06-27 20:07:25.498297+00');
INSERT INTO public.incident_categories (id, code, name, icon, color, active, created_at) VALUES ('ef02ed19-8d99-4a5a-88d7-b80238a45ca5', 'INSTRUMENT_DAMAGE', 'Instrument Damage', 'build', '#F97316', true, '2026-06-27 20:07:25.498297+00');
INSERT INTO public.incident_categories (id, code, name, icon, color, active, created_at) VALUES ('ce9c8a98-1ec3-4f21-8da9-789761546a17', 'WORKER_ABSENCE', 'Worker Absence', 'person_off', '#EAB308', true, '2026-06-27 20:07:25.498297+00');
INSERT INTO public.incident_categories (id, code, name, icon, color, active, created_at) VALUES ('b50b883b-aa49-4436-a3b4-b12e13e17a2d', 'WORKER_REPLACEMENT', 'Worker Replacement', 'swap_horiz', '#A855F7', true, '2026-06-27 20:07:25.498297+00');
INSERT INTO public.incident_categories (id, code, name, icon, color, active, created_at) VALUES ('cdb6cfd1-f418-479d-974d-37a6ecf3840f', 'MATERIAL_SHORTAGE', 'Material Shortage', 'inventory_2', '#3B82F6', true, '2026-06-27 20:07:25.498297+00');
INSERT INTO public.incident_categories (id, code, name, icon, color, active, created_at) VALUES ('36f0c0a3-7d29-4a8a-b734-17e13dfae711', 'MATERIAL_DAMAGE', 'Material Damage', 'broken_image', '#EF4444', true, '2026-06-27 20:07:25.498297+00');
INSERT INTO public.incident_categories (id, code, name, icon, color, active, created_at) VALUES ('b7e36301-91f6-4973-80b4-8c5abc983b80', 'WEATHER', 'Weather Contingency', 'thunderstorm', '#06B6D4', true, '2026-06-27 20:07:25.498297+00');
INSERT INTO public.incident_categories (id, code, name, icon, color, active, created_at) VALUES ('7c71e11d-dfb6-486f-9a8e-fa4da23b3d4c', 'ACCIDENT', 'Accident', 'local_hospital', '#DC2626', true, '2026-06-27 20:07:25.498297+00');
INSERT INTO public.incident_categories (id, code, name, icon, color, active, created_at) VALUES ('34028deb-9ae5-4341-ac85-7cbd0c6d6941', 'QUALITY_DEFECT', 'Quality Defect', 'report_problem', '#F97316', true, '2026-06-27 20:07:25.498297+00');
INSERT INTO public.incident_categories (id, code, name, icon, color, active, created_at) VALUES ('4d56273b-277d-417c-bf42-c68f26174f57', 'OTHER', 'Other', 'warning_amber', '#64748B', true, '2026-06-27 20:07:25.498297+00');


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.profiles (id, name, email, phone, role, avatar_url, updated_at) VALUES ('0adb9f86-7d30-4c75-a431-b1f8e116978c', NULL, 'test@test.com', NULL, 'Employee', NULL, '2026-06-27 20:41:20.557317+00');
INSERT INTO public.profiles (id, name, email, phone, role, avatar_url, updated_at) VALUES ('3b3df1db-8109-4414-b451-6b9e22435254', 'Samuel Parra', 'samuel@mey.com', NULL, 'Admin', NULL, '2026-07-06 10:04:29.499+00');
INSERT INTO public.profiles (id, name, email, phone, role, avatar_url, updated_at) VALUES ('31c15950-da1a-4ff1-8081-66b137691628', 'Admin User', 'admin@test.com', NULL, 'Admin', NULL, '2026-07-07 13:27:17.136+00');
INSERT INTO public.profiles (id, name, email, phone, role, avatar_url, updated_at) VALUES ('097e8824-e345-46ae-b66d-8fb5452fd3c5', 'Fred Parra', 'fred@gmail.com', NULL, 'Admin', NULL, '2026-07-07 13:29:21.96+00');


--
-- Data for Name: incidents; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.incidents (id, project_id, daily_report_id, category_id, title, description, priority, status, started_at, ended_at, cost_impact, actual_expenses, resolution_notes, reported_by, reported_at, resolved_by, resolved_at, evidence_photos, created_at, updated_at) VALUES ('4bc83533-5e77-418e-bf20-2b8f38b468ab', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', NULL, 'ce9c8a98-1ec3-4f21-8da9-789761546a17', 'Falta de trabajador', 'No se report├│ al trabajo', 'medium', 'open', '2026-06-29 23:30:00+00', NULL, NULL, 500, NULL, '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 20:00:24.763067+00', NULL, NULL, '[]', '2026-06-29 20:00:24.763067+00', '2026-06-29 20:00:24.763067+00');
INSERT INTO public.incidents (id, project_id, daily_report_id, category_id, title, description, priority, status, started_at, ended_at, cost_impact, actual_expenses, resolution_notes, reported_by, reported_at, resolved_by, resolved_at, evidence_photos, created_at, updated_at) VALUES ('12b54a60-ffb5-40cb-86ba-79b52a57320b', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', NULL, 'ce9c8a98-1ec3-4f21-8da9-789761546a17', 'Enfermedad', 'Tiene resfriado', 'medium', 'in_progress', '2026-06-30 11:30:00+00', NULL, NULL, 200, NULL, '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-30 16:29:34.987777+00', NULL, NULL, '[]', '2026-06-30 16:29:34.987777+00', '2026-06-30 16:33:28.016394+00');
INSERT INTO public.incidents (id, project_id, daily_report_id, category_id, title, description, priority, status, started_at, ended_at, cost_impact, actual_expenses, resolution_notes, reported_by, reported_at, resolved_by, resolved_at, evidence_photos, created_at, updated_at) VALUES ('628bb0d3-b1e3-428e-a2f0-5a201bae3c56', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', NULL, 'a34c8109-b63b-4302-8c49-3cf938357112', '12345', '54321', 'medium', 'closed', '2026-06-30 11:30:00+00', '2026-06-30 16:36:46.675+00', 444.1888585069444463750, 200, 'Todo solventado
---
123213213', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-30 16:35:43.049853+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-30 16:36:46.676+00', '[]', '2026-06-30 16:35:43.049853+00', '2026-07-02 17:43:41.595591+00');
INSERT INTO public.incidents (id, project_id, daily_report_id, category_id, title, description, priority, status, started_at, ended_at, cost_impact, actual_expenses, resolution_notes, reported_by, reported_at, resolved_by, resolved_at, evidence_photos, created_at, updated_at) VALUES ('f16308a9-f270-4f29-9c97-c142472ff812', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', NULL, 'a34c8109-b63b-4302-8c49-3cf938357112', '123456', 'Alerta', 'high', 'resolved', '2026-07-02 11:30:00+00', '2026-07-02 17:02:30.785+00', 309.99917664930555431250, 200, 'Reparaciones realizadas', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-02 15:28:56.604974+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-02 17:02:30.785+00', '["http://127.0.0.1:8001/storage/v1/object/public/incident-photos/1e5fe596-050c-4f95-b8c3-dd632bb0e45e/2be8a245-a9a3-4e0d-8ec1-386a8cf620f6.png"]', '2026-07-02 15:28:56.604974+00', '2026-07-02 17:43:41.595591+00');
INSERT INTO public.incidents (id, project_id, daily_report_id, category_id, title, description, priority, status, started_at, ended_at, cost_impact, actual_expenses, resolution_notes, reported_by, reported_at, resolved_by, resolved_at, evidence_photos, created_at, updated_at) VALUES ('834ed5d3-e77f-446d-a6aa-22aaa0fe7716', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', NULL, 'a34c8109-b63b-4302-8c49-3cf938357112', 'Recalentada', 'Se requiere reparacion', 'medium', 'closed', '2026-06-29 11:40:00+00', '2026-07-02 17:04:22.168+00', 6724.6599569444444463750, 0, '123
---
123', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:54:17.357064+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-02 17:04:22.168+00', '[]', '2026-06-29 19:54:17.357064+00', '2026-07-02 17:43:41.595591+00');


--
-- Data for Name: incident_actions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.incident_actions (id, incident_id, description, assigned_to, due_date, status, completed_at, created_at) VALUES ('f8a2f70d-abf7-4c96-8a57-cc402e04f571', '834ed5d3-e77f-446d-a6aa-22aaa0fe7716', 'Presupuesto', NULL, NULL, 'completed', '2026-06-29 19:55:02.413+00', '2026-06-29 19:54:32.36914+00');
INSERT INTO public.incident_actions (id, incident_id, description, assigned_to, due_date, status, completed_at, created_at) VALUES ('8fc797f8-839d-4f7b-9501-113afe5ecb27', '4bc83533-5e77-418e-bf20-2b8f38b468ab', 'Buscar el suplente', NULL, NULL, 'pending', NULL, '2026-06-29 20:00:56.429116+00');
INSERT INTO public.incident_actions (id, incident_id, description, assigned_to, due_date, status, completed_at, created_at) VALUES ('1a5eb760-5cb5-4d07-b395-46eccfe6a206', '12b54a60-ffb5-40cb-86ba-79b52a57320b', 'Buscar suplente', NULL, NULL, 'pending', NULL, '2026-06-30 16:33:22.235449+00');
INSERT INTO public.incident_actions (id, incident_id, description, assigned_to, due_date, status, completed_at, created_at) VALUES ('e2bae25c-b25a-476b-afa7-d7ebd98dc0b1', '12b54a60-ffb5-40cb-86ba-79b52a57320b', 'Activar maquinaria', NULL, NULL, 'pending', NULL, '2026-06-30 16:33:49.894201+00');
INSERT INTO public.incident_actions (id, incident_id, description, assigned_to, due_date, status, completed_at, created_at) VALUES ('ac41dd69-2ded-4b1a-a289-1ea6b7ff0f33', '628bb0d3-b1e3-428e-a2f0-5a201bae3c56', 'A', NULL, NULL, 'completed', '2026-06-30 16:36:31.089+00', '2026-06-30 16:36:15.570803+00');
INSERT INTO public.incident_actions (id, incident_id, description, assigned_to, due_date, status, completed_at, created_at) VALUES ('62262a5c-1086-4564-9158-d1babf323336', '628bb0d3-b1e3-428e-a2f0-5a201bae3c56', 'B', NULL, NULL, 'completed', '2026-06-30 16:36:33.317+00', '2026-06-30 16:36:21.306735+00');
INSERT INTO public.incident_actions (id, incident_id, description, assigned_to, due_date, status, completed_at, created_at) VALUES ('d96db3eb-3428-42f1-8d64-1b06029a7a9e', 'f16308a9-f270-4f29-9c97-c142472ff812', 'Compra de repuesto', NULL, '2026-07-02', 'completed', '2026-07-02 17:02:14.946+00', '2026-07-02 17:01:38.786415+00');
INSERT INTO public.incident_actions (id, incident_id, description, assigned_to, due_date, status, completed_at, created_at) VALUES ('382eb36c-a0c7-4906-a1cc-1d49badc9db7', 'f16308a9-f270-4f29-9c97-c142472ff812', 'Reparaci├│n', NULL, '2026-07-02', 'completed', '2026-07-02 17:02:17.673+00', '2026-07-02 17:02:02.690524+00');
INSERT INTO public.incident_actions (id, incident_id, description, assigned_to, due_date, status, completed_at, created_at) VALUES ('8865c036-3aef-45ec-b449-4b76c253c211', '834ed5d3-e77f-446d-a6aa-22aaa0fe7716', 'Compra de repuesto', NULL, NULL, 'completed', '2026-07-02 17:04:12.634+00', '2026-06-29 19:54:45.822422+00');
INSERT INTO public.incident_actions (id, incident_id, description, assigned_to, due_date, status, completed_at, created_at) VALUES ('382f375f-9d88-4d42-b42b-867312ec3e9c', '834ed5d3-e77f-446d-a6aa-22aaa0fe7716', 'Instalar repuesto', NULL, NULL, 'completed', '2026-07-02 17:04:14.913+00', '2026-06-29 19:54:56.643841+00');


--
-- Data for Name: labor_roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('8b4a08aa-acce-4ccb-9362-db4d6069c35b', 'SUPERVISOR', 45.00, '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('1ca8c1ea-a315-4ab2-9926-d8b1b602ddc9', 'Excavator Operator', 35.00, '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('ad5ab34c-c885-4bdb-a755-b429dcc6e8dc', 'Truck Operator', 28.00, '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('e3412aeb-877e-4d3d-83fc-253d4a08f935', 'Shaper Class B', 32.00, '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('d462a586-e118-4da1-8b84-d7a9fbe8a687', 'Scraper operator', 34.00, '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('7f70497d-c6d6-44c7-b214-29ea0c3c4c9c', 'Laborer', 20.00, '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('4f2b630b-8cc4-49be-ac5e-77be4b103d3a', 'SUPERVISOR', 45.00, '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('c1aa1bb2-a2ab-40b8-9219-d2898153758e', 'Excavator Operator', 35.00, '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('fe520365-87c8-4a42-ae6a-9c2e989f1ef0', 'Shaper Class B', 32.00, '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('e5092833-858d-4912-9815-89ada6e99a22', 'Laborer', 20.00, '2026-05-14 13:17:03.392091+00', '2026-05-14 13:17:03.392091+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('15584be2-4d8f-4748-96ba-5684a56a7d74', 'TRUCK OPERATOR', 39, '2026-03-09 18:00:46.516704+00', '2026-05-05 02:35:18.727393+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('626d5dab-2200-4680-961f-f71069db1b94', 'CONSTRUCTION SUPERINTENDENT', 65, '2026-03-09 17:59:37.6127+00', '2026-05-05 02:36:10.381341+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('e5046e4c-eb0c-45cb-8efd-6377a8d24ea1', 'SKILL LABOR', 35, '2026-04-24 17:44:09.129335+00', '2026-05-05 02:36:34.928976+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('da849f21-3558-472d-b242-01cb999dd1d5', 'SHAPER CLASS B', 55, '2026-03-09 17:59:54.115408+00', '2026-05-05 02:36:58.657214+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('5b896dcb-f674-4e43-81b3-d66c23a928c1', 'SCRAPER OPERATOR', 39, '2026-03-09 18:00:06.688295+00', '2026-05-05 02:37:29.559587+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('91da0a23-74b8-4c6d-a546-363c123a18e0', 'LABOR', 30, '2026-04-14 19:02:27.165683+00', '2026-05-05 02:38:34.73764+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('453c550e-47f4-4f27-ad81-f9f5b71bc3ba', 'BUNKER SHAPER', 42, '2026-03-09 18:00:28.655183+00', '2026-05-05 02:39:33.577967+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('a6c2c442-0aab-47d1-8dd6-fbd27d96c73a', 'GREEN SHAPER', 42, '2026-04-24 17:44:59.4694+00', '2026-05-05 02:40:19.95771+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('36694df2-8660-4b05-914f-1aaab0928209', 'TEE SHAPER', 42, '2026-05-05 02:40:50.390438+00', '2026-05-05 02:40:50.390438+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('832d504d-40a5-447e-8efc-5ba3f9f51456', 'FAIRWAY FINISHER', 42, '2026-05-05 02:41:19.018029+00', '2026-05-05 02:41:19.018029+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('933d77e9-f844-4716-a48e-ff1e01c043ab', 'SHAPER CLASS A', 65, '2026-05-05 02:41:52.707573+00', '2026-05-05 02:41:52.707573+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('c0c2df7e-0a1c-4fe1-9f5d-fe2ab5f9042c', 'SHAPER CLASS C', 45, '2026-05-05 02:42:19.467635+00', '2026-05-05 02:42:19.467635+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('5719ff0e-f9a6-417f-bf23-46c82a5b09d6', 'CONSTRUCTION FORMAN', 55, '2026-05-05 02:43:30.401888+00', '2026-05-05 02:43:30.401888+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('d26ac548-d73a-45a9-9f70-6ba979729ed6', 'IRRIGATION FORMAN', 55, '2026-05-05 02:43:52.371018+00', '2026-05-05 02:43:52.371018+00', 0);
INSERT INTO public.labor_roles (id, description, hourly_rate, created_at, updated_at, internal_cost_rate) VALUES ('118fae00-7497-491c-a8fe-cb7ca7468535', 'IRRIGATION SUPERINTENDENT', 65, '2026-05-05 02:44:22.568849+00', '2026-05-05 02:44:22.568849+00', 0);


--
-- Data for Name: logistics_equipment; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.logistics_equipment (id, description, photo_url, associated_service_ids, applications, created_at, updated_at) VALUES ('abd60776-f441-45d9-b571-e514259db597', 'JUPING JACK', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782761204171_Juping_Jack.png', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4}', '{}', '2026-05-14 14:49:01.597819+00', '2026-05-14 14:49:01.597819+00');
INSERT INTO public.logistics_equipment (id, description, photo_url, associated_service_ids, applications, created_at, updated_at) VALUES ('34e7cedc-52b1-4f4a-9f52-45d5110867fe', 'GPS-Topcon', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782761216786_GPS-Topcon.png', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd}', '{Medidas,Compactar,Calibraci??n}', '2026-05-14 14:50:44.862481+00', '2026-05-14 14:50:44.862481+00');
INSERT INTO public.logistics_equipment (id, description, photo_url, associated_service_ids, applications, created_at, updated_at) VALUES ('077301f2-f8d2-4ab4-9dd5-e4534bce0494', '500 GL FUEL TANK', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782761229725_500_GL_FUEL_TANK.png', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd}', '{Administrativo}', '2026-05-14 14:51:40.332473+00', '2026-05-14 14:51:40.332473+00');
INSERT INTO public.logistics_equipment (id, description, photo_url, associated_service_ids, applications, created_at, updated_at) VALUES ('9c6fc789-ee0a-4fb7-9c2d-28333ed4730f', '40" CONEX STORAGE', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782761243414_40_conex_Office_-_Storage.png', '{7ff1fd8a-485b-4eea-bf27-077726ef6bbd,fba9ad4f-880d-477d-b7c8-0f791b04fcc4}', '{Administrativo}', '2026-05-14 14:52:35.432856+00', '2026-05-14 14:52:35.432856+00');
INSERT INTO public.logistics_equipment (id, description, photo_url, associated_service_ids, applications, created_at, updated_at) VALUES ('74367a52-059f-4593-9aad-e15eb47120aa', '40" CONEX OFFICE', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782761255297_40_conex_Office_-_Storage.png', '{7ff1fd8a-485b-4eea-bf27-077726ef6bbd,fba9ad4f-880d-477d-b7c8-0f791b04fcc4}', '{Administrativo}', '2026-05-14 14:53:20.364765+00', '2026-05-14 14:53:20.364765+00');


--
-- Data for Name: machinery; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('5148000c-8dc2-4860-b7ae-9d4e15bf574d', 'Excavator CAT 320', NULL, NULL, '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00', 0, 60, 5.5, 1.5, 60, 0, 'hauling', '{}', '{}', 'support', NULL);
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('1344d54d-ee21-443f-a34a-98ea8b3cd553', 'Dump Truck 14yd', NULL, NULL, '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00', 0, 60, 8.0, 14.0, 15, 0, 'hauling', '{}', '{}', 'support', NULL);
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('a3a30063-b058-4697-acc2-a0c7957d6077', 'Dozer D6', NULL, NULL, '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00', 0, 60, 6.0, 0, 0, 0, 'hauling', '{}', '{}', 'support', NULL);
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('a74da537-ef66-45da-8090-6b62bb7e1053', 'Roller CS56', NULL, NULL, '2026-06-27 20:07:25.641769+00', '2026-06-27 20:07:25.641769+00', 0, 60, 4.0, 0, 0, 0, 'hauling', '{}', '{}', 'support', NULL);
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('5d00a2a7-737f-46c8-9868-d89e18abc81b', 'POLARIS RANGER 1000', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782760899074_Polaris_Ranger.png', '11', '2026-05-14 14:20:44.617701+00', '2026-06-29 19:21:39.49868+00', 0, 60, 2, 0, 0, 0, 'support', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,e9621dbc-11ab-45d8-bd6a-ef20aa2faca6,09af766a-7110-4d29-acca-f49eb364617f,6f5994cb-d499-41ba-9b11-fa90a67f5b7c,7d778fdf-3ea7-4693-a957-949b651869dc,ce3b3780-a114-4240-a7a3-c87f264a6ea0,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d}', '{}', 'support', '626d5dab-2200-4680-961f-f71069db1b94');
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('e2d5d145-b6fc-45d2-a9b4-05146c72e968', 'JD 950 S/U BLADE  4WAY', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782760917469_JD_1050-950-850.png', '30', '2026-05-14 14:24:17.239812+00', '2026-06-29 19:21:57.608005+00', 0, 60, 7, 6, 1, 6, 'production', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,f745f151-0412-4f79-b674-586887eb7af3,9ac9166c-7392-4a13-84a8-f36882846d88,2502bcd5-bf39-48bc-b003-9a0f973405f9,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,5855e5ac-013c-46b4-8efd-f0ab533ef854}', '{}', 'support', 'da849f21-3558-472d-b242-01cb999dd1d5');
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('bfc62521-5d00-47af-9a6d-8b35961f0c83', 'JD 950 L W/GPS', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782760936891_JD_1050-950-850.png', '30', '2026-05-14 14:25:37.951535+00', '2026-06-29 19:22:17.00778+00', 0, 60, 7, 8, 1, 8, 'production', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,6f5994cb-d499-41ba-9b11-fa90a67f5b7c,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,ce3b3780-a114-4240-a7a3-c87f264a6ea0,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d,f745f151-0412-4f79-b674-586887eb7af3,d19dc987-5732-467c-be8e-65b7e97338d1,2502bcd5-bf39-48bc-b003-9a0f973405f9,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,5855e5ac-013c-46b4-8efd-f0ab533ef854}', '{}', 'support', 'fe520365-87c8-4a42-ae6a-9c2e989f1ef0');
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('797daaee-8b31-4ae5-a35b-3606b22dc83e', 'JD 850 L/P LPG W/GPS NO RIPPER', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782760957758_JD_1050-950-850.png', '30', '2026-05-14 14:27:49.578806+00', '2026-06-29 19:22:37.860063+00', 0, 60, 7, 9, 1, 9, 'production', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,6f5994cb-d499-41ba-9b11-fa90a67f5b7c,09af766a-7110-4d29-acca-f49eb364617f,7d778fdf-3ea7-4693-a957-949b651869dc,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,2502bcd5-bf39-48bc-b003-9a0f973405f9}', '{}', 'support', 'da849f21-3558-472d-b242-01cb999dd1d5');
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('960c1212-4f45-42ac-8966-6fa405fe3fbf', 'JD 750L - LPG W/GPS', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782760973194_JD_750L.png', '39', '2026-05-14 14:29:43.836244+00', '2026-06-29 19:22:53.341014+00', 0, 60, 5, 0, 0, 0, 'production', '{dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,09af766a-7110-4d29-acca-f49eb364617f,8bf3ea6e-94ab-4991-b8cf-99f1a54734f7,7d778fdf-3ea7-4693-a957-949b651869dc,97b21602-1dc0-4684-aa9f-ae5772a22bdd,9ac9166c-7392-4a13-84a8-f36882846d88,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,d19dc987-5732-467c-be8e-65b7e97338d1,fba9ad4f-880d-477d-b7c8-0f791b04fcc4,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,2502bcd5-bf39-48bc-b003-9a0f973405f9,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,1751df49-b41e-4ba0-8319-cec920b373fb,042b71dd-2910-49ed-b75b-5f955649f27a,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a}', '{}', 'support', 'da849f21-3558-472d-b242-01cb999dd1d5');
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('456999ca-274f-406d-9896-d8236d1de8a3', 'JD 510P - W/GPS.', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782760990300_JD_510-350.png', '30', '2026-05-14 14:31:24.117903+00', '2026-06-29 19:23:10.531978+00', 0, 60, 7, 1, 1, 1, 'production', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,7d778fdf-3ea7-4693-a957-949b651869dc,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,97b21602-1dc0-4684-aa9f-ae5772a22bdd,ce3b3780-a114-4240-a7a3-c87f264a6ea0,2502bcd5-bf39-48bc-b003-9a0f973405f9,ab8649a9-4741-42b3-9f9a-57953ccb5787,5855e5ac-013c-46b4-8efd-f0ab533ef854,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,3239afc7-e942-482e-a095-18911c9695e7,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a}', '{}', 'support', '453c550e-47f4-4f27-ad81-f9f5b71bc3ba');
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('17b24170-9b73-4c7b-928f-74f4692a741b', 'JD 460P', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782761008692_JD_460-410.png', '30', '2026-05-14 14:32:53.618498+00', '2026-06-29 19:23:28.831213+00', 0, 60, 7, 30, 60, 1800, 'hauling', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,f745f151-0412-4f79-b674-586887eb7af3,d56ff5ce-10c6-4133-addb-6049586c1b7e,d19dc987-5732-467c-be8e-65b7e97338d1,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,9ac9166c-7392-4a13-84a8-f36882846d88,ab8649a9-4741-42b3-9f9a-57953ccb5787,2502bcd5-bf39-48bc-b003-9a0f973405f9,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,896f786e-baee-4230-91f9-ffce2f4c9e8f,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a}', '{}', 'support', '15584be2-4d8f-4748-96ba-5684a56a7d74');
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('1a298eed-6ae3-4c40-828a-01f16160a32a', 'JD 410P', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782761029236_JD_460-410.png', '30', '2026-05-14 13:44:33.520912+00', '2026-06-29 19:23:49.373292+00', 0, 60, 7, 30, 60, 1800, 'hauling', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,e9621dbc-11ab-45d8-bd6a-ef20aa2faca6,09af766a-7110-4d29-acca-f49eb364617f,6f5994cb-d499-41ba-9b11-fa90a67f5b7c,7d778fdf-3ea7-4693-a957-949b651869dc,8bf3ea6e-94ab-4991-b8cf-99f1a54734f7,d623a601-ff3a-4fd3-a928-90fb397c9806,ee85328b-30fc-40b3-921c-e45508374379,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,97b21602-1dc0-4684-aa9f-ae5772a22bdd,ce3b3780-a114-4240-a7a3-c87f264a6ea0,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,f745f151-0412-4f79-b674-586887eb7af3,d56ff5ce-10c6-4133-addb-6049586c1b7e,d19dc987-5732-467c-be8e-65b7e97338d1,9ac9166c-7392-4a13-84a8-f36882846d88,ab8649a9-4741-42b3-9f9a-57953ccb5787,2502bcd5-bf39-48bc-b003-9a0f973405f9,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,896f786e-baee-4230-91f9-ffce2f4c9e8f,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a}', '{}', 'support', '15584be2-4d8f-4748-96ba-5684a56a7d74');
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('e4611099-ac80-4013-814f-e42a898dba34', 'JD 350P W/THUMB', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782761110575_JD_510-350.png', '30', '2026-05-14 14:36:05.328293+00', '2026-06-29 19:25:10.852163+00', 0, 60, 7, 1, 1, 1, 'production', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,09af766a-7110-4d29-acca-f49eb364617f,6f5994cb-d499-41ba-9b11-fa90a67f5b7c,7d778fdf-3ea7-4693-a957-949b651869dc,8bf3ea6e-94ab-4991-b8cf-99f1a54734f7,d623a601-ff3a-4fd3-a928-90fb397c9806,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,ce3b3780-a114-4240-a7a3-c87f264a6ea0,97b21602-1dc0-4684-aa9f-ae5772a22bdd,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,f745f151-0412-4f79-b674-586887eb7af3,d56ff5ce-10c6-4133-addb-6049586c1b7e,d19dc987-5732-467c-be8e-65b7e97338d1,ab8649a9-4741-42b3-9f9a-57953ccb5787,9ac9166c-7392-4a13-84a8-f36882846d88,2502bcd5-bf39-48bc-b003-9a0f973405f9,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,896f786e-baee-4230-91f9-ffce2f4c9e8f,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,e9621dbc-11ab-45d8-bd6a-ef20aa2faca6}', '{}', 'support', '453c550e-47f4-4f27-ad81-f9f5b71bc3ba');
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('01276ae3-42a3-4635-a4dc-e312e9ff7e8c', 'JD 1050 S/U 4WAY -W/RIPPER', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782761125215_JD_1050-950-850.png', '30', '2026-05-14 14:37:32.307618+00', '2026-06-29 19:25:25.332333+00', 0, 60, 4, 4, 1, 4, 'production', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,f745f151-0412-4f79-b674-586887eb7af3,d56ff5ce-10c6-4133-addb-6049586c1b7e,d19dc987-5732-467c-be8e-65b7e97338d1,9ac9166c-7392-4a13-84a8-f36882846d88,ab8649a9-4741-42b3-9f9a-57953ccb5787,2502bcd5-bf39-48bc-b003-9a0f973405f9,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,896f786e-baee-4230-91f9-ffce2f4c9e8f,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a}', '{}', 'support', 'da849f21-3558-472d-b242-01cb999dd1d5');
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('4fbf20c3-f135-4e66-8830-86e31464501f', 'Cat K-teck 1236 scraper', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782761161347_Cat_K-Teck_1236_scraper.png', '33', '2026-05-14 13:44:33.520912+00', '2026-06-29 19:26:01.472237+00', 0, 60, 7, 30, 80, 2400, 'hauling', '{fba9ad4f-880d-477d-b7c8-0f791b04fcc4,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,5855e5ac-013c-46b4-8efd-f0ab533ef854}', '{}', 'support', '5b896dcb-f674-4e43-81b3-d66c23a928c1');
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('f6fa790b-b2c5-43a8-8a0c-2cb76d3a7a50', 'TOYOTA TUNDRA PLATEUM', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782760878647_Toyota_Tundra_Plateum.png', '11', '2026-05-14 14:17:00.33496+00', '2026-06-29 19:21:21.758632+00', 0, 60, 2, 0, 0, 0, 'support', '{dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,16557aec-e8bb-4041-9b9a-b48150b1211d,fea56364-4b5a-4470-86cf-dd55a0814151,e9621dbc-11ab-45d8-bd6a-ef20aa2faca6,09af766a-7110-4d29-acca-f49eb364617f,6f5994cb-d499-41ba-9b11-fa90a67f5b7c,7d778fdf-3ea7-4693-a957-949b651869dc,8bf3ea6e-94ab-4991-b8cf-99f1a54734f7,d623a601-ff3a-4fd3-a928-90fb397c9806,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,97b21602-1dc0-4684-aa9f-ae5772a22bdd,ce3b3780-a114-4240-a7a3-c87f264a6ea0,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,f745f151-0412-4f79-b674-586887eb7af3,d56ff5ce-10c6-4133-addb-6049586c1b7e,d19dc987-5732-467c-be8e-65b7e97338d1,fba9ad4f-880d-477d-b7c8-0f791b04fcc4,9ac9166c-7392-4a13-84a8-f36882846d88,7ff1fd8a-485b-4eea-bf27-077726ef6bbd,ab8649a9-4741-42b3-9f9a-57953ccb5787,2502bcd5-bf39-48bc-b003-9a0f973405f9,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,896f786e-baee-4230-91f9-ffce2f4c9e8f,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a}', '{}', 'support', '626d5dab-2200-4680-961f-f71069db1b94');
INSERT INTO public.machinery (id, description, photo_url, capacity, created_at, updated_at, delivery_cost, default_trips_per_day, fuel_gallons, capacity_yards, trips_per_day, yards_per_day, machinery_type, associated_service_ids, applications, machinery_category, operator_role_id) VALUES ('3aa3bbe9-61cc-4220-8168-c519f4c050c3', '5-6 Yd Dump Truck', 'http://127.0.0.1:8001/storage/v1/object/public/equipment/1782761184367_5-6_Yd_Dump_Truck.png', '11', '2026-05-14 13:17:03.392091+00', '2026-06-29 19:26:24.472455+00', 0, 60, 4, 10, 80, 800, 'hauling', '{7ff1fd8a-485b-4eea-bf27-077726ef6bbd,fba9ad4f-880d-477d-b7c8-0f791b04fcc4,dd661c15-1693-4091-a108-7ea4bc19f1b8,bdcc0905-6040-4561-8c99-9bd7bd8dbcd2,fea56364-4b5a-4470-86cf-dd55a0814151,e9621dbc-11ab-45d8-bd6a-ef20aa2faca6,16557aec-e8bb-4041-9b9a-b48150b1211d,7d778fdf-3ea7-4693-a957-949b651869dc,8bf3ea6e-94ab-4991-b8cf-99f1a54734f7,d623a601-ff3a-4fd3-a928-90fb397c9806,d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,97b21602-1dc0-4684-aa9f-ae5772a22bdd,ce3b3780-a114-4240-a7a3-c87f264a6ea0,2c6dbea5-e9b0-4268-b0d9-80dc6e47242d,f745f151-0412-4f79-b674-586887eb7af3,a98d1cff-ae02-4eb4-9c6d-5a9e5f49ab44,d19dc987-5732-467c-be8e-65b7e97338d1,9ac9166c-7392-4a13-84a8-f36882846d88,5855e5ac-013c-46b4-8efd-f0ab533ef854,3239afc7-e942-482e-a095-18911c9695e7,896f786e-baee-4230-91f9-ffce2f4c9e8f,042b71dd-2910-49ed-b75b-5f955649f27a,1751df49-b41e-4ba0-8319-cec920b373fb,fa947699-257b-4033-8bc5-599db0f25308,e92da126-0e97-4934-b87d-405d5a65eb0e,62b12119-f67b-4d5e-944e-6980c560208a,5c5fafd4-5bd0-4cdd-8206-47ed4ae20136}', '{}', 'support', '15584be2-4d8f-4748-96ba-5684a56a7d74');


--
-- Data for Name: project_baseline_snapshots; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_baseline_snapshots (id, project_id, version, label, reason, frozen_at, frozen_by, calculation_metadata) VALUES ('6674ca52-ae77-48e5-8264-67f4d4935587', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', 1, 'v1', 'Initial baseline', '2026-06-29 19:46:08.457475+00', '3b3df1db-8109-4414-b451-6b9e22435254', '{"baseline_total_days": 134, "baseline_daily_burn_rate": 1500, "baseline_resources_count": 11}');


--
-- Data for Name: quote_service_machineries; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('caff098a-ef44-4ac4-8e85-dd7fae5cca82', 'ee7f93a9-96c4-4335-a021-eb5372fa064a', 'JD 460P', 3.6, 20000, 4, 7, 5.25, '2026-03-12 20:29:39.929387+00', 300, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('b6b15047-ac49-4acd-986b-26ea9aebd088', 'ee7f93a9-96c4-4335-a021-eb5372fa064a', 'Cat K-teck 1236 scraper', 3.9, 15500, 2, 7, 5.25, '2026-03-12 20:29:40.063514+00', 300, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('2bb4f120-04dd-4af2-8609-d0ddc4663224', 'e512195f-c8cd-4bd1-848d-90c30c46f5ad', 'JD 950 S/U BLADE  4WAY', 1, 15000, 1, 7, 5.25, '2026-03-06 03:23:19.31711+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('1ac07bce-8c40-4615-af8c-e99b620a4ac1', 'e512195f-c8cd-4bd1-848d-90c30c46f5ad', 'JD 850 L/P LPG W/GPS NO RIPPER', 3, 12450, 2, 7, 5.25, '2026-03-06 03:23:19.415659+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('5b4ad0c4-ffac-41a0-83f5-773aedc7090c', 'ee7f93a9-96c4-4335-a021-eb5372fa064a', 'JD 510P - W/GPS.', 3.9, 14000, 4, 7, 5.25, '2026-03-12 20:29:40.194122+00', 600, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('5b5eb10f-0fba-4bd7-9624-cc5db9758ad3', 'ee7f93a9-96c4-4335-a021-eb5372fa064a', 'JD 410P', 3.6, 15000, 2, 7, 5.25, '2026-03-12 20:29:40.339471+00', 700, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('6cbf01c0-a510-4405-a71b-75ff7e480165', 'd02c020a-a0de-48e9-8682-fafe05f47509', 'JD 950 S/U BLADE  4WAY', 1, 10000, 1, 7, 5.25, '2026-03-09 23:05:47.344826+00', 600, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('e77ae83b-efe6-4562-8405-b617532de806', 'd02c020a-a0de-48e9-8682-fafe05f47509', 'JD 750L - LPG W/GPS', 1, 12450, 1, 7, 3.25, '2026-03-09 23:05:47.574723+00', 600, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('200e4bb4-b074-4b3e-8e17-7ecf2cad4e8d', 'f513c717-b218-4e7b-b6c1-f8d00660e746', 'JD 850 L/P LPG W/GPS NO RIPPER', 0.4, 0, 1, 7, 5.25, '2026-03-30 19:06:58.756709+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('506170b3-a2bc-4d1f-88ec-3c47daebc357', 'f513c717-b218-4e7b-b6c1-f8d00660e746', 'JD 510P - W/GPS.', 0.4, 0, 1, 7, 5.25, '2026-03-30 19:06:58.834679+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('3773e8fd-bb6d-4ee0-bd82-edbc2f4315b8', 'f513c717-b218-4e7b-b6c1-f8d00660e746', 'JD 460P', 0.4, 0, 4, 7, 5.25, '2026-03-30 19:06:58.891759+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('221d35ed-9c1f-45ec-9995-599f6df1680e', 'f513c717-b218-4e7b-b6c1-f8d00660e746', 'Cat K-teck 1236 scraper', 0.4, 0, 4, 7, 5.25, '2026-03-30 19:06:58.975063+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('2369572c-2ea3-48d5-9692-90d411847c04', 'fad4ea94-045a-454a-8789-b5709e388ac1', 'JD 460P', 3.8, 0, 4, 7, 5.25, '2026-04-07 18:09:56.831198+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('773e990e-2eb7-4148-bb68-2c2e57f38ae0', 'fad4ea94-045a-454a-8789-b5709e388ac1', 'TOYOTA TUNDRA PLATEUM', 3.8, 0, 1, 2, 5.25, '2026-04-07 18:09:56.961562+00', 0, NULL, true, false, 'JD 460P');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('57e4fc09-162d-4359-942a-fbd77c49e230', 'fad4ea94-045a-454a-8789-b5709e388ac1', 'POLARIS RANGER 1000', 3.8, 0, 1, 2, 5.25, '2026-04-07 18:09:57.083209+00', 0, NULL, true, false, 'JD 460P');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('91c4cc17-2b19-461b-bb8c-73044e2c5010', 'fad4ea94-045a-454a-8789-b5709e388ac1', 'Cat K-teck 1236 scraper', 3.8, 0, 2, 7, 5.25, '2026-04-07 18:09:57.204073+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('10585f4a-b4a5-4d34-9b41-d46f0f0b74d9', 'fad4ea94-045a-454a-8789-b5709e388ac1', 'JD 950 S/U BLADE  4WAY', 3.8, 0, 1, 7, 5.25, '2026-04-07 18:09:57.327779+00', 0, NULL, true, false, 'Cat K-teck 1236 scraper');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('f4c5f799-3373-41b5-8395-8b932d965060', 'fad4ea94-045a-454a-8789-b5709e388ac1', 'JD 510P - W/GPS.', 3.8, 0, 1, 7, 5.25, '2026-04-07 18:09:57.458667+00', 0, NULL, true, false, 'Cat K-teck 1236 scraper');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('d4acd861-f12a-443b-8917-9838f3299c6a', '5380d563-d6ac-4231-976c-1579d74b4b52', 'JD 850 L/P LPG W/GPS NO RIPPER', 3, 10000, 2, 7, 5.25, '2026-03-10 00:56:58.735611+00', 1000, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('919dcbff-cb61-4ca8-9871-dbdd4dcfdb84', '5380d563-d6ac-4231-976c-1579d74b4b52', 'JD 950 S/U BLADE  4WAY', 3, 15000, 1, 7, 5.25, '2026-03-10 00:56:58.884265+00', 1500, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('3e0f7deb-bf7e-4a4d-b802-edd99bfc4ec8', '5380d563-d6ac-4231-976c-1579d74b4b52', 'JD 750L - LPG W/GPS', 3, 7500, 1, 4, 5.25, '2026-03-10 00:56:59.101765+00', 600, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('40da23f1-f81a-4f20-b3dd-6da6b20103a4', '5380d563-d6ac-4231-976c-1579d74b4b52', 'JD 410P', 3, 12000, 4, 7, 5.25, '2026-03-10 00:56:59.30082+00', 4000, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('39d83480-09e6-4926-aa65-2a82a7130ba7', '5380d563-d6ac-4231-976c-1579d74b4b52', 'JD 510P - W/GPS.', 3, 17000, 1, 7, 5.25, '2026-03-10 00:56:59.427843+00', 2000, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('2ea218fb-79c5-42ba-892f-639e4e7b2a9d', '5380d563-d6ac-4231-976c-1579d74b4b52', 'Cat K-teck 1236 scraper', 3, 45000, 2, 20, 5.25, '2026-03-10 00:56:59.565166+00', 6000, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('ea2faf07-969b-48d6-9500-1a29beb1e204', '81513bd9-fae6-4e55-97c8-152f788409e5', 'JD 850 L/P LPG W/GPS NO RIPPER', 3, 10000, 2, 7, 5.25, '2026-03-10 00:57:00.957078+00', 800, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('d1aceddf-dec4-4688-bc2d-63c009dc302d', '81513bd9-fae6-4e55-97c8-152f788409e5', 'JD 750L - LPG W/GPS', 3, 7500, 1, 4, 5.25, '2026-03-10 00:57:01.326938+00', 300, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('b670a32b-376e-4872-8d9b-c22201d63651', 'ac7593d3-c6f5-47ef-bb8b-730c75c421e5', 'JD 350P W/THUMB', 2.7, 15000, 1, 7, 5.25, '2026-04-14 18:24:33.470149+00', 700, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('a399d89a-6c37-49cd-9768-dbbe9c022a06', 'ac7593d3-c6f5-47ef-bb8b-730c75c421e5', 'TOYOTA TUNDRA PLATEUM', 2.7, 5000, 1, 2, 5.25, '2026-04-14 18:24:33.601681+00', 100, NULL, true, false, 'JD 350P W/THUMB');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('849878df-e703-41ca-824a-76ea2c3007ed', 'ac7593d3-c6f5-47ef-bb8b-730c75c421e5', 'POLARIS RANGER 1000', 2.7, 2000, 1, 2, 5.25, '2026-04-14 18:24:33.722926+00', 80, NULL, true, false, 'JD 350P W/THUMB');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('de8cfd92-70a3-4986-9fad-8a070f109735', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', 'JD 350P W/THUMB', 14.1, 4500, 1, 7, 5.25, '2026-04-14 19:37:50.031725+00', 350, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('4335df78-e06a-4ce1-8a62-e4fc546f1fea', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', 'POLARIS RANGER 1000', 14.1, 1300, 1, 2, 5.25, '2026-04-14 19:37:50.185973+00', 250, NULL, true, false, 'JD 350P W/THUMB');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('70e1114e-78a1-42be-898a-2f133e4ebb2d', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', 'JD 750L - LPG W/GPS', 14.1, 6500, 1, 0, 5.25, '2026-04-14 19:37:50.31655+00', 450, NULL, true, false, 'JD 350P W/THUMB');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('30d79a68-1641-475a-9829-3554bf4c3de4', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', '5-6 Yd Dump Truck', 14.1, 5500, 4, 4, 5.25, '2026-04-14 19:37:50.44887+00', 3500, NULL, true, false, 'JD 350P W/THUMB');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('1415ebb6-7096-485e-987e-4ec3d517dbe3', '22055dba-b9af-426f-89de-bedd62f536b1', '5-6 Yd Dump Truck', 119.9, 0, 4, 4, 5.25, '2026-04-14 19:37:52.575305+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('65c485c4-0d92-43eb-86bf-2b2d74eebece', '22055dba-b9af-426f-89de-bedd62f536b1', 'JD 750L - LPG W/GPS', 119.9, 0, 1, 0, 5.25, '2026-04-14 19:37:52.682382+00', 0, NULL, true, false, '5-6 Yd Dump Truck');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('800070b9-4596-4149-b5d8-db43b679e534', '6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', 'JD 850 L/P LPG W/GPS NO RIPPER', 0, 0, 1, 7, 5.25, '2026-04-14 19:37:53.481061+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('be724d10-7633-4f39-8510-83ad8f57ca2b', '6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', 'JD 410P', 0, 0, 2, 7, 5.25, '2026-04-14 19:37:53.674392+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('4d21645b-6dac-4ff2-904e-e2336c1b4c04', '6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', 'JD 350P W/THUMB', 0, 0, 1, 7, 5.25, '2026-04-14 19:37:53.823673+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('f0017506-e96b-4a38-984c-9b428dc69afb', '61de1e83-a430-4de6-8ef6-5b851d489e1d', 'JD 350P W/THUMB', 119.9, 0, 1, 7, 5.25, '2026-04-14 19:37:55.556181+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('a3218b7a-09f9-46f2-acbd-16917a39ba16', '61de1e83-a430-4de6-8ef6-5b851d489e1d', 'POLARIS RANGER 1000', 119.9, 0, 1, 2, 5.25, '2026-04-14 19:37:55.679359+00', 0, NULL, true, false, 'JD 350P W/THUMB');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('d2c14d22-740d-4ec2-9b2f-fddcb00add60', '61de1e83-a430-4de6-8ef6-5b851d489e1d', 'JD 750L - LPG W/GPS', 119.9, 0, 1, 0, 5.25, '2026-04-14 19:37:55.811252+00', 0, NULL, true, false, 'JD 350P W/THUMB');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('7790eaee-4a96-46aa-9e17-299372e164d7', '61de1e83-a430-4de6-8ef6-5b851d489e1d', '5-6 Yd Dump Truck', 119.9, 0, 2, 4, 5.25, '2026-04-14 19:37:55.925863+00', 0, NULL, true, false, 'JD 350P W/THUMB');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('1c74f9d0-20e5-4649-9b53-585d246294d6', '96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', 'JD 350P W/THUMB', 1.4, 10000, 2, 7, 5.25, '2026-04-17 22:39:38.577311+00', 300, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('0926c712-842b-42bf-b86f-5c65f1781aa5', '96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', 'POLARIS RANGER 1000', 1.4, 2000, 1, 2, 5.25, '2026-04-17 22:39:38.929847+00', 100, NULL, true, false, 'JD 350P W/THUMB');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('ea1fe340-4653-4f86-900b-aca9750fb9c1', '96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', 'JD 750L - LPG W/GPS', 1.4, 5000, 1, 0, 5.25, '2026-04-17 22:39:39.269877+00', 400, NULL, true, false, 'JD 350P W/THUMB');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('9371ece8-4b7b-4802-8879-a8176f6c447d', 'fe54b6a4-4dd7-447b-8f5b-b3a4eef18d45', 'JD 350P W/THUMB', 1, 2500, 1, 7, 5.25, '2026-04-27 19:06:28.669804+00', 300, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('66b1730d-b6f4-4b58-aac6-8e12ed025f71', 'fe54b6a4-4dd7-447b-8f5b-b3a4eef18d45', '5-6 Yd Dump Truck', 1, 5000, 2, 4, 5.25, '2026-04-27 19:06:28.762081+00', 300, NULL, true, false, 'JD 350P W/THUMB');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('641654bf-715f-474a-9977-d788e480b8b6', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', 'JD 460P', 2.5, 12000, 4, 7, 5.25, '2026-04-27 19:06:29.801028+00', 800, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('73d7fad1-ccc4-4dba-8dd6-5e24db2c9cac', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', 'JD 510P - W/GPS.', 2.5, 15000, 1, 7, 5.25, '2026-04-27 19:06:29.907352+00', 1000, NULL, true, false, 'JD 460P');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('ed5b8093-f797-4204-8ce9-892d0eaa2767', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', 'Cat K-teck 1236 scraper', 2.5, 30000, 1, 7, 5.25, '2026-04-27 19:06:29.985911+00', 3000, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('bfa9150c-4974-4198-a5d5-ae81cfd2e1b1', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', 'JD 950 L W/GPS', 2.5, 12000, 1, 7, 5.25, '2026-04-27 19:06:30.091717+00', 800, NULL, true, false, 'Cat K-teck 1236 scraper');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('9b6a4f7e-35dd-41cd-a724-07d0267029ed', 'd6ff2701-828c-4cb6-b693-05268ade668c', '5-6 Yd Dump Truck', 119.9, 0, 4, 4, 5.25, '2026-04-27 19:06:31.110679+00', 0, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('bd468858-3e70-48a9-9e29-be5e42720a32', 'd6ff2701-828c-4cb6-b693-05268ade668c', 'JD 750L - LPG W/GPS', 119.9, 0, 1, 0, 5.25, '2026-04-27 19:06:31.218368+00', 0, NULL, true, false, '5-6 Yd Dump Truck');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('a0405072-5281-4b18-b013-f4b67e651c86', 'd6ff2701-828c-4cb6-b693-05268ade668c', 'JD 350P W/THUMB', 119.9, 0, 1, 7, 5.25, '2026-04-27 19:06:31.309352+00', 0, NULL, true, false, '5-6 Yd Dump Truck');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('0f501b05-0e02-40e5-81a3-e0a8e7f07597', '584281a5-4f51-4722-9f88-95d94842b380', 'JD 350P W/THUMB', 1.1, 7500, 1, 7, 5.25, '2026-04-27 19:06:32.510846+00', 500, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('52be2a1c-41e1-420c-b749-1674ef1df026', '584281a5-4f51-4722-9f88-95d94842b380', 'JD 410P', 1.1, 5000, 2, 7, 5.25, '2026-04-27 19:06:32.610262+00', 300, NULL, true, false, 'JD 350P W/THUMB');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('3bb25ac4-87ac-4ab0-966a-8a456731a419', '3d08f851-b15e-46a6-bf68-ac823bce1f45', 'JD 460P', 3.3, 12000, 4, 7, 5.25, '2026-05-11 13:05:51.497465+00', 300, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('1c272b16-81c0-4926-ac3d-086d2dbb9cb1', '3d08f851-b15e-46a6-bf68-ac823bce1f45', 'POLARIS RANGER 1000', 3.3, 2000, 1, 2, 5.25, '2026-05-11 13:05:51.645401+00', 100, NULL, true, false, 'JD 460P');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('74f1ff6d-edaa-45ac-8245-8cef5fed6280', '3d08f851-b15e-46a6-bf68-ac823bce1f45', 'JD 950 S/U BLADE  4WAY', 3.3, 2000, 1, 7, 5.25, '2026-05-11 13:05:51.782252+00', 100, NULL, true, false, 'JD 460P');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('672b6c1d-53d9-496d-b3dc-57fd7b25e83b', 'be323d33-83cc-40f2-b3e9-e514b3ad72e3', 'JD 460P', 1.7, 10000, 4, 7, 5.25, '2026-06-27 21:29:09.029778+00', 200, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('5b087ec4-bf37-48da-8d40-d8248e894f27', 'be323d33-83cc-40f2-b3e9-e514b3ad72e3', 'JD 950 L W/GPS', 1.7, 15000, 1, 7, 5.25, '2026-06-27 21:29:09.042049+00', 200, NULL, true, false, 'JD 460P');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('706e9b41-0ed2-41e8-a449-a7212a4b12e2', '1153213f-84f6-4776-885f-9e8cab1f1ca8', 'JD 950 L W/GPS', 0.3, 20000, 2, 7, 5.25, '2026-06-27 21:29:09.146366+00', 300, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('fb1b4192-6b5a-4557-8192-b53bab280ddc', '1153213f-84f6-4776-885f-9e8cab1f1ca8', 'TOYOTA TUNDRA PLATEUM', 0.3, 5000, 1, 2, 5.25, '2026-06-27 21:29:09.155806+00', 50, NULL, true, false, 'JD 950 L W/GPS');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('1b636280-f2f3-49c0-a59e-9e61369105f3', '1153213f-84f6-4776-885f-9e8cab1f1ca8', 'JD 410P', 0.3, 10000, 1, 7, 5.25, '2026-06-27 21:29:09.167569+00', 200, NULL, true, false, 'JD 950 L W/GPS');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('a5457b40-6792-41df-99d6-6908fab962b3', '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', 'JD 460P', 4, 13900, 2, 7, 5, '2026-06-29 19:20:49.162877+00', 400, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('1fda5596-0e49-489b-bf4a-fde95a4aa51b', '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', 'JD 950 L W/GPS', 4, 8950, 1, 7, 5, '2026-06-29 19:20:49.183152+00', 300, NULL, true, false, 'JD 460P');
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('1d6c71ac-7858-48eb-a4bd-a2c0593377f9', 'c55610c7-86d5-497a-9513-97b9a315c49f', 'JD 950 S/U BLADE  4WAY', 0.3, 10000, 2, 7, 5.25, '2026-06-29 19:20:49.291799+00', 200, NULL, true, true, NULL);
INSERT INTO public.quote_service_machineries (id, quote_service_id, machine_name, months_to_use, monthly_rent_cost, quantity, gallons_per_hour, gallon_cost, created_at, delivery_cost, parent_machinery_id, is_primary, is_primary_mover, parent_machine_name) VALUES ('30f26340-aec0-4126-9260-e29a7e5de73e', 'c55610c7-86d5-497a-9513-97b9a315c49f', 'TOYOTA TUNDRA PLATEUM', 0.3, 3000, 1, 2, 5.25, '2026-06-29 19:20:49.304067+00', 50, NULL, true, false, 'JD 950 S/U BLADE  4WAY');


--
-- Data for Name: project_machinery; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('7cc9e734-0a52-40e4-9c5e-db8b670d2c6c', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '641654bf-715f-474a-9977-d788e480b8b6', 'JD 460P', 4, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('2133a6b5-d447-42a8-bd81-fa1d09aa1a7c', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '73d7fad1-ccc4-4dba-8dd6-5e24db2c9cac', 'JD 510P - W/GPS.', 1, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('4af16f0f-38d1-4ecd-916d-b4daae9c7226', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', 'ed5b8093-f797-4204-8ce9-892d0eaa2767', 'Cat K-teck 1236 scraper', 1, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('6bbfe786-c963-48ea-a319-8a6e77a4968e', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', 'bfa9150c-4974-4198-a5d5-ae81cfd2e1b1', 'JD 950 L W/GPS', 1, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('e1def78c-54b6-4f2f-b212-52798d85d68a', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '9b6a4f7e-35dd-41cd-a724-07d0267029ed', '5-6 Yd Dump Truck', 4, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('20241ec0-4418-4fdd-8245-dae8851cdbb9', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', 'bd468858-3e70-48a9-9e29-be5e42720a32', 'JD 750L - LPG W/GPS', 1, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('0521e7a4-1861-4cf4-af1f-aed73670d8df', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', 'a0405072-5281-4b18-b013-f4b67e651c86', 'JD 350P W/THUMB', 1, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('50d94b16-6041-44f2-81e7-6882e46cb3ce', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '0f501b05-0e02-40e5-81a3-e0a8e7f07597', 'JD 350P W/THUMB', 1, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('3c177279-991b-44d9-9359-5e2b4b1ea538', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '52be2a1c-41e1-420c-b749-1674ef1df026', 'JD 410P', 2, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('9cb47185-fce9-4c94-b02d-70619d3cea4f', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '9371ece8-4b7b-4802-8879-a8176f6c447d', 'JD 350P W/THUMB', 1, 1, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('799148bb-1231-446e-9f0c-ea62b4f5eb46', '37bfaa3f-5f73-4b94-b7b5-4b7b6d2ca76b', '66b1730d-b6f4-4b58-aac6-8e12ed025f71', '5-6 Yd Dump Truck', 2, 0, '2026-05-08 23:15:19.62274+00', '2026-05-08 23:15:19.62274+00', '2026-05-12', '2026-06-15', false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('9f17f068-b736-41fd-a2db-d2a53135998d', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', '1c272b16-81c0-4926-ac3d-086d2dbb9cb1', 'POLARIS RANGER 1000', 1, 1, '2026-05-11 13:07:07.038181+00', '2026-05-11 13:07:07.038181+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('d89dc86f-b674-4091-8e6e-3b822d509946', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', '74f1ff6d-edaa-45ac-8245-8cef5fed6280', 'JD 950 S/U BLADE  4WAY', 1, 1, '2026-05-11 13:07:07.038181+00', '2026-05-11 13:07:07.038181+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', '3bb25ac4-87ac-4ab0-966a-8a456731a419', 'JD 460P', 4, 4, '2026-05-11 13:07:07.038181+00', '2026-05-11 13:07:07.038181+00', NULL, NULL, false, NULL, false, 0, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('6ca6fa47-1ddd-43de-824c-e9e6b0b62930', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '30f26340-aec0-4126-9260-e29a7e5de73e', 'TOYOTA TUNDRA PLATEUM', 1, 1, '2026-06-29 19:29:37.59292+00', '2026-06-29 19:29:37.59292+00', '2026-07-01', '2026-07-13', false, NULL, false, 0, 'c55610c7-86d5-497a-9513-97b9a315c49f', NULL, NULL, 'planning', '6674ca52-ae77-48e5-8264-67f4d4935587');
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('972a6eb8-025d-4c47-8cc1-3039ef4a623e', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '1d6c71ac-7858-48eb-a4bd-a2c0593377f9', 'JD 950 S/U BLADE  4WAY', 2, 2, '2026-06-29 19:29:37.59292+00', '2026-06-29 19:29:37.59292+00', '2026-07-01', '2026-07-13', true, NULL, false, 0, 'c55610c7-86d5-497a-9513-97b9a315c49f', NULL, NULL, 'planning', '6674ca52-ae77-48e5-8264-67f4d4935587');
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('53d62d93-4bc1-4466-97a5-237da16b9dfb', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '1fda5596-0e49-489b-bf4a-fde95a4aa51b', 'JD 950 L W/GPS', 1, 1, '2026-06-29 19:29:37.59292+00', '2026-06-29 19:29:37.59292+00', '2026-07-01', '2026-11-13', false, NULL, false, 0, '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', NULL, NULL, 'planning', '6674ca52-ae77-48e5-8264-67f4d4935587');
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('84126c63-c471-4316-b2ca-bb4785d7187b', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', 'a5457b40-6792-41df-99d6-6908fab962b3', 'JD 460P', 2, 2, '2026-06-29 19:29:37.59292+00', '2026-06-29 19:29:37.59292+00', '2026-07-01', '2026-11-13', true, NULL, false, 0, '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', NULL, NULL, 'planning', '6674ca52-ae77-48e5-8264-67f4d4935587');
INSERT INTO public.project_machinery (id, project_id, quote_service_machinery_id, machinery_name, expected_quantity, received_quantity, created_at, updated_at, start_date, end_date, is_principal, parent_machinery_id, is_unplanned, unplanned_cost, quote_service_id, calculation_metadata, machinery_id, change_type, baseline_snapshot_id) VALUES ('82b8fb7c-1be7-46da-9695-9f151860b475', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', NULL, 'JD 460P', 1, 1, '2026-06-29 19:39:57.904978+00', '2026-06-29 19:39:57.904978+00', '2026-07-01', '2026-08-09', true, NULL, true, 28610, '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', '{"days": 30, "rent": 695, "unit": "CY", "capacity": 30, "fuel_gph": 7, "quantity": 1, "transport": 200, "days_saved": 38.03999999999999, "fuel_price": 4.5, "service_id": "98dec84b-2cb2-49d7-b19e-9b17cdf1abf5", "is_principal": true, "monthly_rent": 13900, "hours_per_day": 8, "target_volume": 250000, "trips_per_day": 60, "compression_savings": 137153.21999999997, "parent_machinery_id": null, "performance_per_day": 1800, "original_duration_days": 105, "other_resources_daily_cost": 3605.5, "new_estimated_duration_days": 66.96000000000001, "original_fleet_daily_production": 3600}', '17b24170-9b73-4c7b-928f-74f4692a741b', 'planning', '6674ca52-ae77-48e5-8264-67f4d4935587');


--
-- Data for Name: machinery_inspections; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('4b72e766-afd2-4ef6-8193-e7710a31e4bb', '9f17f068-b736-41fd-a2db-d2a53135998d', '1212', 'POLARIS RANGER 1000', 'owned', NULL, 4545, 'operational', '["http://127.0.0.1:56421/storage/v1/object/public/machinery_evidence/24d128a9-5591-4cd2-b218-2fdfc93bb18f/9f17f068-b736-41fd-a2db-d2a53135998d/1778771019095_GPS-Topcon.png"]', 'ok', '2026-05-14 15:03:39.273306+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-27', NULL, 'hours', NULL, NULL);
INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('c35518e4-0ef3-4ce8-b356-35f2822e8bb7', 'd89dc86f-b674-4091-8e6e-3b822d509946', '3234234', 'JD 950 S/U BLADE  4WAY', 'owned', NULL, 45, 'operational', '["http://127.0.0.1:56421/storage/v1/object/public/machinery_evidence/24d128a9-5591-4cd2-b218-2fdfc93bb18f/d89dc86f-b674-4091-8e6e-3b822d509946/1778771043987_Juping_Jack.png"]', '', '2026-05-14 15:04:04.126334+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-27', NULL, 'hours', NULL, NULL);
INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('31ffefe3-ad48-43d5-9793-881e79a5ac01', '0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01', 'ewew', 'JD 460P', 'owned', NULL, 34, 'operational', '["http://127.0.0.1:56421/storage/v1/object/public/machinery_evidence/24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771070470_500_GL_FUEL_TANK.png"]', '1', '2026-05-14 15:04:30.621932+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-27', NULL, 'hours', NULL, NULL);
INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('091ec225-7817-4a66-840f-8ad484e24e28', '0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01', '222', 'JD 460P', 'owned', NULL, 43, 'operational', '["http://127.0.0.1:56421/storage/v1/object/public/machinery_evidence/24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771092714_500_GL_FUEL_TANK.png"]', '2', '2026-05-14 15:04:52.921777+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-27', NULL, 'hours', NULL, NULL);
INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('0029cb82-97ad-4180-8980-d280ad41046c', '0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01', '21', 'JD 460P', 'owned', NULL, 333, 'operational', '["http://127.0.0.1:56421/storage/v1/object/public/machinery_evidence/24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771110904_500_GL_FUEL_TANK.png"]', '3', '2026-05-14 15:05:11.044847+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-27', NULL, 'hours', NULL, NULL);
INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('597fd086-6584-4302-9603-3155b7994225', '0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01', '12', 'JD 460P', 'owned', NULL, 32, 'operational', '["http://127.0.0.1:56421/storage/v1/object/public/machinery_evidence/24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771131104_500_GL_FUEL_TANK.png"]', '4', '2026-05-14 15:05:31.237364+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-27', NULL, 'hours', NULL, NULL);
INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('488c89c3-5f26-432b-a5d4-9afd95f26bcd', '6ca6fa47-1ddd-43de-824c-e9e6b0b62930', '123', 'TOYOTA TUNDRA PLATEUM', 'owned', NULL, 300, 'operational', '["http://127.0.0.1:8001/storage/v1/object/public/machinery_evidence/1e5fe596-050c-4f95-b8c3-dd632bb0e45e/6ca6fa47-1ddd-43de-824c-e9e6b0b62930/1782761546184_Toyota_Tundra_Plateum.png"]', '', '2026-06-29 19:32:26.331058+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29', 'a01', 'miles', NULL, NULL);
INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('33a3fa6d-b7dd-4eac-a5b1-bae2c3bf3d1e', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '3214', 'JD 950 S/U BLADE  4WAY', 'rented', NULL, 675, 'operational', '["http://127.0.0.1:8001/storage/v1/object/public/machinery_evidence/1e5fe596-050c-4f95-b8c3-dd632bb0e45e/972a6eb8-025d-4c47-8cc1-3039ef4a623e/1782761577080_JD_1050-950-850.png"]', '', '2026-06-29 19:32:57.214769+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29', 'a02', 'hours', NULL, NULL);
INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('f5e75e7a-6dac-4463-8449-ee1a97045d6c', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '9090', 'JD 950 S/U BLADE  4WAY', 'owned', NULL, 6557, 'operational', '["http://127.0.0.1:8001/storage/v1/object/public/machinery_evidence/1e5fe596-050c-4f95-b8c3-dd632bb0e45e/972a6eb8-025d-4c47-8cc1-3039ef4a623e/1782761605843_JD_1050-950-850.png"]', '', '2026-06-29 19:33:25.952555+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29', 'A03', 'hours', NULL, NULL);
INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('2c333090-e4b4-43cf-a14d-cdcd41a502fd', '53d62d93-4bc1-4466-97a5-237da16b9dfb', '7667', 'JD 950 L W/GPS', 'owned', NULL, 657, 'operational', '["http://127.0.0.1:8001/storage/v1/object/public/machinery_evidence/1e5fe596-050c-4f95-b8c3-dd632bb0e45e/53d62d93-4bc1-4466-97a5-237da16b9dfb/1782761636535_JD_1050-950-850.png"]', '', '2026-06-29 19:33:56.646707+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29', 'A04', 'hours', NULL, NULL);
INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('67f4d5f2-b8f5-4a51-b8e6-3aeb42346ca1', '84126c63-c471-4316-b2ca-bb4785d7187b', '76675', 'JD 460P', 'rented', NULL, 6743, 'operational', '["http://127.0.0.1:8001/storage/v1/object/public/machinery_evidence/1e5fe596-050c-4f95-b8c3-dd632bb0e45e/84126c63-c471-4316-b2ca-bb4785d7187b/1782761669469_JD_460-410.png"]', '', '2026-06-29 19:34:29.588544+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29', 'a06', 'hours', NULL, NULL);
INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('0a5dc1a3-7963-4263-b53a-aeb604a3c570', '84126c63-c471-4316-b2ca-bb4785d7187b', '8632', 'JD 460P', 'rented', NULL, 7678, 'operational', '["http://127.0.0.1:8001/storage/v1/object/public/machinery_evidence/1e5fe596-050c-4f95-b8c3-dd632bb0e45e/84126c63-c471-4316-b2ca-bb4785d7187b/1782761700068_JD_460-410.png"]', '', '2026-06-29 19:35:00.21873+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29', 'A07', 'hours', NULL, NULL);
INSERT INTO public.machinery_inspections (id, project_machinery_id, internal_code, brand_model, ownership_type, provider_name, hour_meter_start, condition_status, evidence_photos, observations, received_at, received_by, reception_date, internal_id, odometer_unit, returned_at, hour_meter_end) VALUES ('c1a95072-01e2-4c3b-a0cd-60ecf7dad93b', '82b8fb7c-1be7-46da-9695-9f151860b475', 'c4567', 'JD 460P', 'rented', NULL, 567, 'operational', '["http://127.0.0.1:8001/storage/v1/object/public/machinery_evidence/1e5fe596-050c-4f95-b8c3-dd632bb0e45e/82b8fb7c-1be7-46da-9695-9f151860b475/1782762165886_JD_460-410.png"]', '', '2026-06-29 19:42:46.188317+00', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29', 'A08', 'hours', NULL, NULL);


--
-- Data for Name: materials; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.materials (id, description, unit, yield_factor, associated_service_ids, created_at, updated_at) VALUES ('4a0ec654-150f-4f77-ac85-364b7f0cffee', 'Liner Polim??rico', 'FT', 1, '{2502bcd5-bf39-48bc-b003-9a0f973405f9}', '2026-05-14 14:41:46.750134+00', '2026-05-14 14:41:46.750134+00');
INSERT INTO public.materials (id, description, unit, yield_factor, associated_service_ids, created_at, updated_at) VALUES ('766b3099-3892-4a6f-a62f-58ace99b67df', 'HDPE Perforada 4"', 'LF', 1.05, '{d6aadd2b-b0f1-4570-8597-a590d7ef1eb5}', '2026-05-14 14:42:54.65032+00', '2026-05-14 14:42:54.65032+00');
INSERT INTO public.materials (id, description, unit, yield_factor, associated_service_ids, created_at, updated_at) VALUES ('c0c89647-e1ce-4c59-8d94-6540af64e4ed', 'Grava 1/4"', 'CY', 1, '{d6aadd2b-b0f1-4570-8597-a590d7ef1eb5}', '2026-05-14 14:43:27.288302+00', '2026-05-14 14:43:27.288302+00');
INSERT INTO public.materials (id, description, unit, yield_factor, associated_service_ids, created_at, updated_at) VALUES ('9681fbcd-1cc8-4c29-9c22-2dfb8401d840', 'Conectores (Tees, Elbows, Caps)Conectores (Tees, Elbows, Caps)', 'UN', 0.02, '{d6aadd2b-b0f1-4570-8597-a590d7ef1eb5,2502bcd5-bf39-48bc-b003-9a0f973405f9}', '2026-05-14 14:44:22.237613+00', '2026-05-14 14:44:22.237613+00');
INSERT INTO public.materials (id, description, unit, yield_factor, associated_service_ids, created_at, updated_at) VALUES ('1e5ee343-05b9-46f3-8574-562e6780e9fd', 'Bunker Sand (White)', 'TON', 1, '{2502bcd5-bf39-48bc-b003-9a0f973405f9}', '2026-05-14 14:45:04.413192+00', '2026-05-14 14:45:04.413192+00');
INSERT INTO public.materials (id, description, unit, yield_factor, associated_service_ids, created_at, updated_at) VALUES ('d5bb132c-8c4c-4a9c-8663-92b211f7b5ad', 'Arena Rootzone', 'CY', 1, '{d6aadd2b-b0f1-4570-8597-a590d7ef1eb5}', '2026-05-14 14:45:55.459523+00', '2026-05-14 14:45:55.459523+00');


--
-- Data for Name: quote_service_instruments; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.quote_service_instruments (id, quote_service_id, instrument_id, instrument_name, quantity, unit_price, notes, created_at, updated_at, days) VALUES ('0d116e79-dd98-4139-8728-637d62e38bba', '1153213f-84f6-4776-885f-9e8cab1f1ca8', '9c6fc789-ee0a-4fb7-9c2d-28333ed4730f', '40" CONEX STORAGE', 1, 10, NULL, '2026-06-27 21:29:09.223364+00', '2026-06-27 21:29:09.223364+00', 9);
INSERT INTO public.quote_service_instruments (id, quote_service_id, instrument_id, instrument_name, quantity, unit_price, notes, created_at, updated_at, days) VALUES ('e1662d89-0cc2-4326-9964-395288848e28', 'c55610c7-86d5-497a-9513-97b9a315c49f', '9c6fc789-ee0a-4fb7-9c2d-28333ed4730f', '40" CONEX STORAGE', 1, 0, NULL, '2026-06-29 19:20:49.355057+00', '2026-06-29 19:20:49.355057+00', 9);


--
-- Data for Name: project_instruments; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_instruments (id, project_id, quote_service_instrument_id, instrument_name, expected_quantity, received_quantity, is_unplanned, created_at, updated_at, unplanned_cost, quote_service_id, calculation_metadata, start_date, end_date, instrument_id, change_type, baseline_snapshot_id) VALUES ('d909691c-8f8e-4d03-a2d7-84c26bc12967', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', 'e1662d89-0cc2-4326-9964-395288848e28', '40" CONEX STORAGE', 1, 0, false, '2026-06-29 19:29:37.651503+00', '2026-07-03 20:01:53.904536+00', 0, 'c55610c7-86d5-497a-9513-97b9a315c49f', NULL, '2026-07-01', '2026-07-13', NULL, 'planning', '6674ca52-ae77-48e5-8264-67f4d4935587');


--
-- Data for Name: project_instrument_assignments; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_instrument_assignments (id, project_instrument_id, start_date, end_date, quantity, created_at) VALUES ('0422fa68-564f-4974-84ad-6092211528b6', 'd909691c-8f8e-4d03-a2d7-84c26bc12967', '2026-07-01', '2026-07-11', 1, '2026-06-29 19:31:46.749243+00');


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.roles (id, name, description, created_at, updated_at) VALUES ('07949cfb-9892-4cc7-aa17-3700291ef3a0', 'Admin', 'Full access to all features', '2026-06-27 20:07:24.615557+00', '2026-06-27 20:07:24.615557+00');
INSERT INTO public.roles (id, name, description, created_at, updated_at) VALUES ('74954552-10be-4085-bbb9-e1774dd7a4ac', 'Employee', 'Standard employee access', '2026-06-27 20:07:24.615557+00', '2026-06-27 20:07:24.615557+00');


--
-- Data for Name: quote_service_labors; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('ea02c218-9a18-4eef-a7d0-4cc0b52545f2', 'fe54b6a4-4dd7-447b-8f5b-b3a4eef18d45', NULL, 1, 1, 39, 0, '2026-04-27 19:06:28.872953+00', 'Excavator Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('b34b06e1-de9b-4ced-a0a6-7ded5d8b2d68', 'fe54b6a4-4dd7-447b-8f5b-b3a4eef18d45', NULL, 1, 2, 35, 0, '2026-04-27 19:06:28.954705+00', 'Truck Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('9ea54c4c-4a14-46ad-90a6-88a394207d1c', 'e512195f-c8cd-4bd1-848d-90c30c46f5ad', NULL, 4, 1, 73, 0, '2026-03-06 03:23:19.508991+00', NULL);
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('664dff19-fa19-44d3-8905-debb7f25b274', 'e512195f-c8cd-4bd1-848d-90c30c46f5ad', NULL, 4, 3, 55, 0, '2026-03-06 03:23:19.604437+00', NULL);
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('10f962bc-4871-4c43-8302-5bd31b5b5feb', 'fe54b6a4-4dd7-447b-8f5b-b3a4eef18d45', NULL, 1, 4, 20, 0, '2026-04-27 19:06:29.055768+00', 'labor');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('42dcbcb4-bdf7-4bee-9ca6-3ddca7d25c64', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', NULL, 2.5, 4, 35, 0, '2026-04-27 19:06:30.169127+00', 'Truck Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('ca00edcd-e764-42f7-b02c-452f89c0ecb4', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', NULL, 2.5, 1, 39, 0, '2026-04-27 19:06:30.293075+00', 'Scraper operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('bb8106cd-8a49-4246-a3d5-179e6d97c2dd', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', NULL, 2.5, 1, 39, 0, '2026-04-27 19:06:30.370195+00', 'Excavator Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('0dce68ff-49c8-442e-8acc-cf73c71a2ee3', 'c2623f9b-2a9c-408a-a50b-b9dd3b6260b1', NULL, 2.5, 1, 55, 0, '2026-04-27 19:06:30.477532+00', 'Shaper Class B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('a2102a9d-437a-4ea5-b616-7db9b2fd7fff', 'd6ff2701-828c-4cb6-b693-05268ade668c', NULL, 119.9, 4, 35, 0, '2026-04-27 19:06:31.43901+00', 'Truck Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('a83d08d1-5159-43ea-b86f-4ba08ee5719e', 'd6ff2701-828c-4cb6-b693-05268ade668c', NULL, 119.9, 1, 55, 0, '2026-04-27 19:06:31.536993+00', 'Shaper Class B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('192cc750-a07a-4015-b80c-f8a077338e01', 'd6ff2701-828c-4cb6-b693-05268ade668c', NULL, 119.9, 1, 39, 0, '2026-04-27 19:06:31.69935+00', 'Excavator Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('02a3dfb6-70b0-4b78-9712-9770f5fa781f', 'd02c020a-a0de-48e9-8682-fafe05f47509', NULL, 1, 2, 45, 7, '2026-03-09 23:05:47.903421+00', NULL);
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('25cb6026-27fb-46bc-af0f-d7e01fefe479', 'd02c020a-a0de-48e9-8682-fafe05f47509', NULL, 4, 4, 39, 7, '2026-03-09 23:05:48.116302+00', NULL);
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('5a04cfb5-1fb3-4eb0-88e5-bd4684e0b138', 'd6ff2701-828c-4cb6-b693-05268ade668c', NULL, 119.9, 6, 20, 0, '2026-04-27 19:06:31.780497+00', 'labor');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('73371454-927d-40f8-a8f2-162ca4c6c2fb', '584281a5-4f51-4722-9f88-95d94842b380', NULL, 1.1, 1, 39, 0, '2026-04-27 19:06:32.716255+00', 'Excavator Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('facf8f01-3f06-4786-81cf-527e7933d18f', '584281a5-4f51-4722-9f88-95d94842b380', NULL, 1.1, 2, 35, 0, '2026-04-27 19:06:32.798348+00', 'Truck Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('21956692-ad85-4b5e-9f99-830c36961975', '5380d563-d6ac-4231-976c-1579d74b4b52', NULL, 3, 4, 35, 7, '2026-03-10 00:56:59.703589+00', NULL);
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('3df16a45-6f6e-4697-8fe9-fb6bd86320de', '5380d563-d6ac-4231-976c-1579d74b4b52', NULL, 3, 1, 73, 7, '2026-03-10 00:56:59.859696+00', NULL);
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('0ccca807-e264-4d1e-a0d5-d1a6f91fdb81', '5380d563-d6ac-4231-976c-1579d74b4b52', NULL, 3, 1, 55, 7, '2026-03-10 00:57:00.010967+00', NULL);
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('9e74f0c8-ab24-43e6-8c21-d1cf9d571b64', '5380d563-d6ac-4231-976c-1579d74b4b52', NULL, 3, 2, 39, 7, '2026-03-10 00:57:00.164968+00', NULL);
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('946e8728-1126-4c98-bd59-f79fe4ecd9a3', '5380d563-d6ac-4231-976c-1579d74b4b52', NULL, 3, 4, 39, 7, '2026-03-10 00:57:00.336624+00', NULL);
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('e798f3b3-e8ba-405a-9c25-4e70f89a7540', '81513bd9-fae6-4e55-97c8-152f788409e5', NULL, 3, 3, 55, 7, '2026-03-10 00:57:01.461462+00', NULL);
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('5a223f92-0b4a-4c53-a607-219f65b32517', 'ee7f93a9-96c4-4335-a021-eb5372fa064a', NULL, 3, 1, 73, 4, '2026-03-12 20:29:40.474977+00', 'SUPERVISOR');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('daefb73b-d121-4dc7-88d2-81f2fcdfa1b6', 'f513c717-b218-4e7b-b6c1-f8d00660e746', NULL, 1, 4, 35, 0, '2026-03-30 19:06:59.082773+00', 'Truck Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('e5d126e0-08d1-48a4-9b42-4cb56e952cfb', 'f513c717-b218-4e7b-b6c1-f8d00660e746', NULL, 1, 2, 55, 0, '2026-03-30 19:06:59.154617+00', 'Shaper Class B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('89778eae-6c24-4c73-ba7b-1ca687aa97fa', 'f513c717-b218-4e7b-b6c1-f8d00660e746', NULL, 1, 2, 39, 0, '2026-03-30 19:06:59.218258+00', 'Scraper operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('10a4fca5-ce00-4e77-8219-e64a1833b3fa', 'fad4ea94-045a-454a-8789-b5709e388ac1', NULL, 4, 8, 35, 0, '2026-04-07 18:09:57.648125+00', 'Truck Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('f5c10f3a-d3aa-47ca-96fc-b2e867112d35', 'ac7593d3-c6f5-47ef-bb8b-730c75c421e5', NULL, 2.7, 1, 39, 0, '2026-04-14 18:24:33.918863+00', 'Excavator Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('9fd1188e-0d01-4e60-bf7b-cbfd55d88ccc', 'ac7593d3-c6f5-47ef-bb8b-730c75c421e5', NULL, 2.7, 2, 73, 0, '2026-04-14 18:24:34.057111+00', 'SUPERVISOR');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('2f9ffe5f-fb2f-407f-85e2-ae9345c881cd', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', NULL, 14.1, 1, 39, 0, '2026-04-14 19:37:50.63357+00', 'Excavator Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('8e11cec2-1117-4532-bea0-a89642b52165', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', NULL, 14.1, 1, 73, 0, '2026-04-14 19:37:50.853859+00', 'SUPERVISOR');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('c166dde8-4090-4d77-80ae-97ff25650213', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', NULL, 14.1, 1, 55, 0, '2026-04-14 19:37:50.986974+00', 'Shaper Class B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('5217d2bf-8c82-4a6a-b271-183fd2be0fb0', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', NULL, 14.1, 4, 35, 0, '2026-04-14 19:37:51.106934+00', 'Truck Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('f7742d17-d14a-4011-82dc-6346971b6c05', 'de2a4696-52de-4318-bbfb-002fe45e0ae0', NULL, 14, 4, 20, 0, '2026-04-14 19:37:51.207601+00', '');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('a92f68ee-ad7a-42bf-8458-332686642e9c', '22055dba-b9af-426f-89de-bedd62f536b1', NULL, 119.9, 4, 35, 0, '2026-04-14 19:37:52.794835+00', 'Truck Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('0c6f6d93-f52e-4e9d-8973-6d0edc1a7c9b', '22055dba-b9af-426f-89de-bedd62f536b1', NULL, 119.9, 1, 55, 0, '2026-04-14 19:37:52.900587+00', 'Shaper Class B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('91ef3e94-838d-4d9f-8992-b73fd7a87e8c', '6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', NULL, 0, 1, 55, 0, '2026-04-14 19:37:53.981613+00', 'Shaper Class B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('c90a4e7d-9dd6-4adc-9eac-e0d41b55f57e', '6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', NULL, 0, 2, 35, 0, '2026-04-14 19:37:54.219667+00', 'Truck Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('dd0bd1da-02da-45d6-afe2-f863a671f4f8', '6d604b2c-2a0b-458f-b3bb-35b45dbe8e28', NULL, 0, 1, 39, 0, '2026-04-14 19:37:54.425315+00', 'Excavator Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('d2f701d2-8bee-45fe-b207-33aaa075b94d', '61de1e83-a430-4de6-8ef6-5b851d489e1d', NULL, 119.9, 1, 39, 0, '2026-04-14 19:37:56.029327+00', 'Excavator Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('50f94b4b-653a-41e4-8d96-b31ff85dfb38', '61de1e83-a430-4de6-8ef6-5b851d489e1d', NULL, 119.9, 1, 73, 0, '2026-04-14 19:37:56.167747+00', 'SUPERVISOR');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('271a6bec-5d63-46f7-8771-ac1cd76eaa75', '61de1e83-a430-4de6-8ef6-5b851d489e1d', NULL, 119.9, 1, 55, 0, '2026-04-14 19:37:56.285574+00', 'Shaper Class B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('ca00123a-275b-4c13-9d07-3626f5d921ac', '61de1e83-a430-4de6-8ef6-5b851d489e1d', NULL, 119.9, 2, 35, 0, '2026-04-14 19:37:56.467008+00', 'Truck Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('0e736a9b-9404-4149-81d0-e6ecbb14e445', '96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', NULL, 1.4, 2, 39, 2, '2026-04-17 22:39:39.817112+00', 'Excavator Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('374fc027-8587-4c9d-ae8f-86e7dcfbd91c', '96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', NULL, 1.4, 1, 73, 2, '2026-04-17 22:39:40.4907+00', 'SUPERVISOR');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('668937a1-3d45-4f49-b2f3-a36c14a2b2d3', '96f3bf56-4fc2-41dc-a12c-25a6ced79fd8', NULL, 1.4, 1, 55, 2, '2026-04-17 22:39:40.856288+00', 'Shaper Class B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('6120c093-f949-4313-abb9-feb02e0123d3', '5cffaaa8-5e06-4a4f-86f0-daee894497b4', NULL, 1.25, 1, 55, 0, '2026-04-24 17:46:57.939594+00', 'Shaper Class B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('f7415edc-4616-4156-a814-79d4dfc43f86', '6e3b35aa-aa09-498b-9357-f9c44c1512e9', NULL, 1.25, 3, 39, 0, '2026-04-24 17:47:01.147237+00', 'Multi Equipment Operator');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('8af96e1d-004f-4a56-a7b2-f8bcfc9f828c', 'b6335445-15c1-4d64-8f71-a88855e2f5b2', NULL, 1.25, 1, 35, 0, '2026-04-24 17:47:04.487795+00', 'Skill Labor');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('ebb4d747-f6a5-4d01-b9ed-e2cf2f730573', '3d08f851-b15e-46a6-bf68-ac823bce1f45', NULL, 3.3, 4, 39, 3, '2026-05-11 13:05:51.989048+00', 'TRUCK OPERATOR');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('73fa80a8-8616-4475-b503-4612ed11efd6', '3d08f851-b15e-46a6-bf68-ac823bce1f45', NULL, 3.3, 1, 65, 3, '2026-05-11 13:05:52.25669+00', 'CONSTRUCTION SUPERINTENDENT');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('768515b7-7d4f-4560-9977-0e7d40737300', '3d08f851-b15e-46a6-bf68-ac823bce1f45', NULL, 3.3, 1, 55, 5, '2026-05-11 13:05:52.389179+00', 'SHAPER CLASS B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('c8be85b6-59fa-4da7-a6e8-678515e3aa32', 'be323d33-83cc-40f2-b3e9-e514b3ad72e3', NULL, 1.7, 4, 39, 2, '2026-06-27 21:29:09.055145+00', 'TRUCK OPERATOR');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('65b4b4ef-ddb4-4f73-8756-80abe39ef74e', 'be323d33-83cc-40f2-b3e9-e514b3ad72e3', NULL, 1.7, 1, 32, 2, '2026-06-27 21:29:09.067052+00', 'Shaper Class B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('e7403658-4471-4088-87d9-b280f68e5a81', '1153213f-84f6-4776-885f-9e8cab1f1ca8', NULL, 0.3, 2, 32, 2, '2026-06-27 21:29:09.181375+00', 'Shaper Class B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('e39b99ac-885c-46c8-b388-cc73d6d149a4', '1153213f-84f6-4776-885f-9e8cab1f1ca8', NULL, 0.3, 1, 65, 2, '2026-06-27 21:29:09.194058+00', 'CONSTRUCTION SUPERINTENDENT');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('c1d2c3be-7764-49db-a551-064c2d74e693', '1153213f-84f6-4776-885f-9e8cab1f1ca8', NULL, 0.3, 1, 39, 2, '2026-06-27 21:29:09.206648+00', 'TRUCK OPERATOR');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('55cd21a4-0823-48d5-90ab-e83e53cbd2c8', '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', NULL, 4, 2, 39, 2, '2026-06-29 19:20:49.199105+00', 'TRUCK OPERATOR');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('68d001c3-9db1-4a1e-994d-b7df3d693ee2', '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', NULL, 4, 1, 32, 2, '2026-06-29 19:20:49.212745+00', 'Shaper Class B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('606b1bf2-e032-45c6-b90c-7e4f483e5259', 'c55610c7-86d5-497a-9513-97b9a315c49f', NULL, 0.3, 2, 55, 2, '2026-06-29 19:20:49.320612+00', 'SHAPER CLASS B');
INSERT INTO public.quote_service_labors (id, quote_service_id, role_id, months_to_work, employees_quantity, hourly_rate, per_diem, created_at, role_name) VALUES ('3f19d34e-a549-47fd-8c4c-12c87bda87b4', 'c55610c7-86d5-497a-9513-97b9a315c49f', NULL, 0.3, 1, 65, 2, '2026-06-29 19:20:49.336227+00', 'CONSTRUCTION SUPERINTENDENT');


--
-- Data for Name: project_labor; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_labor (id, project_id, quote_service_labor_id, role_name, expected_employees, active_employees, created_at, is_unplanned, linked_machinery_id, unplanned_cost, quote_service_id, calculation_metadata, start_date, end_date, role_id, change_type, baseline_snapshot_id) VALUES ('2270af13-2b01-4614-ac79-e7eef29a7ed5', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', 'ebb4d747-f6a5-4d01-b9ed-e2cf2f730573', 'TRUCK OPERATOR', 4, 0, '2026-05-11 13:07:07.202078+00', false, NULL, 0, NULL, NULL, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_labor (id, project_id, quote_service_labor_id, role_name, expected_employees, active_employees, created_at, is_unplanned, linked_machinery_id, unplanned_cost, quote_service_id, calculation_metadata, start_date, end_date, role_id, change_type, baseline_snapshot_id) VALUES ('912f31c3-aaf8-4eea-966d-ed48a4df3bd6', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', '73fa80a8-8616-4475-b503-4612ed11efd6', 'CONSTRUCTION SUPERINTENDENT', 1, 0, '2026-05-11 13:07:07.202078+00', false, NULL, 0, NULL, NULL, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_labor (id, project_id, quote_service_labor_id, role_name, expected_employees, active_employees, created_at, is_unplanned, linked_machinery_id, unplanned_cost, quote_service_id, calculation_metadata, start_date, end_date, role_id, change_type, baseline_snapshot_id) VALUES ('a9effc2f-b241-4829-a5fd-62dd53ff9218', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', '768515b7-7d4f-4560-9977-0e7d40737300', 'SHAPER CLASS B', 1, 0, '2026-05-11 13:07:07.202078+00', false, NULL, 0, NULL, NULL, NULL, NULL, NULL, 'planning', NULL);
INSERT INTO public.project_labor (id, project_id, quote_service_labor_id, role_name, expected_employees, active_employees, created_at, is_unplanned, linked_machinery_id, unplanned_cost, quote_service_id, calculation_metadata, start_date, end_date, role_id, change_type, baseline_snapshot_id) VALUES ('a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '55cd21a4-0823-48d5-90ab-e83e53cbd2c8', 'TRUCK OPERATOR', 2, 0, '2026-06-29 19:29:37.628391+00', false, NULL, 0, '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', NULL, NULL, NULL, NULL, 'planning', '6674ca52-ae77-48e5-8264-67f4d4935587');
INSERT INTO public.project_labor (id, project_id, quote_service_labor_id, role_name, expected_employees, active_employees, created_at, is_unplanned, linked_machinery_id, unplanned_cost, quote_service_id, calculation_metadata, start_date, end_date, role_id, change_type, baseline_snapshot_id) VALUES ('efcf18d7-1e1c-4eb9-a317-96e111d64156', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '68d001c3-9db1-4a1e-994d-b7df3d693ee2', 'Shaper Class B', 1, 0, '2026-06-29 19:29:37.628391+00', false, NULL, 0, '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', NULL, NULL, NULL, NULL, 'planning', '6674ca52-ae77-48e5-8264-67f4d4935587');
INSERT INTO public.project_labor (id, project_id, quote_service_labor_id, role_name, expected_employees, active_employees, created_at, is_unplanned, linked_machinery_id, unplanned_cost, quote_service_id, calculation_metadata, start_date, end_date, role_id, change_type, baseline_snapshot_id) VALUES ('37921a1d-f665-49ec-9094-dc8219d8c9e5', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '606b1bf2-e032-45c6-b90c-7e4f483e5259', 'SHAPER CLASS B', 2, 0, '2026-06-29 19:29:37.628391+00', false, NULL, 0, 'c55610c7-86d5-497a-9513-97b9a315c49f', NULL, NULL, NULL, NULL, 'planning', '6674ca52-ae77-48e5-8264-67f4d4935587');
INSERT INTO public.project_labor (id, project_id, quote_service_labor_id, role_name, expected_employees, active_employees, created_at, is_unplanned, linked_machinery_id, unplanned_cost, quote_service_id, calculation_metadata, start_date, end_date, role_id, change_type, baseline_snapshot_id) VALUES ('43d17634-174a-480b-8eb1-d60fcefbf1ad', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '3f19d34e-a549-47fd-8c4c-12c87bda87b4', 'CONSTRUCTION SUPERINTENDENT', 1, 0, '2026-06-29 19:29:37.628391+00', false, NULL, 0, 'c55610c7-86d5-497a-9513-97b9a315c49f', NULL, NULL, NULL, NULL, 'planning', '6674ca52-ae77-48e5-8264-67f4d4935587');
INSERT INTO public.project_labor (id, project_id, quote_service_labor_id, role_name, expected_employees, active_employees, created_at, is_unplanned, linked_machinery_id, unplanned_cost, quote_service_id, calculation_metadata, start_date, end_date, role_id, change_type, baseline_snapshot_id) VALUES ('7bee13b5-d8ae-463a-9256-0335861713a5', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', NULL, 'TRUCK OPERATOR', 1, 0, '2026-06-29 19:39:57.904978+00', true, '82b8fb7c-1be7-46da-9695-9f151860b475', 9390, '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', '{"days": 30, "rent": 312, "unit": "CY", "capacity": 30, "fuel_gph": 0, "quantity": 1, "transport": 30, "days_saved": null, "fuel_price": 4.5, "service_id": "98dec84b-2cb2-49d7-b19e-9b17cdf1abf5", "is_principal": true, "monthly_rent": 0, "hours_per_day": 8, "target_volume": 250000, "trips_per_day": 60, "compression_savings": null, "parent_machinery_id": null, "performance_per_day": 1800, "original_duration_days": 105, "other_resources_daily_cost": 3605.5, "new_estimated_duration_days": null, "original_fleet_daily_production": 3600}', '2026-07-01', '2026-08-09', '15584be2-4d8f-4748-96ba-5684a56a7d74', 'planning', '6674ca52-ae77-48e5-8264-67f4d4935587');


--
-- Data for Name: quote_service_materials; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: project_materials; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: workers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.workers (id, id_number, full_name, hire_date, phone, email, status, role_id, created_at, updated_at) VALUES ('a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', '11950787', 'Fred Parra', '2026-04-08', '(456) 455-5555', 'fred@fred.ve', 'Active', '626d5dab-2200-4680-961f-f71069db1b94', '2026-04-08 20:00:29.509787+00', '2026-04-08 20:00:29.509787+00');
INSERT INTO public.workers (id, id_number, full_name, hire_date, phone, email, status, role_id, created_at, updated_at) VALUES ('d356e711-a989-4ac6-8a0e-b352596f0524', '11223344', 'Albert Parra', '2026-05-05', '(555) 888-4888', 'albert@fff.com', 'Active', '15584be2-4d8f-4748-96ba-5684a56a7d74', '2026-05-05 15:22:36.60714+00', '2026-05-05 15:22:36.60714+00');
INSERT INTO public.workers (id, id_number, full_name, hire_date, phone, email, status, role_id, created_at, updated_at) VALUES ('38dbe85c-a6f8-48ea-a6f2-2816031b064a', '34556876', 'gilberto navarro', '2026-05-05', '(088) 652-468', 'gilber@ggh.com', 'Active', '15584be2-4d8f-4748-96ba-5684a56a7d74', '2026-05-05 15:23:31.919982+00', '2026-05-05 15:23:31.919982+00');
INSERT INTO public.workers (id, id_number, full_name, hire_date, phone, email, status, role_id, created_at, updated_at) VALUES ('af647f93-7be5-47ec-83d5-4627eb3393b8', '68264828', 'Santi barbosa', '2026-05-05', '(555) 111-6401', 'santi@jjmc.com', 'Active', '15584be2-4d8f-4748-96ba-5684a56a7d74', '2026-05-05 15:26:42.404074+00', '2026-05-05 15:26:42.404074+00');
INSERT INTO public.workers (id, id_number, full_name, hire_date, phone, email, status, role_id, created_at, updated_at) VALUES ('533e90cb-43fa-4b6b-91e4-de27f0dcd216', '56432189', 'miranda fosil', '2026-05-05', '(222) 364-8031', 'miran@jjj.com', 'Active', '15584be2-4d8f-4748-96ba-5684a56a7d74', '2026-05-05 15:24:02.326564+00', '2026-05-05 15:27:02.535096+00');
INSERT INTO public.workers (id, id_number, full_name, hire_date, phone, email, status, role_id, created_at, updated_at) VALUES ('6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', '222671936', 'Ana delgado', '2026-05-05', '(222) 316-480', 'ana@jjj.com', 'Active', 'da849f21-3558-472d-b242-01cb999dd1d5', '2026-05-05 15:28:27.489587+00', '2026-05-05 15:28:27.489587+00');
INSERT INTO public.workers (id, id_number, full_name, hire_date, phone, email, status, role_id, created_at, updated_at) VALUES ('07685c96-3506-4464-b94c-3bb363bb41c7', '777625518', 'victoria cumares', '2026-05-05', '(111) 136-4093', 'cuma@jjj.com', 'Active', 'da849f21-3558-472d-b242-01cb999dd1d5', '2026-05-05 15:29:57.270722+00', '2026-05-05 15:29:57.270722+00');
INSERT INTO public.workers (id, id_number, full_name, hire_date, phone, email, status, role_id, created_at, updated_at) VALUES ('b926c60c-96d3-41a7-90f1-3e01f7c69e01', '66638927', 'yandel alejandro', '2026-05-05', '(555) 466-4888', 'ale@jjj.com', 'Active', 'da849f21-3558-472d-b242-01cb999dd1d5', '2026-05-05 15:30:58.455271+00', '2026-05-05 15:30:58.455271+00');
INSERT INTO public.workers (id, id_number, full_name, hire_date, phone, email, status, role_id, created_at, updated_at) VALUES ('8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', '444277819', 'susy medina', '2026-05-05', '(333) 468-4961', 'susa@hhh.com', 'Active', 'da849f21-3558-472d-b242-01cb999dd1d5', '2026-05-05 15:31:42.051728+00', '2026-05-05 15:31:42.051728+00');
INSERT INTO public.workers (id, id_number, full_name, hire_date, phone, email, status, role_id, created_at, updated_at) VALUES ('7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', '34678987', 'dubrasca luciana', '2026-05-05', '(111) 234-678', 'luci@ggg.com', 'Active', 'da849f21-3558-472d-b242-01cb999dd1d5', '2026-05-05 15:32:54.162642+00', '2026-05-05 15:32:54.162642+00');


--
-- Data for Name: incident_affected_items; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.incident_affected_items (id, incident_id, affected_type, project_material_id, project_machinery_id, project_labor_id, project_instrument_id, worker_id, machinery_inspection_id, project_instrument_assignment_id, resource_name, quantity_affected, unit, description, hourly_cost_rate, daily_rate, days_affected) VALUES ('4b8b2f64-3a14-4cb1-9b5f-8ebf1b74521f', '834ed5d3-e77f-446d-a6aa-22aaa0fe7716', 'machinery', NULL, '84126c63-c471-4316-b2ca-bb4785d7187b', NULL, NULL, NULL, NULL, NULL, 'JD 460P', 1, 'hours', NULL, 86.875, 0, 0);
INSERT INTO public.incident_affected_items (id, incident_id, affected_type, project_material_id, project_machinery_id, project_labor_id, project_instrument_id, worker_id, machinery_inspection_id, project_instrument_assignment_id, resource_name, quantity_affected, unit, description, hourly_cost_rate, daily_rate, days_affected) VALUES ('b0adc7ae-3175-4d23-ac30-30e0e9a9acdb', '4bc83533-5e77-418e-bf20-2b8f38b468ab', 'labor', NULL, NULL, 'efcf18d7-1e1c-4eb9-a317-96e111d64156', NULL, NULL, NULL, NULL, 'Shaper Class B', 1, '', NULL, 20, 0, 0);
INSERT INTO public.incident_affected_items (id, incident_id, affected_type, project_material_id, project_machinery_id, project_labor_id, project_instrument_id, worker_id, machinery_inspection_id, project_instrument_assignment_id, resource_name, quantity_affected, unit, description, hourly_cost_rate, daily_rate, days_affected) VALUES ('9a04e66e-ea3e-4a97-aa38-35aaae1d4510', '12b54a60-ffb5-40cb-86ba-79b52a57320b', 'labor', NULL, NULL, 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, NULL, NULL, NULL, 'TRUCK OPERATOR', 1, 'workers', NULL, 39, 0, 0);
INSERT INTO public.incident_affected_items (id, incident_id, affected_type, project_material_id, project_machinery_id, project_labor_id, project_instrument_id, worker_id, machinery_inspection_id, project_instrument_assignment_id, resource_name, quantity_affected, unit, description, hourly_cost_rate, daily_rate, days_affected) VALUES ('995f72cb-6951-484d-9199-be5e90324d74', '628bb0d3-b1e3-428e-a2f0-5a201bae3c56', 'machinery', NULL, '84126c63-c471-4316-b2ca-bb4785d7187b', NULL, NULL, NULL, NULL, NULL, 'JD 460P', 1, 'hrs', NULL, 86.875, 463.3333333333333, 1);
INSERT INTO public.incident_affected_items (id, incident_id, affected_type, project_material_id, project_machinery_id, project_labor_id, project_instrument_id, worker_id, machinery_inspection_id, project_instrument_assignment_id, resource_name, quantity_affected, unit, description, hourly_cost_rate, daily_rate, days_affected) VALUES ('b0fa12bc-69f6-4f70-b620-db903123ebf4', 'f16308a9-f270-4f29-9c97-c142472ff812', 'machinery', NULL, '53d62d93-4bc1-4466-97a5-237da16b9dfb', NULL, NULL, NULL, NULL, NULL, 'JD 950 L W/GPS', 1, 'hrs', NULL, 55.9375, 298.3333333333333, 1);


--
-- Data for Name: instrument_inspections; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: invoices; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: invoice_change_order_links; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: invoice_details; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: invoice_machinery_deductions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: invoice_sequences; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: project_tasks; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_tasks (id, project_id, quote_service_id, name, description, status, estimated_hours, actual_hours, created_at) VALUES ('a9d57768-0155-49a8-9b2e-e7d11a362ae7', '24d128a9-5591-4cd2-b218-2fdfc93bb18f', '3d08f851-b15e-46a6-bf68-ac823bce1f45', 'TOPSOIL MANAGEMENT', NULL, 'pending', 0, 0, '2026-05-11 13:07:07.376558+00');
INSERT INTO public.project_tasks (id, project_id, quote_service_id, name, description, status, estimated_hours, actual_hours, created_at) VALUES ('0c1b1aaa-0084-442c-804a-f1f503e7593e', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', 'TOPSOIL MANAGEMENT', NULL, 'pending', 0, 0, '2026-06-29 19:29:37.682279+00');
INSERT INTO public.project_tasks (id, project_id, quote_service_id, name, description, status, estimated_hours, actual_hours, created_at) VALUES ('a8fd1743-f603-40d4-8008-7072eb6c1234', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', 'c55610c7-86d5-497a-9513-97b9a315c49f', 'CLEARING', NULL, 'pending', 0, 0, '2026-06-29 19:29:37.682279+00');


--
-- Data for Name: labor_checkins; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: logistics_applications; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.logistics_applications (id, name, created_at) VALUES ('d57a9120-618b-4443-914e-3d63321fe726', 'Medidas', '2026-05-14 14:50:12.622913+00');
INSERT INTO public.logistics_applications (id, name, created_at) VALUES ('5836847f-311b-478f-91e7-5e9f26588af6', 'Compactar', '2026-05-14 14:50:20.709746+00');
INSERT INTO public.logistics_applications (id, name, created_at) VALUES ('03b6f504-efaf-4417-afa8-ceaa153cbe26', 'Calibraci??n', '2026-05-14 14:50:30.356858+00');
INSERT INTO public.logistics_applications (id, name, created_at) VALUES ('3aef1ade-d3ee-4a4c-98b5-757a6486c876', 'Administrativo', '2026-05-14 14:51:29.305847+00');


--
-- Data for Name: machinery_applications; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: material_receptions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: payroll_periods; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: weekly_inspections; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.weekly_inspections (id, project_id, inspection_date, inspector_id, method, general_notes, evidence_files, status, created_at, updated_at) VALUES ('33d6457a-7eb2-4e4c-a159-7a2f562b6ca4', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '2026-07-07', '3b3df1db-8109-4414-b451-6b9e22435254', 'drone', '1234', '[{"url": "http://127.0.0.1:8001/storage/v1/object/public/inspections/1783434297424_40_conex_Office_-_Storage.png", "type": "photo", "description": "40 conex Office - Storage.png"}]', 'approved', '2026-07-07 14:24:59.923063+00', '2026-07-07 17:16:20.02281+00');
INSERT INTO public.weekly_inspections (id, project_id, inspection_date, inspector_id, method, general_notes, evidence_files, status, created_at, updated_at) VALUES ('54d54992-8d2e-47f7-bb3b-ceed73c7c997', '4c03065f-a79b-4086-bbcf-4b3e5c5467dd', '2026-07-07', '097e8824-e345-46ae-b66d-8fb5452fd3c5', 'gps', '121231231', '[{"url": "http://127.0.0.1:8001/storage/v1/object/public/inspections/1783445590095_500_GL_FUEL_TANK.png", "type": "photo", "description": "500 GL FUEL TANK.png"}]', 'draft', '2026-07-07 17:33:10.92268+00', '2026-07-07 17:33:10.92268+00');


--
-- Data for Name: weekly_inspection_details; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.weekly_inspection_details (id, inspection_id, quote_service_id, measured_quantity, unit, total_planned_quantity, percentage_completion, notes, created_at) VALUES ('e684af14-1173-49ee-b1bb-743141d995c5', '33d6457a-7eb2-4e4c-a159-7a2f562b6ca4', '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', 16000, 'CY', 250000, 6.40, '321', '2026-07-07 14:25:00.123343+00');
INSERT INTO public.weekly_inspection_details (id, inspection_id, quote_service_id, measured_quantity, unit, total_planned_quantity, percentage_completion, notes, created_at) VALUES ('d22ac9f1-7a64-436b-b553-d3956022353d', '33d6457a-7eb2-4e4c-a159-7a2f562b6ca4', 'c55610c7-86d5-497a-9513-97b9a315c49f', 45, 'AC', 80, 56.25, '21', '2026-07-07 14:25:00.318092+00');
INSERT INTO public.weekly_inspection_details (id, inspection_id, quote_service_id, measured_quantity, unit, total_planned_quantity, percentage_completion, notes, created_at) VALUES ('b3f28aae-9e59-4051-9d2b-be813d74be52', '54d54992-8d2e-47f7-bb3b-ceed73c7c997', 'd132154f-655b-4ad1-8321-9e4a7fae0706', 41111, 'CY', 5000, 822.22, '45454', '2026-07-07 17:33:10.997193+00');
INSERT INTO public.weekly_inspection_details (id, inspection_id, quote_service_id, measured_quantity, unit, total_planned_quantity, percentage_completion, notes, created_at) VALUES ('4ec80618-5465-475c-8c2c-b1512b6acf8e', '54d54992-8d2e-47f7-bb3b-ceed73c7c997', 'fa87a96a-9271-4ed4-a57a-148bd61f0a4e', 21, 'SQFT', 45000, 0.05, '4545', '2026-07-07 17:33:11.064129+00');


--
-- Data for Name: progress_comparisons; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.progress_comparisons (id, inspection_id, inspection_detail_id, quote_service_id, period_start, period_end, accumulated_daily_quantity, inspection_measured_quantity, deviation_absolute, deviation_percentage, threshold_configured, exceeds_threshold, status, reconciliation_notes, proposed_by, proposed_at, approved_by, approved_at, created_at, updated_at) VALUES ('e1b85d17-3f09-40dc-8bbd-0f9a5f68b30f', '33d6457a-7eb2-4e4c-a159-7a2f562b6ca4', 'e684af14-1173-49ee-b1bb-743141d995c5', '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', '2026-07-01', '2026-07-07', 13500, 16000, 2500, 1, 5, false, 'comparison_done', NULL, NULL, NULL, NULL, NULL, '2026-07-07 17:35:24.773684+00', '2026-07-07 17:35:24.773684+00');
INSERT INTO public.progress_comparisons (id, inspection_id, inspection_detail_id, quote_service_id, period_start, period_end, accumulated_daily_quantity, inspection_measured_quantity, deviation_absolute, deviation_percentage, threshold_configured, exceeds_threshold, status, reconciliation_notes, proposed_by, proposed_at, approved_by, approved_at, created_at, updated_at) VALUES ('8f9f893c-d654-4fef-b6d5-05bcae5c597b', '33d6457a-7eb2-4e4c-a159-7a2f562b6ca4', 'd22ac9f1-7a64-436b-b553-d3956022353d', 'c55610c7-86d5-497a-9513-97b9a315c49f', '2026-07-01', '2026-07-07', 26, 45, 19, 23.75, 5, true, 'reconciled', '', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-07 13:36:47.478+00', '097e8824-e345-46ae-b66d-8fb5452fd3c5', '2026-07-07 13:51:34.055+00', '2026-07-07 17:35:24.687052+00', '2026-07-07 17:51:34.063418+00');


--
-- Data for Name: progress_adjustments; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.progress_adjustments (id, comparison_id, daily_report_id, resource_type, log_id, field_name, original_value, adjusted_value, adjustment_reason, adjusted_by, adjusted_at) VALUES ('617719b1-b740-4e1f-841b-fdc622c72619', '8f9f893c-d654-4fef-b6d5-05bcae5c597b', '0189c613-db85-44ce-a4e2-a76a35df777f', 'machinery', 'e452ba21-0106-4461-a6fa-d62ba2c7b9df', 'production_value', 5, 10, '5444', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-07 17:36:47.404929+00');
INSERT INTO public.progress_adjustments (id, comparison_id, daily_report_id, resource_type, log_id, field_name, original_value, adjusted_value, adjustment_reason, adjusted_by, adjusted_at) VALUES ('d6329335-0a7c-4282-8c33-28a040d462c1', '8f9f893c-d654-4fef-b6d5-05bcae5c597b', '0189c613-db85-44ce-a4e2-a76a35df777f', 'machinery', '23f9501e-99f7-4191-a0f6-ec42affb01e9', 'production_value', 5, 510, '0000', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-07 17:36:47.467242+00');


--
-- Data for Name: project_labor_assignments; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_labor_assignments (id, project_labor_id, worker_id, assigned_at, start_date, end_date, actual_start_date, actual_end_date, status) VALUES ('b8fb68f8-5188-45fa-a253-ed84c61704b5', '37921a1d-f665-49ec-9094-dc8219d8c9e5', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', '2026-06-29 19:35:35.381363+00', '2026-07-01', '2026-07-11', NULL, NULL, 'scheduled');
INSERT INTO public.project_labor_assignments (id, project_labor_id, worker_id, assigned_at, start_date, end_date, actual_start_date, actual_end_date, status) VALUES ('9e28ef8f-9e23-4512-9324-7027750b9b2e', '37921a1d-f665-49ec-9094-dc8219d8c9e5', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', '2026-06-29 19:35:39.251003+00', '2026-07-01', '2026-07-11', NULL, NULL, 'scheduled');
INSERT INTO public.project_labor_assignments (id, project_labor_id, worker_id, assigned_at, start_date, end_date, actual_start_date, actual_end_date, status) VALUES ('4649cd17-55d4-4e80-a200-07e6b3468564', '43d17634-174a-480b-8eb1-d60fcefbf1ad', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', '2026-06-29 19:36:03.663758+00', '2026-07-01', '2026-07-11', NULL, NULL, 'scheduled');
INSERT INTO public.project_labor_assignments (id, project_labor_id, worker_id, assigned_at, start_date, end_date, actual_start_date, actual_end_date, status) VALUES ('dcc53adf-cb86-4745-897a-e8a57fc3bc27', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', 'd356e711-a989-4ac6-8a0e-b352596f0524', '2026-06-29 19:36:26.299233+00', '2026-07-01', '2026-11-11', NULL, NULL, 'scheduled');
INSERT INTO public.project_labor_assignments (id, project_labor_id, worker_id, assigned_at, start_date, end_date, actual_start_date, actual_end_date, status) VALUES ('f6ef5e19-1239-4ebb-998b-5929f53b3fb9', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', 'af647f93-7be5-47ec-83d5-4627eb3393b8', '2026-06-29 19:36:29.095412+00', '2026-07-01', '2026-11-11', NULL, NULL, 'scheduled');
INSERT INTO public.project_labor_assignments (id, project_labor_id, worker_id, assigned_at, start_date, end_date, actual_start_date, actual_end_date, status) VALUES ('95d23cf6-0e43-49ec-bdd8-2e43dedc68ef', 'efcf18d7-1e1c-4eb9-a317-96e111d64156', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', '2026-06-29 19:38:00.233283+00', '2026-07-01', '2026-11-11', NULL, NULL, 'scheduled');
INSERT INTO public.project_labor_assignments (id, project_labor_id, worker_id, assigned_at, start_date, end_date, actual_start_date, actual_end_date, status) VALUES ('117995af-101c-4ee9-8ae1-1b5d2489a613', '7bee13b5-d8ae-463a-9256-0335861713a5', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', '2026-06-29 19:44:00.344758+00', '2026-07-01', '2026-07-08', NULL, NULL, 'scheduled');


--
-- Data for Name: project_machinery_assignments; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_machinery_assignments (id, project_machinery_id, start_date, end_date, quantity, actual_start_date, actual_end_date, status, created_at) VALUES ('a7bd03e8-8baf-47ce-982f-7a7cb4b57f64', '6ca6fa47-1ddd-43de-824c-e9e6b0b62930', '2026-07-01', '2026-07-11', 1, NULL, NULL, 'scheduled', '2026-06-29 19:30:09.453929+00');
INSERT INTO public.project_machinery_assignments (id, project_machinery_id, start_date, end_date, quantity, actual_start_date, actual_end_date, status, created_at) VALUES ('34f29b0c-dcc6-490a-a5d7-5aefd1d22455', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '2026-07-01', '2026-07-11', 2, NULL, NULL, 'scheduled', '2026-06-29 19:30:29.366012+00');
INSERT INTO public.project_machinery_assignments (id, project_machinery_id, start_date, end_date, quantity, actual_start_date, actual_end_date, status, created_at) VALUES ('6fb7981a-70e1-4db8-9dd7-de827df3416e', '53d62d93-4bc1-4466-97a5-237da16b9dfb', '2026-07-01', '2026-11-11', 1, NULL, NULL, 'scheduled', '2026-06-29 19:30:54.632182+00');
INSERT INTO public.project_machinery_assignments (id, project_machinery_id, start_date, end_date, quantity, actual_start_date, actual_end_date, status, created_at) VALUES ('d4f8172e-317c-49a4-b0eb-151e57884b1f', '84126c63-c471-4316-b2ca-bb4785d7187b', '2026-07-01', '2026-11-11', 2, NULL, NULL, 'scheduled', '2026-06-29 19:31:26.731274+00');
INSERT INTO public.project_machinery_assignments (id, project_machinery_id, start_date, end_date, quantity, actual_start_date, actual_end_date, status, created_at) VALUES ('724c0cc5-7ddc-475e-ac91-d7f054b0a9bc', '82b8fb7c-1be7-46da-9695-9f151860b475', '2026-07-01', '2026-08-07', 1, NULL, NULL, 'scheduled', '2026-06-29 19:42:14.424983+00');


--
-- Data for Name: project_non_working_days; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_non_working_days (id, project_id, date, reason, partial_ratio, daily_report_id, created_at) VALUES ('c5970277-c40d-42e6-8f2f-e99309c659d4', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '2026-07-03', 'Adverse weather', 1, '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', '2026-07-03 15:34:01.564751+00');
INSERT INTO public.project_non_working_days (id, project_id, date, reason, partial_ratio, daily_report_id, created_at) VALUES ('efeca56a-1af2-4e4a-8f16-77a11ee9e8c2', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e', '2026-07-05', 'Adverse weather', 1, '722a010f-3fa9-486f-804a-9e90b9fa5203', '2026-07-03 18:48:43.827829+00');


--
-- Data for Name: quote_service_estimations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.quote_service_estimations (id, quote_service_id, topsoil_volume, compacted_volume, swell_factor, total_cy_loose, start_date, end_date, total_working_days, created_at, updated_at, thickness_inches, gravel_thickness_inches, trench_width_inches, trench_depth_inches) VALUES ('d12c5416-95a9-40bc-9cd0-a8a098761b24', 'be323d33-83cc-40f2-b3e9-e514b3ad72e3', 50000, 200000, 0.15, 200000, '2026-07-01 00:00:00+00', '2026-08-20 00:00:00+00', 44, '2026-06-27 21:29:09.081578+00', '2026-06-27 21:29:09.081578+00', 0, 0, 0.00, 0.00);
INSERT INTO public.quote_service_estimations (id, quote_service_id, topsoil_volume, compacted_volume, swell_factor, total_cy_loose, start_date, end_date, total_working_days, created_at, updated_at, thickness_inches, gravel_thickness_inches, trench_width_inches, trench_depth_inches) VALUES ('7d32b35c-3fae-48b8-b931-16bb0a8a5037', '1153213f-84f6-4776-885f-9e8cab1f1ca8', 0, 80, 0.15, 80, '2026-07-01 00:00:00+00', '2026-07-10 00:00:00+00', 9, '2026-06-27 21:29:09.241964+00', '2026-06-27 21:29:09.241964+00', 0, 0, 0.00, 0.00);
INSERT INTO public.quote_service_estimations (id, quote_service_id, topsoil_volume, compacted_volume, swell_factor, total_cy_loose, start_date, end_date, total_working_days, created_at, updated_at, thickness_inches, gravel_thickness_inches, trench_width_inches, trench_depth_inches) VALUES ('0afb5c3a-0f67-4525-b8ee-be9f1c32e469', '98dec84b-2cb2-49d7-b19e-9b17cdf1abf5', 50000, 250000, 0.15, 250000, '2026-07-01 00:00:00+00', '2026-10-30 00:00:00+00', 105, '2026-06-29 19:20:49.231606+00', '2026-06-29 19:20:49.231606+00', 0, 0, 0.00, 0.00);
INSERT INTO public.quote_service_estimations (id, quote_service_id, topsoil_volume, compacted_volume, swell_factor, total_cy_loose, start_date, end_date, total_working_days, created_at, updated_at, thickness_inches, gravel_thickness_inches, trench_width_inches, trench_depth_inches) VALUES ('a7921553-60cf-4f9a-a899-5d27582dbed1', 'c55610c7-86d5-497a-9513-97b9a315c49f', 0, 80, 0.15, 80, '2026-07-01 00:00:00+00', '2026-07-10 00:00:00+00', 9, '2026-06-29 19:20:49.371259+00', '2026-06-29 19:20:49.371259+00', 0, 0, 0.00, 0.00);


--
-- Data for Name: quote_service_estimation_resources; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.quote_service_estimation_resources (id, estimation_id, machine_id, quantity, trips_per_day, capacity_per_trip, created_at, parent_resource_id, is_primary_mover, performance_per_day) VALUES ('c1f3cd4c-0065-45ba-936f-be2d85b6857a', 'd12c5416-95a9-40bc-9cd0-a8a098761b24', '17b24170-9b73-4c7b-928f-74f4692a741b', 4, 60, 30, '2026-06-27 21:29:09.099252+00', NULL, true, 0);
INSERT INTO public.quote_service_estimation_resources (id, estimation_id, machine_id, quantity, trips_per_day, capacity_per_trip, created_at, parent_resource_id, is_primary_mover, performance_per_day) VALUES ('aa5c6d90-2a49-4b2e-972a-c3fa2eae6de0', 'd12c5416-95a9-40bc-9cd0-a8a098761b24', 'bfc62521-5d00-47af-9a6d-8b35961f0c83', 1, 0, 0, '2026-06-27 21:29:09.124504+00', 'c1f3cd4c-0065-45ba-936f-be2d85b6857a', false, 0);
INSERT INTO public.quote_service_estimation_resources (id, estimation_id, machine_id, quantity, trips_per_day, capacity_per_trip, created_at, parent_resource_id, is_primary_mover, performance_per_day) VALUES ('f4b6ea7b-adf1-4188-8638-534a61fccdbc', '7d32b35c-3fae-48b8-b931-16bb0a8a5037', 'bfc62521-5d00-47af-9a6d-8b35961f0c83', 2, 1, 8, '2026-06-27 21:29:09.2519+00', NULL, true, 5);
INSERT INTO public.quote_service_estimation_resources (id, estimation_id, machine_id, quantity, trips_per_day, capacity_per_trip, created_at, parent_resource_id, is_primary_mover, performance_per_day) VALUES ('75cb9f49-36a0-44eb-8a09-9d2bc8908342', '7d32b35c-3fae-48b8-b931-16bb0a8a5037', 'f6fa790b-b2c5-43a8-8a0c-2cb76d3a7a50', 1, 0, 0, '2026-06-27 21:29:09.264522+00', 'f4b6ea7b-adf1-4188-8638-534a61fccdbc', false, 0);
INSERT INTO public.quote_service_estimation_resources (id, estimation_id, machine_id, quantity, trips_per_day, capacity_per_trip, created_at, parent_resource_id, is_primary_mover, performance_per_day) VALUES ('55032d8d-cd87-4222-bc77-952b9f91ec8c', '7d32b35c-3fae-48b8-b931-16bb0a8a5037', '1a298eed-6ae3-4c40-828a-01f16160a32a', 1, 0, 0, '2026-06-27 21:29:09.264522+00', 'f4b6ea7b-adf1-4188-8638-534a61fccdbc', false, 0);
INSERT INTO public.quote_service_estimation_resources (id, estimation_id, machine_id, quantity, trips_per_day, capacity_per_trip, created_at, parent_resource_id, is_primary_mover, performance_per_day) VALUES ('f238b917-deca-4d6e-aa88-a2b098dd0c34', '0afb5c3a-0f67-4525-b8ee-be9f1c32e469', '17b24170-9b73-4c7b-928f-74f4692a741b', 2, 60, 30, '2026-06-29 19:20:49.24727+00', NULL, true, 0);
INSERT INTO public.quote_service_estimation_resources (id, estimation_id, machine_id, quantity, trips_per_day, capacity_per_trip, created_at, parent_resource_id, is_primary_mover, performance_per_day) VALUES ('b161db5b-4e01-4363-a7ee-2acfb5e70e6c', '0afb5c3a-0f67-4525-b8ee-be9f1c32e469', 'bfc62521-5d00-47af-9a6d-8b35961f0c83', 1, 0, 0, '2026-06-29 19:20:49.263028+00', 'f238b917-deca-4d6e-aa88-a2b098dd0c34', false, 0);
INSERT INTO public.quote_service_estimation_resources (id, estimation_id, machine_id, quantity, trips_per_day, capacity_per_trip, created_at, parent_resource_id, is_primary_mover, performance_per_day) VALUES ('45ed0eb0-ee07-4663-b55e-5346d809fee6', 'a7921553-60cf-4f9a-a899-5d27582dbed1', 'e2d5d145-b6fc-45d2-a9b4-05146c72e968', 2, 1, 6, '2026-06-29 19:20:49.385893+00', NULL, true, 5);
INSERT INTO public.quote_service_estimation_resources (id, estimation_id, machine_id, quantity, trips_per_day, capacity_per_trip, created_at, parent_resource_id, is_primary_mover, performance_per_day) VALUES ('ce9bf309-0675-407b-894c-65843aa6e2d0', 'a7921553-60cf-4f9a-a899-5d27582dbed1', 'f6fa790b-b2c5-43a8-8a0c-2cb76d3a7a50', 1, 0, 0, '2026-06-29 19:20:49.399973+00', '45ed0eb0-ee07-4663-b55e-5346d809fee6', false, 0);


--
-- Data for Name: report_labor_logs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('7be74f10-e04e-4809-98ef-01bb9e657932', '0189c613-db85-44ce-a4e2-a76a35df777f', 'd356e711-a989-4ac6-8a0e-b352596f0524', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-06-29 19:52:46.863275+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('4e23f479-10a0-43a4-8a73-1605a227e3a8', '0189c613-db85-44ce-a4e2-a76a35df777f', 'af647f93-7be5-47ec-83d5-4627eb3393b8', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-06-29 19:52:46.863275+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('e282ebe7-3ccb-4eb7-9439-fd4b4af3f117', '0189c613-db85-44ce-a4e2-a76a35df777f', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', '7bee13b5-d8ae-463a-9256-0335861713a5', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-06-29 19:52:46.863275+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('23a677eb-2691-4bf4-a62e-f5efbd18a076', '0189c613-db85-44ce-a4e2-a76a35df777f', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', 'efcf18d7-1e1c-4eb9-a317-96e111d64156', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-06-29 19:52:46.863275+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('252f147a-57f4-455c-b4e6-09e3d787fa0c', '0189c613-db85-44ce-a4e2-a76a35df777f', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-06-29 19:52:46.863275+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('e7a6c292-57e1-459e-8c03-ad35002cafed', '0189c613-db85-44ce-a4e2-a76a35df777f', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-06-29 19:52:46.863275+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('fa58e2cf-87de-4f4c-aa5f-57ffa4333274', '0189c613-db85-44ce-a4e2-a76a35df777f', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', '43d17634-174a-480b-8eb1-d60fcefbf1ad', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-06-29 19:52:46.863275+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('3d617fcc-98f3-40b0-8011-31c1cf8ef33b', '2b42c06c-c5b7-4a98-91db-e12128dfe7f4', 'd356e711-a989-4ac6-8a0e-b352596f0524', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-02 19:37:52.977713+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('b950bb03-dec6-4423-b50e-4f281fc2073a', '2b42c06c-c5b7-4a98-91db-e12128dfe7f4', 'af647f93-7be5-47ec-83d5-4627eb3393b8', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-02 19:37:52.977713+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('85734095-73b2-4ee4-b962-ed7acc85312e', '2b42c06c-c5b7-4a98-91db-e12128dfe7f4', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', '7bee13b5-d8ae-463a-9256-0335861713a5', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-02 19:37:52.977713+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('0a7b2db4-0209-4d16-b0fe-1470f3d253df', '2b42c06c-c5b7-4a98-91db-e12128dfe7f4', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-02 19:37:52.977713+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('5c17986f-6380-47c2-91a0-a270e57fe63a', '2b42c06c-c5b7-4a98-91db-e12128dfe7f4', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-02 19:37:52.977713+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('9ed7e034-74f4-449a-ba72-3e312f77a68a', '2b42c06c-c5b7-4a98-91db-e12128dfe7f4', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', 'efcf18d7-1e1c-4eb9-a317-96e111d64156', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-02 19:37:52.977713+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('bc0487a1-242e-41f5-98b9-689a35f10e86', '2b42c06c-c5b7-4a98-91db-e12128dfe7f4', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', '43d17634-174a-480b-8eb1-d60fcefbf1ad', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-02 19:37:52.977713+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('93b75d48-0a46-4429-bdbd-1eb6a271568f', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', 'd356e711-a989-4ac6-8a0e-b352596f0524', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:00:00', '12:00:00', 5, 0, false, NULL, '', '2026-07-03 15:25:15.561217+00', 0, 5);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('c91c336a-a833-4e12-ba4a-4abc1cddfa92', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', 'af647f93-7be5-47ec-83d5-4627eb3393b8', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:30:00', '12:00:00', 4.5, 0, false, NULL, '', '2026-07-03 15:25:15.561217+00', 0, 4.5);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('84f93927-dd78-4cb8-973a-2db5001d4b14', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', '7bee13b5-d8ae-463a-9256-0335861713a5', NULL, '07:00:00', '12:00:00', 5, 0, false, NULL, '', '2026-07-03 15:25:15.561217+00', 0, 5);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('f09ac418-0227-4d89-8d12-ba3fd0f05a5d', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', 'efcf18d7-1e1c-4eb9-a317-96e111d64156', NULL, '07:00:00', '12:00:00', 5, 0, false, NULL, '', '2026-07-03 15:25:15.561217+00', 0, 5);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('81c39800-dfff-4ecf-9c94-1a49057b7968', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:00:00', '12:00:00', 5, 0, false, NULL, '', '2026-07-03 15:25:15.561217+00', 0, 5);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('73d39e81-5ef0-45fd-9850-f54a647fcbce', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:00:00', '12:00:00', 5, 0, false, NULL, '', '2026-07-03 15:25:15.561217+00', 0, 5);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('c65a545e-6225-4014-824a-49384e54efc0', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', '43d17634-174a-480b-8eb1-d60fcefbf1ad', NULL, '07:00:00', '12:00:00', 5, 0, false, NULL, '', '2026-07-03 15:25:15.561217+00', 0, 5);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('298acf0b-c81a-42b5-a0eb-da2aafb5e545', 'b759434d-c175-41ae-be7b-0d7b7b52185d', 'd356e711-a989-4ac6-8a0e-b352596f0524', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:00:00', '16:00:00', 8, 0.5, false, NULL, '', '2026-07-03 18:47:18.928295+00', 30, 8.5);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('7a1147a0-758d-455e-8afb-aed45d555b98', 'b759434d-c175-41ae-be7b-0d7b7b52185d', 'af647f93-7be5-47ec-83d5-4627eb3393b8', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-03 18:47:18.928295+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('f4bd48da-8a1d-4e14-8bed-45547f316c02', 'b759434d-c175-41ae-be7b-0d7b7b52185d', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', '7bee13b5-d8ae-463a-9256-0335861713a5', NULL, '08:00:00', '16:30:00', 8, 0, false, NULL, '', '2026-07-03 18:47:18.928295+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('3bbccaee-1ac4-4592-89d6-1a4b7fad4da2', 'b759434d-c175-41ae-be7b-0d7b7b52185d', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', 'efcf18d7-1e1c-4eb9-a317-96e111d64156', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-03 18:47:18.928295+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('d4034403-2465-450a-bfa1-fa72f7870694', 'b759434d-c175-41ae-be7b-0d7b7b52185d', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:30:00', '16:30:00', 8, 0.5, false, NULL, '', '2026-07-03 18:47:18.928295+00', 30, 8.5);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('0b0dceb5-2bf7-4537-af66-0af1b43a96c5', 'b759434d-c175-41ae-be7b-0d7b7b52185d', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-03 18:47:18.928295+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('61acce93-a9f6-4f41-bb2f-585409e62007', 'b759434d-c175-41ae-be7b-0d7b7b52185d', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', '43d17634-174a-480b-8eb1-d60fcefbf1ad', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-03 18:47:18.928295+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('d35e5b86-be56-4f42-97fa-a906cc7679bf', '722a010f-3fa9-486f-804a-9e90b9fa5203', 'd356e711-a989-4ac6-8a0e-b352596f0524', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-03 18:48:43.890835+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('bd406487-3445-4e59-a27e-24d460abf2f5', '722a010f-3fa9-486f-804a-9e90b9fa5203', 'af647f93-7be5-47ec-83d5-4627eb3393b8', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-03 18:48:43.890835+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('dfb6b620-b91d-43d5-b0cc-c8ec9a252f1d', '722a010f-3fa9-486f-804a-9e90b9fa5203', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', '7bee13b5-d8ae-463a-9256-0335861713a5', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-03 18:48:43.890835+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('5230578b-bf9d-4acf-931b-896d0b112468', '722a010f-3fa9-486f-804a-9e90b9fa5203', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-03 18:48:43.890835+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('24c0577e-11f7-432d-ab0f-da56067b2df6', '722a010f-3fa9-486f-804a-9e90b9fa5203', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-03 18:48:43.890835+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('0ab7d2a2-acf7-4b10-a0b8-4a3e6003325b', '722a010f-3fa9-486f-804a-9e90b9fa5203', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', 'efcf18d7-1e1c-4eb9-a317-96e111d64156', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-03 18:48:43.890835+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('04ec242e-92bd-43c0-8d0f-e989dc8d2edb', '722a010f-3fa9-486f-804a-9e90b9fa5203', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', '43d17634-174a-480b-8eb1-d60fcefbf1ad', NULL, '07:00:00', '08:00:00', 1, 0, true, NULL, '', '2026-07-03 18:48:43.890835+00', 0, 1);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('7c40d850-8f6c-437e-933c-052645f6c9e6', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', 'd356e711-a989-4ac6-8a0e-b352596f0524', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-06 13:55:57.440013+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('6d163a99-095c-4231-80a2-9430f8bbd790', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', 'af647f93-7be5-47ec-83d5-4627eb3393b8', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-06 13:55:57.440013+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('d64cdbd9-8d69-40b1-87fa-0f8846f9f2b2', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', '7bee13b5-d8ae-463a-9256-0335861713a5', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-06 13:55:57.440013+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('f6734be5-81c1-4be6-b6bf-b454f6a6f83b', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', 'efcf18d7-1e1c-4eb9-a317-96e111d64156', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-06 13:55:57.440013+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('86ad3752-f9ab-46bd-9801-4de1968d41d1', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-06 13:55:57.440013+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('cb594c4e-0e94-4dac-b282-7e6f4c287090', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-06 13:55:57.440013+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('29f72174-f68e-4949-ab65-296a3a212911', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', '43d17634-174a-480b-8eb1-d60fcefbf1ad', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-06 13:55:57.440013+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('6d1a4716-75df-4b4e-8a72-87123c665b8d', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', 'd356e711-a989-4ac6-8a0e-b352596f0524', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-10 00:53:19.770876+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('ef1afaa9-2bfd-48ee-88d9-ad8fe1f59b53', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', 'af647f93-7be5-47ec-83d5-4627eb3393b8', 'a42f03b7-281a-4a1c-9f28-b28d4ac71cbb', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-10 00:53:19.770876+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('0225e802-d25b-40a9-93e1-41baa10c8908', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', '7bee13b5-d8ae-463a-9256-0335861713a5', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-10 00:53:19.770876+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('d026dbe2-d020-41dd-90ed-9c725d4e4ff8', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', 'efcf18d7-1e1c-4eb9-a317-96e111d64156', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-10 00:53:19.770876+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('4779ed6b-5f92-4619-851f-21fb3ad65d1c', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-10 00:53:19.770876+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('4cacf209-92a0-4f64-a2b2-b87572920d14', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', '37921a1d-f665-49ec-9094-dc8219d8c9e5', NULL, '07:30:00', '16:00:00', 8, 0, false, NULL, '', '2026-07-10 00:53:19.770876+00', 30, 8);
INSERT INTO public.report_labor_logs (id, daily_report_id, worker_id, project_labor_id, project_task_id, check_in_time, check_out_time, regular_hours, overtime_hours, is_unplanned, deviation_reason_id, notes, created_at, break_minutes, total_net_hours) VALUES ('0f6c2f17-5aef-4c87-b78a-98ffb7b82964', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', '43d17634-174a-480b-8eb1-d60fcefbf1ad', NULL, '07:30:00', '16:30:00', 8, 0.5, false, NULL, '', '2026-07-10 00:53:19.770876+00', 30, 8.5);


--
-- Data for Name: report_machinery_logs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('cb378706-c228-49f7-9ae0-93a2ab157bb5', '0189c613-db85-44ce-a4e2-a76a35df777f', 'f6fa790b-b2c5-43a8-8a0c-2cb76d3a7a50', '6ca6fa47-1ddd-43de-824c-e9e6b0b62930', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', 60, 70, 10, 7, false, NULL, '', '2026-06-29 19:52:46.934344+00', 0, NULL, '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('583a2f22-c98d-451b-ba5a-2d8ca05c5feb', '0189c613-db85-44ce-a4e2-a76a35df777f', 'bfc62521-5d00-47af-9a6d-8b35961f0c83', '53d62d93-4bc1-4466-97a5-237da16b9dfb', 'd356e711-a989-4ac6-8a0e-b352596f0524', 500, 510, 10, 20, false, NULL, '', '2026-06-29 19:52:46.934344+00', 0, NULL, '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('aaf31d20-8362-43ca-925c-4341f8481ba1', '0189c613-db85-44ce-a4e2-a76a35df777f', '17b24170-9b73-4c7b-928f-74f4692a741b', '84126c63-c471-4316-b2ca-bb4785d7187b', 'af647f93-7be5-47ec-83d5-4627eb3393b8', 60, 70, 10, 8, false, NULL, '', '2026-06-29 19:52:46.934344+00', 60, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('6991e46e-e8b2-4050-ac21-35a4d9d255d9', '0189c613-db85-44ce-a4e2-a76a35df777f', '17b24170-9b73-4c7b-928f-74f4692a741b', '84126c63-c471-4316-b2ca-bb4785d7187b', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', 90, 100, 10, 15, false, NULL, '', '2026-06-29 19:52:46.934344+00', 60, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('1fe2d7ac-6931-4b5a-ae14-54125783da6c', '0189c613-db85-44ce-a4e2-a76a35df777f', '17b24170-9b73-4c7b-928f-74f4692a741b', '82b8fb7c-1be7-46da-9695-9f151860b475', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', 60, 70, 10, 122, false, NULL, '', '2026-06-29 19:52:46.934344+00', 60, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('6b8b7fd1-e658-44ad-bec2-c59911a4ba9d', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', 'f6fa790b-b2c5-43a8-8a0c-2cb76d3a7a50', '6ca6fa47-1ddd-43de-824c-e9e6b0b62930', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', 300, 310, 10, 7, false, NULL, '', '2026-07-03 15:39:40.844413+00', 0, NULL, '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('b1f654ac-27cb-4129-933a-bb365de7cd40', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', 'e2d5d145-b6fc-45d2-a9b4-05146c72e968', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', 500, 505, 5, 6, false, NULL, '', '2026-07-03 15:39:40.844413+00', 3, 'ac', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('3d4f4f2e-cc17-4745-a868-d83286ed675a', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', 'e2d5d145-b6fc-45d2-a9b4-05146c72e968', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', 600, 605, 5, 4, false, NULL, '', '2026-07-03 15:39:40.844413+00', 3, 'ac', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('1217b356-8676-4ca3-bf55-484c06fed3ae', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', 'bfc62521-5d00-47af-9a6d-8b35961f0c83', '53d62d93-4bc1-4466-97a5-237da16b9dfb', 'af647f93-7be5-47ec-83d5-4627eb3393b8', 605, 610, 5, 6, false, NULL, '', '2026-07-03 15:39:40.844413+00', 0, NULL, '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('eefca9f3-6dbb-4d4a-8fe9-dfa2d6b86f52', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', '17b24170-9b73-4c7b-928f-74f4692a741b', '84126c63-c471-4316-b2ca-bb4785d7187b', 'd356e711-a989-4ac6-8a0e-b352596f0524', 300, 305, 5, 5, false, NULL, '', '2026-07-03 15:39:40.844413+00', 30, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('419c35b9-30e3-4df6-9fff-f39dcdc18105', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', '17b24170-9b73-4c7b-928f-74f4692a741b', '84126c63-c471-4316-b2ca-bb4785d7187b', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', 10, 15, 5, 5, false, NULL, '', '2026-07-03 15:39:40.844413+00', 30, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('abcf093d-1f5b-4ee3-9c37-68cc738ad39b', '342a9c71-5c06-4d2e-96d9-a3ffc4c65dbe', '17b24170-9b73-4c7b-928f-74f4692a741b', '82b8fb7c-1be7-46da-9695-9f151860b475', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', 10, 15, 5, 5, false, NULL, '', '2026-07-03 15:39:40.844413+00', 30, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('2ef732fb-1008-4304-a22a-59bbf9eb258e', 'b759434d-c175-41ae-be7b-0d7b7b52185d', 'f6fa790b-b2c5-43a8-8a0c-2cb76d3a7a50', '6ca6fa47-1ddd-43de-824c-e9e6b0b62930', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', 400, 425, 25, 5, false, NULL, '', '2026-07-03 18:47:19.027673+00', 0, NULL, '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('44613d8b-1c4c-418f-a135-c0f556fc2f1e', 'b759434d-c175-41ae-be7b-0d7b7b52185d', 'e2d5d145-b6fc-45d2-a9b4-05146c72e968', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', 50, 59, 9, 4, false, NULL, '', '2026-07-03 18:47:19.027673+00', 5, 'ac', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('52a6251f-1fb1-4642-b336-748e3c3a8b85', 'b759434d-c175-41ae-be7b-0d7b7b52185d', 'e2d5d145-b6fc-45d2-a9b4-05146c72e968', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', 55, 64, 9, 5, false, NULL, '', '2026-07-03 18:47:19.027673+00', 5, 'ac', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('a0c82c7f-dae3-41c4-9ebe-6e06ede8c1e0', 'b759434d-c175-41ae-be7b-0d7b7b52185d', 'bfc62521-5d00-47af-9a6d-8b35961f0c83', '53d62d93-4bc1-4466-97a5-237da16b9dfb', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', 212, 220, 8, 5, false, NULL, '', '2026-07-03 18:47:19.027673+00', 0, NULL, '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('13a6f9ef-377b-4ecc-a53f-47f8084d510e', 'b759434d-c175-41ae-be7b-0d7b7b52185d', '17b24170-9b73-4c7b-928f-74f4692a741b', '84126c63-c471-4316-b2ca-bb4785d7187b', 'd356e711-a989-4ac6-8a0e-b352596f0524', 20, 30, 10, 5, false, NULL, '', '2026-07-03 18:47:19.027673+00', 60, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('866be68b-26db-46cf-a0b4-a0ba8ae2335b', 'b759434d-c175-41ae-be7b-0d7b7b52185d', '17b24170-9b73-4c7b-928f-74f4692a741b', '84126c63-c471-4316-b2ca-bb4785d7187b', 'af647f93-7be5-47ec-83d5-4627eb3393b8', 60, 70, 10, 5, false, NULL, '', '2026-07-03 18:47:19.027673+00', 60, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('e1e6cc9d-fba4-4d03-8beb-848f64ec4671', 'b759434d-c175-41ae-be7b-0d7b7b52185d', '17b24170-9b73-4c7b-928f-74f4692a741b', '82b8fb7c-1be7-46da-9695-9f151860b475', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', 50, 59, 9, 5, false, NULL, '', '2026-07-03 18:47:19.027673+00', 60, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('e452ba21-0106-4461-a6fa-d62ba2c7b9df', '0189c613-db85-44ce-a4e2-a76a35df777f', 'e2d5d145-b6fc-45d2-a9b4-05146c72e968', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', 20, 30, 10, 4, false, NULL, '', '2026-06-29 19:52:46.934344+00', 10, 'ac', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('23f9501e-99f7-4191-a0f6-ec42affb01e9', '0189c613-db85-44ce-a4e2-a76a35df777f', 'e2d5d145-b6fc-45d2-a9b4-05146c72e968', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', 500, 520, 20, 5, false, NULL, '', '2026-06-29 19:52:46.934344+00', 510, 'ac', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('95b10a76-bbde-44e2-a3fc-28f9f6b64ef0', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', 'f6fa790b-b2c5-43a8-8a0c-2cb76d3a7a50', '6ca6fa47-1ddd-43de-824c-e9e6b0b62930', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', 45, 55, 10, 5, false, NULL, '', '2026-07-06 13:55:57.589939+00', 0, NULL, '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('d97b5897-8cfe-40f3-b447-6bc6ea4677fe', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', 'e2d5d145-b6fc-45d2-a9b4-05146c72e968', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', 45, 56, 11, 5, false, NULL, '', '2026-07-06 13:55:57.589939+00', 5, 'ac', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('1b241755-d532-4156-a102-adbc6856efd6', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', 'e2d5d145-b6fc-45d2-a9b4-05146c72e968', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', 55, 65, 10, 6, false, NULL, '', '2026-07-06 13:55:57.589939+00', 6, 'ac', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('ddbe3a3f-a472-4723-886f-ef98f4194045', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', 'bfc62521-5d00-47af-9a6d-8b35961f0c83', '53d62d93-4bc1-4466-97a5-237da16b9dfb', 'd356e711-a989-4ac6-8a0e-b352596f0524', 45, 55, 10, 5, false, NULL, '', '2026-07-06 13:55:57.589939+00', 0, NULL, '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('6927b81e-85d8-485b-ae35-058426840bda', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', '17b24170-9b73-4c7b-928f-74f4692a741b', '84126c63-c471-4316-b2ca-bb4785d7187b', 'af647f93-7be5-47ec-83d5-4627eb3393b8', 55, 65, 10, 5, false, NULL, '', '2026-07-06 13:55:57.589939+00', 60, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('cd3b9d44-30f4-4329-8eeb-4f65ad602108', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', '17b24170-9b73-4c7b-928f-74f4692a741b', '84126c63-c471-4316-b2ca-bb4785d7187b', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', 66, 77, 11, 5, false, NULL, '', '2026-07-06 13:55:57.589939+00', 60, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('6478726c-43a6-48f3-9759-bc7129170517', 'c15776cf-5c67-4ee2-858a-ccf5caf3d2e3', '17b24170-9b73-4c7b-928f-74f4692a741b', '82b8fb7c-1be7-46da-9695-9f151860b475', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', 56, 66, 10, 5, false, NULL, '', '2026-07-06 13:55:57.589939+00', 30, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('ddc9a8df-f8c8-4556-aa26-45fcd460bc1e', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', 'f6fa790b-b2c5-43a8-8a0c-2cb76d3a7a50', '6ca6fa47-1ddd-43de-824c-e9e6b0b62930', 'a04bf86e-c6cd-4c9a-b98c-660be9d5a8f2', 20, 30, 10, 5, false, NULL, '', '2026-07-10 00:53:19.841445+00', 0, NULL, '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('ae7a111d-bc80-463a-b2d3-41d169ad3262', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', 'e2d5d145-b6fc-45d2-a9b4-05146c72e968', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '6cd8b219-6aaa-4ce9-ad04-ca1e462b827f', 45, 55, 10, 5, false, NULL, '', '2026-07-10 00:53:19.841445+00', 5, 'ac', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('49a27203-9570-4e5a-a74b-58db851efd01', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', 'e2d5d145-b6fc-45d2-a9b4-05146c72e968', '972a6eb8-025d-4c47-8cc1-3039ef4a623e', '8c9c041d-2a80-4d82-9d53-e1255a3c4b9f', 55, 66, 11, 5, false, NULL, '', '2026-07-10 00:53:19.841445+00', 5, 'ac', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('88ee83d2-ad9d-4b59-831f-27721898e8a8', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', 'bfc62521-5d00-47af-9a6d-8b35961f0c83', '53d62d93-4bc1-4466-97a5-237da16b9dfb', 'd356e711-a989-4ac6-8a0e-b352596f0524', 100, 110, 10, 5, false, NULL, '', '2026-07-10 00:53:19.841445+00', 0, NULL, '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('be1ed4d4-f094-495c-9272-e912cb7f6023', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', '17b24170-9b73-4c7b-928f-74f4692a741b', '84126c63-c471-4316-b2ca-bb4785d7187b', 'af647f93-7be5-47ec-83d5-4627eb3393b8', 10, 20, 10, 5, false, NULL, '', '2026-07-10 00:53:19.841445+00', 60, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('a652b6b7-36a0-43a9-bd89-2f3139bdbfc2', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', '17b24170-9b73-4c7b-928f-74f4692a741b', '84126c63-c471-4316-b2ca-bb4785d7187b', '38dbe85c-a6f8-48ea-a6f2-2816031b064a', 10, 20, 10, 5, false, NULL, '', '2026-07-10 00:53:19.841445+00', 60, 'cy', '[]', '[]', NULL);
INSERT INTO public.report_machinery_logs (id, daily_report_id, machinery_id, project_machinery_id, operator_id, start_meter, end_meter, total_hours, fuel_added, is_unplanned, deviation_reason_id, notes, created_at, production_value, production_unit, start_shift_photos, end_shift_photos, rate_override) VALUES ('276a40f7-3361-4073-a58c-16f4ed1ca733', 'f8dad96e-2e84-4b69-b3a9-793fef3a007a', '17b24170-9b73-4c7b-928f-74f4692a741b', '82b8fb7c-1be7-46da-9695-9f151860b475', '7a3028bc-3aa6-4bb8-98bf-e31d37dc6510', 60, 77, 17, 5, false, NULL, '', '2026-07-10 00:53:19.841445+00', 60, 'cy', '[]', '[]', NULL);


--
-- Data for Name: report_material_usage; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: service_inspection_thresholds; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: worker_role_history; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: messages_2026_07_07; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_07_08; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_07_09; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_07_10; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_07_11; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_07_12; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_07_13; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: -
--

INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116024918, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116045059, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116050929, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116051442, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116212300, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116213355, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116213934, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116214523, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211122062447, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211124070109, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211202204204, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211202204605, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211210212804, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211228014915, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220107221237, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220228202821, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220312004840, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220603231003, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220603232444, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220615214548, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220712093339, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220908172859, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220916233421, '2026-06-27 20:07:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230119133233, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230128025114, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230128025212, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230227211149, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230228184745, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230308225145, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230328144023, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20231018144023, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20231204144023, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20231204144024, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20231204144025, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240108234812, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240109165339, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240227174441, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240311171622, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240321100241, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240401105812, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240418121054, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240523004032, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240618124746, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240801235015, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240805133720, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240827160934, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240919163303, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240919163305, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241019105805, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241030150047, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241108114728, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241121104152, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241130184212, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241220035512, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241220123912, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241224161212, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250107150512, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250110162412, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250123174212, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250128220012, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250506224012, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250523164012, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250714121412, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250905041441, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20251103001201, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20251120212548, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20251120215549, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20260218120000, '2026-06-27 20:07:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20260326120000, '2026-06-27 20:07:14');


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: -
--

INSERT INTO storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) VALUES ('equipment', 'equipment', NULL, '2026-06-27 20:07:24.691993+00', '2026-06-27 20:07:24.691993+00', true, false, NULL, NULL, NULL, 'STANDARD');
INSERT INTO storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) VALUES ('machinery_evidence', 'machinery_evidence', NULL, '2026-06-27 20:07:24.943305+00', '2026-06-27 20:07:24.943305+00', true, false, NULL, NULL, NULL, 'STANDARD');
INSERT INTO storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) VALUES ('incident-photos', 'incident-photos', NULL, '2026-07-02 15:23:23.132101+00', '2026-07-02 15:23:23.132101+00', true, false, NULL, NULL, NULL, 'STANDARD');
INSERT INTO storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) VALUES ('inspections', 'inspections', NULL, '2026-07-06 19:27:54.982857+00', '2026-07-06 19:27:54.982857+00', true, false, 52428800, '{image/jpeg,image/png,image/webp,image/gif}', NULL, 'STANDARD');


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: iceberg_namespaces; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: iceberg_tables; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: -
--

INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (0, 'create-migrations-table', 'e18db593bcde2aca2a408c4d1100f6abba2195df', '2026-06-27 20:07:22.495794');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (1, 'initialmigration', '6ab16121fbaa08bbd11b712d05f358f9b555d777', '2026-06-27 20:07:22.504803');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (2, 'storage-schema', 'f6a1fa2c93cbcd16d4e487b362e45fca157a8dbd', '2026-06-27 20:07:22.510163');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (3, 'pathtoken-column', '2cb1b0004b817b29d5b0a971af16bafeede4b70d', '2026-06-27 20:07:22.524473');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (4, 'add-migrations-rls', '427c5b63fe1c5937495d9c635c263ee7a5905058', '2026-06-27 20:07:22.532735');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (5, 'add-size-functions', '79e081a1455b63666c1294a440f8ad4b1e6a7f84', '2026-06-27 20:07:22.540743');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (6, 'change-column-name-in-get-size', 'ded78e2f1b5d7e616117897e6443a925965b30d2', '2026-06-27 20:07:22.546568');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (7, 'add-rls-to-buckets', 'e7e7f86adbc51049f341dfe8d30256c1abca17aa', '2026-06-27 20:07:22.552386');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (8, 'add-public-to-buckets', 'fd670db39ed65f9d08b01db09d6202503ca2bab3', '2026-06-27 20:07:22.556672');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (9, 'fix-search-function', 'af597a1b590c70519b464a4ab3be54490712796b', '2026-06-27 20:07:22.560724');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (10, 'search-files-search-function', 'b595f05e92f7e91211af1bbfe9c6a13bb3391e16', '2026-06-27 20:07:22.567277');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (11, 'add-trigger-to-auto-update-updated_at-column', '7425bdb14366d1739fa8a18c83100636d74dcaa2', '2026-06-27 20:07:22.57277');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (12, 'add-automatic-avif-detection-flag', '8e92e1266eb29518b6a4c5313ab8f29dd0d08df9', '2026-06-27 20:07:22.577547');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (13, 'add-bucket-custom-limits', 'cce962054138135cd9a8c4bcd531598684b25e7d', '2026-06-27 20:07:22.582095');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (14, 'use-bytes-for-max-size', '941c41b346f9802b411f06f30e972ad4744dad27', '2026-06-27 20:07:22.586481');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (15, 'add-can-insert-object-function', '934146bc38ead475f4ef4b555c524ee5d66799e5', '2026-06-27 20:07:22.59934');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (16, 'add-version', '76debf38d3fd07dcfc747ca49096457d95b1221b', '2026-06-27 20:07:22.605722');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (17, 'drop-owner-foreign-key', 'f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101', '2026-06-27 20:07:22.610412');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (18, 'add_owner_id_column_deprecate_owner', 'e7a511b379110b08e2f214be852c35414749fe66', '2026-06-27 20:07:22.616304');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (19, 'alter-default-value-objects-id', '02e5e22a78626187e00d173dc45f58fa66a4f043', '2026-06-27 20:07:22.621186');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (20, 'list-objects-with-delimiter', 'cd694ae708e51ba82bf012bba00caf4f3b6393b7', '2026-06-27 20:07:22.62669');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (21, 's3-multipart-uploads', '8c804d4a566c40cd1e4cc5b3725a664a9303657f', '2026-06-27 20:07:22.631855');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (22, 's3-multipart-uploads-big-ints', '9737dc258d2397953c9953d9b86920b8be0cdb73', '2026-06-27 20:07:22.643726');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (23, 'optimize-search-function', '9d7e604cddc4b56a5422dc68c9313f4a1b6f132c', '2026-06-27 20:07:22.652695');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (24, 'operation-function', '8312e37c2bf9e76bbe841aa5fda889206d2bf8aa', '2026-06-27 20:07:22.660238');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (25, 'custom-metadata', 'd974c6057c3db1c1f847afa0e291e6165693b990', '2026-06-27 20:07:22.666916');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (26, 'objects-prefixes', '215cabcb7f78121892a5a2037a09fedf9a1ae322', '2026-06-27 20:07:22.67301');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (27, 'search-v2', '859ba38092ac96eb3964d83bf53ccc0b141663a6', '2026-06-27 20:07:22.67886');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (28, 'object-bucket-name-sorting', 'c73a2b5b5d4041e39705814fd3a1b95502d38ce4', '2026-06-27 20:07:22.684121');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (29, 'create-prefixes', 'ad2c1207f76703d11a9f9007f821620017a66c21', '2026-06-27 20:07:22.689126');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (30, 'update-object-levels', '2be814ff05c8252fdfdc7cfb4b7f5c7e17f0bed6', '2026-06-27 20:07:22.69562');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (31, 'objects-level-index', 'b40367c14c3440ec75f19bbce2d71e914ddd3da0', '2026-06-27 20:07:22.701086');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (32, 'backward-compatible-index-on-objects', 'e0c37182b0f7aee3efd823298fb3c76f1042c0f7', '2026-06-27 20:07:22.708313');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (33, 'backward-compatible-index-on-prefixes', 'b480e99ed951e0900f033ec4eb34b5bdcb4e3d49', '2026-06-27 20:07:22.714048');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (34, 'optimize-search-function-v1', 'ca80a3dc7bfef894df17108785ce29a7fc8ee456', '2026-06-27 20:07:22.719529');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (35, 'add-insert-trigger-prefixes', '458fe0ffd07ec53f5e3ce9df51bfdf4861929ccc', '2026-06-27 20:07:22.723748');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (36, 'optimise-existing-functions', '6ae5fca6af5c55abe95369cd4f93985d1814ca8f', '2026-06-27 20:07:22.727951');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (37, 'add-bucket-name-length-trigger', '3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1', '2026-06-27 20:07:22.731876');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (38, 'iceberg-catalog-flag-on-buckets', '02716b81ceec9705aed84aa1501657095b32e5c5', '2026-06-27 20:07:22.737374');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (39, 'add-search-v2-sort-support', '6706c5f2928846abee18461279799ad12b279b78', '2026-06-27 20:07:22.753913');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (40, 'fix-prefix-race-conditions-optimized', '7ad69982ae2d372b21f48fc4829ae9752c518f6b', '2026-06-27 20:07:22.758635');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (41, 'add-object-level-update-trigger', '07fcf1a22165849b7a029deed059ffcde08d1ae0', '2026-06-27 20:07:22.764151');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (42, 'rollback-prefix-triggers', '771479077764adc09e2ea2043eb627503c034cd4', '2026-06-27 20:07:22.769718');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (43, 'fix-object-level', '84b35d6caca9d937478ad8a797491f38b8c2979f', '2026-06-27 20:07:22.773851');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (44, 'vector-bucket-type', '99c20c0ffd52bb1ff1f32fb992f3b351e3ef8fb3', '2026-06-27 20:07:22.779409');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (45, 'vector-buckets', '049e27196d77a7cb76497a85afae669d8b230953', '2026-06-27 20:07:22.784757');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (46, 'buckets-objects-grants', 'fedeb96d60fefd8e02ab3ded9fbde05632f84aed', '2026-06-27 20:07:22.793038');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (47, 'iceberg-table-metadata', '649df56855c24d8b36dd4cc1aeb8251aa9ad42c2', '2026-06-27 20:07:22.799055');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (48, 'iceberg-catalog-ids', 'e0e8b460c609b9999ccd0df9ad14294613eed939', '2026-06-27 20:07:22.803877');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (49, 'buckets-objects-grants-postgres', '072b1195d0d5a2f888af6b2302a1938dd94b8b3d', '2026-06-27 20:07:22.826615');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (50, 'search-v2-optimised', '6323ac4f850aa14e7387eb32102869578b5bd478', '2026-06-27 20:07:22.832022');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (51, 'index-backward-compatible-search', '2ee395d433f76e38bcd3856debaf6e0e5b674011', '2026-06-27 20:07:22.856067');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (52, 'drop-not-used-indexes-and-functions', '5cc44c8696749ac11dd0dc37f2a3802075f3a171', '2026-06-27 20:07:22.859859');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (53, 'drop-index-lower-name', 'd0cb18777d9e2a98ebe0bc5cc7a42e57ebe41854', '2026-06-27 20:07:22.869298');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (54, 'drop-index-object-level', '6289e048b1472da17c31a7eba1ded625a6457e67', '2026-06-27 20:07:22.873477');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (55, 'prevent-direct-deletes', '262a4798d5e0f2e7c8970232e03ce8be695d5819', '2026-06-27 20:07:22.878705');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (56, 'fix-optimized-search-function', 'cb58526ebc23048049fd5bf2fd148d18b04a2073', '2026-06-27 20:07:22.88748');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (57, 's3-multipart-uploads-metadata', 'f127886e00d1b374fadbc7c6b31e09336aad5287', '2026-06-27 20:07:22.894609');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (58, 'operation-ergonomics', '00ca5d483b3fe0d522133d9002ccc5df98365120', '2026-06-27 20:07:22.899744');


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: -
--

INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('eed3d703-0dc7-429d-93b7-17dbbf4e2575', 'equipment', '1778768215979_Toyota_Tundra_Plateum.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:16:59.551573+00', '2026-05-14 14:16:59.551573+00', '2026-05-14 14:16:59.551573+00', '{"eTag": "\"347d3e4368d8e0e5027a3e411634da4d\"", "size": 301626, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:16:59.321Z", "contentLength": 301626, "httpStatusCode": 200}', 'c12d7cc5-aed0-41d9-8f7d-a3e5f8e78c6d', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('c1bcaa17-4a73-41c3-9d54-32939f0c392a', 'equipment', '1778768443575_Polaris_Ranger.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:20:44.322827+00', '2026-05-14 14:20:44.322827+00', '2026-05-14 14:20:44.322827+00', '{"eTag": "\"f90434204edaddf683f325d831275480\"", "size": 3135464, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:20:43.877Z", "contentLength": 3135464, "httpStatusCode": 200}', '94c2ce8f-dd81-400c-bf5d-51a3a7ea553e', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('7039be0b-0d6a-4f4a-ac1c-95a0cb7732ee', 'equipment', '1778768656708_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:24:16.886611+00', '2026-05-14 14:24:16.886611+00', '2026-05-14 14:24:16.886611+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:24:16.866Z", "contentLength": 109635, "httpStatusCode": 200}', '790a8b66-9d52-4d8b-989d-81eafccb043d', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('bcaae435-27c4-448e-8eb5-3fb41cbdf5a8', 'equipment', '1778768737633_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:25:37.723866+00', '2026-05-14 14:25:37.723866+00', '2026-05-14 14:25:37.723866+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:25:37.716Z", "contentLength": 109635, "httpStatusCode": 200}', '0f5aa25e-b7bd-4004-8543-47231a6a1785', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('63733e35-9dd4-4197-9e18-1243b219c88c', 'equipment', '1778768869313_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:27:49.389704+00', '2026-05-14 14:27:49.389704+00', '2026-05-14 14:27:49.389704+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:27:49.381Z", "contentLength": 109635, "httpStatusCode": 200}', '7ec16c14-420d-448e-8e50-e07ea17842aa', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('ad4bdfac-3711-4526-9279-9df29ac99039', 'equipment', '1778768983343_JD_750L.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:29:43.498786+00', '2026-05-14 14:29:43.498786+00', '2026-05-14 14:29:43.498786+00', '{"eTag": "\"a3b5c5e7f404215c7c36ab214acda101\"", "size": 212297, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:29:43.485Z", "contentLength": 212297, "httpStatusCode": 200}', 'aebeac7e-6d27-4189-95b4-9b1f6cab1edd', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('5f0c575b-534e-47d0-92aa-38b187f8071b', 'equipment', '1778769083671_JD_510-350.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:31:23.877791+00', '2026-05-14 14:31:23.877791+00', '2026-05-14 14:31:23.877791+00', '{"eTag": "\"95c1c49e84ededf5653ad3942bcaf1c3\"", "size": 114653, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:31:23.854Z", "contentLength": 114653, "httpStatusCode": 200}', 'd9b8a1f8-4272-430e-bfb9-dbe36c471624', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('f2137f25-9c3c-4a22-b869-6d311072dec6', 'equipment', '1778769173191_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:32:53.358151+00', '2026-05-14 14:32:53.358151+00', '2026-05-14 14:32:53.358151+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:32:53.344Z", "contentLength": 108816, "httpStatusCode": 200}', '9c394882-65af-4e48-8fb1-a97cf56e9d2f', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('58691c5e-59b0-44d6-8cd0-8c4dd3fc3865', 'equipment', '1778769282202_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:34:42.302854+00', '2026-05-14 14:34:42.302854+00', '2026-05-14 14:34:42.302854+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:34:42.292Z", "contentLength": 108816, "httpStatusCode": 200}', '71b1992c-fc77-4bfd-996c-17296d9d45ff', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('e905cdd5-eb90-4db8-9a55-39fc5e2f60d8', 'equipment', '1778769365033_JD_510-350.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:36:05.08884+00', '2026-05-14 14:36:05.08884+00', '2026-05-14 14:36:05.08884+00', '{"eTag": "\"95c1c49e84ededf5653ad3942bcaf1c3\"", "size": 114653, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:36:05.081Z", "contentLength": 114653, "httpStatusCode": 200}', '34228282-8b17-483c-b52c-cacbe312a358', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('b79883a6-a83e-4556-912d-862f48e48f1b', 'equipment', '1778769451977_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:37:32.048095+00', '2026-05-14 14:37:32.048095+00', '2026-05-14 14:37:32.048095+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:37:32.043Z", "contentLength": 109635, "httpStatusCode": 200}', '56b48672-ff2a-4217-84fb-26c4a9e45752', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('e50fef5b-2e08-4dd7-8848-3deb5e9b5fd3', 'equipment', '1778769529952_Cat_K-Teck_1236_scraper.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:38:50.021745+00', '2026-05-14 14:38:50.021745+00', '2026-05-14 14:38:50.021745+00', '{"eTag": "\"a36b2ec3bf70a375897261ade118a9bc\"", "size": 27619, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:38:50.015Z", "contentLength": 27619, "httpStatusCode": 200}', '5a2040b0-1519-4ed6-bac8-394a2801ef08', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('209120ba-8911-4c37-95e2-1af56bf46983', 'equipment', '1778769616676_5-6_Yd_Dump_Truck.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:40:16.744263+00', '2026-05-14 14:40:16.744263+00', '2026-05-14 14:40:16.744263+00', '{"eTag": "\"4bcafd13afb233cc4d60cc6f32e8cc16\"", "size": 72998, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:40:16.736Z", "contentLength": 72998, "httpStatusCode": 200}', 'abec80de-cc82-46a5-8bb1-66726ef5d23c', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('651324ec-88ff-4a66-9632-6fa08fc25e3d', 'equipment', '1778770141403_Juping_Jack.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:49:01.481349+00', '2026-05-14 14:49:01.481349+00', '2026-05-14 14:49:01.481349+00', '{"eTag": "\"22ebea29730f5ac41f333075b9bb2079\"", "size": 91840, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:49:01.476Z", "contentLength": 91840, "httpStatusCode": 200}', '7ac267bd-a5ec-4a85-b17b-45fc74577771', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('cda48b0f-3c98-4f32-8519-f0b073078b9b', 'equipment', '1778770244467_GPS-Topcon.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:50:44.577821+00', '2026-05-14 14:50:44.577821+00', '2026-05-14 14:50:44.577821+00', '{"eTag": "\"5d04a090b76337db9de6fe657e589043\"", "size": 28137, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:50:44.567Z", "contentLength": 28137, "httpStatusCode": 200}', '7accdd80-ba4d-42dc-a6bb-c27627178a4f', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('579dd9ad-7f51-4795-8f5e-154a051f8bc9', 'equipment', '1778770300105_500_GL_FUEL_TANK.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:51:40.16481+00', '2026-05-14 14:51:40.16481+00', '2026-05-14 14:51:40.16481+00', '{"eTag": "\"524a2e8b6159570221ef02489e6390ca\"", "size": 104345, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:51:40.158Z", "contentLength": 104345, "httpStatusCode": 200}', 'bcca837e-1103-4fa7-a5ad-cd176c35d54a', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('ec34b05b-2ca4-4ea7-83c2-0d21297b8975', 'equipment', '1778770355145_40_conex_Office_-_Storage.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:52:35.213722+00', '2026-05-14 14:52:35.213722+00', '2026-05-14 14:52:35.213722+00', '{"eTag": "\"f3befee1387abfb35914d7561fc89248\"", "size": 94071, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:52:35.206Z", "contentLength": 94071, "httpStatusCode": 200}', '206c9905-7e06-468a-91c5-6ac70d08b7ad', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('bb5b835a-0661-48f3-bf4b-867d9fdee4ff', 'equipment', '1778770400033_40_conex_Office_-_Storage.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 14:53:20.115131+00', '2026-05-14 14:53:20.115131+00', '2026-05-14 14:53:20.115131+00', '{"eTag": "\"f3befee1387abfb35914d7561fc89248\"", "size": 94071, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T14:53:20.107Z", "contentLength": 94071, "httpStatusCode": 200}', '8734d794-271e-4ea0-97a3-1e05f5525682', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('e80c6d3f-4cc0-4530-b156-5465d68bc6a4', 'machinery_evidence', '24d128a9-5591-4cd2-b218-2fdfc93bb18f/9f17f068-b736-41fd-a2db-d2a53135998d/1778771019095_GPS-Topcon.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:03:39.175279+00', '2026-05-14 15:03:39.175279+00', '2026-05-14 15:03:39.175279+00', '{"eTag": "\"5d04a090b76337db9de6fe657e589043\"", "size": 28137, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T15:03:39.171Z", "contentLength": 28137, "httpStatusCode": 200}', 'a2fcf504-933f-4b9f-befb-3c53a17a3ee7', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('246af230-6a97-4a9a-a7e5-05a55ed0c0eb', 'machinery_evidence', '24d128a9-5591-4cd2-b218-2fdfc93bb18f/d89dc86f-b674-4091-8e6e-3b822d509946/1778771043987_Juping_Jack.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:04:04.041809+00', '2026-05-14 15:04:04.041809+00', '2026-05-14 15:04:04.041809+00', '{"eTag": "\"22ebea29730f5ac41f333075b9bb2079\"", "size": 91840, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T15:04:04.035Z", "contentLength": 91840, "httpStatusCode": 200}', '2728fc1e-46b2-48b3-9b04-1ecb7fd52a23', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('7408022a-5bb0-47cf-96ba-f99a82db8e88', 'machinery_evidence', '24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771070470_500_GL_FUEL_TANK.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:04:30.520875+00', '2026-05-14 15:04:30.520875+00', '2026-05-14 15:04:30.520875+00', '{"eTag": "\"524a2e8b6159570221ef02489e6390ca\"", "size": 104345, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T15:04:30.516Z", "contentLength": 104345, "httpStatusCode": 200}', '79c7a6bc-5c1b-4354-aba7-a4a775494bed', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('90301b25-4e6f-447f-9d02-41e463e203ab', 'machinery_evidence', '24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771092714_500_GL_FUEL_TANK.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:04:52.775743+00', '2026-05-14 15:04:52.775743+00', '2026-05-14 15:04:52.775743+00', '{"eTag": "\"524a2e8b6159570221ef02489e6390ca\"", "size": 104345, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T15:04:52.766Z", "contentLength": 104345, "httpStatusCode": 200}', '3db7ac67-5828-4e10-8e91-365a113f730b', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('9d79effb-913c-4fdf-b1c3-fdcbee0aabdc', 'machinery_evidence', '24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771110904_500_GL_FUEL_TANK.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:05:10.954857+00', '2026-05-14 15:05:10.954857+00', '2026-05-14 15:05:10.954857+00', '{"eTag": "\"524a2e8b6159570221ef02489e6390ca\"", "size": 104345, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T15:05:10.950Z", "contentLength": 104345, "httpStatusCode": 200}', 'e3b2f9c0-309f-4949-ab81-c8bf3a835713', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('401e7fe6-4279-4936-971e-509a66d96611', 'machinery_evidence', '24d128a9-5591-4cd2-b218-2fdfc93bb18f/0e3ce2f3-3ef0-46c9-b2d7-3f58a9e62e01/1778771131104_500_GL_FUEL_TANK.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 15:05:31.154914+00', '2026-05-14 15:05:31.154914+00', '2026-05-14 15:05:31.154914+00', '{"eTag": "\"524a2e8b6159570221ef02489e6390ca\"", "size": 104345, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T15:05:31.146Z", "contentLength": 104345, "httpStatusCode": 200}', 'db0e8ab0-f59c-41eb-88d4-5ca866266298', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('9d13e849-a5e8-464d-9e7e-0962b3ecff71', 'equipment', '1778782333241_Toyota_Tundra_Plateum.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:12:13.43106+00', '2026-05-14 18:12:13.43106+00', '2026-05-14 18:12:13.43106+00', '{"eTag": "\"347d3e4368d8e0e5027a3e411634da4d\"", "size": 301626, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:12:13.409Z", "contentLength": 301626, "httpStatusCode": 200}', '6b523881-b00f-44e0-bd06-ecfc4e3d9cf9', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('acf8fddb-fcad-482f-bb56-23f48fa5eb2c', 'equipment', '1778782374671_Polaris_Ranger.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:12:54.836586+00', '2026-05-14 18:12:54.836586+00', '2026-05-14 18:12:54.836586+00', '{"eTag": "\"f90434204edaddf683f325d831275480\"", "size": 3135464, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:12:54.809Z", "contentLength": 3135464, "httpStatusCode": 200}', '9b4fedef-218c-4a6c-b46c-c556156f9df4', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('9db2e111-4f7f-4b2b-9a8e-4125dc7b4146', 'equipment', '1778782432525_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:13:52.594289+00', '2026-05-14 18:13:52.594289+00', '2026-05-14 18:13:52.594289+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:13:52.582Z", "contentLength": 109635, "httpStatusCode": 200}', 'ee45322e-0d6c-40db-90b4-9b68948ae10a', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('ebf7e3a3-570f-4a2c-9ae3-577b70c2bd41', 'equipment', '1778782484707_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:14:44.760285+00', '2026-05-14 18:14:44.760285+00', '2026-05-14 18:14:44.760285+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:14:44.751Z", "contentLength": 109635, "httpStatusCode": 200}', '348756f7-c020-4676-92a3-80099f30c6b2', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('f909fc7a-148e-4b01-b1db-91ff69feb101', 'equipment', '1778782532974_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:15:33.046695+00', '2026-05-14 18:15:33.046695+00', '2026-05-14 18:15:33.046695+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:15:33.037Z", "contentLength": 109635, "httpStatusCode": 200}', '570b39cc-c523-4984-8aa2-f0b4b77792e4', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('96ba4247-04cd-4b6f-8b6c-374b525ac3c9', 'equipment', '1778782579585_JD_750L.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:16:19.643777+00', '2026-05-14 18:16:19.643777+00', '2026-05-14 18:16:19.643777+00', '{"eTag": "\"a3b5c5e7f404215c7c36ab214acda101\"", "size": 212297, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:16:19.634Z", "contentLength": 212297, "httpStatusCode": 200}', '63dec7f3-1514-4eb0-92e2-5019b93493bb', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('a4105928-22cd-43a2-b207-31b2bbc2d3bd', 'equipment', '1778782652535_JD_510-350.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:17:32.621309+00', '2026-05-14 18:17:32.621309+00', '2026-05-14 18:17:32.621309+00', '{"eTag": "\"95c1c49e84ededf5653ad3942bcaf1c3\"", "size": 114653, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:17:32.614Z", "contentLength": 114653, "httpStatusCode": 200}', '12eb3c54-4706-4047-a64e-9d3ce1b79f8d', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('a8afaf20-2f6c-41a1-89c6-875ce4204e61', 'equipment', '1778782704764_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:18:24.837715+00', '2026-05-14 18:18:24.837715+00', '2026-05-14 18:18:24.837715+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:18:24.829Z", "contentLength": 108816, "httpStatusCode": 200}', 'acf84b04-b330-483c-991e-cfd236e285e8', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('b3376a25-bc9d-46a7-82b9-6dcf4ec938f0', 'equipment', '1778782752335_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:19:12.384234+00', '2026-05-14 18:19:12.384234+00', '2026-05-14 18:19:12.384234+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:19:12.380Z", "contentLength": 108816, "httpStatusCode": 200}', 'b8771d3c-3279-4fdd-a944-7f04c4b651ea', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('2052cac4-49e0-40df-b2ea-02f4c1affa14', 'equipment', '1778782819926_JD_510-350.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:20:19.995944+00', '2026-05-14 18:20:19.995944+00', '2026-05-14 18:20:19.995944+00', '{"eTag": "\"95c1c49e84ededf5653ad3942bcaf1c3\"", "size": 114653, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:20:19.986Z", "contentLength": 114653, "httpStatusCode": 200}', 'a067ec20-162f-4203-b9bc-e69e3ec20a28', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('13963a86-6394-4898-826a-73d9bd8abb29', 'equipment', '1778782882160_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:21:22.253992+00', '2026-05-14 18:21:22.253992+00', '2026-05-14 18:21:22.253992+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:21:22.246Z", "contentLength": 109635, "httpStatusCode": 200}', '40e17291-b0c3-4858-aef7-2d828986f0b7', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('b7a91fd7-e1bc-49ff-83fb-9f12de6fac84', 'equipment', '1778782930889_Cat_K-Teck_1236_scraper.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:22:10.93744+00', '2026-05-14 18:22:10.93744+00', '2026-05-14 18:22:10.93744+00', '{"eTag": "\"a36b2ec3bf70a375897261ade118a9bc\"", "size": 27619, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:22:10.928Z", "contentLength": 27619, "httpStatusCode": 200}', '44c0afae-896a-4856-853c-915d99474330', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('324c1e8e-0747-4d94-b9ca-b160cbfc0d73', 'equipment', '1778782998243_5-6_Yd_Dump_Truck.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-05-14 18:23:18.320147+00', '2026-05-14 18:23:18.320147+00', '2026-05-14 18:23:18.320147+00', '{"eTag": "\"4bcafd13afb233cc4d60cc6f32e8cc16\"", "size": 72998, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-05-14T18:23:18.310Z", "contentLength": 72998, "httpStatusCode": 200}', '326c8a12-1225-4964-b5a6-2bf780db3561', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('2de24952-8435-4c5e-bfae-c498d63aa8a6', 'equipment', '1782760878647_Toyota_Tundra_Plateum.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:21:21.478442+00', '2026-06-29 19:21:21.478442+00', '2026-06-29 19:21:21.478442+00', '{"eTag": "\"347d3e4368d8e0e5027a3e411634da4d\"", "size": 301626, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:21:21.393Z", "contentLength": 301626, "httpStatusCode": 200}', 'd72bb95f-1fcb-4678-8859-6a38d7027bd0', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('72434191-fd57-4cf0-8466-1f0e24140948', 'equipment', '1782760899074_Polaris_Ranger.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:21:39.392784+00', '2026-06-29 19:21:39.392784+00', '2026-06-29 19:21:39.392784+00', '{"eTag": "\"f90434204edaddf683f325d831275480\"", "size": 3135464, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:21:39.361Z", "contentLength": 3135464, "httpStatusCode": 200}', 'ac6b145f-a4e9-49b9-93ab-c31f713552e7', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('bd48694d-d16a-4f9d-b995-f73a023eb743', 'equipment', '1782760917469_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:21:57.544801+00', '2026-06-29 19:21:57.544801+00', '2026-06-29 19:21:57.544801+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:21:57.534Z", "contentLength": 109635, "httpStatusCode": 200}', '2f0a7959-b3cd-49ae-aabc-73f661020f2c', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('ec643520-4c93-41be-a831-f24c9a18e14d', 'equipment', '1782760936891_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:22:16.937354+00', '2026-06-29 19:22:16.937354+00', '2026-06-29 19:22:16.937354+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:22:16.928Z", "contentLength": 109635, "httpStatusCode": 200}', 'dc525c16-9b93-48c0-806e-9ef99d605867', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('62afea0f-074c-4741-9d7e-1baca8bd8019', 'equipment', '1782760957758_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:22:37.802327+00', '2026-06-29 19:22:37.802327+00', '2026-06-29 19:22:37.802327+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:22:37.793Z", "contentLength": 109635, "httpStatusCode": 200}', '2b0acc3d-bc9f-4e1c-89c3-54222200660b', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('540a6ed4-40f2-416b-9957-bdfb7ed81106', 'equipment', '1782760990300_JD_510-350.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:23:10.451281+00', '2026-06-29 19:23:10.451281+00', '2026-06-29 19:23:10.451281+00', '{"eTag": "\"95c1c49e84ededf5653ad3942bcaf1c3\"", "size": 114653, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:23:10.442Z", "contentLength": 114653, "httpStatusCode": 200}', 'e5b2df5b-6048-4554-9adc-812bdeb23afa', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('6bbd822f-f05a-40a1-9e31-5db822c06521', 'equipment', '1782761029236_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:23:49.304435+00', '2026-06-29 19:23:49.304435+00', '2026-06-29 19:23:49.304435+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:23:49.292Z", "contentLength": 108816, "httpStatusCode": 200}', 'e6c94ca9-d655-41eb-9565-1856cf0ca8ba', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('b338af4a-8e6f-4c9b-88e3-5d8f16ca83d1', 'equipment', '1782760973194_JD_750L.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:22:53.281008+00', '2026-06-29 19:22:53.281008+00', '2026-06-29 19:22:53.281008+00', '{"eTag": "\"a3b5c5e7f404215c7c36ab214acda101\"", "size": 212297, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:22:53.262Z", "contentLength": 212297, "httpStatusCode": 200}', 'a5634371-5d5b-4879-9d50-170b70a2ad1a', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('2211c1b6-adf0-4faa-8ff9-0dba7d5dbf7e', 'equipment', '1782761008692_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:23:28.759419+00', '2026-06-29 19:23:28.759419+00', '2026-06-29 19:23:28.759419+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:23:28.747Z", "contentLength": 108816, "httpStatusCode": 200}', 'c184c829-07a6-45ab-83c1-b6c6f670a29c', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('a3a8f929-7354-4d2d-b41b-a0e006f3879b', 'equipment', '1782761110575_JD_510-350.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:25:10.735489+00', '2026-06-29 19:25:10.735489+00', '2026-06-29 19:25:10.735489+00', '{"eTag": "\"95c1c49e84ededf5653ad3942bcaf1c3\"", "size": 114653, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:25:10.710Z", "contentLength": 114653, "httpStatusCode": 200}', 'b0715bb2-3957-4101-925d-cfe214090faf', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('91f2d6fa-7029-45a4-9f2e-0c26bb06f6bd', 'equipment', '1782761125215_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:25:25.266765+00', '2026-06-29 19:25:25.266765+00', '2026-06-29 19:25:25.266765+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:25:25.255Z", "contentLength": 109635, "httpStatusCode": 200}', 'fa72d644-41e2-407d-a252-ff6953c90a2d', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('237c322c-14c5-4472-9861-1266943dffc4', 'equipment', '1782761161347_Cat_K-Teck_1236_scraper.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:26:01.400924+00', '2026-06-29 19:26:01.400924+00', '2026-06-29 19:26:01.400924+00', '{"eTag": "\"a36b2ec3bf70a375897261ade118a9bc\"", "size": 27619, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:26:01.392Z", "contentLength": 27619, "httpStatusCode": 200}', '4aa73a5b-ac18-45a4-92a5-3093dd393227', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('65b2c3ef-0664-4dd7-b52d-37e8d27560ea', 'equipment', '1782761184367_5-6_Yd_Dump_Truck.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:26:24.409597+00', '2026-06-29 19:26:24.409597+00', '2026-06-29 19:26:24.409597+00', '{"eTag": "\"4bcafd13afb233cc4d60cc6f32e8cc16\"", "size": 72998, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:26:24.400Z", "contentLength": 72998, "httpStatusCode": 200}', '29bef657-5a1a-4f71-91f2-8bde4a1e69a8', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('3a017158-b17b-4b74-89e7-fffbbcb59043', 'equipment', '1782761204171_Juping_Jack.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:26:44.225091+00', '2026-06-29 19:26:44.225091+00', '2026-06-29 19:26:44.225091+00', '{"eTag": "\"22ebea29730f5ac41f333075b9bb2079\"", "size": 91840, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:26:44.217Z", "contentLength": 91840, "httpStatusCode": 200}', '9ba41b30-8d39-408c-9838-6acfa63681d0', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('c4e01297-0f48-4d2c-aa83-f8644451a007', 'equipment', '1782761216786_GPS-Topcon.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:26:56.820951+00', '2026-06-29 19:26:56.820951+00', '2026-06-29 19:26:56.820951+00', '{"eTag": "\"5d04a090b76337db9de6fe657e589043\"", "size": 28137, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:26:56.814Z", "contentLength": 28137, "httpStatusCode": 200}', 'b3c693f4-04f4-46be-88e2-abd6520c3ae5', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('46ba7f2c-5638-4108-b404-9f46c38d7741', 'equipment', '1782761229725_500_GL_FUEL_TANK.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:27:09.794042+00', '2026-06-29 19:27:09.794042+00', '2026-06-29 19:27:09.794042+00', '{"eTag": "\"524a2e8b6159570221ef02489e6390ca\"", "size": 104345, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:27:09.785Z", "contentLength": 104345, "httpStatusCode": 200}', '50ef69b0-ef3c-43c1-893e-9a7cf90915eb', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('8b7f2e2b-c4bd-43d5-949a-77d50e8bcfe4', 'equipment', '1782761243414_40_conex_Office_-_Storage.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:27:23.4668+00', '2026-06-29 19:27:23.4668+00', '2026-06-29 19:27:23.4668+00', '{"eTag": "\"f3befee1387abfb35914d7561fc89248\"", "size": 94071, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:27:23.462Z", "contentLength": 94071, "httpStatusCode": 200}', '064eade4-dee7-406d-8456-35ee28450eee', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('4018d7e7-a575-4f48-b406-7dc537eddc38', 'equipment', '1782761255297_40_conex_Office_-_Storage.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:27:35.336663+00', '2026-06-29 19:27:35.336663+00', '2026-06-29 19:27:35.336663+00', '{"eTag": "\"f3befee1387abfb35914d7561fc89248\"", "size": 94071, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:27:35.332Z", "contentLength": 94071, "httpStatusCode": 200}', '39dcd129-19e5-4569-8778-98bb41f8ef4f', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('cbb4afcf-edbe-4ef5-aed4-9930df6014f5', 'machinery_evidence', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e/6ca6fa47-1ddd-43de-824c-e9e6b0b62930/1782761546184_Toyota_Tundra_Plateum.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:32:26.270789+00', '2026-06-29 19:32:26.270789+00', '2026-06-29 19:32:26.270789+00', '{"eTag": "\"347d3e4368d8e0e5027a3e411634da4d\"", "size": 301626, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:32:26.254Z", "contentLength": 301626, "httpStatusCode": 200}', 'a36ba165-5887-47a1-8f2e-82154f49b351', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('5523c2e2-f378-4dfd-a3d0-1fd4453ff52d', 'machinery_evidence', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e/972a6eb8-025d-4c47-8cc1-3039ef4a623e/1782761577080_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:32:57.137167+00', '2026-06-29 19:32:57.137167+00', '2026-06-29 19:32:57.137167+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:32:57.131Z", "contentLength": 109635, "httpStatusCode": 200}', '5caff6d5-a97e-4b1e-be3c-6fbf2e641eb0', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('29644d46-c2b2-43b3-9ba1-8a2ed55f7b73', 'machinery_evidence', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e/972a6eb8-025d-4c47-8cc1-3039ef4a623e/1782761605843_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:33:25.888356+00', '2026-06-29 19:33:25.888356+00', '2026-06-29 19:33:25.888356+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:33:25.875Z", "contentLength": 109635, "httpStatusCode": 200}', 'd8ab85ee-2c40-4a41-898e-5c6d09d6d651', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('3258201a-0cfd-45c5-b8f4-79eac996acea', 'machinery_evidence', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e/53d62d93-4bc1-4466-97a5-237da16b9dfb/1782761636535_JD_1050-950-850.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:33:56.583095+00', '2026-06-29 19:33:56.583095+00', '2026-06-29 19:33:56.583095+00', '{"eTag": "\"09e15e4087012a0f0a6ed49aeaff646b\"", "size": 109635, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:33:56.573Z", "contentLength": 109635, "httpStatusCode": 200}', '0c428372-c050-41ec-a421-2b256cf4c715', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('a1228db3-23e5-4d8b-9c6b-6c843712f8ca', 'machinery_evidence', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e/84126c63-c471-4316-b2ca-bb4785d7187b/1782761669469_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:34:29.520451+00', '2026-06-29 19:34:29.520451+00', '2026-06-29 19:34:29.520451+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:34:29.507Z", "contentLength": 108816, "httpStatusCode": 200}', '9a82ca6e-8dce-464f-be11-9566ed2c7b48', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('fd23c509-9cf5-40e1-b35f-478cdc9fb122', 'machinery_evidence', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e/84126c63-c471-4316-b2ca-bb4785d7187b/1782761700068_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:35:00.118109+00', '2026-06-29 19:35:00.118109+00', '2026-06-29 19:35:00.118109+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:35:00.108Z", "contentLength": 108816, "httpStatusCode": 200}', '4254359a-b632-437d-b6e5-500e15567876', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('8ac4e098-d336-4f41-8464-ea43de6d46ef', 'machinery_evidence', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e/82b8fb7c-1be7-46da-9695-9f151860b475/1782762165886_JD_460-410.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-06-29 19:42:45.969004+00', '2026-06-29 19:42:45.969004+00', '2026-06-29 19:42:45.969004+00', '{"eTag": "\"30fc62f28154d7e61c0811f8b4106b91\"", "size": 108816, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-06-29T19:42:45.959Z", "contentLength": 108816, "httpStatusCode": 200}', 'e3f3c4fb-3d86-4cf8-a8fa-2f8cd68e71e4', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('297bf1f5-3637-4f3b-ac15-bec7f3eb2ee8', 'incident-photos', '1e5fe596-050c-4f95-b8c3-dd632bb0e45e/2be8a245-a9a3-4e0d-8ec1-386a8cf620f6.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-02 15:28:51.020777+00', '2026-07-02 15:28:51.020777+00', '2026-07-02 15:28:51.020777+00', '{"eTag": "\"bfd7caeb82bd72a754f7bd04f36143e4\"", "size": 1474573, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-07-02T15:28:50.989Z", "contentLength": 1474573, "httpStatusCode": 200}', 'b3b94017-022f-4f6e-93ec-b126373a3db9', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('b927cbaf-5091-4d98-b5c7-b06f9cc5bd91', 'inspections', '1783366725857_Cat_K-Teck_1236_scraper.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-06 19:38:46.2575+00', '2026-07-06 19:38:46.2575+00', '2026-07-06 19:38:46.2575+00', '{"eTag": "\"a36b2ec3bf70a375897261ade118a9bc\"", "size": 27619, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-07-06T19:38:46.232Z", "contentLength": 27619, "httpStatusCode": 200}', '5cc044a1-3680-4b2d-84ce-e18ab9601d53', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('edef6e70-a998-462e-b37a-b8f85c4cde62', 'inspections', '1783434297424_40_conex_Office_-_Storage.png', '3b3df1db-8109-4414-b451-6b9e22435254', '2026-07-07 14:24:59.198186+00', '2026-07-07 14:24:59.198186+00', '2026-07-07 14:24:59.198186+00', '{"eTag": "\"f3befee1387abfb35914d7561fc89248\"", "size": 94071, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-07-07T14:24:59.138Z", "contentLength": 94071, "httpStatusCode": 200}', '3b4e2e02-1885-4733-a237-f5cfd333cb07', '3b3df1db-8109-4414-b451-6b9e22435254', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('abfd12c2-1287-4117-9ee2-eecb4b44d050', 'inspections', '1783445590095_500_GL_FUEL_TANK.png', '097e8824-e345-46ae-b66d-8fb5452fd3c5', '2026-07-07 17:33:10.708302+00', '2026-07-07 17:33:10.708302+00', '2026-07-07 17:33:10.708302+00', '{"eTag": "\"524a2e8b6159570221ef02489e6390ca\"", "size": 104345, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-07-07T17:33:10.688Z", "contentLength": 104345, "httpStatusCode": 200}', 'b111537f-22fb-4901-bafd-5bcb9b8eea3d', '097e8824-e345-46ae-b66d-8fb5452fd3c5', '{}');


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: hooks; Type: TABLE DATA; Schema: supabase_functions; Owner: -
--



--
-- Data for Name: migrations; Type: TABLE DATA; Schema: supabase_functions; Owner: -
--

INSERT INTO supabase_functions.migrations (version, inserted_at) VALUES ('initial', '2026-06-27 20:07:08.527203+00');
INSERT INTO supabase_functions.migrations (version, inserted_at) VALUES ('20210809183423_update_grants', '2026-06-27 20:07:08.527203+00');


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: supabase_migrations; Owner: -
--

INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260216000000', '{"-- Create profiles table
create table public.profiles (
  id uuid references auth.users not null primary key,
  name text,
  email text,
  phone text,
  role text default ''Employee'' check (role in (''Admin'', ''Employee'')),
  avatar_url text,
  updated_at timestamp with time zone default now()
)","-- Set up Row Level Security (RLS)
alter table public.profiles enable row level security","-- Policies for profiles
create policy \"Public profiles are viewable by everyone.\" on public.profiles
  for select using (true)","create policy \"Users can insert their own profile.\" on public.profiles
  for insert with check (auth.uid() = id)","create policy \"Users can update own profile.\" on public.profiles
  for update using (auth.uid() = id)","-- Trigger to create profile when a user signs up
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name, role)
  values (new.id, new.email, new.raw_user_meta_data->>''name'', ''Employee'');
  return new;
end;
$$ language plpgsql security definer","create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user()"}', 'create_profiles');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260224000000', '{"-- Create roles table
create table if not exists public.roles (
  id uuid default gen_random_uuid() primary key,
  name text not null unique,
  description text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
)","-- Enable RLS
alter table public.roles enable row level security","-- Everyone can read roles
create policy \"Roles are viewable by everyone.\" on public.roles
  for select using (true)","-- Only authenticated users can manage roles
create policy \"Authenticated users can insert roles.\" on public.roles
  for insert with check (auth.role() = ''authenticated'')","create policy \"Authenticated users can update roles.\" on public.roles
  for update using (auth.role() = ''authenticated'')","create policy \"Authenticated users can delete roles.\" on public.roles
  for delete using (auth.role() = ''authenticated'')","-- Seed default roles
insert into public.roles (name, description) values
  (''Admin'', ''Full access to all features''),
  (''Employee'', ''Standard employee access'')
on conflict (name) do nothing","-- Remove the check constraint on profiles.role so it can accept any role
alter table public.profiles drop constraint if exists profiles_role_check"}', 'create_roles');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260224010000', '{"-- Allow admins to manage all profiles
-- First, check if the policy exists and drop it
drop policy if exists \"Admins can update any profile.\" on public.profiles","drop policy if exists \"Admins can insert any profile.\" on public.profiles","drop policy if exists \"Admins can delete any profile.\" on public.profiles","-- Admins can update any profile
create policy \"Admins can update any profile.\" on public.profiles
  for update using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = ''Admin''
    )
  )","-- Admins can insert any profile
create policy \"Admins can insert any profile.\" on public.profiles
  for insert with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = ''Admin''
    )
  )","-- Admins can delete any profile
create policy \"Admins can delete any profile.\" on public.profiles
  for delete using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = ''Admin''
    )
  )"}', 'admin_profiles_policy');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260306020211', '{"-- 1. Create Quotes Table
create table public.quotes (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid, -- Assuming some company reference might be needed later
  title text not null default ''Nueva Cotizaci├│n'',
  status text not null default ''draft'', -- draft, sent, accepted, rejected
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
)","-- 2. Create Quote Services Table (The items in the quote)
create table public.quote_services (
  id uuid primary key default uuid_generate_v4(),
  quote_id uuid not null references public.quotes(id) on delete cascade,
  service_number text,
  name text not null default '''',
  unit_of_measure text not null default ''und'',
  quantity numeric not null default 1,
  overhead_percentage numeric not null default 0,
  profit_percentage numeric not null default 0,
  created_at timestamp with time zone default now()
)","-- 3. Create Quote Service Machineries (The machines for a service)
create table public.quote_service_machineries (
  id uuid primary key default uuid_generate_v4(),
  quote_service_id uuid not null references public.quote_services(id) on delete cascade,
  machine_name text not null default '''',
  months_to_use numeric not null default 0,
  monthly_rent_cost numeric not null default 0,
  quantity numeric not null default 1,
  gallons_per_hour numeric not null default 0,
  gallon_cost numeric not null default 0,
  created_at timestamp with time zone default now()
)","-- 4. Create Quote Service Labors (The labor for a service)
create table public.quote_service_labors (
  id uuid primary key default uuid_generate_v4(),
  quote_service_id uuid not null references public.quote_services(id) on delete cascade,
  role_id uuid references public.roles(id), -- Nullable in case they want a free text option later
  months_to_work numeric not null default 0,
  employees_quantity numeric not null default 1,
  hourly_rate numeric not null default 0,
  per_diem numeric not null default 0,
  created_at timestamp with time zone default now()
)","-- Enforce Row Level Security (RLS)
alter table public.quotes enable row level security","alter table public.quote_services enable row level security","alter table public.quote_service_machineries enable row level security","alter table public.quote_service_labors enable row level security","-- Policies for Authenticated Users (Admins usually handle this)
-- For now, allow authenticated users to do everything (you can restrict later)
create policy \"Allow all actions for authenticated users on quotes\"
  on public.quotes for all to authenticated using (true)","create policy \"Allow all actions for authenticated users on quote_services\"
  on public.quote_services for all to authenticated using (true)","create policy \"Allow all actions for authenticated users on quote_service_machineries\"
  on public.quote_service_machineries for all to authenticated using (true)","create policy \"Allow all actions for authenticated users on quote_service_labors\"
  on public.quote_service_labors for all to authenticated using (true)"}', 'create_quotes');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260306030000', '{"-- Create Labor Roles Catalog
create table if not exists public.labor_roles (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  hourly_rate numeric not null default 0,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
)","-- Create Machinery Catalog
create table if not exists public.machinery (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  photo_url text,
  capacity text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
)","-- Create Services Catalog
create table if not exists public.services (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  unit text not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
)","-- Enable RLS
alter table public.labor_roles enable row level security","alter table public.machinery enable row level security","alter table public.services enable row level security","-- Policies (Allow all for authenticated users for now)
create policy \"Allow all actions for authenticated users on labor_roles\"
  on public.labor_roles for all to authenticated using (true)","create policy \"Allow all actions for authenticated users on machinery\"
  on public.machinery for all to authenticated using (true)","create policy \"Allow all actions for authenticated users on services\"
  on public.services for all to authenticated using (true)","-- Trigger for updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql","create trigger labor_roles_updated_at
  before update on public.labor_roles
  for each row execute procedure public.handle_updated_at()","create trigger machinery_updated_at
  before update on public.machinery
  for each row execute procedure public.handle_updated_at()","create trigger services_updated_at
  before update on public.services
  for each row execute procedure public.handle_updated_at()"}', 'create_catalogs');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260309140000', '{"-- Create the equipment storage bucket
insert into storage.buckets (id, name, public)
values (''equipment'', ''equipment'', true)
on conflict (id) do nothing","-- Allow public read access (select)
create policy \"Public Access equipment\"
on storage.objects for select
to public
using ( bucket_id = ''equipment'' )","-- Allow authenticated users to upload (insert)
create policy \"Authenticated users can upload equipment\"
on storage.objects for insert
to authenticated
with check ( bucket_id = ''equipment'' )","-- Allow authenticated users to update their files (update)
create policy \"Authenticated users can update equipment\"
on storage.objects for update
to authenticated
using ( bucket_id = ''equipment'' )","-- Allow authenticated users to delete their files (delete)
create policy \"Authenticated users can delete equipment\"
on storage.objects for delete
to authenticated
using ( bucket_id = ''equipment'' )"}', 'create_storage_buckets');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260309142500', '{"-- Add missing columns to quotes table
alter table public.quotes 
add column if not exists client_name text,
add column if not exists total_amount numeric default 0,
add column if not exists quote_date date default current_date","-- Add delivery_cost to quote_service_machineries
alter table public.quote_service_machineries 
add column if not exists delivery_cost numeric default 0","-- Add delivery_cost to catalog machinery
alter table public.machinery 
add column if not exists delivery_cost numeric default 0"}', 'add_quote_columns');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260407120000', '{"-- Add hierarchy support to estimation resources
-- is_primary_mover: true = primary mover (counts in calculation & calendar)
-- parent_resource_id: UUID of primary machine this support belongs to

ALTER TABLE quote_service_estimation_resources
  ADD COLUMN IF NOT EXISTS is_primary_mover BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS parent_resource_id UUID REFERENCES quote_service_estimation_resources(id) ON DELETE SET NULL"}', 'add_hierarchy_to_estimation_resources');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260309220000', '{"-- Update machinery table to include default trips per day
alter table public.machinery add column if not exists default_trips_per_day numeric not null default 60","-- Create service estimations table
create table if not exists public.quote_service_estimations (
  id uuid primary key default uuid_generate_v4(),
  quote_service_id uuid not null references public.quote_services(id) on delete cascade,
  topsoil_volume numeric not null default 0,
  compacted_volume numeric not null default 0,
  swell_factor numeric not null default 0.15,
  total_cy_loose numeric not null default 0,
  start_date timestamp with time zone not null default now(),
  end_date timestamp with time zone,
  total_working_days numeric,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
)","-- Create estimation resources table (to store specific config for this estimation)
create table if not exists public.quote_service_estimation_resources (
  id uuid primary key default uuid_generate_v4(),
  estimation_id uuid not null references public.quote_service_estimations(id) on delete cascade,
  machine_id uuid not null references public.machinery(id),
  quantity numeric not null default 1,
  trips_per_day numeric not null default 60,
  capacity_per_trip numeric not null default 30,
  created_at timestamp with time zone default now()
)","-- Enable RLS
alter table public.quote_service_estimations enable row level security","alter table public.quote_service_estimation_resources enable row level security","-- Policies
create policy \"Allow all actions for authenticated users on quote_service_estimations\"
  on public.quote_service_estimations for all to authenticated using (true)","create policy \"Allow all actions for authenticated users on quote_service_estimation_resources\"
  on public.quote_service_estimation_resources for all to authenticated using (true)","-- Trigger for updated_at
create trigger quote_service_estimations_updated_at
  before update on public.quote_service_estimations
  for each row execute procedure public.handle_updated_at()"}', 'create_service_estimations');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260312094500', '{"-- Ensure the storage bucket for equipment exists and is public
insert into storage.buckets (id, name, public)
values (''equipment'', ''equipment'', true)
on conflict (id) do update set public = true","-- Allow public access to the equipment bucket
create policy \"Allow public access to equipment bucket\"
on storage.objects for select
using ( bucket_id = ''equipment'' )","-- Allow authenticated users to upload to equipment bucket
create policy \"Allow authenticated uploads to equipment bucket\"
on storage.objects for insert
with check ( bucket_id = ''equipment'' )","create policy \"Allow authenticated updates to equipment bucket\"
on storage.objects for update
with check ( bucket_id = ''equipment'' )","create policy \"Allow authenticated deletes to equipment bucket\"
on storage.objects for delete
using ( bucket_id = ''equipment'' )"}', 'ensure_equipment_bucket');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260312104500', '{"-- 1. Ensure all missing columns in quotes table
ALTER TABLE public.quotes 
ADD COLUMN IF NOT EXISTS client_name text,
ADD COLUMN IF NOT EXISTS total_amount numeric default 0,
ADD COLUMN IF NOT EXISTS quote_date date default current_date,
ADD COLUMN IF NOT EXISTS project_name text","-- 2. Ensure all missing columns in quote_services table
ALTER TABLE public.quote_services 
ADD COLUMN IF NOT EXISTS fuel_price numeric default 0,
ADD COLUMN IF NOT EXISTS per_diem_cost numeric default 0,
ADD COLUMN IF NOT EXISTS labor_hours_per_month numeric default 0","-- 3. Ensure all missing columns in quote_service_machineries table
ALTER TABLE public.quote_service_machineries 
ADD COLUMN IF NOT EXISTS delivery_cost numeric default 0","-- 4. Ensure all missing columns in quote_service_labors table
ALTER TABLE public.quote_service_labors 
ADD COLUMN IF NOT EXISTS role_name text","-- Notify PostgREST to reload schema cache
NOTIFY pgrst, ''reload schema''"}', 'add_role_name_to_labors');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260324100000', '{"-- Migration: expand_machinery_catalog
-- Added on: March 24, 2026 (local timing)

-- Add new columns to machinery table
alter table public.machinery 
add column if not exists fuel_gallons numeric default 0,
add column if not exists capacity_yards numeric default 0,
add column if not exists trips_per_day numeric default 0,
add column if not exists yards_per_day numeric default 0,
add column if not exists machinery_type text default ''hauling'',
add column if not exists associated_service_ids uuid[] default ''{}'',
add column if not exists applications text[] default ''{}''","-- Optional: Create a table for managing known applications if we want to suggest them later
create table if not exists public.machinery_applications (
  id uuid primary key default uuid_generate_v4(),
  name text unique not null,
  created_at timestamp with time zone default now()
)","-- Policy for machinery_applications
alter table public.machinery_applications enable row level security","do $$
begin
  if not exists (select 1 from pg_policies where policyname = ''Allow all actions for authenticated users on machinery_applications'') then
    create policy \"Allow all actions for authenticated users on machinery_applications\"
      on public.machinery_applications for all to authenticated using (true);
  end if;
end $$"}', 'expand_machinery_catalog');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260330112700', '{"-- Final fix for missing machinery columns
-- This ensures the column exists even if the previous migration was skipped or marked as completed

alter table public.machinery 
add column if not exists machinery_type text default ''hauling''","-- Trigger schema reload just in case
notify pgrst, ''reload schema''"}', 'fix_machinery_type');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260330114500', '{"-- Migration: create_logistics_tables
-- Added on: March 30, 2026

-- 1. Create table for logistics equipment
create table if not exists public.logistics_equipment (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  photo_url text,
  associated_service_ids uuid[] default ''{}'',
  applications text[] default ''{}'',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
)","-- 2. Create table for logistics applications
create table if not exists public.logistics_applications (
  id uuid primary key default uuid_generate_v4(),
  name text unique not null,
  created_at timestamp with time zone default now()
)","-- 3. Enable RLS
alter table public.logistics_equipment enable row level security","alter table public.logistics_applications enable row level security","-- 4. Create Policies
do $$
begin
  -- Policies for logistics_equipment
  if not exists (select 1 from pg_policies where policyname = ''Allow all actions for authenticated users on logistics_equipment'') then
    create policy \"Allow all actions for authenticated users on logistics_equipment\"
      on public.logistics_equipment for all to authenticated using (true);
  end if;

  -- Policies for logistics_applications
  if not exists (select 1 from pg_policies where policyname = ''Allow all actions for authenticated users on logistics_applications'') then
    create policy \"Allow all actions for authenticated users on logistics_applications\"
      on public.logistics_applications for all to authenticated using (true);
  end if;
end $$","-- 5. Notify schema reload
notify pgrst, ''reload schema''"}', 'create_logistics_tables');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260405083000', '{"-- Migration: enable_work_groups
-- Added on: April 5, 2026

-- Add category to machinery catalog
alter table public.machinery 
add column if not exists machinery_category text not null default ''support'' 
check (machinery_category in (''transport'', ''support'', ''dual''))","-- Update existing hauling machines to transport for consistency
update public.machinery set machinery_category = ''transport'' where machinery_type = ''hauling''","update public.machinery set machinery_category = ''support'' where machinery_type = ''support''","update public.machinery set machinery_category = ''dual'' where machinery_type = ''production''","-- Add group relationship to estimation resources
alter table public.quote_service_estimation_resources
add column if not exists parent_resource_id uuid references public.quote_service_estimation_resources(id) on delete cascade,
add column if not exists is_primary_mover boolean not null default false","-- Trigger schema reload
notify pgrst, ''reload schema''"}', 'enable_work_groups');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260405090000', '{"-- Migration: add_hierarchy_to_quote_machinery
-- Added on: April 5, 2026

alter table public.quote_service_machineries
add column if not exists parent_machinery_id uuid references public.quote_service_machineries(id) on delete cascade,
add column if not exists is_primary boolean not null default true","-- Trigger schema reload
notify pgrst, ''reload schema''"}', 'add_hierarchy_to_quote_machinery');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260407140000', '{"-- Add hierarchy columns to quote_service_machineries
ALTER TABLE public.quote_service_machineries 
ADD COLUMN IF NOT EXISTS is_primary_mover BOOLEAN DEFAULT TRUE","ALTER TABLE public.quote_service_machineries 
ADD COLUMN IF NOT EXISTS parent_machine_name VARCHAR","-- Update foreign keys to CASCADE ON DELETE
ALTER TABLE quote_service_estimations DROP CONSTRAINT IF EXISTS quote_service_estimations_quote_service_id_fkey","ALTER TABLE quote_service_estimations ADD CONSTRAINT quote_service_estimations_quote_service_id_fkey FOREIGN KEY (quote_service_id) REFERENCES quote_services(id) ON DELETE CASCADE","ALTER TABLE quote_service_machineries DROP CONSTRAINT IF EXISTS quote_service_machineries_quote_service_id_fkey","ALTER TABLE quote_service_machineries ADD CONSTRAINT quote_service_machineries_quote_service_id_fkey FOREIGN KEY (quote_service_id) REFERENCES quote_services(id) ON DELETE CASCADE","ALTER TABLE quote_service_labors DROP CONSTRAINT IF EXISTS quote_service_labors_quote_service_id_fkey","ALTER TABLE quote_service_labors ADD CONSTRAINT quote_service_labors_quote_service_id_fkey FOREIGN KEY (quote_service_id) REFERENCES quote_services(id) ON DELETE CASCADE","ALTER TABLE quote_service_estimation_resources DROP CONSTRAINT IF EXISTS quote_service_estimation_resources_estimation_id_fkey","ALTER TABLE quote_service_estimation_resources ADD CONSTRAINT quote_service_estimation_resources_estimation_id_fkey FOREIGN KEY (estimation_id) REFERENCES quote_service_estimations(id) ON DELETE CASCADE","-- Trigger schema reload
NOTIFY pgrst, ''reload schema''"}', 'update_cascade_and_machinery_columns');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260408101527', '{"-- Create Workers Table
create table if not exists public.workers (
  id uuid primary key default uuid_generate_v4(),
  id_number text unique, -- C├®dula/ID
  full_name text not null,
  hire_date date,
  phone text,
  email text,
  status text not null default ''Active'', -- Active / Inactive
  role_id uuid references public.labor_roles(id) on delete set null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
)","-- Create Worker Role History Table
create table if not exists public.worker_role_history (
  id uuid primary key default uuid_generate_v4(),
  worker_id uuid references public.workers(id) on delete cascade not null,
  previous_role_id uuid references public.labor_roles(id) on delete set null,
  new_role_id uuid references public.labor_roles(id) on delete set null,
  previous_hourly_rate numeric,
  changed_at timestamp with time zone default now()
)","-- Enable RLS
alter table public.workers enable row level security","alter table public.worker_role_history enable row level security","-- Policies
create policy \"Allow all actions for authenticated users on workers\"
  on public.workers for all to authenticated using (true)","create policy \"Allow all actions for authenticated users on worker_role_history\"
  on public.worker_role_history for all to authenticated using (true)","-- Updated_at trigger for workers
create trigger workers_updated_at
  before update on public.workers
  for each row execute procedure public.handle_updated_at()","-- Trigger to automatically track role changes
create or replace function public.handle_worker_role_change()
returns trigger as $$
declare
  prev_rate numeric;
begin
  if (TG_OP = ''UPDATE'' and old.role_id is distinct from new.role_id) then
    -- Get previous hourly rate
    select hourly_rate into prev_rate from public.labor_roles where id = old.role_id;
    
    insert into public.worker_role_history (worker_id, previous_role_id, new_role_id, previous_hourly_rate)
    values (new.id, old.role_id, new.role_id, prev_rate);
  end if;
  return new;
end;
$$ language plpgsql","create trigger track_worker_role_changes
  after update on public.workers
  for each row execute procedure public.handle_worker_role_change()"}', 'create_workers_module');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260410144000', '{"-- Add support for Area-based (FT) estimation
ALTER TABLE public.quote_service_estimations 
ADD COLUMN IF NOT EXISTS thickness_inches numeric DEFAULT 0","ALTER TABLE public.quote_service_estimation_resources
ADD COLUMN IF NOT EXISTS performance_per_day numeric DEFAULT 0","-- Optional: Add a comment to explain the columns
COMMENT ON COLUMN public.quote_service_estimations.thickness_inches IS ''Thickness in inches for SQFT based calculations''","COMMENT ON COLUMN public.quote_service_estimation_resources.performance_per_day IS ''Machine performance in Units/Day (e.g. SQFT/Day if unit is FT)''"}', 'add_area_estimation_support');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260412180000', '{"-- Migration: Add material assignment support to quotes
-- Date: 2026-04-12
-- Branch: feat/agregar-material

-- 1. Create materials catalog table if not exists (Ensures remote DB compatibility)
CREATE TABLE IF NOT EXISTS public.materials (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    description text NOT NULL DEFAULT '''',
    unit text,
    yield_factor decimal DEFAULT 1.0,
    associated_service_ids uuid[] DEFAULT ''{}'',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
)","-- Enable RLS for materials
ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY","-- Policy for materials
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = ''Enable all access for materials''
    ) THEN
        CREATE POLICY \"Enable all access for materials\" ON public.materials
        FOR ALL USING (true) WITH CHECK (true);
    END IF;
END
$$","-- 2. Create the materials assignment table for quotes
CREATE TABLE IF NOT EXISTS public.quote_service_materials (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_service_id uuid NOT NULL REFERENCES quote_services(id) ON DELETE CASCADE,
    material_id uuid REFERENCES materials(id) ON DELETE SET NULL,
    material_name text, -- Persist name for history
    unit_name text,     -- Persist unit for history
    quantity decimal NOT NULL DEFAULT 0,
    unit_price decimal NOT NULL DEFAULT 0,
    total_cost decimal GENERATED ALWAYS AS (quantity * unit_price) STORED,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
)","-- 3. Security: Enable RLS
ALTER TABLE public.quote_service_materials ENABLE ROW LEVEL SECURITY","-- 4. Policies: Allow full access
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = ''Enable all access for quote_service_materials''
    ) THEN
        CREATE POLICY \"Enable all access for quote_service_materials\" ON public.quote_service_materials
        FOR ALL USING (true) WITH CHECK (true);
    END IF;
END
$$","-- 5. Helper triggers for updated_at (Uses handle_updated_at from previous migrations)
CREATE OR REPLACE TRIGGER update_materials_modtime
    BEFORE UPDATE ON public.materials
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at()","CREATE OR REPLACE TRIGGER update_quote_service_materials_modtime
    BEFORE UPDATE ON public.quote_service_materials
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at()"}', 'add_material_assignment_support');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260414124500', '{"-- Force reload the schema cache for the API
NOTIFY pgrst, ''reload schema''"}', 'force_reload_schema');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260414140000', '{"ALTER TABLE public.machinery 
ADD COLUMN IF NOT EXISTS operator_role_id uuid REFERENCES public.labor_roles(id)","-- Force reload the schema cache for the API
NOTIFY pgrst, ''reload schema''"}', 'add_operator_role_id');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260415120000', '{"-- Add support for dual-layer estimation (Earth + Gravel) for area-based services
-- The existing ''thickness_inches'' column represents the Earth layer thickness
-- The new ''gravel_thickness_inches'' column represents the Gravel layer thickness

ALTER TABLE public.quote_service_estimations 
ADD COLUMN IF NOT EXISTS gravel_thickness_inches numeric DEFAULT 0","-- Add layer_type to materials so each material knows which calculation layer to use
ALTER TABLE public.quote_service_materials 
ADD COLUMN IF NOT EXISTS layer_type text DEFAULT ''earth''","COMMENT ON COLUMN public.quote_service_estimations.thickness_inches 
  IS ''Earth layer thickness in inches for SQFT-based calculations''","COMMENT ON COLUMN public.quote_service_estimations.gravel_thickness_inches 
  IS ''Gravel layer thickness in inches for SQFT-based calculations''","COMMENT ON COLUMN public.quote_service_materials.layer_type 
  IS ''Which calculation layer this material belongs to: earth or gravel''","NOTIFY pgrst, ''reload schema''"}', 'add_dual_layer_estimation');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260415140000', '{"-- Migration to support linear feet (LF) estimation (e.g. trenching, pipes)
ALTER TABLE quote_service_estimations 
ADD COLUMN IF NOT EXISTS trench_width_inches DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS trench_depth_inches DECIMAL(10,2) DEFAULT 0"}', 'add_linear_estimation_support');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260518100000', '{"-- Migration: Create Project Machinery Assignments Table
-- Note: This table may also be created by 20260522000000 (IF NOT EXISTS makes it safe)

CREATE TABLE IF NOT EXISTS public.project_machinery_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_machinery_id UUID NOT NULL REFERENCES public.project_machinery(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    actual_start_date DATE,
    actual_end_date DATE,
    status TEXT DEFAULT ''scheduled'' CHECK (status IN (''scheduled'', ''in_progress'', ''completed'', ''delayed'')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)","ALTER TABLE public.project_machinery_assignments ENABLE ROW LEVEL SECURITY","DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = ''Enable all access for machinery_assignments''
    ) THEN
        CREATE POLICY \"Enable all access for machinery_assignments\" ON public.project_machinery_assignments
        FOR ALL USING (auth.role() = ''authenticated'') WITH CHECK (auth.role() = ''authenticated'');
    END IF;
END
$$"}', 'create_project_machinery_assignments');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260415170000', '{"-- Migration: Add instruments assignment support to quotes
-- Date: 2026-04-15
-- Description: Creates the quote_service_instruments table to store manually added instruments/tools from the logistics catalog.

-- 1. Create the instruments assignment table for quotes
CREATE TABLE IF NOT EXISTS public.quote_service_instruments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_service_id uuid NOT NULL REFERENCES quote_services(id) ON DELETE CASCADE,
    instrument_id uuid REFERENCES logistics_equipment(id) ON DELETE SET NULL,
    instrument_name text, -- Persist name for history
    quantity decimal NOT NULL DEFAULT 1,
    unit_price decimal NOT NULL DEFAULT 0,
    total_cost decimal GENERATED ALWAYS AS (quantity * unit_price) STORED,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
)","-- 2. Security: Enable RLS
ALTER TABLE public.quote_service_instruments ENABLE ROW LEVEL SECURITY","-- 3. Policies: Allow full access for authenticated users
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = ''Enable all access for quote_service_instruments''
    ) THEN
        CREATE POLICY \"Enable all access for quote_service_instruments\" ON public.quote_service_instruments
        FOR ALL USING (true) WITH CHECK (true);
    END IF;
END
$$","-- 4. Helper trigger for updated_at
DROP TRIGGER IF EXISTS update_quote_service_instruments_modtime ON public.quote_service_instruments","CREATE TRIGGER update_quote_service_instruments_modtime
    BEFORE UPDATE ON public.quote_service_instruments
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at()"}', 'add_instruments_support');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260415173000', '{"-- Add days column to quote_service_instruments
ALTER TABLE public.quote_service_instruments 
ADD COLUMN days decimal NOT NULL DEFAULT 1","-- Update generated column calculation
ALTER TABLE public.quote_service_instruments 
DROP COLUMN total_cost","ALTER TABLE public.quote_service_instruments 
ADD COLUMN total_cost decimal GENERATED ALWAYS AS (quantity * unit_price * days) STORED"}', 'add_days_to_instruments');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260423135000', '{"-- Create Customers Table
create table public.customers (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  ein text, -- Format: XX-XXXXXXX
  address text,
  phone text,
  email text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
)","-- Enable RLS
alter table public.customers enable row level security","-- Policies
create policy \"Allow all actions for authenticated users on customers\"
  on public.customers for all to authenticated using (true)"}', 'create_customers');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260427140000', '{"ALTER TABLE public.quote_services
ADD COLUMN direct_cost numeric not null default 0"}', 'add_direct_cost_to_quote_services');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260428080000', '{"ALTER TABLE public.quotes ADD COLUMN IF NOT EXISTS quote_type text NOT NULL DEFAULT ''standard''"}', 'add_quote_type_to_quotes');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260504162000', '{"-- Create projects table
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_id UUID REFERENCES public.quotes(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    client_name TEXT,
    status TEXT DEFAULT ''active'' CHECK (status IN (''active'', ''completed'', ''on_hold'', ''cancelled'')),
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)","-- Create project_machinery table (Expected inventory)
CREATE TABLE IF NOT EXISTS public.project_machinery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    quote_service_machinery_id UUID REFERENCES public.quote_service_machineries(id) ON DELETE SET NULL,
    machinery_name TEXT NOT NULL,
    expected_quantity INTEGER NOT NULL DEFAULT 1,
    received_quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)","-- Create machinery_inspections table (Individual machines received)
CREATE TABLE IF NOT EXISTS public.machinery_inspections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_machinery_id UUID NOT NULL REFERENCES public.project_machinery(id) ON DELETE CASCADE,
    internal_code TEXT,
    brand_model TEXT,
    ownership_type TEXT DEFAULT ''owned'' CHECK (ownership_type IN (''owned'', ''rented'')),
    provider_name TEXT,
    hour_meter_start NUMERIC,
    condition_status TEXT DEFAULT ''operational'' CHECK (condition_status IN (''excellent'', ''operational'', ''needs_maintenance'', ''damaged'')),
    evidence_photos JSONB DEFAULT ''[]''::jsonb,
    observations TEXT,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    received_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
)","-- Create bucket for machinery photos if it doesn''t exist
INSERT INTO storage.buckets (id, name, public) 
VALUES (''machinery_evidence'', ''machinery_evidence'', true)
ON CONFLICT (id) DO NOTHING","-- Storage policies for machinery evidence
CREATE POLICY \"Public Access for machinery evidence\" 
ON storage.objects FOR SELECT 
USING ( bucket_id = ''machinery_evidence'' )","CREATE POLICY \"Auth Insert for machinery evidence\" 
ON storage.objects FOR INSERT 
WITH CHECK ( bucket_id = ''machinery_evidence'' AND auth.role() = ''authenticated'' )","-- RLS Policies for projects
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on projects\"
    ON public.projects FOR ALL
    USING (auth.role() = ''authenticated'')
    WITH CHECK (auth.role() = ''authenticated'')","-- RLS Policies for project_machinery
ALTER TABLE public.project_machinery ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on project_machinery\"
    ON public.project_machinery FOR ALL
    USING (auth.role() = ''authenticated'')
    WITH CHECK (auth.role() = ''authenticated'')","-- RLS Policies for machinery_inspections
ALTER TABLE public.machinery_inspections ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on machinery_inspections\"
    ON public.machinery_inspections FOR ALL
    USING (auth.role() = ''authenticated'')
    WITH CHECK (auth.role() = ''authenticated'')"}', 'create_projects_and_machinery');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260505100000', '{"-- Create project_labor table
CREATE TABLE IF NOT EXISTS public.project_labor (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    quote_service_labor_id UUID REFERENCES public.quote_service_labors(id) ON DELETE SET NULL,
    role_name TEXT NOT NULL,
    expected_employees INTEGER NOT NULL DEFAULT 1,
    active_employees INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
)","-- Create labor_checkins table (to track who is working where)
CREATE TABLE IF NOT EXISTS public.labor_checkins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    project_labor_id UUID NOT NULL REFERENCES public.project_labor(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES public.workers(id) ON DELETE CASCADE,
    check_in TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    check_out TIMESTAMP WITH TIME ZONE,
    status TEXT NOT NULL DEFAULT ''active'', -- active, completed
    observations TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
)","-- Enable RLS
ALTER TABLE public.project_labor ENABLE ROW LEVEL SECURITY","ALTER TABLE public.labor_checkins ENABLE ROW LEVEL SECURITY","DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = ''Allow all actions for authenticated users on project_labor'') THEN
        CREATE POLICY \"Allow all actions for authenticated users on project_labor\" ON public.project_labor TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = ''Allow all actions for authenticated users on labor_checkins'') THEN
        CREATE POLICY \"Allow all actions for authenticated users on labor_checkins\" ON public.labor_checkins TO authenticated USING (true);
    END IF;
END $$","-- Populate project_labor for existing projects
INSERT INTO public.project_labor (project_id, quote_service_labor_id, role_name, expected_employees)
SELECT 
    p.id as project_id,
    qsl.id as quote_service_labor_id,
    qsl.role_name as role_name,
    qsl.employees_quantity as expected_employees
FROM public.projects p
JOIN public.quote_services qs ON p.quote_id = qs.quote_id
JOIN public.quote_service_labors qsl ON qs.id = qsl.quote_service_id
ON CONFLICT DO NOTHING"}', 'create_project_labor');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260505100001', '{"-- Trigger to update active_employees count in project_labor
CREATE OR REPLACE FUNCTION public.handle_labor_checkin_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = ''INSERT'') THEN
        UPDATE public.project_labor 
        SET active_employees = active_employees + 1
        WHERE id = NEW.project_labor_id;
    ELSIF (TG_OP = ''UPDATE'') THEN
        IF (OLD.status = ''active'' AND NEW.status = ''completed'') THEN
            UPDATE public.project_labor 
            SET active_employees = active_employees - 1
            WHERE id = NEW.project_labor_id;
        END IF;
    ELSIF (TG_OP = ''DELETE'') THEN
        IF (OLD.status = ''active'') THEN
            UPDATE public.project_labor 
            SET active_employees = active_employees - 1
            WHERE id = OLD.project_labor_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql","DROP TRIGGER IF EXISTS on_labor_checkin_change ON public.labor_checkins","CREATE TRIGGER on_labor_checkin_change
AFTER INSERT OR UPDATE OR DELETE ON public.labor_checkins
FOR EACH ROW EXECUTE FUNCTION public.handle_labor_checkin_changes()"}', 'labor_trigger');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260610000001', '{"-- Fix FK references in incidents module: use profiles(id) instead of auth.users(id)
-- profiles.id = auth.users.id, but PostgREST needs direct FK to resolve joins

ALTER TABLE public.incidents
    DROP CONSTRAINT IF EXISTS incidents_reported_by_fkey,
    DROP CONSTRAINT IF EXISTS incidents_resolved_by_fkey","ALTER TABLE public.incidents
    ADD CONSTRAINT incidents_reported_by_fkey FOREIGN KEY (reported_by) REFERENCES public.profiles(id) ON DELETE SET NULL,
    ADD CONSTRAINT incidents_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.profiles(id) ON DELETE SET NULL","ALTER TABLE public.incident_actions
    DROP CONSTRAINT IF EXISTS incident_actions_assigned_to_fkey","ALTER TABLE public.incident_actions
    ADD CONSTRAINT incident_actions_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(id) ON DELETE SET NULL","NOTIFY pgrst, ''reload schema''"}', 'fix_incidents_fk_to_profiles');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260505100002', '{"-- Create project_tasks table
CREATE TABLE IF NOT EXISTS public.project_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    quote_service_id UUID REFERENCES public.quote_services(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT ''pending'', -- pending, in_progress, completed, blocked
    estimated_hours NUMERIC DEFAULT 0,
    actual_hours NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
)","-- Add task_id to labor_checkins
ALTER TABLE public.labor_checkins ADD COLUMN IF NOT EXISTS project_task_id UUID REFERENCES public.project_tasks(id) ON DELETE SET NULL","-- Enable RLS
ALTER TABLE public.project_tasks ENABLE ROW LEVEL SECURITY","DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = ''Allow all actions for authenticated users on project_tasks'') THEN
        CREATE POLICY \"Allow all actions for authenticated users on project_tasks\" ON public.project_tasks TO authenticated USING (true);
    END IF;
END $$","-- Backfill tasks from existing quote_services for active projects
INSERT INTO public.project_tasks (project_id, quote_service_id, name, status)
SELECT 
    p.id as project_id,
    qs.id as quote_service_id,
    qs.name as name,
    ''in_progress'' as status
FROM public.projects p
JOIN public.quote_services qs ON p.quote_id = qs.quote_id"}', 'create_project_tasks');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260505100003', '{"-- Trigger to update actual_hours in project_tasks when a check-in is completed
CREATE OR REPLACE FUNCTION public.handle_checkin_completion()
RETURNS TRIGGER AS $$
DECLARE
    duration_hours NUMERIC;
BEGIN
    IF NEW.status = ''completed'' AND OLD.status = ''active'' AND NEW.check_out IS NOT NULL THEN
        -- Calculate hours
        duration_hours := EXTRACT(EPOCH FROM (NEW.check_out - NEW.check_in)) / 3600;
        
        -- Update task
        IF NEW.project_task_id IS NOT NULL THEN
            UPDATE public.project_tasks
            SET actual_hours = actual_hours + duration_hours
            WHERE id = NEW.project_task_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql","DROP TRIGGER IF EXISTS on_checkin_completion ON public.labor_checkins","CREATE TRIGGER on_checkin_completion
AFTER UPDATE ON public.labor_checkins
FOR EACH ROW
EXECUTE FUNCTION public.handle_checkin_completion()"}', 'trigger_accumulate_hours');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260505100004', '{"-- Create project_labor_assignments table
CREATE TABLE IF NOT EXISTS public.project_labor_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_labor_id UUID REFERENCES public.project_labor(id) ON DELETE CASCADE,
    worker_id UUID REFERENCES public.workers(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(project_labor_id, worker_id)
)","-- Enable RLS
ALTER TABLE public.project_labor_assignments ENABLE ROW LEVEL SECURITY","-- Create policy
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = ''allow_all_assignments'') THEN
        CREATE POLICY \"allow_all_assignments\" ON public.project_labor_assignments
        FOR ALL TO authenticated USING (true);
    END IF;
END $$"}', 'create_project_labor_assignments');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260505180000', '{"-- Migration to add scheduling dates to labor assignments
ALTER TABLE public.project_labor_assignments 
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE","-- Ensure end_date is not before start_date
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = ''check_assignment_dates'') THEN
        ALTER TABLE public.project_labor_assignments 
        ADD CONSTRAINT check_assignment_dates CHECK (end_date >= start_date);
    END IF;
END $$"}', 'add_scheduling_dates');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260506100000', '{"-- Migration: Seed 45 test workers for production/staging
-- Created: 2026-05-06

DO $$ 
DECLARE 
    role_id_var UUID;
BEGIN
    -- SUPERVISORES (5)
    SELECT id INTO role_id_var FROM public.labor_roles WHERE description = ''SUPERVISOR'' LIMIT 1;
    IF role_id_var IS NOT NULL THEN
        INSERT INTO public.workers (full_name, id_number, role_id, status) VALUES
        (''Carlos Rodriguez'', ''ID-1001'', role_id_var, ''Active''),
        (''Maria Gonzales'', ''ID-1002'', role_id_var, ''Active''),
        (''Jose Martinez'', ''ID-1003'', role_id_var, ''Active''),
        (''Luis Hernandez'', ''ID-1004'', role_id_var, ''Active''),
        (''Ana Lopez'', ''ID-1005'', role_id_var, ''Active'')
        ON CONFLICT (id_number) DO NOTHING;
    END IF;

    -- EXCAVATOR OPERATORS (10)
    SELECT id INTO role_id_var FROM public.labor_roles WHERE description = ''Excavator Operator'' LIMIT 1;
    IF role_id_var IS NOT NULL THEN
        INSERT INTO public.workers (full_name, id_number, role_id, status) VALUES
        (''Juan Perez'', ''OP-2001'', role_id_var, ''Active''),
        (''Pedro Garcia'', ''OP-2002'', role_id_var, ''Active''),
        (''Miguel Angel'', ''OP-2003'', role_id_var, ''Active''),
        (''Francisco Javier'', ''OP-2004'', role_id_var, ''Active''),
        (''Antonio Jose'', ''OP-2005'', role_id_var, ''Active''),
        (''David Smith'', ''OP-2006'', role_id_var, ''Active''),
        (''James Wilson'', ''OP-2007'', role_id_var, ''Active''),
        (''Robert Brown'', ''OP-2008'', role_id_var, ''Active''),
        (''John Miller'', ''OP-2009'', role_id_var, ''Active''),
        (''Richard Moore'', ''OP-2010'', role_id_var, ''Active'')
        ON CONFLICT (id_number) DO NOTHING;
    END IF;

    -- TRUCK OPERATORS (10)
    SELECT id INTO role_id_var FROM public.labor_roles WHERE description = ''Truck Operator'' LIMIT 1;
    IF role_id_var IS NOT NULL THEN
        INSERT INTO public.workers (full_name, id_number, role_id, status) VALUES
        (''Oscar Duarte'', ''TK-3001'', role_id_var, ''Active''),
        (''Ramon Valdez'', ''TK-3002'', role_id_var, ''Active''),
        (''Nelson Mendez'', ''TK-3003'', role_id_var, ''Active''),
        (''Victor Hugo'', ''TK-3004'', role_id_var, ''Active''),
        (''Hugo Sanchez'', ''TK-3005'', role_id_var, ''Active''),
        (''Mario Kempes'', ''TK-3006'', role_id_var, ''Active''),
        (''Gabriel Batistuta'', ''TK-3007'', role_id_var, ''Active''),
        (''Hernan Crespo'', ''TK-3008'', role_id_var, ''Active''),
        (''Lionel Messi'', ''TK-3009'', role_id_var, ''Active''),
        (''Diego Maradona'', ''TK-3010'', role_id_var, ''Active'')
        ON CONFLICT (id_number) DO NOTHING;
    END IF;

    -- SHAPER CLASS B (10)
    SELECT id INTO role_id_var FROM public.labor_roles WHERE description = ''Shaper Class B'' LIMIT 1;
    IF role_id_var IS NOT NULL THEN
        INSERT INTO public.workers (full_name, id_number, role_id, status) VALUES
        (''Arthur Morgan'', ''SH-4001'', role_id_var, ''Active''),
        (''John Marston'', ''SH-4002'', role_id_var, ''Active''),
        (''Sadie Adler'', ''SH-4003'', role_id_var, ''Active''),
        (''Charles Smith'', ''SH-4004'', role_id_var, ''Active''),
        (''Bill Williamson'', ''SH-4005'', role_id_var, ''Active''),
        (''Javier Escuella'', ''SH-4006'', role_id_var, ''Active''),
        (''Dutch van der Linde'', ''SH-4007'', role_id_var, ''Active''),
        (''Hosea Matthews'', ''SH-4008'', role_id_var, ''Active''),
        (''Micah Bell'', ''SH-4009'', role_id_var, ''Active''),
        (''Lenny Summers'', ''SH-4010'', role_id_var, ''Active'')
        ON CONFLICT (id_number) DO NOTHING;
    END IF;

    -- SCRAPER OPERATORS (10)
    SELECT id INTO role_id_var FROM public.labor_roles WHERE description = ''Scraper operator'' LIMIT 1;
    IF role_id_var IS NOT NULL THEN
        INSERT INTO public.workers (full_name, id_number, role_id, status) VALUES
        (''Geralt of Rivia'', ''SC-5001'', role_id_var, ''Active''),
        (''Yennefer Vengerberg'', ''SC-5002'', role_id_var, ''Active''),
        (''Triss Merigold'', ''SC-5003'', role_id_var, ''Active''),
        (''Ciri Riannon'', ''SC-5004'', role_id_var, ''Active''),
        (''Vesemir Kaer'', ''SC-5005'', role_id_var, ''Active''),
        (''Lambert Eskel'', ''SC-5006'', role_id_var, ''Active''),
        (''Dandelion Julian'', ''SC-5007'', role_id_var, ''Active''),
        (''Zoltan Chivay'', ''SC-5008'', role_id_var, ''Active''),
        (''Sigismund Dijkstra'', ''SC-5009'', role_id_var, ''Active''),
        (''Emhyr Var Emreis'', ''SC-5010'', role_id_var, ''Active'')
        ON CONFLICT (id_number) DO NOTHING;
    END IF;

END $$"}', 'seed_production_workers');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260509073300', '{"CREATE TABLE public.project_materials (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    quote_service_material_id uuid REFERENCES public.quote_service_materials(id) ON DELETE SET NULL,
    material_name text NOT NULL,
    unit_name text,
    expected_quantity numeric NOT NULL DEFAULT 0,
    received_quantity numeric NOT NULL DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
)","ALTER TABLE public.project_materials ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on project_materials\" ON public.project_materials FOR ALL TO authenticated USING (true) WITH CHECK (true)","CREATE TABLE public.material_receptions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    project_material_id uuid NOT NULL REFERENCES public.project_materials(id) ON DELETE CASCADE,
    received_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    invoice_number text,
    provider_name text,
    quantity_received numeric NOT NULL,
    condition_status text DEFAULT ''good'' CHECK (condition_status IN (''good'', ''damaged'', ''incomplete'')),
    observations text,
    evidence_photos jsonb DEFAULT ''[]''::jsonb,
    received_at timestamp with time zone DEFAULT now()
)","ALTER TABLE public.material_receptions ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on material_receptions\" ON public.material_receptions FOR ALL TO authenticated USING (true) WITH CHECK (true)","-- Script to backfill project_materials for existing projects
INSERT INTO public.project_materials (project_id, quote_service_material_id, material_name, unit_name, expected_quantity, received_quantity)
SELECT 
    p.id as project_id,
    qsm.id as quote_service_material_id,
    qsm.material_name,
    qsm.unit_name,
    qsm.quantity as expected_quantity,
    0 as received_quantity
FROM public.projects p
JOIN public.quote_services qs ON qs.quote_id = p.quote_id
JOIN public.quote_service_materials qsm ON qsm.quote_service_id = qs.id
WHERE NOT EXISTS (
    SELECT 1 FROM public.project_materials pm WHERE pm.project_id = p.id
)","-- Tell PostgREST to reload schema cache
NOTIFY pgrst, ''reload schema''"}', 'create_project_materials');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260509200000', '{"-- Migration to add scheduling dates to project machinery
ALTER TABLE public.project_machinery 
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE","-- Ensure end_date is not before start_date
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = ''check_machinery_scheduling_dates'') THEN
        ALTER TABLE public.project_machinery 
        ADD CONSTRAINT check_machinery_scheduling_dates CHECK (end_date >= start_date);
    END IF;
END $$","-- Tell PostgREST to reload schema cache
NOTIFY pgrst, ''reload schema''"}', 'add_machinery_scheduling_dates');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260513180000', '{"-- Migration: Add Planning Baseline Fields
-- Description: Adds fields to support execution baseline, principal machinery, and unplanned resources.

-- 1. Update projects table to inherit quote_type
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS project_type TEXT NOT NULL DEFAULT ''standard''","-- Propagate the type from quotes to existing projects
UPDATE public.projects p
SET project_type = q.quote_type
FROM public.quotes q
WHERE p.quote_id = q.id","-- 2. Update project_machinery table for principal/support hierarchy and unplanned flag
ALTER TABLE public.project_machinery 
ADD COLUMN IF NOT EXISTS is_principal BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS parent_machinery_id UUID REFERENCES public.project_machinery(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS is_unplanned BOOLEAN NOT NULL DEFAULT false","-- 3. Update project_labor table to link with machinery and track unplanned resources
ALTER TABLE public.project_labor 
ADD COLUMN IF NOT EXISTS is_unplanned BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS linked_machinery_id UUID REFERENCES public.project_machinery(id) ON DELETE CASCADE","-- 4. Automatic Operator Assignment Trigger
-- When a machinery is added (unplanned/replan), automatically create an operator placeholder in project_labor
CREATE OR REPLACE FUNCTION public.handle_machinery_operator_assignment()
RETURNS TRIGGER AS $$
DECLARE
    v_role_name TEXT;
BEGIN
    -- We only auto-generate for unplanned machinery added during execution/re-planning phase.
    -- (Planned machinery from quotes already has its labor inserted via ProjectService.convertQuoteToProject)
    IF NEW.is_unplanned = true THEN
        v_role_name := ''Operador de '' || NEW.machinery_name;

        INSERT INTO public.project_labor (
            project_id, 
            quote_service_id,
            role_name, 
            expected_employees, 
            is_unplanned, 
            linked_machinery_id
        ) VALUES (
            NEW.project_id,
            NEW.quote_service_id,
            v_role_name,
            NEW.expected_quantity, -- Match the number of operators to the number of machines
            true,
            NEW.id
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER","DROP TRIGGER IF EXISTS trigger_machinery_operator_assignment ON public.project_machinery","CREATE TRIGGER trigger_machinery_operator_assignment
AFTER INSERT ON public.project_machinery
FOR EACH ROW
EXECUTE FUNCTION public.handle_machinery_operator_assignment()"}', 'add_planning_baseline_fields');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260513180500', '{"-- Migration: Create Project Instruments Table
-- Description: Adds the project_instruments table to track tools and minor equipment allocated to a project.

-- 1. Create the project_instruments table
CREATE TABLE IF NOT EXISTS public.project_instruments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    quote_service_instrument_id UUID REFERENCES public.quote_service_instruments(id) ON DELETE SET NULL,
    instrument_name TEXT NOT NULL,
    expected_quantity DECIMAL NOT NULL DEFAULT 1,
    received_quantity DECIMAL NOT NULL DEFAULT 0,
    is_unplanned BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)","-- 2. Security: Enable RLS
ALTER TABLE public.project_instruments ENABLE ROW LEVEL SECURITY","-- 3. Policies: Allow full access for authenticated users
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = ''Enable all access for project_instruments''
    ) THEN
        CREATE POLICY \"Enable all access for project_instruments\" ON public.project_instruments
        FOR ALL USING (auth.role() = ''authenticated'') WITH CHECK (auth.role() = ''authenticated'');
    END IF;
END
$$","-- 4. Helper trigger for updated_at
DROP TRIGGER IF EXISTS update_project_instruments_modtime ON public.project_instruments","CREATE TRIGGER update_project_instruments_modtime
    BEFORE UPDATE ON public.project_instruments
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at()","-- 5. Data Migration: Copy existing instruments from approved quotes to active projects
-- This ensures backward compatibility for projects already created.
INSERT INTO public.project_instruments (
    project_id, 
    quote_service_instrument_id, 
    instrument_name, 
    expected_quantity
)
SELECT 
    p.id,
    qsi.id,
    qsi.instrument_name,
    qsi.quantity
FROM public.projects p
JOIN public.quote_services qs ON p.quote_id = qs.quote_id
JOIN public.quote_service_instruments qsi ON qs.id = qsi.quote_service_id
ON CONFLICT DO NOTHING"}', 'create_project_instruments');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260513190000', '{"ALTER TABLE project_machinery ADD COLUMN IF NOT EXISTS unplanned_cost numeric DEFAULT 0","ALTER TABLE project_labor ADD COLUMN IF NOT EXISTS unplanned_cost numeric DEFAULT 0","ALTER TABLE project_materials ADD COLUMN IF NOT EXISTS unplanned_cost numeric DEFAULT 0","ALTER TABLE project_instruments ADD COLUMN IF NOT EXISTS unplanned_cost numeric DEFAULT 0"}', 'add_unplanned_cost');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260514013134', '{"-- Add service link to unplanned resources
ALTER TABLE project_machinery ADD COLUMN IF NOT EXISTS quote_service_id UUID REFERENCES quote_services(id)","ALTER TABLE project_labor ADD COLUMN IF NOT EXISTS quote_service_id UUID REFERENCES quote_services(id)","ALTER TABLE project_materials ADD COLUMN IF NOT EXISTS quote_service_id UUID REFERENCES quote_services(id)","ALTER TABLE project_instruments ADD COLUMN IF NOT EXISTS quote_service_id UUID REFERENCES quote_services(id)","-- Add metadata for complex cost calculations
ALTER TABLE project_machinery ADD COLUMN IF NOT EXISTS calculation_metadata JSONB","ALTER TABLE project_labor ADD COLUMN IF NOT EXISTS calculation_metadata JSONB","ALTER TABLE project_materials ADD COLUMN IF NOT EXISTS calculation_metadata JSONB","ALTER TABLE project_instruments ADD COLUMN IF NOT EXISTS calculation_metadata JSONB"}', 'add_service_link_to_unplanned_resources');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260514111500', '{"-- Migration: Add unplanned flag to project materials
-- Description: Ensures project_materials also has the is_unplanned column for consistent baseline analysis.

ALTER TABLE public.project_materials 
ADD COLUMN IF NOT EXISTS is_unplanned BOOLEAN NOT NULL DEFAULT false","-- Notify PostgREST to reload schema cache
NOTIFY pgrst, ''reload schema''"}', 'fix_project_materials_unplanned');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260514200000', '{"-- Migration: Create Instrument Inspections Table
-- Description: Adds the instrument_inspections table for tracking individual instrument reception records

CREATE TABLE IF NOT EXISTS public.instrument_inspections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_instrument_id UUID NOT NULL REFERENCES public.project_instruments(id) ON DELETE CASCADE,
    internal_code TEXT,
    brand_model TEXT,
    ownership_type TEXT DEFAULT ''owned'' CHECK (ownership_type IN (''owned'', ''rented'')),
    condition_status TEXT DEFAULT ''operational'' CHECK (condition_status IN (''operational'', ''needs_maintenance'', ''damaged'')),
    evidence_photos JSONB DEFAULT ''[]''::jsonb,
    observations TEXT,
    quantity_received INTEGER NOT NULL DEFAULT 1,
    reception_date DATE NOT NULL DEFAULT CURRENT_DATE,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    received_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
)","-- RLS
ALTER TABLE public.instrument_inspections ENABLE ROW LEVEL SECURITY","DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = ''Enable all access for instrument_inspections''
    ) THEN
        CREATE POLICY \"Enable all access for instrument_inspections\" ON public.instrument_inspections
        FOR ALL USING (auth.role() = ''authenticated'') WITH CHECK (auth.role() = ''authenticated'');
    END IF;
END
$$"}', 'create_instrument_inspections');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260515200000', '{"-- Add new fields to machinery_inspections
ALTER TABLE machinery_inspections
  ADD COLUMN IF NOT EXISTS reception_date DATE NOT NULL DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS internal_id TEXT,
  ADD COLUMN IF NOT EXISTS odometer_unit TEXT NOT NULL DEFAULT ''hours''","-- ''hours'' or ''miles''

-- Add reception_date to material_receptions
ALTER TABLE material_receptions
  ADD COLUMN IF NOT EXISTS reception_date DATE NOT NULL DEFAULT CURRENT_DATE","-- Add reception_date to instrument_inspections
ALTER TABLE instrument_inspections
  ADD COLUMN IF NOT EXISTS reception_date DATE NOT NULL DEFAULT CURRENT_DATE"}', 'add_reception_fields');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260516183000', '{"ALTER TABLE labor_roles 
ADD COLUMN IF NOT EXISTS internal_cost_rate NUMERIC DEFAULT 0"}', 'add_internal_cost_rate_to_roles');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260518200000', '{"-- Migration: Create Instrument Assignments + Scheduling Columns
-- Note: This table may also be created by 20260522000000 (IF NOT EXISTS makes it safe)

CREATE TABLE IF NOT EXISTS public.project_instrument_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_instrument_id UUID NOT NULL REFERENCES public.project_instruments(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)","ALTER TABLE public.project_instrument_assignments ENABLE ROW LEVEL SECURITY","DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = ''Enable all access for instrument_assignments''
    ) THEN
        CREATE POLICY \"Enable all access for instrument_assignments\" ON public.project_instrument_assignments
        FOR ALL USING (auth.role() = ''authenticated'') WITH CHECK (auth.role() = ''authenticated'');
    END IF;
END
$$","ALTER TABLE public.project_instruments
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE"}', 'create_instrument_assignments');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260519093900', '{"-- Add tracking fields for EVM (Planned vs Real) on Machinery
ALTER TABLE public.machinery_inspections
ADD COLUMN IF NOT EXISTS returned_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS hour_meter_end NUMERIC","-- Ensure returned_at is not before received_at
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = ''check_inspection_dates'') THEN
        ALTER TABLE public.machinery_inspections 
        ADD CONSTRAINT check_inspection_dates CHECK (returned_at >= received_at);
    END IF;
END $$","-- Add tracking fields for EVM on Machinery Assignments
ALTER TABLE public.project_machinery_assignments
ADD COLUMN IF NOT EXISTS actual_start_date DATE,
ADD COLUMN IF NOT EXISTS actual_end_date DATE,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT ''scheduled'' CHECK (status IN (''scheduled'', ''in_progress'', ''completed'', ''delayed''))","-- Add tracking fields for EVM on Labor Assignments
ALTER TABLE public.project_labor_assignments
ADD COLUMN IF NOT EXISTS actual_start_date DATE,
ADD COLUMN IF NOT EXISTS actual_end_date DATE,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT ''scheduled'' CHECK (status IN (''scheduled'', ''in_progress'', ''completed'', ''delayed''))","-- Tell PostgREST to reload schema cache
NOTIFY pgrst, ''reload schema''"}', 'add_evm_tracking_fields');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260520000000', '{"-- Migration to add scheduling dates to project_labor
ALTER TABLE public.project_labor 
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE","-- Ensure end_date is not before start_date
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = ''check_labor_scheduling_dates'') THEN
        ALTER TABLE public.project_labor 
        ADD CONSTRAINT check_labor_scheduling_dates CHECK (end_date >= start_date);
    END IF;
END $$"}', 'add_labor_scheduling_dates');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260521000000', '{"-- Add quantity_received to instrument_inspections (batch reception support)
ALTER TABLE instrument_inspections
ADD COLUMN IF NOT EXISTS quantity_received INTEGER NOT NULL DEFAULT 1","-- Add quantity field to material_receptions for consistency
ALTER TABLE material_receptions
ADD COLUMN IF NOT EXISTS quantity_received INTEGER NOT NULL DEFAULT 1"}', 'add_quantity_to_instrument_inspections');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260522000000', '{"-- Migration: Create missing assignment/inspection tables
-- These tables are referenced by app code and later migrations but were never created

-- 1. Create project_machinery_assignments (for scheduling dialog + EVM fields)
CREATE TABLE IF NOT EXISTS public.project_machinery_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_machinery_id UUID NOT NULL REFERENCES public.project_machinery(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    actual_start_date DATE,
    actual_end_date DATE,
    status TEXT DEFAULT ''scheduled'' CHECK (status IN (''scheduled'', ''in_progress'', ''completed'', ''delayed'')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)","ALTER TABLE public.project_machinery_assignments ENABLE ROW LEVEL SECURITY","DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = ''Enable all access for machinery_assignments''
    ) THEN
        CREATE POLICY \"Enable all access for machinery_assignments\" ON public.project_machinery_assignments
        FOR ALL USING (auth.role() = ''authenticated'') WITH CHECK (auth.role() = ''authenticated'');
    END IF;
END
$$","-- 2. Create project_instrument_assignments (for instrument scheduling dialog)
CREATE TABLE IF NOT EXISTS public.project_instrument_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_instrument_id UUID NOT NULL REFERENCES public.project_instruments(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)","ALTER TABLE public.project_instrument_assignments ENABLE ROW LEVEL SECURITY","DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = ''Enable all access for instrument_assignments''
    ) THEN
        CREATE POLICY \"Enable all access for instrument_assignments\" ON public.project_instrument_assignments
        FOR ALL USING (auth.role() = ''authenticated'') WITH CHECK (auth.role() = ''authenticated'');
    END IF;
END
$$","-- 3. Add scheduling date columns to project_instruments
ALTER TABLE public.project_instruments
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE"}', 'fix_missing_assignment_tables');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260522100000', '{"-- Add catalog machinery reference to project_machinery for unplanned resources
ALTER TABLE project_machinery ADD COLUMN IF NOT EXISTS machinery_id UUID REFERENCES machinery(id)"}', 'add_machinery_id_to_project_machinery');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260522110000', '{"-- Add catalog reference columns for unplanned resources
ALTER TABLE project_labor ADD COLUMN IF NOT EXISTS role_id UUID REFERENCES labor_roles(id)","ALTER TABLE project_materials ADD COLUMN IF NOT EXISTS material_id UUID REFERENCES materials(id)","ALTER TABLE project_instruments ADD COLUMN IF NOT EXISTS instrument_id UUID REFERENCES logistics_equipment(id)"}', 'add_catalog_refs_to_resources');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260528000000', '{"-- Add client_address column to quotes table
ALTER TABLE public.quotes ADD COLUMN IF NOT EXISTS client_address text"}', 'add_client_address_to_quotes');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260529000000', '{"-- ============================================================================
-- M├│dulo de Operaciones en Campo: Reporte Diario
-- Tablas para captura de progreso diario (labor, maquinaria, materiales)
-- ============================================================================

-- 1. Cat├ílogo de motivos de desviaci├│n
CREATE TABLE IF NOT EXISTS public.deviation_reasons (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    code text UNIQUE NOT NULL,
    description text NOT NULL,
    category text NOT NULL DEFAULT ''general'' CHECK (category IN (''labor'', ''machinery'', ''material'', ''general'')),
    created_at timestamp with time zone DEFAULT now()
)","ALTER TABLE public.deviation_reasons ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on deviation_reasons\"
    ON public.deviation_reasons FOR ALL TO authenticated
    USING (true) WITH CHECK (true)","-- Seed: motivos de desviaci├│n predefinidos
INSERT INTO public.deviation_reasons (code, description, category) VALUES
    (''ABSENCE'', ''Ausencia justificada del trabajador'', ''labor''),
    (''SUBSTITUTION'', ''Sustituci├│n por enfermedad o emergencia'', ''labor''),
    (''REINFORCEMENT'', ''Refuerzo por retraso en la tarea'', ''labor''),
    (''BREAKDOWN'', ''Aver├¡a de m├íquina titular'', ''machinery''),
    (''TERRAIN'', ''Condici├│n de terreno imprevista'', ''machinery''),
    (''URGENCY'', ''Urgencia solicitada por el cliente'', ''general''),
    (''WEATHER'', ''Condiciones clim├íticas adversas'', ''general''),
    (''OTHER'', ''Otro motivo (especificar en notas)'', ''general'')
ON CONFLICT (code) DO NOTHING","-- 2. Cabecera del reporte diario
CREATE TABLE IF NOT EXISTS public.daily_reports (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    report_date date NOT NULL DEFAULT CURRENT_DATE,
    supervisor_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    weather_condition text,
    general_notes text,
    evidence_photos jsonb DEFAULT ''[]''::jsonb,
    signature_data text,
    status text NOT NULL DEFAULT ''draft'' CHECK (status IN (''draft'', ''submitted'', ''approved'', ''rejected'')),
    approved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
)","-- ├ìndice compuesto: un solo reporte por proyecto y fecha
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_reports_project_date
    ON public.daily_reports(project_id, report_date)","ALTER TABLE public.daily_reports ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on daily_reports\"
    ON public.daily_reports FOR ALL TO authenticated
    USING (true) WITH CHECK (true)","-- 3. Registro de jornada laboral diaria
CREATE TABLE IF NOT EXISTS public.report_labor_logs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    daily_report_id uuid NOT NULL REFERENCES public.daily_reports(id) ON DELETE CASCADE,
    worker_id uuid NOT NULL REFERENCES public.workers(id) ON DELETE CASCADE,
    project_labor_id uuid REFERENCES public.project_labor(id) ON DELETE SET NULL,
    project_task_id uuid REFERENCES public.project_tasks(id) ON DELETE SET NULL,
    check_in_time time NOT NULL,
    check_out_time time,
    regular_hours numeric NOT NULL DEFAULT 0,
    overtime_hours numeric NOT NULL DEFAULT 0,
    is_unplanned boolean NOT NULL DEFAULT false,
    deviation_reason_id uuid REFERENCES public.deviation_reasons(id) ON DELETE SET NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now()
)","ALTER TABLE public.report_labor_logs ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on report_labor_logs\"
    ON public.report_labor_logs FOR ALL TO authenticated
    USING (true) WITH CHECK (true)","-- 4. Registro de producci├│n diaria de maquinaria
CREATE TABLE IF NOT EXISTS public.report_machinery_logs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    daily_report_id uuid NOT NULL REFERENCES public.daily_reports(id) ON DELETE CASCADE,
    machinery_id uuid NOT NULL REFERENCES public.machinery(id) ON DELETE CASCADE,
    project_machinery_id uuid REFERENCES public.project_machinery(id) ON DELETE SET NULL,
    operator_id uuid NOT NULL REFERENCES public.workers(id) ON DELETE CASCADE,
    start_meter numeric NOT NULL DEFAULT 0,
    end_meter numeric,
    total_hours numeric NOT NULL DEFAULT 0,
    fuel_added numeric NOT NULL DEFAULT 0,
    is_unplanned boolean NOT NULL DEFAULT false,
    deviation_reason_id uuid REFERENCES public.deviation_reasons(id) ON DELETE SET NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now()
)","ALTER TABLE public.report_machinery_logs ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on report_machinery_logs\"
    ON public.report_machinery_logs FOR ALL TO authenticated
    USING (true) WITH CHECK (true)","-- 5. Registro de consumo diario de materiales
CREATE TABLE IF NOT EXISTS public.report_material_usage (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    daily_report_id uuid NOT NULL REFERENCES public.daily_reports(id) ON DELETE CASCADE,
    material_id uuid NOT NULL REFERENCES public.materials(id) ON DELETE CASCADE,
    project_material_id uuid REFERENCES public.project_materials(id) ON DELETE SET NULL,
    quantity_used numeric NOT NULL DEFAULT 0,
    area_installed numeric,
    unit text,
    notes text,
    created_at timestamp with time zone DEFAULT now()
)","ALTER TABLE public.report_material_usage ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on report_material_usage\"
    ON public.report_material_usage FOR ALL TO authenticated
    USING (true) WITH CHECK (true)","-- ÔöÇÔöÇ Trigger: actualizar updated_at en daily_reports ÔöÇÔöÇ
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql","DROP TRIGGER IF EXISTS set_updated_at ON public.daily_reports","CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.daily_reports
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at()","-- Notificar a PostgREST para recargar el esquema
NOTIFY pgrst, ''reload schema''"}', 'create_daily_reports_module');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260529010000', '{"-- ============================================================================
-- Agrega FKs faltantes para que PostgREST pueda resolver relaciones embebidas
-- necesarias para el m├│dulo de Daily Reports
-- ============================================================================

-- FK: project_labor.role_id ÔåÆ labor_roles.id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = ''project_labor_role_id_fkey''
  ) THEN
    ALTER TABLE public.project_labor
      ADD CONSTRAINT project_labor_role_id_fkey
      FOREIGN KEY (role_id) REFERENCES public.labor_roles(id)
      ON DELETE SET NULL;
  END IF;
END $$","-- FK: project_machinery.machinery_id ÔåÆ machinery.id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = ''project_machinery_machinery_id_fkey''
  ) THEN
    ALTER TABLE public.project_machinery
      ADD CONSTRAINT project_machinery_machinery_id_fkey
      FOREIGN KEY (machinery_id) REFERENCES public.machinery(id)
      ON DELETE SET NULL;
  END IF;
END $$","NOTIFY pgrst, ''reload schema''"}', 'add_missing_catalog_fks');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260529020000', '{"-- Backfill: llenar quote_service_id en registros hu├®rfanos de recursos del proyecto
-- Project Labor (via quote_service_labor_id)
UPDATE public.project_labor pl
SET quote_service_id = qsl.quote_service_id
FROM public.quote_service_labors qsl
WHERE pl.quote_service_labor_id = qsl.id
  AND pl.quote_service_id IS NULL","-- Project Machinery (via quote_service_machinery_id)
UPDATE public.project_machinery pm
SET quote_service_id = qsm.quote_service_id
FROM public.quote_service_machineries qsm
WHERE pm.quote_service_machinery_id = qsm.id
  AND pm.quote_service_id IS NULL","-- Project Materials (via quote_service_material_id)
UPDATE public.project_materials pm
SET quote_service_id = qsm.quote_service_id
FROM public.quote_service_materials qsm
WHERE pm.quote_service_material_id = qsm.id
  AND pm.quote_service_id IS NULL","DO $$
BEGIN
  RAISE NOTICE ''Orphans remaining: labor=%, machinery=%, materials=%'',
    (SELECT COUNT(*) FROM project_labor WHERE quote_service_id IS NULL AND quote_service_labor_id IS NOT NULL),
    (SELECT COUNT(*) FROM project_machinery WHERE quote_service_id IS NULL AND quote_service_machinery_id IS NOT NULL),
    (SELECT COUNT(*) FROM project_materials WHERE quote_service_id IS NULL AND quote_service_material_id IS NOT NULL);
END $$","NOTIFY pgrst, ''reload schema''"}', 'backfill_project_labor_service');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260529020001', '{"-- Backfill: llenar quote_service_id en project_machinery y project_materials
-- Project Machinery (via quote_service_machinery_id)
UPDATE public.project_machinery pm
SET quote_service_id = qsm.quote_service_id
FROM public.quote_service_machineries qsm
WHERE pm.quote_service_machinery_id = qsm.id
  AND pm.quote_service_id IS NULL","-- Project Materials (via quote_service_material_id)
UPDATE public.project_materials pm
SET quote_service_id = qsm.quote_service_id
FROM public.quote_service_materials qsm
WHERE pm.quote_service_material_id = qsm.id
  AND pm.quote_service_id IS NULL","DO $$
BEGIN
  RAISE NOTICE ''Orphans remaining: machinery=%, materials=%'',
    (SELECT COUNT(*) FROM project_machinery WHERE quote_service_id IS NULL AND quote_service_machinery_id IS NOT NULL),
    (SELECT COUNT(*) FROM project_materials WHERE quote_service_id IS NULL AND quote_service_material_id IS NOT NULL);
END $$","NOTIFY pgrst, ''reload schema''"}', 'backfill_machinery_materials_service');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260601000000', '{"-- Backfill: llenar machinery_id en project_machinery por nombre
UPDATE public.project_machinery pm
SET machinery_id = m.id
FROM public.machinery m
WHERE pm.machinery_name = m.description
  AND pm.machinery_id IS NULL","DO $$
BEGIN
  RAISE NOTICE ''Orphan machinery_id remaining: %'',
    (SELECT COUNT(*) FROM project_machinery WHERE machinery_id IS NULL);
END $$","NOTIFY pgrst, ''reload schema''"}', 'backfill_machinery_id');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260601000001', '{"-- Backfill: llenar role_id en project_labor por nombre (case-insensitive)
UPDATE public.project_labor pl
SET role_id = lr.id
FROM public.labor_roles lr
WHERE LOWER(pl.role_name) = LOWER(lr.description)
  AND pl.role_id IS NULL","DO $$
BEGIN
  RAISE NOTICE ''Orphan role_id remaining: %'',
    (SELECT COUNT(*) FROM project_labor WHERE role_id IS NULL);
END $$","NOTIFY pgrst, ''reload schema''"}', 'backfill_role_id');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260601000002', '{"-- Agrega campos de producci├│n a reportes de maquinaria
ALTER TABLE public.report_machinery_logs
  ADD COLUMN IF NOT EXISTS production_value numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS production_unit text","NOTIFY pgrst, ''reload schema''"}', 'add_production_fields');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260603000000', '{"-- Agrega calculation_metadata a projects para guardar baseline y otra metadata
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS calculation_metadata JSONB","NOTIFY pgrst, ''reload schema''"}', 'add_calculation_metadata_to_projects');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260603000001', '{"-- Backfill definitivo: llena quote_service_id usando todas las fuentes disponibles
-- Labor (v├¡a quote_service_labor_id)
UPDATE public.project_labor pl
SET quote_service_id = qsl.quote_service_id
FROM public.quote_service_labors qsl
WHERE pl.quote_service_labor_id = qsl.id AND pl.quote_service_id IS NULL","-- Labor (v├¡a calculation_metadata.service_id para extras sin qsl_id)
UPDATE public.project_labor pl
SET quote_service_id = (pl.calculation_metadata->>''service_id'')::uuid
WHERE pl.calculation_metadata->>''service_id'' IS NOT NULL AND pl.quote_service_id IS NULL","-- Machinery (v├¡a quote_service_machinery_id)
UPDATE public.project_machinery pm
SET quote_service_id = qsm.quote_service_id
FROM public.quote_service_machineries qsm
WHERE pm.quote_service_machinery_id = qsm.id AND pm.quote_service_id IS NULL","-- Machinery (v├¡a calculation_metadata)
UPDATE public.project_machinery pm
SET quote_service_id = (pm.calculation_metadata->>''service_id'')::uuid
WHERE pm.calculation_metadata->>''service_id'' IS NOT NULL AND pm.quote_service_id IS NULL","-- Materials (v├¡a quote_service_material_id)
UPDATE public.project_materials pm
SET quote_service_id = qsm.quote_service_id
FROM public.quote_service_materials qsm
WHERE pm.quote_service_material_id = qsm.id AND pm.quote_service_id IS NULL","-- Materials (v├¡a calculation_metadata)
UPDATE public.project_materials pm
SET quote_service_id = (pm.calculation_metadata->>''service_id'')::uuid
WHERE pm.calculation_metadata->>''service_id'' IS NOT NULL AND pm.quote_service_id IS NULL","-- Instruments (v├¡a quote_service_instrument_id)
UPDATE public.project_instruments pi
SET quote_service_id = qsi.quote_service_id
FROM public.quote_service_instruments qsi
WHERE pi.quote_service_instrument_id = qsi.id AND pi.quote_service_id IS NULL","-- Instruments (v├¡a calculation_metadata)
UPDATE public.project_instruments pi
SET quote_service_id = (pi.calculation_metadata->>''service_id'')::uuid
WHERE pi.calculation_metadata->>''service_id'' IS NOT NULL AND pi.quote_service_id IS NULL","DO $$
BEGIN
  RAISE NOTICE ''Orphans remaining: labor=%, machinery=%, materials=%, instruments=%'',
    (SELECT COUNT(*) FROM project_labor WHERE quote_service_id IS NULL),
    (SELECT COUNT(*) FROM project_machinery WHERE quote_service_id IS NULL),
    (SELECT COUNT(*) FROM project_materials WHERE quote_service_id IS NULL),
    (SELECT COUNT(*) FROM project_instruments WHERE quote_service_id IS NULL);
END $$","NOTIFY pgrst, ''reload schema''"}', 'backfill_service_id_definitive');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260603000002', '{"-- Verificaci├│n de FKs faltantes para PostgREST en producci├│n
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = ''project_machinery_machinery_id_fkey'') THEN
    ALTER TABLE public.project_machinery
      ADD CONSTRAINT project_machinery_machinery_id_fkey
      FOREIGN KEY (machinery_id) REFERENCES public.machinery(id)
      ON DELETE SET NULL;
    RAISE NOTICE ''Created project_machinery_machinery_id_fkey'';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = ''project_labor_role_id_fkey'') THEN
    ALTER TABLE public.project_labor
      ADD CONSTRAINT project_labor_role_id_fkey
      FOREIGN KEY (role_id) REFERENCES public.labor_roles(id)
      ON DELETE SET NULL;
    RAISE NOTICE ''Created project_labor_role_id_fkey'';
  END IF;
END $$","DO $$
DECLARE
  m_fk boolean;
  l_fk boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM pg_constraint WHERE conname = ''project_machinery_machinery_id_fkey'') INTO m_fk;
  SELECT EXISTS(SELECT 1 FROM pg_constraint WHERE conname = ''project_labor_role_id_fkey'') INTO l_fk;
  RAISE NOTICE ''FK status: machinery=%, labor=%'', m_fk, l_fk;
END $$","NOTIFY pgrst, ''reload schema''"}', 'ensure_catalog_fks_production');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260607000000', '{"-- Create payroll_periods table for project labor cost tracking
CREATE TABLE IF NOT EXISTS public.payroll_periods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_regular_hours NUMERIC NOT NULL DEFAULT 0,
  total_overtime_hours NUMERIC NOT NULL DEFAULT 0,
  total_workers INTEGER NOT NULL DEFAULT 0,
  total_cost NUMERIC NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT ''calculated'',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT payroll_periods_dates_check CHECK (end_date >= start_date)
)","-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION handle_payroll_periods_update()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql","DROP TRIGGER IF EXISTS trg_payroll_periods_update ON public.payroll_periods","CREATE TRIGGER trg_payroll_periods_update
  BEFORE UPDATE ON public.payroll_periods
  FOR EACH ROW EXECUTE FUNCTION handle_payroll_periods_update()","-- Index for fast lookup by project
CREATE INDEX IF NOT EXISTS idx_payroll_periods_project
  ON public.payroll_periods(project_id)","-- Enable RLS
ALTER TABLE public.payroll_periods ENABLE ROW LEVEL SECURITY","-- RLS: authenticated users can read all
CREATE POLICY \"Authenticated users can read payroll_periods\"
  ON public.payroll_periods FOR SELECT
  TO authenticated
  USING (true)","-- RLS: authenticated users can insert
CREATE POLICY \"Authenticated users can insert payroll_periods\"
  ON public.payroll_periods FOR INSERT
  TO authenticated
  WITH CHECK (true)","-- RLS: authenticated users can update
CREATE POLICY \"Authenticated users can update payroll_periods\"
  ON public.payroll_periods FOR UPDATE
  TO authenticated
  USING (true)","-- RLS: authenticated users can delete
CREATE POLICY \"Authenticated users can delete payroll_periods\"
  ON public.payroll_periods FOR DELETE
  TO authenticated
  USING (true)","NOTIFY pgrst, ''reload schema''"}', 'create_payroll_periods');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260608000000', '{"ALTER TABLE public.report_machinery_logs
  ADD COLUMN IF NOT EXISTS evidence_photos jsonb DEFAULT ''[]''::jsonb NOT NULL","NOTIFY pgrst, ''reload schema''"}', 'add_evidence_photos_to_machinery_logs');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260608000001', '{"ALTER TABLE public.report_machinery_logs 
  RENAME COLUMN evidence_photos TO start_shift_photos","ALTER TABLE public.report_machinery_logs 
  ADD COLUMN IF NOT EXISTS end_shift_photos jsonb DEFAULT ''[]''::jsonb NOT NULL","NOTIFY pgrst, ''reload schema''"}', 'split_shift_photos');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260610000000', '{"-- Migration: Create Incidents Module
-- Description: Adds incident reporting with specific resource impact tracking

-- Add hourly_operating_cost to projects for automatic impact calculation
ALTER TABLE public.projects
ADD COLUMN IF NOT EXISTS hourly_operating_cost NUMERIC DEFAULT 0","-- Create incident categories catalog (editable from app)
CREATE TABLE IF NOT EXISTS public.incident_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    icon TEXT DEFAULT ''warning_amber'',
    color TEXT DEFAULT ''#EF4444'',
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
)","ALTER TABLE public.incident_categories ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on incident_categories\"
    ON public.incident_categories FOR ALL
    USING (auth.role() = ''authenticated'')
    WITH CHECK (auth.role() = ''authenticated'')","-- Seed default categories
INSERT INTO public.incident_categories (code, name, icon, color) VALUES
    (''MACHINERY_BREAKDOWN'', ''Machinery Breakdown'', ''engineering'', ''#EF4444''),
    (''INSTRUMENT_DAMAGE'', ''Instrument Damage'', ''build'', ''#F97316''),
    (''WORKER_ABSENCE'', ''Worker Absence'', ''person_off'', ''#EAB308''),
    (''WORKER_REPLACEMENT'', ''Worker Replacement'', ''swap_horiz'', ''#A855F7''),
    (''MATERIAL_SHORTAGE'', ''Material Shortage'', ''inventory_2'', ''#3B82F6''),
    (''MATERIAL_DAMAGE'', ''Material Damage'', ''broken_image'', ''#EF4444''),
    (''WEATHER'', ''Weather Contingency'', ''thunderstorm'', ''#06B6D4''),
    (''ACCIDENT'', ''Accident'', ''local_hospital'', ''#DC2626''),
    (''QUALITY_DEFECT'', ''Quality Defect'', ''report_problem'', ''#F97316''),
    (''OTHER'', ''Other'', ''warning_amber'', ''#64748B'')
ON CONFLICT (code) DO NOTHING","-- Main incidents table
CREATE TABLE IF NOT EXISTS public.incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    daily_report_id UUID REFERENCES public.daily_reports(id) ON DELETE SET NULL,
    category_id UUID REFERENCES public.incident_categories(id),
    title TEXT NOT NULL,
    description TEXT,
    priority TEXT NOT NULL DEFAULT ''medium''
        CHECK (priority IN (''low'', ''medium'', ''high'', ''critical'')),
    status TEXT NOT NULL DEFAULT ''open''
        CHECK (status IN (''open'', ''in_progress'', ''resolved'', ''closed'')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    time_impact_hours NUMERIC GENERATED ALWAYS AS (
        CASE WHEN ended_at IS NOT NULL
             THEN EXTRACT(EPOCH FROM (ended_at - started_at)) / 3600
             ELSE NULL END
    ) STORED,
    cost_impact NUMERIC,
    actual_expenses NUMERIC DEFAULT 0,
    resolution_notes TEXT,
    reported_by UUID REFERENCES auth.users(id),
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    evidence_photos JSONB DEFAULT ''[]''::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
)","ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on incidents\"
    ON public.incidents FOR ALL
    USING (auth.role() = ''authenticated'')
    WITH CHECK (auth.role() = ''authenticated'')","-- Specific project resources affected by the incident
CREATE TABLE IF NOT EXISTS public.incident_affected_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
    affected_type TEXT NOT NULL
        CHECK (affected_type IN (''material'', ''machinery'', ''labor'', ''instrument'')),
    project_material_id UUID REFERENCES public.project_materials(id) ON DELETE SET NULL,
    project_machinery_id UUID REFERENCES public.project_machinery(id) ON DELETE SET NULL,
    project_labor_id UUID REFERENCES public.project_labor(id) ON DELETE SET NULL,
    project_instrument_id UUID REFERENCES public.project_instruments(id) ON DELETE SET NULL,
    worker_id UUID REFERENCES public.workers(id) ON DELETE SET NULL,
    machinery_inspection_id UUID REFERENCES public.machinery_inspections(id) ON DELETE SET NULL,
    project_instrument_assignment_id UUID REFERENCES public.project_instrument_assignments(id) ON DELETE SET NULL,
    resource_name TEXT NOT NULL,
    quantity_affected NUMERIC NOT NULL DEFAULT 0,
    unit TEXT,
    estimated_cost NUMERIC DEFAULT 0,
    description TEXT,
    CONSTRAINT chk_single_resource CHECK (
        (CASE WHEN project_material_id IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN project_machinery_id IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN project_labor_id IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN project_instrument_id IS NOT NULL THEN 1 ELSE 0 END) >= 1
    )
)","ALTER TABLE public.incident_affected_items ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on incident_affected_items\"
    ON public.incident_affected_items FOR ALL
    USING (auth.role() = ''authenticated'')
    WITH CHECK (auth.role() = ''authenticated'')","-- Follow-up actions for each incident
CREATE TABLE IF NOT EXISTS public.incident_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    assigned_to UUID REFERENCES auth.users(id),
    due_date DATE,
    status TEXT DEFAULT ''pending'' CHECK (status IN (''pending'', ''completed'')),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
)","ALTER TABLE public.incident_actions ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Enable all access for authenticated users on incident_actions\"
    ON public.incident_actions FOR ALL
    USING (auth.role() = ''authenticated'')
    WITH CHECK (auth.role() = ''authenticated'')","-- Function to calculate cost_impact when ended_at is set
CREATE OR REPLACE FUNCTION public.calculate_incident_cost_impact()
RETURNS TRIGGER AS $$
DECLARE
    v_hourly_rate NUMERIC;
BEGIN
    IF NEW.ended_at IS NOT NULL AND OLD.ended_at IS DISTINCT FROM NEW.ended_at THEN
        SELECT hourly_operating_cost INTO v_hourly_rate
        FROM public.projects WHERE id = NEW.project_id;
        NEW.cost_impact := (EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at)) / 3600) * COALESCE(v_hourly_rate, 0);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER","DROP TRIGGER IF EXISTS calculate_incident_cost_impact ON public.incidents","CREATE TRIGGER calculate_incident_cost_impact
    BEFORE INSERT OR UPDATE OF ended_at ON public.incidents
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_incident_cost_impact()","-- Trigger to update updated_at on incidents
DROP TRIGGER IF EXISTS update_incidents_modtime ON public.incidents","CREATE TRIGGER update_incidents_modtime
    BEFORE UPDATE ON public.incidents
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at()","NOTIFY pgrst, ''reload schema''"}', 'create_incidents_module');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260613000000', '{"-- ============================================================================
-- Agrega columna break_minutes (descanso de 30 min al medio d├¡a)
-- y total_net_hours (horas netas despu├®s del break) a report_labor_logs
-- ============================================================================

ALTER TABLE public.report_labor_logs
  ADD COLUMN break_minutes integer NOT NULL DEFAULT 30,
  ADD COLUMN total_net_hours numeric NOT NULL DEFAULT 0","-- Backfill: calcular total_net_hours para registros existentes
-- F├│rmula: (check_out - check_in) en horas - break_minutes/60
-- Para registros existentes sin break, asumimos 30 min si la jornada >= 6h
UPDATE public.report_labor_logs
SET
  break_minutes = CASE
    WHEN check_out_time IS NOT NULL
      AND (EXTRACT(EPOCH FROM check_out_time - check_in_time) / 3600) >= 6
    THEN 30 ELSE 0
  END,
  total_net_hours = CASE
    WHEN check_out_time IS NOT NULL THEN
      GREATEST(0,
        (EXTRACT(EPOCH FROM check_out_time - check_in_time) / 3600)
        - CASE
            WHEN (EXTRACT(EPOCH FROM check_out_time - check_in_time) / 3600) >= 6
            THEN 30.0 / 60.0 ELSE 0
          END
      )
    ELSE 0
  END","NOTIFY pgrst, ''reload schema''"}', 'add_break_and_net_hours');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260613000001', '{"ALTER TABLE report_machinery_logs ADD COLUMN IF NOT EXISTS rate_override NUMERIC","COMMENT ON COLUMN report_machinery_logs.rate_override IS ''Hourly rate override when a lower-rate worker operates higher-rate machinery. Used in payroll uplift calculation.''"}', 'add_rate_override');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260614000001', '{"-- Baseline versioning: support for multiple baseline snapshots and change orders

-- 1. Baseline Snapshots table
CREATE TABLE IF NOT EXISTS public.project_baseline_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
    version INT NOT NULL CHECK (version >= 1),
    label TEXT,
    reason TEXT,
    frozen_at TIMESTAMPTZ DEFAULT now(),
    frozen_by UUID REFERENCES auth.users(id),
    calculation_metadata JSONB NOT NULL DEFAULT ''{}'',
    UNIQUE(project_id, version)
)","ALTER TABLE public.project_baseline_snapshots ENABLE ROW LEVEL SECURITY","CREATE POLICY \"Users can view baselines for their projects\"
    ON public.project_baseline_snapshots FOR SELECT
    USING (auth.role() = ''authenticated'')","CREATE POLICY \"Users can insert baselines\"
    ON public.project_baseline_snapshots FOR INSERT
    WITH CHECK (auth.role() = ''authenticated'')","-- 2. change_type columns on resource tables
ALTER TABLE public.project_machinery
    ADD COLUMN IF NOT EXISTS change_type TEXT NOT NULL DEFAULT ''planning''
        CHECK (change_type IN (''planning'', ''change_order'')),
    ADD COLUMN IF NOT EXISTS baseline_snapshot_id UUID
        REFERENCES public.project_baseline_snapshots(id)","ALTER TABLE public.project_labor
    ADD COLUMN IF NOT EXISTS change_type TEXT NOT NULL DEFAULT ''planning''
        CHECK (change_type IN (''planning'', ''change_order'')),
    ADD COLUMN IF NOT EXISTS baseline_snapshot_id UUID
        REFERENCES public.project_baseline_snapshots(id)","ALTER TABLE public.project_materials
    ADD COLUMN IF NOT EXISTS change_type TEXT NOT NULL DEFAULT ''planning''
        CHECK (change_type IN (''planning'', ''change_order'')),
    ADD COLUMN IF NOT EXISTS baseline_snapshot_id UUID
        REFERENCES public.project_baseline_snapshots(id)","ALTER TABLE public.project_instruments
    ADD COLUMN IF NOT EXISTS change_type TEXT NOT NULL DEFAULT ''planning''
        CHECK (change_type IN (''planning'', ''change_order'')),
    ADD COLUMN IF NOT EXISTS baseline_snapshot_id UUID
        REFERENCES public.project_baseline_snapshots(id)","-- 3. Index for faster queries
CREATE INDEX IF NOT EXISTS idx_baseline_snapshots_project
    ON public.project_baseline_snapshots(project_id, version DESC)","CREATE INDEX IF NOT EXISTS idx_machinery_baseline_snapshot
    ON public.project_machinery(baseline_snapshot_id)","CREATE INDEX IF NOT EXISTS idx_labor_baseline_snapshot
    ON public.project_labor(baseline_snapshot_id)","CREATE INDEX IF NOT EXISTS idx_materials_baseline_snapshot
    ON public.project_materials(baseline_snapshot_id)","CREATE INDEX IF NOT EXISTS idx_instruments_baseline_snapshot
    ON public.project_instruments(baseline_snapshot_id)"}', 'baseline_versioning');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260614000002', '{"-- Migrate existing projects with baseline_frozen = true to the new versioned system

DO $$
DECLARE
    project_rec RECORD;
    snapshot_id UUID;
    v INT;
    meta JSONB;
BEGIN
    FOR project_rec IN
        SELECT id, calculation_metadata
        FROM public.projects
        WHERE calculation_metadata->>''baseline_frozen'' = ''true''
          AND calculation_metadata->>''baseline_latest_snapshot_id'' IS NULL
    LOOP
        -- Determine next version
        SELECT COALESCE(MAX(version), 0) + 1 INTO v
        FROM public.project_baseline_snapshots
        WHERE project_id = project_rec.id;

        -- Create snapshot
        meta := project_rec.calculation_metadata;
        meta := jsonb_set(meta, ''{baseline_latest_version}'', to_jsonb(v));

        INSERT INTO public.project_baseline_snapshots
            (project_id, version, label, frozen_at, calculation_metadata)
        VALUES
            (project_rec.id, v, ''v'' || v, 
             COALESCE(
                 (project_rec.calculation_metadata->>''baseline_frozen_at'')::timestamptz,
                 now()
             ),
             project_rec.calculation_metadata)
        RETURNING id INTO snapshot_id;

        -- Update calculation_metadata with snapshot reference
        meta := jsonb_set(meta, ''{baseline_latest_snapshot_id}'', to_jsonb(snapshot_id::text));
        meta := meta - ''baseline_frozen'';

        UPDATE public.projects
        SET calculation_metadata = meta
        WHERE id = project_rec.id;

        -- Assign snapshot to all existing resources for this project
        UPDATE public.project_machinery
        SET baseline_snapshot_id = snapshot_id,
            change_type = ''planning''
        WHERE project_id = project_rec.id
          AND baseline_snapshot_id IS NULL;

        UPDATE public.project_labor
        SET baseline_snapshot_id = snapshot_id,
            change_type = ''planning''
        WHERE project_id = project_rec.id
          AND baseline_snapshot_id IS NULL;

        UPDATE public.project_materials
        SET baseline_snapshot_id = snapshot_id,
            change_type = ''planning''
        WHERE project_id = project_rec.id
          AND baseline_snapshot_id IS NULL;

        UPDATE public.project_instruments
        SET baseline_snapshot_id = snapshot_id,
            change_type = ''planning''
        WHERE project_id = project_rec.id
          AND baseline_snapshot_id IS NULL;
    END LOOP;
END $$"}', 'migrate_existing_baselines');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260618000000', '{"-- Migration: Refactor incident cost calculation to use resource-specific hourly rates
-- Replaces project-level hourly_operating_cost with per-resource hourly_cost_rate

-- 1. Add hourly_cost_rate to incident_affected_items (suggested, user-editable)
ALTER TABLE public.incident_affected_items
ADD COLUMN IF NOT EXISTS hourly_cost_rate NUMERIC DEFAULT 0","-- 2. Remove estimated_cost (confusing with actual_expenses)
ALTER TABLE public.incident_affected_items
DROP COLUMN IF EXISTS estimated_cost","-- 3. Modify trigger to use SUM of resource hourly rates instead of project.hourly_operating_cost
CREATE OR REPLACE FUNCTION public.calculate_incident_cost_impact()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ended_at IS NOT NULL THEN
        NEW.cost_impact := NEW.time_impact_hours * COALESCE(
            (SELECT SUM(hourly_cost_rate) FROM public.incident_affected_items WHERE incident_id = NEW.id),
            0
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER","-- 4. Ensure trigger is properly set
DROP TRIGGER IF EXISTS calculate_incident_cost_impact ON public.incidents","CREATE TRIGGER calculate_incident_cost_impact
    BEFORE INSERT OR UPDATE OF ended_at ON public.incidents
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_incident_cost_impact()","NOTIFY pgrst, ''reload schema''"}', 'refactor_incident_cost_calc');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260618000100', '{"-- Migration: Create Billing & Change Orders Module
-- Pay Application (G702/G703) + Change Orders (AIA G701)

-- ============================================================
-- 1. INVOICE SEQUENCES (auto-incremental global numbering)
-- ============================================================
CREATE TABLE public.invoice_sequences (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prefix      text NOT NULL,
  year        integer NOT NULL DEFAULT extract(year from now()),
  last_number integer NOT NULL DEFAULT 0,
  UNIQUE(prefix, year)
)","CREATE OR REPLACE FUNCTION public.next_invoice_number(p_prefix text)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE
  v_year integer := extract(year from now());
  v_next integer;
BEGIN
  INSERT INTO public.invoice_sequences (prefix, year, last_number)
  VALUES (p_prefix, v_year, 1)
  ON CONFLICT (prefix, year) DO UPDATE SET last_number = invoice_sequences.last_number + 1
  RETURNING last_number INTO v_next;
  RETURN p_prefix || ''-'' || v_year::text || ''-'' || LPAD(v_next::text, 4, ''0'');
END;
$$","-- ============================================================
-- 2. CHANGE ORDERS
-- ============================================================
CREATE TABLE public.change_orders (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id        uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  co_number         text NOT NULL UNIQUE DEFAULT public.next_invoice_number(''CO''),
  title             text NOT NULL,
  status            text NOT NULL DEFAULT ''draft''
                    CHECK (status IN (''draft'',''submitted'',''approved'',''rejected'')),
  description       text,
  executed_date     date,
  original_contract_amount  numeric NOT NULL DEFAULT 0,
  adjustment_amount         numeric NOT NULL DEFAULT 0,
  new_contract_amount       numeric GENERATED ALWAYS AS (original_contract_amount + adjustment_amount) STORED,
  schedule_days_change      integer NOT NULL DEFAULT 0,
  created_by        uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_by       uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_at       timestamptz,
  rejected_at       timestamptz,
  rejection_reason  text,
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now()
)","CREATE TABLE public.change_order_details (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  change_order_id   uuid NOT NULL REFERENCES public.change_orders(id) ON DELETE CASCADE,
  line_type         text NOT NULL DEFAULT ''existing_service''
                    CHECK (line_type IN (''existing_service'',''new_service'',''deduction'')),
  quote_service_id  uuid REFERENCES public.quote_services(id) ON DELETE SET NULL,
  catalog_service_id uuid REFERENCES public.services(id) ON DELETE SET NULL,
  service_name      text NOT NULL,
  unit_of_measure   text NOT NULL,
  quantity_change   numeric NOT NULL,
  unit_price        numeric NOT NULL,
  total_change      numeric GENERATED ALWAYS AS (quantity_change * unit_price) STORED,
  notes             text,
  created_at        timestamptz DEFAULT now()
)","-- Trigger: recalculate adjustment_amount on change_orders when details change
CREATE OR REPLACE FUNCTION public.recalc_change_order_total()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.change_orders
  SET adjustment_amount = (
    SELECT COALESCE(SUM(total_change), 0)
    FROM public.change_order_details
    WHERE change_order_id = COALESCE(NEW.change_order_id, OLD.change_order_id)
  )
  WHERE id = COALESCE(NEW.change_order_id, OLD.change_order_id);
  RETURN NULL;
END;
$$","CREATE CONSTRAINT TRIGGER trg_recalc_co_total
AFTER INSERT OR UPDATE OR DELETE ON public.change_order_details
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION public.recalc_change_order_total()","-- Trigger: auto update updated_at
CREATE TRIGGER trg_change_orders_updated_at
  BEFORE UPDATE ON public.change_orders
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at()","-- ============================================================
-- 3. INVOICES (Pay Application Header / G702)
-- ============================================================
CREATE TABLE public.invoices (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id            uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  invoice_number        text NOT NULL UNIQUE DEFAULT public.next_invoice_number(''INV''),
  application_date      date NOT NULL DEFAULT CURRENT_DATE,
  period_start          date NOT NULL,
  period_end            date NOT NULL,
  status                text NOT NULL DEFAULT ''draft''
                        CHECK (status IN (''draft'',''submitted'',''paid'',''cancelled'')),
  retainage_rate        numeric NOT NULL DEFAULT 5.0,
  original_contract     numeric NOT NULL DEFAULT 0,
  approved_cos_total    numeric NOT NULL DEFAULT 0,
  current_contract      numeric GENERATED ALWAYS AS (original_contract + approved_cos_total) STORED,
  total_previous_billed numeric NOT NULL DEFAULT 0,
  total_this_period     numeric NOT NULL DEFAULT 0,
  total_completed       numeric GENERATED ALWAYS AS (total_previous_billed + total_this_period) STORED,
  total_retainage       numeric NOT NULL DEFAULT 0,
  total_due             numeric GENERATED ALWAYS AS (total_this_period - total_retainage) STORED,
  balance_to_finish     numeric GENERATED ALWAYS AS ((original_contract + approved_cos_total) - (total_previous_billed + total_this_period)) STORED,
  notes                 text,
  created_by            uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at            timestamptz DEFAULT now(),
  updated_at            timestamptz DEFAULT now(),
  CHECK (period_end >= period_start)
)","CREATE TRIGGER trg_invoices_updated_at
  BEFORE UPDATE ON public.invoices
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at()","-- ============================================================
-- 4. INVOICE DETAILS (Pay Application Line Items / G703)
-- ============================================================
CREATE TABLE public.invoice_details (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id            uuid NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  quote_service_id      uuid REFERENCES public.quote_services(id) ON DELETE SET NULL,
  change_order_id       uuid REFERENCES public.change_orders(id) ON DELETE SET NULL,
  line_type             text NOT NULL DEFAULT ''service''
                        CHECK (line_type IN (''service'',''equipment'',''co_adjustment'')),
  sort_order            integer NOT NULL DEFAULT 0,
  service_name          text NOT NULL,
  unit_of_measure       text NOT NULL,
  scheduled_value       numeric NOT NULL,
  previous_completed    numeric NOT NULL DEFAULT 0,
  this_period_qty       numeric NOT NULL DEFAULT 0,
  this_period_amount    numeric NOT NULL DEFAULT 0,
  equipment_present     numeric NOT NULL DEFAULT 0,
  retainage_rate        numeric NOT NULL DEFAULT 5.0,
  notes                 text,
  created_at            timestamptz DEFAULT now()
)","-- ============================================================
-- 5. INVOICE Ôåö CHANGE ORDER LINK
-- ============================================================
CREATE TABLE public.invoice_change_order_links (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id      uuid NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  change_order_id uuid NOT NULL REFERENCES public.change_orders(id) ON DELETE CASCADE,
  UNIQUE(invoice_id, change_order_id)
)","-- ============================================================
-- 6. HELPER FUNCTION: Get previous billing totals per service
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_previous_billing_totals(
  p_project_id uuid,
  p_exclude_invoice_id uuid DEFAULT NULL
)
RETURNS TABLE(quote_service_id uuid, total_previous numeric, total_previous_qty numeric)
LANGUAGE sql STABLE AS $$
  SELECT
    id.quote_service_id,
    COALESCE(SUM(id.this_period_amount), 0)::numeric as total_previous,
    COALESCE(SUM(id.this_period_qty), 0)::numeric as total_previous_qty
  FROM public.invoice_details id
  JOIN public.invoices i ON i.id = id.invoice_id
  WHERE i.project_id = p_project_id
    AND i.status IN (''submitted'', ''paid'')
    AND (p_exclude_invoice_id IS NULL OR i.id != p_exclude_invoice_id)
  GROUP BY id.quote_service_id;
$$","-- ============================================================
-- 7. HELPER FUNCTION: Get Pay Application data for a project
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_pay_application_data(
  p_project_id    uuid,
  p_period_start  date,
  p_period_end    date,
  p_exclude_inv_id uuid DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_quote_id          uuid;
  v_original_contract numeric := 0;
  v_approved_cos      numeric := 0;
  v_previous_total    numeric := 0;
  v_lines             jsonb := ''[]''::jsonb;
  v_line              record;
  v_prev_rec          record;
  v_accumulated_qty   numeric;
  v_earned            numeric;
  v_this_period_amt   numeric;
BEGIN
  -- Get project quote_id
  SELECT quote_id INTO v_quote_id FROM public.projects WHERE id = p_project_id;

  -- Calculate original contract sum (scheduled value from quote services)
  SELECT COALESCE(SUM(COALESCE(qs.direct_cost, 0)), 0) INTO v_original_contract
  FROM public.quote_services qs
  WHERE qs.quote_id = v_quote_id;

  -- Sum approved change orders
  SELECT COALESCE(SUM(adjustment_amount), 0) INTO v_approved_cos
  FROM public.change_orders
  WHERE project_id = p_project_id AND status = ''approved'';

  -- Sum previous billings (paid invoices)
  SELECT COALESCE(SUM(total_this_period), 0) INTO v_previous_total
  FROM public.invoices
  WHERE project_id = p_project_id AND status = ''paid'';

  -- Build invoice lines from quote_services
  FOR v_line IN
    SELECT
      qs.id as quote_service_id,
      qs.name as service_name,
      qs.unit_of_measure,
      COALESCE(qs.direct_cost, 0) as scheduled_value,
      qs.quantity as contract_quantity
    FROM public.quote_services qs
    WHERE qs.quote_id = v_quote_id
    ORDER BY qs.created_at
  LOOP
    -- Get previous billing for this service
    SELECT total_previous, total_previous_qty
    INTO v_prev_rec
    FROM public.get_previous_billing_totals(p_project_id, p_exclude_inv_id)
    WHERE quote_service_id = v_line.quote_service_id;

    -- Get accumulated production from daily reports for this service
    SELECT COALESCE(SUM(rml.production_value), 0)
    INTO v_accumulated_qty
    FROM public.report_machinery_logs rml
    JOIN public.daily_reports dr ON dr.id = rml.daily_report_id
    JOIN public.project_machinery pm ON pm.id = rml.project_machinery_id
    WHERE pm.quote_service_id = v_line.quote_service_id
      AND dr.project_id = p_project_id
      AND dr.report_date <= p_period_end
      AND dr.status IN (''submitted'', ''approved'');

    -- Calculate this period amount based on % progress
    v_this_period_amt := 0;
    IF v_line.contract_quantity > 0 AND v_line.scheduled_value > 0 THEN
      v_earned := (v_accumulated_qty / v_line.contract_quantity) * v_line.scheduled_value;
      v_this_period_amt := GREATEST(0, v_earned - COALESCE(v_prev_rec.total_previous, 0));
    END IF;

    v_lines := v_lines || jsonb_build_object(
      ''quote_service_id'', v_line.quote_service_id,
      ''service_name'', v_line.service_name,
      ''unit_of_measure'', v_line.unit_of_measure,
      ''line_type'', ''service'',
      ''scheduled_value'', v_line.scheduled_value,
      ''previous_completed'', COALESCE(v_prev_rec.total_previous, 0),
      ''previous_qty'', COALESCE(v_prev_rec.total_previous_qty, 0),
      ''this_period_qty'', v_accumulated_qty,
      ''this_period_amount'', v_this_period_amt,
      ''equipment_present'', 0
    );
  END LOOP;

  RETURN jsonb_build_object(
    ''original_contract'', v_original_contract,
    ''approved_cos_total'', v_approved_cos,
    ''current_contract'', v_original_contract + v_approved_cos,
    ''previous_total'', v_previous_total,
    ''lines'', v_lines
  );
END;
$$","-- ============================================================
-- 8. ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.invoice_sequences ENABLE ROW LEVEL SECURITY","ALTER TABLE public.change_orders ENABLE ROW LEVEL SECURITY","ALTER TABLE public.change_order_details ENABLE ROW LEVEL SECURITY","ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY","ALTER TABLE public.invoice_details ENABLE ROW LEVEL SECURITY","ALTER TABLE public.invoice_change_order_links ENABLE ROW LEVEL SECURITY","-- Allow all authenticated users access (matching existing project policies style)
CREATE POLICY select_all ON public.invoice_sequences FOR SELECT USING (true)","CREATE POLICY all_all ON public.invoice_sequences FOR ALL USING (true)","CREATE POLICY select_change_orders ON public.change_orders FOR SELECT USING (true)","CREATE POLICY insert_change_orders ON public.change_orders FOR INSERT WITH CHECK (true)","CREATE POLICY update_change_orders ON public.change_orders FOR UPDATE USING (true)","CREATE POLICY delete_change_orders ON public.change_orders FOR DELETE USING (true)","CREATE POLICY select_change_order_details ON public.change_order_details FOR SELECT USING (true)","CREATE POLICY insert_change_order_details ON public.change_order_details FOR INSERT WITH CHECK (true)","CREATE POLICY update_change_order_details ON public.change_order_details FOR UPDATE USING (true)","CREATE POLICY delete_change_order_details ON public.change_order_details FOR DELETE USING (true)","CREATE POLICY select_invoices ON public.invoices FOR SELECT USING (true)","CREATE POLICY insert_invoices ON public.invoices FOR INSERT WITH CHECK (true)","CREATE POLICY update_invoices ON public.invoices FOR UPDATE USING (true)","CREATE POLICY delete_invoices ON public.invoices FOR DELETE USING (true)","CREATE POLICY select_invoice_details ON public.invoice_details FOR SELECT USING (true)","CREATE POLICY insert_invoice_details ON public.invoice_details FOR INSERT WITH CHECK (true)","CREATE POLICY update_invoice_details ON public.invoice_details FOR UPDATE USING (true)","CREATE POLICY delete_invoice_details ON public.invoice_details FOR DELETE USING (true)","CREATE POLICY select_links ON public.invoice_change_order_links FOR SELECT USING (true)","CREATE POLICY insert_links ON public.invoice_change_order_links FOR INSERT WITH CHECK (true)","CREATE POLICY delete_links ON public.invoice_change_order_links FOR DELETE USING (true)","NOTIFY pgrst, ''reload schema''"}', 'create_billing_module');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260623000000', '{"-- ============================================================
-- FIX: Replace billing RPC functions with corrected versions
-- ============================================================

-- 1. get_previous_billing_totals: include ''submitted'' invoices
CREATE OR REPLACE FUNCTION public.get_previous_billing_totals(
  p_project_id uuid,
  p_exclude_invoice_id uuid DEFAULT NULL
)
RETURNS TABLE(quote_service_id uuid, total_previous numeric, total_previous_qty numeric)
LANGUAGE sql STABLE AS $$
  SELECT
    id.quote_service_id,
    COALESCE(SUM(id.this_period_amount), 0)::numeric as total_previous,
    COALESCE(SUM(id.this_period_qty), 0)::numeric as total_previous_qty
  FROM public.invoice_details id
  JOIN public.invoices i ON i.id = id.invoice_id
  WHERE i.project_id = p_project_id
    AND i.status IN (''submitted'', ''paid'')
    AND (p_exclude_invoice_id IS NULL OR i.id != p_exclude_invoice_id)
  GROUP BY id.quote_service_id;
$$","-- 2. get_pay_application_data: all accumulated fixes
CREATE OR REPLACE FUNCTION public.get_pay_application_data(
  p_project_id    uuid,
  p_period_start  date,
  p_period_end    date,
  p_exclude_inv_id uuid DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_quote_id          uuid;
  v_original_contract numeric := 0;
  v_approved_cos      numeric := 0;
  v_previous_total    numeric := 0;
  v_lines             jsonb := ''[]''::jsonb;
  v_line              record;
  v_prev_rec          record;
  v_accumulated_qty   numeric;
  v_earned            numeric;
  v_this_period_amt   numeric;
BEGIN
  -- Get project quote_id
  SELECT quote_id INTO v_quote_id FROM public.projects WHERE id = p_project_id;

  -- Calculate original contract sum (direct_cost already holds totalSaleV2)
  SELECT COALESCE(SUM(COALESCE(qs.direct_cost, 0)), 0) INTO v_original_contract
  FROM public.quote_services qs
  WHERE qs.quote_id = v_quote_id;

  -- Sum approved change orders
  SELECT COALESCE(SUM(adjustment_amount), 0) INTO v_approved_cos
  FROM public.change_orders
  WHERE project_id = p_project_id AND status = ''approved'';

  -- Sum previous billings (paid invoices)
  SELECT COALESCE(SUM(total_this_period), 0) INTO v_previous_total
  FROM public.invoices
  WHERE project_id = p_project_id AND status = ''paid'';

  -- Build invoice lines from quote_services
  FOR v_line IN
    SELECT
      qs.id as quote_service_id,
      qs.name as service_name,
      qs.unit_of_measure,
      COALESCE(qs.direct_cost, 0) as scheduled_value,
      qs.quantity as contract_quantity
    FROM public.quote_services qs
    WHERE qs.quote_id = v_quote_id
    ORDER BY qs.created_at
  LOOP
    -- Get previous billing for this service
    SELECT total_previous, total_previous_qty
    INTO v_prev_rec
    FROM public.get_previous_billing_totals(p_project_id, p_exclude_inv_id)
    WHERE quote_service_id = v_line.quote_service_id;

    -- Get accumulated production from daily reports for this service
    SELECT COALESCE(SUM(rml.production_value), 0)
    INTO v_accumulated_qty
    FROM public.report_machinery_logs rml
    JOIN public.daily_reports dr ON dr.id = rml.daily_report_id
    JOIN public.project_machinery pm ON pm.id = rml.project_machinery_id
    WHERE pm.quote_service_id = v_line.quote_service_id
      AND dr.project_id = p_project_id
      AND dr.report_date <= p_period_end
      AND dr.status IN (''submitted'', ''approved'');

    -- Calculate this period amount based on % progress
    v_this_period_amt := 0;
    IF v_line.contract_quantity > 0 AND v_line.scheduled_value > 0 THEN
      v_earned := (v_accumulated_qty / v_line.contract_quantity) * v_line.scheduled_value;
      v_this_period_amt := GREATEST(0, v_earned - COALESCE(v_prev_rec.total_previous, 0));
    END IF;

    v_lines := v_lines || jsonb_build_object(
      ''quote_service_id'', v_line.quote_service_id,
      ''service_name'', v_line.service_name,
      ''unit_of_measure'', v_line.unit_of_measure,
      ''line_type'', ''service'',
      ''scheduled_value'', v_line.scheduled_value,
      ''previous_completed'', COALESCE(v_prev_rec.total_previous, 0),
      ''previous_qty'', COALESCE(v_prev_rec.total_previous_qty, 0),
      ''this_period_qty'', v_accumulated_qty,
      ''this_period_amount'', v_this_period_amt,
      ''equipment_present'', 0
    );
  END LOOP;

  RETURN jsonb_build_object(
    ''original_contract'', v_original_contract,
    ''approved_cos_total'', v_approved_cos,
    ''current_contract'', v_original_contract + v_approved_cos,
    ''previous_total'', v_previous_total,
    ''lines'', v_lines
  );
END;
$$"}', 'fix_billing_functions');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260624000000', '{"-- Add change_order_header and change_order_detail to invoice_details line_type check
ALTER TABLE public.invoice_details
  DROP CONSTRAINT IF EXISTS invoice_details_line_type_check","ALTER TABLE public.invoice_details
  ADD CONSTRAINT invoice_details_line_type_check
    CHECK (line_type = ANY (ARRAY[
      ''service''::text,
      ''equipment''::text,
      ''co_adjustment''::text,
      ''change_order_header''::text,
      ''change_order_detail''::text
    ]))"}', 'add_co_line_types');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260628000000', '{"ALTER TABLE public.quote_services 
  ADD COLUMN IF NOT EXISTS target_price numeric DEFAULT 0"}', 'add_target_price');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260628000001', '{"-- Migration: Add daily rate and days affected for machinery downtime cost tracking
-- Supports monetary compensation for rented machinery unavailability

-- 1. Add columns to incident_affected_items
ALTER TABLE public.incident_affected_items
  ADD COLUMN IF NOT EXISTS daily_rate NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS days_affected NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS downtime_rent_cost NUMERIC 
    GENERATED ALWAYS AS (daily_rate * days_affected) STORED","-- 2. Update trigger to include downtime_rent_cost in cost_impact
CREATE OR REPLACE FUNCTION public.calculate_incident_cost_impact()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ended_at IS NOT NULL THEN
        NEW.cost_impact := (NEW.time_impact_hours * COALESCE(
            (SELECT SUM(hourly_cost_rate) FROM public.incident_affected_items WHERE incident_id = NEW.id),
            0
        )) + COALESCE(
            (SELECT SUM(downtime_rent_cost) FROM public.incident_affected_items WHERE incident_id = NEW.id),
            0
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER","-- 3. Re-create trigger
DROP TRIGGER IF EXISTS calculate_incident_cost_impact ON public.incidents","CREATE TRIGGER calculate_incident_cost_impact
    BEFORE INSERT OR UPDATE OF ended_at ON public.incidents
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_incident_cost_impact()"}', 'add_downtime_cost_tracking');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260628000002', '{"-- Migration: Fix cost_impact recalculation when affected items change after resolution
-- Previously cost_impact was only recalculated when ended_at changed.
-- Now it also recalculates when affected items are added, removed, or updated.

CREATE OR REPLACE FUNCTION public.recalculate_incident_cost_after_items_change()
RETURNS TRIGGER AS $$
DECLARE
    v_incident_id UUID;
BEGIN
    IF TG_OP = ''DELETE'' THEN
        v_incident_id := OLD.incident_id;
    ELSE
        v_incident_id := NEW.incident_id;
    END IF;

    UPDATE public.incidents
    SET cost_impact = (
        SELECT COALESCE(
            (SELECT SUM(hourly_cost_rate) FROM public.incident_affected_items WHERE incident_id = v_incident_id),
            0
        ) * COALESCE(
            (SELECT EXTRACT(EPOCH FROM (ended_at - started_at)) / 3600 FROM public.incidents WHERE id = v_incident_id),
            0
        ) + COALESCE(
            (SELECT SUM(downtime_rent_cost) FROM public.incident_affected_items WHERE incident_id = v_incident_id),
            0
        )
    )
    WHERE id = v_incident_id
      AND ended_at IS NOT NULL;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER","DROP TRIGGER IF EXISTS recalculate_incident_cost_after_items_change ON public.incident_affected_items","CREATE TRIGGER recalculate_incident_cost_after_items_change
    AFTER INSERT OR UPDATE OR DELETE ON public.incident_affected_items
    FOR EACH ROW
    EXECUTE FUNCTION public.recalculate_incident_cost_after_items_change()","NOTIFY pgrst, ''reload schema''"}', 'fix_incident_cost_recalc_trigger');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260628000003', '{"-- Migration: Remove downtime_rent_cost from cost_impact calculation
-- Downtime rent is compensated by the contracting company, so only time-based cost applies

CREATE OR REPLACE FUNCTION public.calculate_incident_cost_impact()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ended_at IS NOT NULL THEN
        NEW.cost_impact := NEW.time_impact_hours * COALESCE(
            (SELECT SUM(hourly_cost_rate) FROM public.incident_affected_items WHERE incident_id = NEW.id),
            0
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER","DROP TRIGGER IF EXISTS calculate_incident_cost_impact ON public.incidents","CREATE TRIGGER calculate_incident_cost_impact
    BEFORE INSERT OR UPDATE OF ended_at ON public.incidents
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_incident_cost_impact()"}', 'remove_rent_from_cost_impact');


--
-- Data for Name: seed_files; Type: TABLE DATA; Schema: supabase_migrations; Owner: -
--

INSERT INTO supabase_migrations.seed_files (path, hash) VALUES ('supabase/seed.sql', '45940738315eb3425b49046521099b870595ba5f7500c49f36f17142f62b656b');


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: -
--



--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 79, true);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: -
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


--
-- Name: hooks_id_seq; Type: SEQUENCE SET; Schema: supabase_functions; Owner: -
--

SELECT pg_catalog.setval('supabase_functions.hooks_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

\unrestrict jM926k8dtrTyxNDef0gJsPQbeNxHZIyifWCIV39BjmghHKaP3lKDft39GbAQWcT

