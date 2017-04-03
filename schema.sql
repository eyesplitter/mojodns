--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.1
-- Dumped by pg_dump version 9.6.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: update_ns(); Type: FUNCTION; Schema: public; Owner: dns
--

CREATE FUNCTION update_ns() RETURNS trigger
    LANGUAGE plpgsql
    AS $$begin
if(TG_OP='UPDATE' or TG_OP='INSERT')then
	if(new."type"='NS') then
		update records set content='dns.aksinet.net vladimir@aksinet.net '||nextval('tech_serial')::varchar||' 300 180 3600 180' where zone_id=0 and "type"='SOA';
	end if;
elsif(TG_OP='DELETE') then
	if(old."type"='NS') then
		update records set content='dns.aksinet.net vladimir@aksinet.net '||nextval('tech_serial')::varchar||' 300 180 3600 180' where zone_id=0 and "type"='SOA';
	end if;
end if;
end;$$;


ALTER FUNCTION public.update_ns() OWNER TO dns;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: audits; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE audits (
    id integer NOT NULL,
    auditable_id integer,
    auditable_type character varying(255),
    auditable_parent_id integer,
    auditable_parent_type character varying(255),
    user_id integer,
    user_type character varying(255),
    username character varying(255),
    action character varying(255),
    changes text,
    version integer DEFAULT 0,
    created_at timestamp without time zone
);


ALTER TABLE audits OWNER TO dns;

--
-- Name: audits_id_seq; Type: SEQUENCE; Schema: public; Owner: dns
--

CREATE SEQUENCE audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE audits_id_seq OWNER TO dns;

--
-- Name: audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dns
--

ALTER SEQUENCE audits_id_seq OWNED BY audits.id;


--
-- Name: auth_tokens; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE auth_tokens (
    id integer NOT NULL,
    domain_id integer,
    user_id integer,
    token character varying(255) NOT NULL,
    permissions text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    expires_at timestamp without time zone NOT NULL
);


ALTER TABLE auth_tokens OWNER TO dns;

--
-- Name: auth_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: dns
--

CREATE SEQUENCE auth_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE auth_tokens_id_seq OWNER TO dns;

--
-- Name: auth_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dns
--

ALTER SEQUENCE auth_tokens_id_seq OWNED BY auth_tokens.id;


--
-- Name: domains; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE domains (
    id integer NOT NULL,
    name character varying(255),
    master character varying(255),
    last_check integer,
    type character varying(255) DEFAULT 'NATIVE'::character varying,
    notified_serial integer,
    account character varying(255),
    ttl integer DEFAULT 86400,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    notes text
);


ALTER TABLE domains OWNER TO dns;

--
-- Name: domains_id_seq; Type: SEQUENCE; Schema: public; Owner: dns
--

CREATE SEQUENCE domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE domains_id_seq OWNER TO dns;

--
-- Name: domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dns
--

ALTER SEQUENCE domains_id_seq OWNED BY domains.id;


--
-- Name: history; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE history (
    uid bigint NOT NULL,
    user_id bigint,
    target_id bigint,
    target_type character varying,
    t timestamp with time zone,
    message character varying
);


ALTER TABLE history OWNER TO dns;

--
-- Name: history_uid_seq; Type: SEQUENCE; Schema: public; Owner: dns
--

CREATE SEQUENCE history_uid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE history_uid_seq OWNER TO dns;

--
-- Name: history_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dns
--

ALTER SEQUENCE history_uid_seq OWNED BY history.uid;


--
-- Name: macro_steps; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE macro_steps (
    id integer NOT NULL,
    macro_id integer,
    action character varying(255),
    record_type character varying(255),
    name character varying(255),
    content character varying(255),
    ttl integer,
    prio integer,
    "position" integer NOT NULL,
    active boolean DEFAULT true,
    note character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE macro_steps OWNER TO dns;

--
-- Name: macro_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: dns
--

CREATE SEQUENCE macro_steps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE macro_steps_id_seq OWNER TO dns;

--
-- Name: macro_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dns
--

ALTER SEQUENCE macro_steps_id_seq OWNED BY macro_steps.id;


--
-- Name: macros; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE macros (
    id integer NOT NULL,
    name character varying(255),
    description character varying(255),
    user_id integer,
    active boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE macros OWNER TO dns;

--
-- Name: macros_id_seq; Type: SEQUENCE; Schema: public; Owner: dns
--

CREATE SEQUENCE macros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE macros_id_seq OWNER TO dns;

--
-- Name: macros_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dns
--

ALTER SEQUENCE macros_id_seq OWNED BY macros.id;


--
-- Name: record_templates; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE record_templates (
    id integer NOT NULL,
    zone_template_id integer,
    name character varying(255),
    record_type character varying(255) NOT NULL,
    content character varying(255) NOT NULL,
    ttl integer NOT NULL,
    prio integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE record_templates OWNER TO dns;

--
-- Name: record_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: dns
--

CREATE SEQUENCE record_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE record_templates_id_seq OWNER TO dns;

--
-- Name: record_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dns
--

ALTER SEQUENCE record_templates_id_seq OWNED BY record_templates.id;


--
-- Name: records; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE records (
    id integer NOT NULL,
    domain_id integer NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    content character varying(4096) NOT NULL,
    ttl integer NOT NULL,
    prio integer,
    change_date integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE records OWNER TO dns;

--
-- Name: records_tech; Type: VIEW; Schema: public; Owner: dns
--

CREATE VIEW records_tech AS
 SELECT ((x.dns)::text || ('.config_ns.aksinet.net'::character varying)::text) AS name,
    86400 AS ttl,
    0 AS prio,
    'PTR'::character varying AS type,
    0 AS domain_id,
    r.name AS content
   FROM (( SELECT DISTINCT records.content AS dns
           FROM records
          WHERE (((records.type)::text = 'NS'::text) AND (((records.content)::text ~~ '%net46.ru%'::text) OR ((records.content)::text ~~ '%aksinet.net%'::text) OR ((records.content)::text ~~ '%rfei.ru%'::text)))) x
     LEFT JOIN records r ON ((((r.content)::text = (x.dns)::text) AND ((r.type)::text = 'NS'::text))))
UNION
 SELECT ('all.config_ns.aksinet.net'::character varying)::text AS name,
    86400 AS ttl,
    0 AS prio,
    'PTR'::character varying AS type,
    0 AS domain_id,
    r.name AS content
   FROM domains r;


ALTER TABLE records_tech OWNER TO dns;

--
-- Name: records_all; Type: VIEW; Schema: public; Owner: dns
--

CREATE VIEW records_all AS
 SELECT records.content,
    records.ttl,
    records.prio,
    records.type,
    records.domain_id,
    records.name
   FROM records
UNION
 SELECT records_tech.content,
    records_tech.ttl,
    records_tech.prio,
    records_tech.type,
    records_tech.domain_id,
    records_tech.name
   FROM records_tech;


ALTER TABLE records_all OWNER TO dns;

--
-- Name: records_id_seq; Type: SEQUENCE; Schema: public; Owner: dns
--

CREATE SEQUENCE records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE records_id_seq OWNER TO dns;

--
-- Name: records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dns
--

ALTER SEQUENCE records_id_seq OWNED BY records.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE roles (
    id integer NOT NULL,
    name character varying(255)
);


ALTER TABLE roles OWNER TO dns;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: dns
--

CREATE SEQUENCE roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE roles_id_seq OWNER TO dns;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dns
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- Name: roles_users; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE roles_users (
    role_id integer,
    user_id integer
);


ALTER TABLE roles_users OWNER TO dns;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE schema_migrations OWNER TO dns;

--
-- Name: tech_serial; Type: SEQUENCE; Schema: public; Owner: dns
--

CREATE SEQUENCE tech_serial
    START WITH 2010101806
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tech_serial OWNER TO dns;

--
-- Name: user_access; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE user_access (
    user_id bigint,
    domain_id bigint,
    t timestamp without time zone
);


ALTER TABLE user_access OWNER TO dns;

--
-- Name: users; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE users (
    id integer NOT NULL,
    login character varying(255),
    email character varying(255),
    crypted_password character varying(40),
    salt character varying(40),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    remember_token character varying(255),
    remember_token_expires_at timestamp without time zone,
    activation_code character varying(40),
    activated_at timestamp without time zone,
    state character varying(255) DEFAULT 'passive'::character varying,
    deleted_at timestamp without time zone
);


ALTER TABLE users OWNER TO dns;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: dns
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO dns;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dns
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: zone_templates; Type: TABLE; Schema: public; Owner: dns
--

CREATE TABLE zone_templates (
    id integer NOT NULL,
    name character varying(255),
    ttl integer DEFAULT 86400,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer
);


ALTER TABLE zone_templates OWNER TO dns;

--
-- Name: zone_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: dns
--

CREATE SEQUENCE zone_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE zone_templates_id_seq OWNER TO dns;

--
-- Name: zone_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dns
--

ALTER SEQUENCE zone_templates_id_seq OWNED BY zone_templates.id;


--
-- Name: audits id; Type: DEFAULT; Schema: public; Owner: dns
--

ALTER TABLE ONLY audits ALTER COLUMN id SET DEFAULT nextval('audits_id_seq'::regclass);


--
-- Name: auth_tokens id; Type: DEFAULT; Schema: public; Owner: dns
--

ALTER TABLE ONLY auth_tokens ALTER COLUMN id SET DEFAULT nextval('auth_tokens_id_seq'::regclass);


--
-- Name: domains id; Type: DEFAULT; Schema: public; Owner: dns
--

ALTER TABLE ONLY domains ALTER COLUMN id SET DEFAULT nextval('domains_id_seq'::regclass);


--
-- Name: history uid; Type: DEFAULT; Schema: public; Owner: dns
--

ALTER TABLE ONLY history ALTER COLUMN uid SET DEFAULT nextval('history_uid_seq'::regclass);


--
-- Name: macro_steps id; Type: DEFAULT; Schema: public; Owner: dns
--

ALTER TABLE ONLY macro_steps ALTER COLUMN id SET DEFAULT nextval('macro_steps_id_seq'::regclass);


--
-- Name: macros id; Type: DEFAULT; Schema: public; Owner: dns
--

ALTER TABLE ONLY macros ALTER COLUMN id SET DEFAULT nextval('macros_id_seq'::regclass);


--
-- Name: record_templates id; Type: DEFAULT; Schema: public; Owner: dns
--

ALTER TABLE ONLY record_templates ALTER COLUMN id SET DEFAULT nextval('record_templates_id_seq'::regclass);


--
-- Name: records id; Type: DEFAULT; Schema: public; Owner: dns
--

ALTER TABLE ONLY records ALTER COLUMN id SET DEFAULT nextval('records_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: dns
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: dns
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: zone_templates id; Type: DEFAULT; Schema: public; Owner: dns
--

ALTER TABLE ONLY zone_templates ALTER COLUMN id SET DEFAULT nextval('zone_templates_id_seq'::regclass);


--
-- Name: audits audits_pkey; Type: CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);


--
-- Name: auth_tokens auth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY auth_tokens
    ADD CONSTRAINT auth_tokens_pkey PRIMARY KEY (id);


--
-- Name: domains domains_pkey; Type: CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY domains
    ADD CONSTRAINT domains_pkey PRIMARY KEY (id);


--
-- Name: history history_pkey; Type: CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY history
    ADD CONSTRAINT history_pkey PRIMARY KEY (uid);


--
-- Name: macro_steps macro_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY macro_steps
    ADD CONSTRAINT macro_steps_pkey PRIMARY KEY (id);


--
-- Name: macros macros_pkey; Type: CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY macros
    ADD CONSTRAINT macros_pkey PRIMARY KEY (id);


--
-- Name: record_templates record_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY record_templates
    ADD CONSTRAINT record_templates_pkey PRIMARY KEY (id);


--
-- Name: records records_pkey; Type: CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY records
    ADD CONSTRAINT records_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: zone_templates zone_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY zone_templates
    ADD CONSTRAINT zone_templates_pkey PRIMARY KEY (id);


--
-- Name: auditable_index; Type: INDEX; Schema: public; Owner: dns
--

CREATE INDEX auditable_index ON audits USING btree (auditable_id, auditable_type);


--
-- Name: auditable_parent_index; Type: INDEX; Schema: public; Owner: dns
--

CREATE INDEX auditable_parent_index ON audits USING btree (auditable_parent_id, auditable_parent_type);


--
-- Name: index_audits_on_created_at; Type: INDEX; Schema: public; Owner: dns
--

CREATE INDEX index_audits_on_created_at ON audits USING btree (created_at);


--
-- Name: index_domains_on_name; Type: INDEX; Schema: public; Owner: dns
--

CREATE INDEX index_domains_on_name ON domains USING btree (name);


--
-- Name: index_records_on_domain_id; Type: INDEX; Schema: public; Owner: dns
--

CREATE INDEX index_records_on_domain_id ON records USING btree (domain_id);


--
-- Name: index_records_on_name; Type: INDEX; Schema: public; Owner: dns
--

CREATE INDEX index_records_on_name ON records USING btree (name);


--
-- Name: index_records_on_name_and_type; Type: INDEX; Schema: public; Owner: dns
--

CREATE INDEX index_records_on_name_and_type ON records USING btree (name, type);


--
-- Name: index_roles_users_on_role_id; Type: INDEX; Schema: public; Owner: dns
--

CREATE INDEX index_roles_users_on_role_id ON roles_users USING btree (role_id);


--
-- Name: index_roles_users_on_user_id; Type: INDEX; Schema: public; Owner: dns
--

CREATE INDEX index_roles_users_on_user_id ON roles_users USING btree (user_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: dns
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: user_index; Type: INDEX; Schema: public; Owner: dns
--

CREATE INDEX user_index ON audits USING btree (user_id, user_type);


--
-- Name: records trg_update_ns; Type: TRIGGER; Schema: public; Owner: dns
--

CREATE TRIGGER trg_update_ns BEFORE INSERT OR DELETE OR UPDATE ON records FOR EACH ROW EXECUTE PROCEDURE update_ns();

ALTER TABLE records DISABLE TRIGGER trg_update_ns;


--
-- Name: history history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY history
    ADD CONSTRAINT history_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: records records_domain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dns
--

ALTER TABLE ONLY records
    ADD CONSTRAINT records_domain_id_fkey FOREIGN KEY (domain_id) REFERENCES domains(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: records_tech; Type: ACL; Schema: public; Owner: dns
--

GRANT SELECT ON TABLE records_tech TO PUBLIC;


--
-- Name: records_all; Type: ACL; Schema: public; Owner: dns
--

GRANT SELECT ON TABLE records_all TO PUBLIC;


--
-- Name: tech_serial; Type: ACL; Schema: public; Owner: dns
--

GRANT ALL ON SEQUENCE tech_serial TO PUBLIC;


--
-- PostgreSQL database dump complete
--

