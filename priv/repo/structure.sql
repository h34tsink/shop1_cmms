--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

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
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: asset_criticality; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.asset_criticality AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);


--
-- Name: asset_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.asset_status AS ENUM (
    'operational',
    'maintenance',
    'repair',
    'retired',
    'disposed'
);


--
-- Name: document_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.document_type AS ENUM (
    'manual',
    'drawing',
    'specification',
    'procedure',
    'work_instruction',
    'certificate',
    'calibration',
    'warranty',
    'other'
);


--
-- Name: pm_frequency; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.pm_frequency AS ENUM (
    'daily',
    'weekly',
    'biweekly',
    'monthly',
    'quarterly',
    'semiannual',
    'annual',
    'biennial',
    'meter_based',
    'condition_based'
);


--
-- Name: work_order_priority; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.work_order_priority AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);


--
-- Name: work_order_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.work_order_status AS ENUM (
    'open',
    'assigned',
    'in_progress',
    'on_hold',
    'completed',
    'cancelled'
);


--
-- Name: work_order_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.work_order_type AS ENUM (
    'corrective',
    'preventive',
    'emergency',
    'project'
);


--
-- Name: get_customer_attribute_value(integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_customer_attribute_value(p_customer_id integer, p_attribute_key character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    attr_def customer_attribute_definitions%ROWTYPE;
    attr_val customer_attributes%ROWTYPE;
    result TEXT;
BEGIN
    -- Get attribute definition
    SELECT * INTO attr_def 
    FROM customer_attribute_definitions 
    WHERE attribute_key = p_attribute_key AND is_active = TRUE;
    
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    
    -- Get attribute value
    SELECT * INTO attr_val 
    FROM customer_attributes 
    WHERE customer_id = p_customer_id AND attribute_id = attr_def.id;
    
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    
    -- Return typed value
    CASE attr_def.attribute_type
        WHEN 'string' THEN result := attr_val.string_value;
        WHEN 'integer' THEN result := attr_val.integer_value::TEXT;
        WHEN 'decimal' THEN result := attr_val.decimal_value::TEXT;
        WHEN 'boolean' THEN result := attr_val.boolean_value::TEXT;
        WHEN 'date' THEN result := attr_val.date_value::TEXT;
        WHEN 'text' THEN result := attr_val.text_value;
        WHEN 'json' THEN result := attr_val.json_value::TEXT;
        ELSE result := NULL;
    END CASE;
    
    RETURN result;
END;
$$;


--
-- Name: validate_customer_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_customer_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
BEGIN
    -- Ensure customer name is provided
    IF NEW.name IS NULL OR TRIM(NEW.name) = '' THEN
        RAISE EXCEPTION 'Customer name is required';
    END IF;
    
    -- Validate customer number format (6 digits)
    IF NEW.customer_number !~ '^[0-9]{6}$' THEN
        RAISE EXCEPTION 'Customer number must be exactly 6 digits';
    END IF;
    
    -- Set defaults based on status
    IF NEW.status = 'P' THEN -- Prospect
        NEW.default_apqp_level := COALESCE(NEW.default_apqp_level, 2);
        NEW.promise_date_req := COALESCE(NEW.promise_date_req, TRUE);
    END IF;
    
    -- Update modified timestamp
    NEW.modified_date := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: asset_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_documents (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    file_path character varying(255) NOT NULL,
    file_size integer,
    file_type character varying(255),
    document_type character varying(255) NOT NULL,
    uploaded_by bigint,
    asset_id uuid NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    document_number character varying(255),
    title character varying(255),
    file_name character varying(255),
    mime_type character varying(255),
    file_url character varying(255),
    version character varying(255),
    revision_date date,
    expiry_date date,
    issued_by character varying(255),
    approved_by character varying(255),
    tags character varying(255)[] DEFAULT ARRAY[]::character varying[],
    is_active boolean DEFAULT true,
    pm_schedule_id uuid,
    work_order_id uuid
);


--
-- Name: asset_location_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_location_types (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    code character varying(255) NOT NULL,
    icon character varying(255),
    color character varying(255),
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: asset_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_locations (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    code character varying(255) NOT NULL,
    address text,
    gps_coordinates character varying(255),
    area_size numeric(10,2),
    area_unit character varying(255) DEFAULT 'sqft'::character varying,
    parent_location_id uuid,
    location_type_id uuid NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: asset_meters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_meters (
    id uuid NOT NULL,
    current_reading numeric(12,2) DEFAULT 0.0 NOT NULL,
    last_reading_date timestamp(0) without time zone,
    reading_frequency integer,
    next_reading_due date,
    is_active boolean DEFAULT true NOT NULL,
    asset_id uuid NOT NULL,
    meter_type_id uuid NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: asset_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_types (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    code character varying(255) NOT NULL,
    category character varying(255) NOT NULL,
    icon character varying(255),
    color character varying(255),
    has_meters boolean DEFAULT false NOT NULL,
    has_components boolean DEFAULT false NOT NULL,
    default_pm_frequency integer,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assets (
    id uuid NOT NULL,
    asset_number character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    manufacturer character varying(255),
    model character varying(255),
    serial_number character varying(255),
    barcode character varying(255),
    qr_code character varying(255),
    purchase_date date,
    purchase_cost numeric(12,2),
    warranty_expiry date,
    install_date date,
    commission_date date,
    status public.asset_status DEFAULT 'operational'::public.asset_status NOT NULL,
    criticality public.asset_criticality DEFAULT 'medium'::public.asset_criticality NOT NULL,
    specifications jsonb,
    notes text,
    parent_asset_id uuid,
    location_id uuid,
    asset_type_id uuid NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    user_id integer,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    action_type text NOT NULL,
    entity_type text NOT NULL,
    entity_id integer,
    field_changed text,
    old_value text,
    new_value text,
    ip_address text
);


--
-- Name: TABLE audit_logs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.audit_logs IS 'Security-critical audit trail for compliance';


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: cmms_user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cmms_user_roles (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    display_name character varying(255) NOT NULL,
    description text,
    permissions text[] DEFAULT '{}'::text[],
    is_system_role boolean DEFAULT false,
    is_active boolean DEFAULT true,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: cmms_user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cmms_user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cmms_user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cmms_user_roles_id_seq OWNED BY public.cmms_user_roles.id;


--
-- Name: components; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.components (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    component_type character varying(255),
    manufacturer character varying(255),
    model character varying(255),
    serial_number character varying(255),
    install_date date,
    status character varying(255) DEFAULT 'active'::character varying NOT NULL,
    asset_id uuid NOT NULL,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacts (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    name text NOT NULL,
    "position" text,
    phone text,
    email text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE contacts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.contacts IS 'People at customer companies';


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contacts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: custom_field_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_field_values (
    id uuid NOT NULL,
    custom_field_id uuid NOT NULL,
    entity_type character varying(255) NOT NULL,
    entity_id uuid NOT NULL,
    field_value text,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: custom_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_fields (
    id uuid NOT NULL,
    entity_type character varying(255) NOT NULL,
    field_name character varying(255) NOT NULL,
    field_label character varying(255) NOT NULL,
    field_type character varying(255) NOT NULL,
    field_options jsonb,
    default_value text,
    is_required boolean DEFAULT false,
    validation_rules jsonb,
    display_order integer DEFAULT 0,
    help_text text,
    is_active boolean DEFAULT true NOT NULL,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: customer_attribute_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_attribute_definitions (
    id integer NOT NULL,
    attribute_key character varying(50) NOT NULL,
    attribute_name character varying(100) NOT NULL,
    attribute_type character varying(20) NOT NULL,
    max_length integer,
    min_value numeric(15,4),
    max_value numeric(15,4),
    allowed_values text,
    is_required boolean DEFAULT false,
    display_order integer DEFAULT 0,
    group_name character varying(50),
    description text,
    help_text text,
    is_active boolean DEFAULT true,
    created_by character varying(20),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    modified_by character varying(20),
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_attribute_type CHECK (((attribute_type)::text = ANY ((ARRAY['string'::character varying, 'integer'::character varying, 'decimal'::character varying, 'boolean'::character varying, 'date'::character varying, 'text'::character varying, 'json'::character varying])::text[])))
);


--
-- Name: customer_attribute_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_attribute_definitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_attribute_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_attribute_definitions_id_seq OWNED BY public.customer_attribute_definitions.id;


--
-- Name: customer_attribute_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_attribute_history (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    attribute_id integer NOT NULL,
    old_string_value character varying(255),
    old_integer_value integer,
    old_decimal_value numeric(15,4),
    old_boolean_value boolean,
    old_date_value date,
    old_text_value text,
    old_json_value jsonb,
    new_string_value character varying(255),
    new_integer_value integer,
    new_decimal_value numeric(15,4),
    new_boolean_value boolean,
    new_date_value date,
    new_text_value text,
    new_json_value jsonb,
    change_type character varying(10),
    changed_by character varying(20),
    changed_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: customer_attribute_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_attribute_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_attribute_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_attribute_history_id_seq OWNED BY public.customer_attribute_history.id;


--
-- Name: customer_attributes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_attributes (
    id integer NOT NULL,
    customer_id integer,
    attribute_id integer,
    string_value character varying(255),
    integer_value integer,
    decimal_value numeric(15,4),
    boolean_value boolean,
    date_value date,
    text_value text,
    "json_value" jsonb,
    created_by character varying(20),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    modified_by character varying(20),
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE customer_attributes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.customer_attributes IS 'EAV system for flexible custom customer fields';


--
-- Name: customer_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_attributes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_attributes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_attributes_id_seq OWNED BY public.customer_attributes.id;


--
-- Name: customer_billing_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_billing_addresses (
    id integer NOT NULL,
    customer_id integer,
    name character varying(30),
    address_line_1 character varying(30),
    address_line_2 character varying(30),
    city character varying(20),
    state character varying(8),
    zip_code character varying(10),
    is_active boolean DEFAULT true,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: customer_billing_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_billing_addresses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_billing_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_billing_addresses_id_seq OWNED BY public.customer_billing_addresses.id;


--
-- Name: customer_contact_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_contact_log (
    id integer NOT NULL,
    customer_id integer,
    contact_date date,
    made_by character varying(20),
    contact_person character varying(20),
    subject character varying(20),
    notes text,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: customer_contact_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_contact_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_contact_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_contact_log_id_seq OWNED BY public.customer_contact_log.id;


--
-- Name: customer_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_contacts (
    id integer NOT NULL,
    customer_id integer,
    first_name character varying(30),
    last_name character varying(30),
    "position" character varying(25),
    phone character varying(14),
    extension character varying(4),
    email character varying(60),
    receives_ready_notice boolean DEFAULT false,
    is_primary boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: customer_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_contacts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_contacts_id_seq OWNED BY public.customer_contacts.id;


--
-- Name: customer_parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_parts (
    id integer NOT NULL,
    customer_id integer,
    part_number character varying(15) NOT NULL,
    part_description character varying(15),
    process_description character varying(60),
    process_code character varying(22),
    process_code_2 character varying(22),
    process_code_3 character varying(22),
    alloy character varying(8),
    temper character varying(6),
    revision character varying(6),
    last_run_date date,
    is_active boolean DEFAULT true,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE customer_parts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.customer_parts IS 'Customer-specific parts with process codes and specifications';


--
-- Name: customer_parts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_parts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_parts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_parts_id_seq OWNED BY public.customer_parts.id;


--
-- Name: customer_pricing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_pricing (
    id integer NOT NULL,
    customer_id integer,
    part_number character varying(15) NOT NULL,
    part_description character varying(15),
    process_description character varying(40),
    unit_price numeric(14,4),
    sub_account_1 character varying(4),
    sub_price_1 numeric(14,4),
    sub_account_2 character varying(4),
    sub_price_2 numeric(14,4),
    sub_account_3 character varying(4),
    sub_price_3 numeric(14,4),
    sub_account_4 character varying(4),
    sub_price_4 numeric(14,4),
    sub_account_5 character varying(4),
    sub_price_5 numeric(14,4),
    sub_account_6 character varying(4),
    sub_price_6 numeric(14,4),
    activity_code character varying(4),
    created_date date,
    changed_date date,
    last_referenced date,
    is_active boolean DEFAULT true
);


--
-- Name: TABLE customer_pricing; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.customer_pricing IS 'Multi-level pricing structure for customer parts';


--
-- Name: customer_pricing_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_pricing_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_pricing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_pricing_id_seq OWNED BY public.customer_pricing.id;


--
-- Name: customer_quality_metrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_quality_metrics (
    id integer NOT NULL,
    customer_id integer,
    year integer,
    month integer,
    processed_quantity integer DEFAULT 0,
    damaged_quantity integer DEFAULT 0,
    ppm_value numeric(10,2),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE customer_quality_metrics; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.customer_quality_metrics IS 'PPM defect tracking and quality metrics';


--
-- Name: customer_quality_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_quality_metrics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_quality_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_quality_metrics_id_seq OWNED BY public.customer_quality_metrics.id;


--
-- Name: customer_red_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_red_flags (
    id integer NOT NULL,
    customer_id integer,
    is_red_flagged boolean DEFAULT false,
    flag_date date,
    flag_notes text,
    created_by character varying(20),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: customer_red_flags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_red_flags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_red_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_red_flags_id_seq OWNED BY public.customer_red_flags.id;


--
-- Name: customer_shipping_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_shipping_addresses (
    id integer NOT NULL,
    customer_id integer,
    name character varying(30),
    address_line_1 character varying(30),
    address_line_2 character varying(30),
    city character varying(20),
    state character varying(8),
    zip_code character varying(10),
    preferred_carrier character varying(20),
    carrier_account character varying(25),
    is_default boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: customer_shipping_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_shipping_addresses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_shipping_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_shipping_addresses_id_seq OWNED BY public.customer_shipping_addresses.id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
    id integer NOT NULL,
    customer_number character varying(6) NOT NULL,
    name character varying(30) NOT NULL,
    address_line_1 character varying(30),
    address_line_2 character varying(30),
    city character varying(20),
    state character varying(8),
    zip_code character varying(11),
    contact_person character varying(20),
    phone character varying(18),
    fax_number character varying(18),
    website character varying(80),
    terms character varying(10),
    sales_rep character varying(20),
    industry_group character varying(10),
    status character varying(1) DEFAULT 'P'::character varying NOT NULL,
    po_required boolean DEFAULT false,
    no_minimum_charge boolean DEFAULT false,
    no_cert_charge boolean DEFAULT false,
    minimum_charge numeric(10,2) DEFAULT 0.00,
    email_ready_notice boolean DEFAULT false,
    serial_numbers_req boolean DEFAULT false,
    template_only boolean DEFAULT false,
    lot_number_req boolean DEFAULT false,
    cert_required boolean DEFAULT false,
    detailed_job_list boolean DEFAULT false,
    full_shipper boolean DEFAULT false,
    order_hide_nc boolean DEFAULT false,
    promise_date_req boolean DEFAULT false,
    no_certs boolean DEFAULT false,
    no_quantity_labels boolean DEFAULT false,
    generate_schedule_cards boolean DEFAULT false,
    ffl_number character varying(20),
    ffl_expiration date,
    default_apqp_level integer DEFAULT 2,
    turnaround_agreement text,
    fax_order_ready boolean DEFAULT false,
    fax_contact character varying(25),
    email_invoice_to character varying(40),
    created_date date DEFAULT CURRENT_DATE,
    last_activity date,
    last_paid_date date,
    created_by character varying(20),
    modified_by character varying(20),
    modified_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_apqp_level CHECK (((default_apqp_level >= 1) AND (default_apqp_level <= 3))),
    CONSTRAINT chk_customer_status CHECK (((status)::text = ANY ((ARRAY['C'::character varying, 'P'::character varying, 'I'::character varying, 'D'::character varying, 'S'::character varying])::text[])))
);


--
-- Name: TABLE customers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.customers IS 'Main customer information table with comprehensive business data';


--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customers_id_seq OWNED BY public.customers.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255),
    description text,
    manager_name character varying(255),
    manager_email character varying(255),
    cost_center character varying(255),
    budget_code character varying(255),
    parent_department_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: entity_properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entity_properties (
    id integer NOT NULL,
    entity_type text NOT NULL,
    entity_id integer NOT NULL,
    name text NOT NULL,
    value text,
    value_type text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE entity_properties; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.entity_properties IS 'Flexible key-value properties for any entity (EAV pattern)';


--
-- Name: entity_properties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.entity_properties_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entity_properties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.entity_properties_id_seq OWNED BY public.entity_properties.id;


--
-- Name: event_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_logs (
    id integer NOT NULL,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    user_id integer,
    event_type text NOT NULL,
    source text,
    message text,
    reference_id integer,
    data_json jsonb
);


--
-- Name: TABLE event_logs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.event_logs IS 'General system event logging';


--
-- Name: event_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.event_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.event_logs_id_seq OWNED BY public.event_logs.id;


--
-- Name: job_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_cards (
    id integer NOT NULL,
    order_id integer NOT NULL,
    customer_name text,
    part_desc text,
    current_dept text,
    status text,
    color_code text,
    locked_by integer,
    last_moved timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE job_cards; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.job_cards IS 'Shop floor production tracking cards';


--
-- Name: job_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.job_cards_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.job_cards_id_seq OWNED BY public.job_cards.id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    address_line_1 character varying(255),
    address_line_2 character varying(255),
    city character varying(100),
    state character varying(10),
    zip_code character varying(20),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.locations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.locations_id_seq OWNED BY public.locations.id;


--
-- Name: maintenance_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_categories (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255),
    description text,
    type character varying(255) NOT NULL,
    default_frequency_days integer,
    requires_shutdown boolean DEFAULT false,
    skill_requirements text,
    safety_requirements text,
    parent_category_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: manufacturers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.manufacturers (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255),
    description text,
    website character varying(255),
    contact_email character varying(255),
    contact_phone character varying(255),
    address text,
    notes text,
    is_active boolean DEFAULT true NOT NULL,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: meter_readings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meter_readings (
    id uuid NOT NULL,
    reading numeric(12,2) NOT NULL,
    reading_date timestamp(0) without time zone NOT NULL,
    reading_type character varying(255) DEFAULT 'manual'::character varying NOT NULL,
    notes text,
    recorded_by bigint,
    asset_meter_id uuid NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: meter_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meter_types (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    unit character varying(255) NOT NULL,
    data_type character varying(255) DEFAULT 'integer'::character varying NOT NULL,
    is_cumulative boolean DEFAULT true NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    part_id integer NOT NULL,
    po_number text,
    lot text,
    release text,
    process text,
    quantity integer,
    notes text,
    created_by integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE orders; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.orders IS 'Production orders for specific parts';


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parts (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    pn text NOT NULL,
    description text,
    process text,
    last_run_date date,
    disabled boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE parts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.parts IS 'Items manufactured for customers';


--
-- Name: parts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parts_id_seq OWNED BY public.parts.id;


--
-- Name: pm_checklist_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pm_checklist_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sequence integer NOT NULL,
    item_description text NOT NULL,
    expected_result text,
    pass_fail boolean DEFAULT false,
    requires_measurement boolean DEFAULT false,
    measurement_unit character varying(255),
    min_value numeric(12,4),
    max_value numeric(12,4),
    pm_schedule_id uuid NOT NULL,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: pm_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pm_executions (
    id uuid NOT NULL,
    execution_number character varying(255) NOT NULL,
    execution_date timestamp(0) without time zone NOT NULL,
    completed_date timestamp(0) without time zone,
    status character varying(255) DEFAULT 'in_progress'::character varying NOT NULL,
    pm_schedule_id uuid NOT NULL,
    work_order_id uuid,
    completed_by_user_id bigint,
    asset_id uuid NOT NULL,
    component_id uuid,
    step_results jsonb DEFAULT '[]'::jsonb,
    tech_notes text,
    parts_used jsonb DEFAULT '[]'::jsonb,
    actual_duration_minutes integer,
    meter_reading numeric,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: pm_schedule_components; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pm_schedule_components (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    component_name character varying(255) NOT NULL,
    component_description text,
    component_location character varying(255),
    pm_schedule_id uuid NOT NULL,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: pm_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pm_schedules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    schedule_number character varying(255) NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    frequency public.pm_frequency NOT NULL,
    frequency_interval integer DEFAULT 1,
    meter_threshold numeric(12,2),
    meter_unit character varying(255),
    work_instructions text,
    estimated_duration numeric(8,2),
    required_skills character varying(255)[] DEFAULT ARRAY[]::character varying[],
    required_tools character varying(255)[] DEFAULT ARRAY[]::character varying[],
    required_parts jsonb DEFAULT '[]'::jsonb,
    safety_notes text,
    ppe_required character varying(255)[] DEFAULT ARRAY[]::character varying[],
    last_completed_date timestamp(0) without time zone,
    next_due_date timestamp(0) without time zone,
    is_active boolean DEFAULT true,
    asset_id uuid NOT NULL,
    created_by integer,
    updated_by integer,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    instruction_steps jsonb DEFAULT '[]'::jsonb,
    total_completions integer DEFAULT 0,
    on_time_completions integer DEFAULT 0,
    completion_rate numeric(5,2),
    component_id uuid
);


--
-- Name: priority_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.priority_codes (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255),
    description text,
    level integer NOT NULL,
    color character varying(255),
    sla_hours integer,
    auto_escalate boolean DEFAULT false,
    escalation_hours integer,
    is_active boolean DEFAULT true NOT NULL,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    permissions text[] DEFAULT '{}'::text[] NOT NULL
);


--
-- Name: TABLE roles; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.roles IS 'User roles with array-based permissions system';


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    profile_id integer,
    session_token text NOT NULL,
    refresh_token text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    refresh_expires_at timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL,
    revoked_at timestamp with time zone,
    revoked_by integer,
    revocation_reason text,
    ip_address inet,
    user_agent text,
    client_info jsonb DEFAULT '{}'::jsonb,
    last_activity timestamp with time zone DEFAULT now(),
    activity_count integer DEFAULT 1,
    mfa_verified boolean DEFAULT false,
    mfa_verified_at timestamp with time zone,
    security_flags jsonb DEFAULT '{}'::jsonb
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sessions IS 'User session management with security features';


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: shifts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shifts (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    days_of_week integer[],
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: shifts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shifts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shifts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shifts_id_seq OWNED BY public.shifts.id;


--
-- Name: sites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sites (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    display_name character varying(255),
    description text,
    address text,
    phone character varying(255),
    email character varying(255),
    timezone character varying(255),
    is_active boolean DEFAULT true,
    settings jsonb DEFAULT '{}'::jsonb,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    code character varying(255)
);


--
-- Name: sites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sites_id_seq OWNED BY public.sites.id;


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255),
    description text,
    type character varying(255),
    contact_name character varying(255),
    contact_email character varying(255),
    contact_phone character varying(255),
    address text,
    website character varying(255),
    tax_id character varying(255),
    payment_terms character varying(255),
    credit_rating character varying(255),
    notes text,
    is_active boolean DEFAULT true NOT NULL,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: sync_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sync_queue (
    id integer NOT NULL,
    entity_type text NOT NULL,
    entity_id integer NOT NULL,
    payload_json jsonb NOT NULL,
    attempts integer DEFAULT 0,
    last_attempt timestamp with time zone,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE sync_queue; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sync_queue IS 'Background processing queue for async operations';


--
-- Name: sync_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sync_queue_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sync_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sync_queue_id_seq OWNED BY public.sync_queue.id;


--
-- Name: tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    display_name character varying(255),
    description text,
    address text,
    phone character varying(255),
    email character varying(255),
    website character varying(255),
    timezone character varying(255) DEFAULT 'America/Chicago'::character varying,
    is_active boolean DEFAULT true,
    settings jsonb DEFAULT '{}'::jsonb,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    code character varying(255)
);


--
-- Name: tenants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenants_id_seq OWNED BY public.tenants.id;


--
-- Name: user_profile_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_profile_assignments (
    id integer NOT NULL,
    user_id integer NOT NULL,
    profile_id integer NOT NULL,
    is_primary boolean DEFAULT false,
    is_active boolean DEFAULT true,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL,
    assigned_by integer,
    expires_at timestamp with time zone,
    revoked_at timestamp with time zone,
    revoked_by integer,
    revocation_reason text,
    notes text
);


--
-- Name: TABLE user_profile_assignments; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_profile_assignments IS 'Many-to-many junction table for user-profile relationships';


--
-- Name: user_profile_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_profile_assignments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profile_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_profile_assignments_id_seq OWNED BY public.user_profile_assignments.id;


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_profiles (
    id integer NOT NULL,
    profile_name character varying(100) NOT NULL,
    profile_type character varying(50) DEFAULT 'individual'::character varying,
    display_name character varying(150),
    avatar_url text,
    job_title character varying(100),
    department character varying(100),
    location character varying(100),
    manager_id integer,
    hire_date date,
    employee_id character varying(50),
    phone_ext character varying(10),
    emergency_contact_name character varying(150),
    emergency_contact_phone character varying(20),
    bio text,
    preferences jsonb DEFAULT '{}'::jsonb,
    timezone character varying(50) DEFAULT 'America/Chicago'::character varying,
    date_format character varying(20) DEFAULT 'MM/dd/yyyy'::character varying,
    time_format character varying(10) DEFAULT '12h'::character varying,
    language character varying(10) DEFAULT 'en'::character varying,
    theme character varying(20) DEFAULT 'light'::character varying,
    notifications_enabled boolean DEFAULT true,
    email_notifications boolean DEFAULT true,
    is_active boolean DEFAULT true,
    is_template boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by integer,
    modified_by integer
);


--
-- Name: TABLE user_profiles; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_profiles IS 'Extended user profiles (can be shared by multiple users)';


--
-- Name: user_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_profiles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_profiles_id_seq OWNED BY public.user_profiles.id;


--
-- Name: user_tenant_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_tenant_assignments (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    role_id bigint NOT NULL,
    default_site_id bigint,
    assigned_by_id bigint,
    assigned_at timestamp without time zone NOT NULL,
    is_active boolean DEFAULT true,
    notes text,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_tenant_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_tenant_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_tenant_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_tenant_assignments_id_seq OWNED BY public.user_tenant_assignments.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    username character varying(255) NOT NULL,
    password_hash character varying(255),
    is_active boolean DEFAULT true NOT NULL,
    inserted_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    cmms_enabled boolean DEFAULT false,
    last_cmms_login timestamp without time zone,
    preferences jsonb DEFAULT '{}'::jsonb,
    role_id integer,
    last_login timestamp with time zone,
    failed_logins integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone
);


--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.users IS 'System users with authentication and profile information';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: work_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    work_order_number character varying(255) NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    status public.work_order_status DEFAULT 'open'::public.work_order_status NOT NULL,
    priority public.work_order_priority DEFAULT 'medium'::public.work_order_priority NOT NULL,
    type public.work_order_type DEFAULT 'corrective'::public.work_order_type NOT NULL,
    requested_date timestamp(0) without time zone NOT NULL,
    scheduled_start_date timestamp(0) without time zone,
    scheduled_end_date timestamp(0) without time zone,
    actual_start_date timestamp(0) without time zone,
    actual_end_date timestamp(0) without time zone,
    due_date timestamp(0) without time zone,
    requested_by integer,
    assigned_to integer,
    created_by integer,
    updated_by integer,
    asset_id uuid,
    location_description character varying(255),
    estimated_hours numeric(8,2),
    actual_hours numeric(8,2),
    estimated_cost numeric(12,2),
    actual_cost numeric(12,2),
    completion_notes text,
    work_performed text,
    failure_reason text,
    parts_used jsonb,
    safety_notes text,
    attachments jsonb,
    tenant_id integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: cmms_user_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmms_user_roles ALTER COLUMN id SET DEFAULT nextval('public.cmms_user_roles_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: customer_attribute_definitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_attribute_definitions ALTER COLUMN id SET DEFAULT nextval('public.customer_attribute_definitions_id_seq'::regclass);


--
-- Name: customer_attribute_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_attribute_history ALTER COLUMN id SET DEFAULT nextval('public.customer_attribute_history_id_seq'::regclass);


--
-- Name: customer_attributes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_attributes ALTER COLUMN id SET DEFAULT nextval('public.customer_attributes_id_seq'::regclass);


--
-- Name: customer_billing_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_billing_addresses ALTER COLUMN id SET DEFAULT nextval('public.customer_billing_addresses_id_seq'::regclass);


--
-- Name: customer_contact_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_contact_log ALTER COLUMN id SET DEFAULT nextval('public.customer_contact_log_id_seq'::regclass);


--
-- Name: customer_contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_contacts ALTER COLUMN id SET DEFAULT nextval('public.customer_contacts_id_seq'::regclass);


--
-- Name: customer_parts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_parts ALTER COLUMN id SET DEFAULT nextval('public.customer_parts_id_seq'::regclass);


--
-- Name: customer_pricing id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_pricing ALTER COLUMN id SET DEFAULT nextval('public.customer_pricing_id_seq'::regclass);


--
-- Name: customer_quality_metrics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_quality_metrics ALTER COLUMN id SET DEFAULT nextval('public.customer_quality_metrics_id_seq'::regclass);


--
-- Name: customer_red_flags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_red_flags ALTER COLUMN id SET DEFAULT nextval('public.customer_red_flags_id_seq'::regclass);


--
-- Name: customer_shipping_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_shipping_addresses ALTER COLUMN id SET DEFAULT nextval('public.customer_shipping_addresses_id_seq'::regclass);


--
-- Name: customers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers ALTER COLUMN id SET DEFAULT nextval('public.customers_id_seq'::regclass);


--
-- Name: entity_properties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_properties ALTER COLUMN id SET DEFAULT nextval('public.entity_properties_id_seq'::regclass);


--
-- Name: event_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_logs ALTER COLUMN id SET DEFAULT nextval('public.event_logs_id_seq'::regclass);


--
-- Name: job_cards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_cards ALTER COLUMN id SET DEFAULT nextval('public.job_cards_id_seq'::regclass);


--
-- Name: locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations ALTER COLUMN id SET DEFAULT nextval('public.locations_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: parts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parts ALTER COLUMN id SET DEFAULT nextval('public.parts_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: shifts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shifts ALTER COLUMN id SET DEFAULT nextval('public.shifts_id_seq'::regclass);


--
-- Name: sites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites ALTER COLUMN id SET DEFAULT nextval('public.sites_id_seq'::regclass);


--
-- Name: sync_queue id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_queue ALTER COLUMN id SET DEFAULT nextval('public.sync_queue_id_seq'::regclass);


--
-- Name: tenants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants ALTER COLUMN id SET DEFAULT nextval('public.tenants_id_seq'::regclass);


--
-- Name: user_profile_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profile_assignments ALTER COLUMN id SET DEFAULT nextval('public.user_profile_assignments_id_seq'::regclass);


--
-- Name: user_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles ALTER COLUMN id SET DEFAULT nextval('public.user_profiles_id_seq'::regclass);


--
-- Name: user_tenant_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tenant_assignments ALTER COLUMN id SET DEFAULT nextval('public.user_tenant_assignments_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: asset_documents asset_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_documents
    ADD CONSTRAINT asset_documents_pkey PRIMARY KEY (id);


--
-- Name: asset_location_types asset_location_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_location_types
    ADD CONSTRAINT asset_location_types_pkey PRIMARY KEY (id);


--
-- Name: asset_locations asset_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_locations
    ADD CONSTRAINT asset_locations_pkey PRIMARY KEY (id);


--
-- Name: asset_meters asset_meters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_meters
    ADD CONSTRAINT asset_meters_pkey PRIMARY KEY (id);


--
-- Name: asset_types asset_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_types
    ADD CONSTRAINT asset_types_pkey PRIMARY KEY (id);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: cmms_user_roles cmms_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmms_user_roles
    ADD CONSTRAINT cmms_user_roles_pkey PRIMARY KEY (id);


--
-- Name: components components_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.components
    ADD CONSTRAINT components_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: custom_field_values custom_field_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_values
    ADD CONSTRAINT custom_field_values_pkey PRIMARY KEY (id);


--
-- Name: custom_fields custom_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_fields
    ADD CONSTRAINT custom_fields_pkey PRIMARY KEY (id);


--
-- Name: customer_attribute_definitions customer_attribute_definitions_attribute_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_attribute_definitions
    ADD CONSTRAINT customer_attribute_definitions_attribute_key_key UNIQUE (attribute_key);


--
-- Name: customer_attribute_definitions customer_attribute_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_attribute_definitions
    ADD CONSTRAINT customer_attribute_definitions_pkey PRIMARY KEY (id);


--
-- Name: customer_attribute_history customer_attribute_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_attribute_history
    ADD CONSTRAINT customer_attribute_history_pkey PRIMARY KEY (id);


--
-- Name: customer_attributes customer_attributes_customer_id_attribute_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_attributes
    ADD CONSTRAINT customer_attributes_customer_id_attribute_id_key UNIQUE (customer_id, attribute_id);


--
-- Name: customer_attributes customer_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_attributes
    ADD CONSTRAINT customer_attributes_pkey PRIMARY KEY (id);


--
-- Name: customer_billing_addresses customer_billing_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_billing_addresses
    ADD CONSTRAINT customer_billing_addresses_pkey PRIMARY KEY (id);


--
-- Name: customer_contact_log customer_contact_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_contact_log
    ADD CONSTRAINT customer_contact_log_pkey PRIMARY KEY (id);


--
-- Name: customer_contacts customer_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_contacts
    ADD CONSTRAINT customer_contacts_pkey PRIMARY KEY (id);


--
-- Name: customer_parts customer_parts_customer_id_part_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_parts
    ADD CONSTRAINT customer_parts_customer_id_part_number_key UNIQUE (customer_id, part_number);


--
-- Name: customer_parts customer_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_parts
    ADD CONSTRAINT customer_parts_pkey PRIMARY KEY (id);


--
-- Name: customer_pricing customer_pricing_customer_id_part_number_activity_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_pricing
    ADD CONSTRAINT customer_pricing_customer_id_part_number_activity_code_key UNIQUE (customer_id, part_number, activity_code);


--
-- Name: customer_pricing customer_pricing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_pricing
    ADD CONSTRAINT customer_pricing_pkey PRIMARY KEY (id);


--
-- Name: customer_quality_metrics customer_quality_metrics_customer_id_year_month_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_quality_metrics
    ADD CONSTRAINT customer_quality_metrics_customer_id_year_month_key UNIQUE (customer_id, year, month);


--
-- Name: customer_quality_metrics customer_quality_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_quality_metrics
    ADD CONSTRAINT customer_quality_metrics_pkey PRIMARY KEY (id);


--
-- Name: customer_red_flags customer_red_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_red_flags
    ADD CONSTRAINT customer_red_flags_pkey PRIMARY KEY (id);


--
-- Name: customer_shipping_addresses customer_shipping_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_shipping_addresses
    ADD CONSTRAINT customer_shipping_addresses_pkey PRIMARY KEY (id);


--
-- Name: customers customers_customer_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_customer_number_key UNIQUE (customer_number);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: entity_properties entity_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_properties
    ADD CONSTRAINT entity_properties_pkey PRIMARY KEY (id);


--
-- Name: event_logs event_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_logs
    ADD CONSTRAINT event_logs_pkey PRIMARY KEY (id);


--
-- Name: job_cards job_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_cards
    ADD CONSTRAINT job_cards_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: maintenance_categories maintenance_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_categories
    ADD CONSTRAINT maintenance_categories_pkey PRIMARY KEY (id);


--
-- Name: manufacturers manufacturers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manufacturers
    ADD CONSTRAINT manufacturers_pkey PRIMARY KEY (id);


--
-- Name: meter_readings meter_readings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meter_readings
    ADD CONSTRAINT meter_readings_pkey PRIMARY KEY (id);


--
-- Name: meter_types meter_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meter_types
    ADD CONSTRAINT meter_types_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: parts parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parts
    ADD CONSTRAINT parts_pkey PRIMARY KEY (id);


--
-- Name: pm_checklist_items pm_checklist_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_checklist_items
    ADD CONSTRAINT pm_checklist_items_pkey PRIMARY KEY (id);


--
-- Name: pm_executions pm_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_executions
    ADD CONSTRAINT pm_executions_pkey PRIMARY KEY (id);


--
-- Name: pm_schedule_components pm_schedule_components_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_schedule_components
    ADD CONSTRAINT pm_schedule_components_pkey PRIMARY KEY (id);


--
-- Name: pm_schedules pm_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_schedules
    ADD CONSTRAINT pm_schedules_pkey PRIMARY KEY (id);


--
-- Name: priority_codes priority_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.priority_codes
    ADD CONSTRAINT priority_codes_pkey PRIMARY KEY (id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_refresh_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_refresh_token_key UNIQUE (refresh_token);


--
-- Name: sessions sessions_session_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_session_token_key UNIQUE (session_token);


--
-- Name: shifts shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shifts
    ADD CONSTRAINT shifts_pkey PRIMARY KEY (id);


--
-- Name: sites sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: sync_queue sync_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_queue
    ADD CONSTRAINT sync_queue_pkey PRIMARY KEY (id);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- Name: user_profile_assignments user_profile_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profile_assignments
    ADD CONSTRAINT user_profile_assignments_pkey PRIMARY KEY (id);


--
-- Name: user_profile_assignments user_profile_assignments_user_id_profile_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profile_assignments
    ADD CONSTRAINT user_profile_assignments_user_id_profile_id_key UNIQUE (user_id, profile_id);


--
-- Name: user_profiles user_profiles_employee_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_employee_id_key UNIQUE (employee_id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);


--
-- Name: user_tenant_assignments user_tenant_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tenant_assignments
    ADD CONSTRAINT user_tenant_assignments_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: work_orders work_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_orders
    ADD CONSTRAINT work_orders_pkey PRIMARY KEY (id);


--
-- Name: asset_documents_document_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_documents_document_type_index ON public.asset_documents USING btree (document_type);


--
-- Name: asset_documents_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_documents_is_active_index ON public.asset_documents USING btree (is_active);


--
-- Name: asset_documents_pm_schedule_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_documents_pm_schedule_id_index ON public.asset_documents USING btree (pm_schedule_id);


--
-- Name: asset_documents_tenant_id_asset_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_documents_tenant_id_asset_id_index ON public.asset_documents USING btree (tenant_id, asset_id);


--
-- Name: asset_documents_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_documents_tenant_id_index ON public.asset_documents USING btree (tenant_id);


--
-- Name: asset_documents_uploaded_by_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_documents_uploaded_by_index ON public.asset_documents USING btree (uploaded_by);


--
-- Name: asset_documents_work_order_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_documents_work_order_id_index ON public.asset_documents USING btree (work_order_id);


--
-- Name: asset_location_types_tenant_id_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX asset_location_types_tenant_id_code_index ON public.asset_location_types USING btree (tenant_id, code);


--
-- Name: asset_location_types_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_location_types_tenant_id_index ON public.asset_location_types USING btree (tenant_id);


--
-- Name: asset_locations_tenant_id_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX asset_locations_tenant_id_code_index ON public.asset_locations USING btree (tenant_id, code);


--
-- Name: asset_locations_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_locations_tenant_id_index ON public.asset_locations USING btree (tenant_id);


--
-- Name: asset_locations_tenant_id_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_locations_tenant_id_is_active_index ON public.asset_locations USING btree (tenant_id, is_active);


--
-- Name: asset_locations_tenant_id_location_type_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_locations_tenant_id_location_type_id_index ON public.asset_locations USING btree (tenant_id, location_type_id);


--
-- Name: asset_locations_tenant_id_parent_location_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_locations_tenant_id_parent_location_id_index ON public.asset_locations USING btree (tenant_id, parent_location_id);


--
-- Name: asset_meters_asset_id_meter_type_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX asset_meters_asset_id_meter_type_id_index ON public.asset_meters USING btree (asset_id, meter_type_id);


--
-- Name: asset_meters_next_reading_due_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_meters_next_reading_due_index ON public.asset_meters USING btree (next_reading_due);


--
-- Name: asset_meters_tenant_id_asset_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_meters_tenant_id_asset_id_index ON public.asset_meters USING btree (tenant_id, asset_id);


--
-- Name: asset_meters_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_meters_tenant_id_index ON public.asset_meters USING btree (tenant_id);


--
-- Name: asset_meters_tenant_id_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_meters_tenant_id_is_active_index ON public.asset_meters USING btree (tenant_id, is_active);


--
-- Name: asset_types_tenant_id_category_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_types_tenant_id_category_index ON public.asset_types USING btree (tenant_id, category);


--
-- Name: asset_types_tenant_id_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX asset_types_tenant_id_code_index ON public.asset_types USING btree (tenant_id, code);


--
-- Name: asset_types_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX asset_types_tenant_id_index ON public.asset_types USING btree (tenant_id);


--
-- Name: assets_barcode_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_barcode_index ON public.assets USING btree (barcode);


--
-- Name: assets_serial_number_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_serial_number_index ON public.assets USING btree (serial_number);


--
-- Name: assets_tenant_id_asset_number_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX assets_tenant_id_asset_number_index ON public.assets USING btree (tenant_id, asset_number);


--
-- Name: assets_tenant_id_asset_type_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_tenant_id_asset_type_id_index ON public.assets USING btree (tenant_id, asset_type_id);


--
-- Name: assets_tenant_id_criticality_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_tenant_id_criticality_index ON public.assets USING btree (tenant_id, criticality);


--
-- Name: assets_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_tenant_id_index ON public.assets USING btree (tenant_id);


--
-- Name: assets_tenant_id_location_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_tenant_id_location_id_index ON public.assets USING btree (tenant_id, location_id);


--
-- Name: assets_tenant_id_parent_asset_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_tenant_id_parent_asset_id_index ON public.assets USING btree (tenant_id, parent_asset_id);


--
-- Name: assets_tenant_id_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_tenant_id_status_index ON public.assets USING btree (tenant_id, status);


--
-- Name: cmms_user_roles_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX cmms_user_roles_name_index ON public.cmms_user_roles USING btree (name);


--
-- Name: components_asset_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX components_asset_id_index ON public.components USING btree (asset_id);


--
-- Name: components_component_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX components_component_type_index ON public.components USING btree (component_type);


--
-- Name: components_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX components_status_index ON public.components USING btree (status);


--
-- Name: components_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX components_tenant_id_index ON public.components USING btree (tenant_id);


--
-- Name: custom_field_values_entity_type_entity_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX custom_field_values_entity_type_entity_id_index ON public.custom_field_values USING btree (entity_type, entity_id);


--
-- Name: custom_field_values_field_entity_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX custom_field_values_field_entity_index ON public.custom_field_values USING btree (custom_field_id, entity_id);


--
-- Name: custom_field_values_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX custom_field_values_tenant_id_index ON public.custom_field_values USING btree (tenant_id);


--
-- Name: custom_fields_display_order_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX custom_fields_display_order_index ON public.custom_fields USING btree (display_order);


--
-- Name: custom_fields_entity_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX custom_fields_entity_type_index ON public.custom_fields USING btree (entity_type);


--
-- Name: custom_fields_tenant_entity_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX custom_fields_tenant_entity_name_index ON public.custom_fields USING btree (tenant_id, entity_type, field_name);


--
-- Name: custom_fields_tenant_id_entity_type_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX custom_fields_tenant_id_entity_type_is_active_index ON public.custom_fields USING btree (tenant_id, entity_type, is_active);


--
-- Name: departments_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX departments_name_index ON public.departments USING btree (name);


--
-- Name: departments_parent_department_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX departments_parent_department_id_index ON public.departments USING btree (parent_department_id);


--
-- Name: departments_tenant_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX departments_tenant_code_index ON public.departments USING btree (tenant_id, code) WHERE (code IS NOT NULL);


--
-- Name: departments_tenant_id_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX departments_tenant_id_is_active_index ON public.departments USING btree (tenant_id, is_active);


--
-- Name: departments_tenant_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX departments_tenant_name_index ON public.departments USING btree (tenant_id, name);


--
-- Name: idx_audit_logs_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_entity ON public.audit_logs USING btree (entity_type, entity_id);


--
-- Name: idx_audit_logs_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_timestamp ON public.audit_logs USING btree ("timestamp");


--
-- Name: idx_audit_logs_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs USING btree (user_id);


--
-- Name: idx_contacts_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contacts_customer_id ON public.contacts USING btree (customer_id);


--
-- Name: idx_customer_attr_def_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_attr_def_group ON public.customer_attribute_definitions USING btree (group_name);


--
-- Name: idx_customer_attr_def_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_attr_def_key ON public.customer_attribute_definitions USING btree (attribute_key);


--
-- Name: idx_customer_attr_def_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_attr_def_order ON public.customer_attribute_definitions USING btree (display_order);


--
-- Name: idx_customer_attributes_attribute; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_attributes_attribute ON public.customer_attributes USING btree (attribute_id);


--
-- Name: idx_customer_attributes_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_attributes_customer ON public.customer_attributes USING btree (customer_id);


--
-- Name: idx_customer_attributes_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_attributes_date ON public.customer_attributes USING btree (date_value) WHERE (date_value IS NOT NULL);


--
-- Name: idx_customer_attributes_decimal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_attributes_decimal ON public.customer_attributes USING btree (decimal_value) WHERE (decimal_value IS NOT NULL);


--
-- Name: idx_customer_attributes_integer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_attributes_integer ON public.customer_attributes USING btree (integer_value) WHERE (integer_value IS NOT NULL);


--
-- Name: idx_customer_attributes_json; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_attributes_json ON public.customer_attributes USING gin ("json_value") WHERE ("json_value" IS NOT NULL);


--
-- Name: idx_customer_attributes_string; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_attributes_string ON public.customer_attributes USING btree (string_value) WHERE (string_value IS NOT NULL);


--
-- Name: idx_customer_contacts_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_contacts_customer ON public.customer_contacts USING btree (customer_id);


--
-- Name: idx_customer_contacts_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_contacts_email ON public.customer_contacts USING btree (email);


--
-- Name: idx_customer_parts_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_parts_customer ON public.customer_parts USING btree (customer_id);


--
-- Name: idx_customer_parts_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_parts_number ON public.customer_parts USING btree (part_number);


--
-- Name: idx_customer_pricing_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_pricing_customer ON public.customer_pricing USING btree (customer_id);


--
-- Name: idx_customer_pricing_part; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_pricing_part ON public.customer_pricing USING btree (part_number);


--
-- Name: idx_customer_quality_customer_year; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_quality_customer_year ON public.customer_quality_metrics USING btree (customer_id, year);


--
-- Name: idx_customers_city_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customers_city_state ON public.customers USING btree (city, state);


--
-- Name: idx_customers_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customers_name ON public.customers USING btree (name);


--
-- Name: idx_customers_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customers_number ON public.customers USING btree (customer_number);


--
-- Name: idx_customers_sales_rep; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customers_sales_rep ON public.customers USING btree (sales_rep);


--
-- Name: idx_customers_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customers_status ON public.customers USING btree (status);


--
-- Name: idx_entity_properties_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_entity_properties_entity ON public.entity_properties USING btree (entity_type, entity_id);


--
-- Name: idx_entity_properties_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_entity_properties_name ON public.entity_properties USING btree (name);


--
-- Name: idx_event_logs_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_logs_event_type ON public.event_logs USING btree (event_type);


--
-- Name: idx_event_logs_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_logs_user_id ON public.event_logs USING btree (user_id);


--
-- Name: idx_job_cards_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_cards_order_id ON public.job_cards USING btree (order_id);


--
-- Name: idx_job_cards_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_cards_status ON public.job_cards USING btree (status);


--
-- Name: idx_orders_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_customer_id ON public.orders USING btree (customer_id);


--
-- Name: idx_orders_part_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_part_id ON public.orders USING btree (part_id);


--
-- Name: idx_parts_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_parts_customer_id ON public.parts USING btree (customer_id);


--
-- Name: idx_parts_pn; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_parts_pn ON public.parts USING btree (pn);


--
-- Name: idx_sessions_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_active ON public.sessions USING btree (is_active, expires_at);


--
-- Name: idx_sessions_ip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_ip ON public.sessions USING btree (ip_address);


--
-- Name: idx_sessions_last_activity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_last_activity ON public.sessions USING btree (last_activity);


--
-- Name: idx_sessions_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_profile_id ON public.sessions USING btree (profile_id);


--
-- Name: idx_sessions_refresh_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_refresh_token ON public.sessions USING btree (refresh_token);


--
-- Name: idx_sessions_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_token ON public.sessions USING btree (session_token);


--
-- Name: idx_sessions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_user_id ON public.sessions USING btree (user_id);


--
-- Name: idx_sync_queue_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sync_queue_entity ON public.sync_queue USING btree (entity_type, entity_id);


--
-- Name: idx_sync_queue_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sync_queue_status ON public.sync_queue USING btree (status);


--
-- Name: idx_user_profile_assignments_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profile_assignments_expires_at ON public.user_profile_assignments USING btree (expires_at);


--
-- Name: idx_user_profile_assignments_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profile_assignments_is_active ON public.user_profile_assignments USING btree (is_active);


--
-- Name: idx_user_profile_assignments_primary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profile_assignments_primary ON public.user_profile_assignments USING btree (user_id, is_primary) WHERE (is_primary = true);


--
-- Name: idx_user_profile_assignments_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profile_assignments_profile_id ON public.user_profile_assignments USING btree (profile_id);


--
-- Name: idx_user_profile_assignments_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profile_assignments_user_id ON public.user_profile_assignments USING btree (user_id);


--
-- Name: idx_user_profiles_department; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profiles_department ON public.user_profiles USING btree (department);


--
-- Name: idx_user_profiles_employee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profiles_employee_id ON public.user_profiles USING btree (employee_id);


--
-- Name: idx_user_profiles_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profiles_is_active ON public.user_profiles USING btree (is_active);


--
-- Name: idx_user_profiles_is_template; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profiles_is_template ON public.user_profiles USING btree (is_template);


--
-- Name: idx_user_profiles_manager_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profiles_manager_id ON public.user_profiles USING btree (manager_id);


--
-- Name: idx_user_profiles_profile_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profiles_profile_type ON public.user_profiles USING btree (profile_type);


--
-- Name: maintenance_categories_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance_categories_name_index ON public.maintenance_categories USING btree (name);


--
-- Name: maintenance_categories_parent_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance_categories_parent_category_id_index ON public.maintenance_categories USING btree (parent_category_id);


--
-- Name: maintenance_categories_tenant_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX maintenance_categories_tenant_code_index ON public.maintenance_categories USING btree (tenant_id, code) WHERE (code IS NOT NULL);


--
-- Name: maintenance_categories_tenant_id_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance_categories_tenant_id_is_active_index ON public.maintenance_categories USING btree (tenant_id, is_active);


--
-- Name: maintenance_categories_tenant_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX maintenance_categories_tenant_name_index ON public.maintenance_categories USING btree (tenant_id, name);


--
-- Name: maintenance_categories_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance_categories_type_index ON public.maintenance_categories USING btree (type);


--
-- Name: manufacturers_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX manufacturers_name_index ON public.manufacturers USING btree (name);


--
-- Name: manufacturers_tenant_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX manufacturers_tenant_code_index ON public.manufacturers USING btree (tenant_id, code) WHERE (code IS NOT NULL);


--
-- Name: manufacturers_tenant_id_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX manufacturers_tenant_id_is_active_index ON public.manufacturers USING btree (tenant_id, is_active);


--
-- Name: manufacturers_tenant_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX manufacturers_tenant_name_index ON public.manufacturers USING btree (tenant_id, name);


--
-- Name: meter_readings_reading_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meter_readings_reading_date_index ON public.meter_readings USING btree (reading_date);


--
-- Name: meter_readings_recorded_by_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meter_readings_recorded_by_index ON public.meter_readings USING btree (recorded_by);


--
-- Name: meter_readings_tenant_id_asset_meter_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meter_readings_tenant_id_asset_meter_id_index ON public.meter_readings USING btree (tenant_id, asset_meter_id);


--
-- Name: meter_readings_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meter_readings_tenant_id_index ON public.meter_readings USING btree (tenant_id);


--
-- Name: meter_types_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meter_types_tenant_id_index ON public.meter_types USING btree (tenant_id);


--
-- Name: meter_types_tenant_id_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX meter_types_tenant_id_name_index ON public.meter_types USING btree (tenant_id, name);


--
-- Name: pm_checklist_items_pm_schedule_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_checklist_items_pm_schedule_id_index ON public.pm_checklist_items USING btree (pm_schedule_id);


--
-- Name: pm_checklist_items_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_checklist_items_tenant_id_index ON public.pm_checklist_items USING btree (tenant_id);


--
-- Name: pm_executions_asset_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_executions_asset_id_index ON public.pm_executions USING btree (asset_id);


--
-- Name: pm_executions_component_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_executions_component_id_index ON public.pm_executions USING btree (component_id);


--
-- Name: pm_executions_execution_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_executions_execution_date_index ON public.pm_executions USING btree (execution_date);


--
-- Name: pm_executions_execution_number_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pm_executions_execution_number_index ON public.pm_executions USING btree (execution_number);


--
-- Name: pm_executions_pm_schedule_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_executions_pm_schedule_id_index ON public.pm_executions USING btree (pm_schedule_id);


--
-- Name: pm_executions_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_executions_status_index ON public.pm_executions USING btree (status);


--
-- Name: pm_executions_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_executions_tenant_id_index ON public.pm_executions USING btree (tenant_id);


--
-- Name: pm_schedule_components_pm_schedule_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_schedule_components_pm_schedule_id_index ON public.pm_schedule_components USING btree (pm_schedule_id);


--
-- Name: pm_schedule_components_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_schedule_components_tenant_id_index ON public.pm_schedule_components USING btree (tenant_id);


--
-- Name: pm_schedules_asset_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_schedules_asset_id_index ON public.pm_schedules USING btree (asset_id);


--
-- Name: pm_schedules_component_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_schedules_component_id_index ON public.pm_schedules USING btree (component_id);


--
-- Name: pm_schedules_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_schedules_is_active_index ON public.pm_schedules USING btree (is_active);


--
-- Name: pm_schedules_next_due_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_schedules_next_due_date_index ON public.pm_schedules USING btree (next_due_date);


--
-- Name: pm_schedules_schedule_number_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pm_schedules_schedule_number_tenant_id_index ON public.pm_schedules USING btree (schedule_number, tenant_id);


--
-- Name: pm_schedules_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pm_schedules_tenant_id_index ON public.pm_schedules USING btree (tenant_id);


--
-- Name: priority_codes_level_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX priority_codes_level_index ON public.priority_codes USING btree (level);


--
-- Name: priority_codes_tenant_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX priority_codes_tenant_code_index ON public.priority_codes USING btree (tenant_id, code) WHERE (code IS NOT NULL);


--
-- Name: priority_codes_tenant_id_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX priority_codes_tenant_id_is_active_index ON public.priority_codes USING btree (tenant_id, is_active);


--
-- Name: priority_codes_tenant_level_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX priority_codes_tenant_level_index ON public.priority_codes USING btree (tenant_id, level);


--
-- Name: priority_codes_tenant_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX priority_codes_tenant_name_index ON public.priority_codes USING btree (tenant_id, name);


--
-- Name: sites_tenant_id_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sites_tenant_id_code_index ON public.sites USING btree (tenant_id, code);


--
-- Name: sites_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sites_tenant_id_index ON public.sites USING btree (tenant_id);


--
-- Name: sites_tenant_id_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sites_tenant_id_name_index ON public.sites USING btree (tenant_id, name);


--
-- Name: suppliers_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX suppliers_name_index ON public.suppliers USING btree (name);


--
-- Name: suppliers_tenant_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX suppliers_tenant_code_index ON public.suppliers USING btree (tenant_id, code) WHERE (code IS NOT NULL);


--
-- Name: suppliers_tenant_id_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX suppliers_tenant_id_is_active_index ON public.suppliers USING btree (tenant_id, is_active);


--
-- Name: suppliers_tenant_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX suppliers_tenant_name_index ON public.suppliers USING btree (tenant_id, name);


--
-- Name: suppliers_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX suppliers_type_index ON public.suppliers USING btree (type);


--
-- Name: tenants_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX tenants_code_index ON public.tenants USING btree (code);


--
-- Name: tenants_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX tenants_name_index ON public.tenants USING btree (name);


--
-- Name: user_tenant_assignments_role_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_tenant_assignments_role_id_index ON public.user_tenant_assignments USING btree (role_id);


--
-- Name: user_tenant_assignments_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_tenant_assignments_tenant_id_index ON public.user_tenant_assignments USING btree (tenant_id);


--
-- Name: user_tenant_assignments_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_tenant_assignments_user_id_index ON public.user_tenant_assignments USING btree (user_id);


--
-- Name: user_tenant_assignments_user_id_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_tenant_assignments_user_id_tenant_id_index ON public.user_tenant_assignments USING btree (user_id, tenant_id);


--
-- Name: users_username_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_username_index ON public.users USING btree (username);


--
-- Name: work_orders_asset_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX work_orders_asset_id_index ON public.work_orders USING btree (asset_id);


--
-- Name: work_orders_assigned_to_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX work_orders_assigned_to_index ON public.work_orders USING btree (assigned_to);


--
-- Name: work_orders_due_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX work_orders_due_date_index ON public.work_orders USING btree (due_date);


--
-- Name: work_orders_priority_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX work_orders_priority_index ON public.work_orders USING btree (priority);


--
-- Name: work_orders_requested_by_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX work_orders_requested_by_index ON public.work_orders USING btree (requested_by);


--
-- Name: work_orders_scheduled_start_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX work_orders_scheduled_start_date_index ON public.work_orders USING btree (scheduled_start_date);


--
-- Name: work_orders_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX work_orders_status_index ON public.work_orders USING btree (status);


--
-- Name: work_orders_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX work_orders_tenant_id_index ON public.work_orders USING btree (tenant_id);


--
-- Name: work_orders_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX work_orders_type_index ON public.work_orders USING btree (type);


--
-- Name: work_orders_work_order_number_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX work_orders_work_order_number_tenant_id_index ON public.work_orders USING btree (work_order_number, tenant_id);


--
-- Name: customers tr_validate_customer_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_validate_customer_insert BEFORE INSERT OR UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.validate_customer_insert();


--
-- Name: asset_documents asset_documents_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_documents
    ADD CONSTRAINT asset_documents_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(id) ON DELETE CASCADE;


--
-- Name: asset_documents asset_documents_pm_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_documents
    ADD CONSTRAINT asset_documents_pm_schedule_id_fkey FOREIGN KEY (pm_schedule_id) REFERENCES public.pm_schedules(id) ON DELETE CASCADE;


--
-- Name: asset_documents asset_documents_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_documents
    ADD CONSTRAINT asset_documents_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: asset_documents asset_documents_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_documents
    ADD CONSTRAINT asset_documents_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: asset_documents asset_documents_work_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_documents
    ADD CONSTRAINT asset_documents_work_order_id_fkey FOREIGN KEY (work_order_id) REFERENCES public.work_orders(id) ON DELETE CASCADE;


--
-- Name: asset_location_types asset_location_types_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_location_types
    ADD CONSTRAINT asset_location_types_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: asset_locations asset_locations_location_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_locations
    ADD CONSTRAINT asset_locations_location_type_id_fkey FOREIGN KEY (location_type_id) REFERENCES public.asset_location_types(id) ON DELETE RESTRICT;


--
-- Name: asset_locations asset_locations_parent_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_locations
    ADD CONSTRAINT asset_locations_parent_location_id_fkey FOREIGN KEY (parent_location_id) REFERENCES public.asset_locations(id) ON DELETE SET NULL;


--
-- Name: asset_locations asset_locations_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_locations
    ADD CONSTRAINT asset_locations_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: asset_meters asset_meters_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_meters
    ADD CONSTRAINT asset_meters_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(id) ON DELETE CASCADE;


--
-- Name: asset_meters asset_meters_meter_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_meters
    ADD CONSTRAINT asset_meters_meter_type_id_fkey FOREIGN KEY (meter_type_id) REFERENCES public.meter_types(id) ON DELETE RESTRICT;


--
-- Name: asset_meters asset_meters_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_meters
    ADD CONSTRAINT asset_meters_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: asset_types asset_types_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_types
    ADD CONSTRAINT asset_types_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: assets assets_asset_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_asset_type_id_fkey FOREIGN KEY (asset_type_id) REFERENCES public.asset_types(id) ON DELETE RESTRICT;


--
-- Name: assets assets_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.asset_locations(id) ON DELETE RESTRICT;


--
-- Name: assets assets_parent_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_parent_asset_id_fkey FOREIGN KEY (parent_asset_id) REFERENCES public.assets(id) ON DELETE SET NULL;


--
-- Name: assets assets_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: components components_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.components
    ADD CONSTRAINT components_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(id) ON DELETE CASCADE;


--
-- Name: custom_field_values custom_field_values_custom_field_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_values
    ADD CONSTRAINT custom_field_values_custom_field_id_fkey FOREIGN KEY (custom_field_id) REFERENCES public.custom_fields(id) ON DELETE CASCADE;


--
-- Name: custom_field_values custom_field_values_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_values
    ADD CONSTRAINT custom_field_values_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: custom_fields custom_fields_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_fields
    ADD CONSTRAINT custom_fields_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: customer_attributes customer_attributes_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_attributes
    ADD CONSTRAINT customer_attributes_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.customer_attribute_definitions(id) ON DELETE CASCADE;


--
-- Name: customer_attributes customer_attributes_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_attributes
    ADD CONSTRAINT customer_attributes_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: customer_billing_addresses customer_billing_addresses_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_billing_addresses
    ADD CONSTRAINT customer_billing_addresses_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: customer_contact_log customer_contact_log_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_contact_log
    ADD CONSTRAINT customer_contact_log_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: customer_contacts customer_contacts_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_contacts
    ADD CONSTRAINT customer_contacts_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: customer_parts customer_parts_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_parts
    ADD CONSTRAINT customer_parts_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: customer_pricing customer_pricing_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_pricing
    ADD CONSTRAINT customer_pricing_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: customer_quality_metrics customer_quality_metrics_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_quality_metrics
    ADD CONSTRAINT customer_quality_metrics_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: customer_red_flags customer_red_flags_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_red_flags
    ADD CONSTRAINT customer_red_flags_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: customer_shipping_addresses customer_shipping_addresses_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_shipping_addresses
    ADD CONSTRAINT customer_shipping_addresses_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: departments departments_parent_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_parent_department_id_fkey FOREIGN KEY (parent_department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: departments departments_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: event_logs event_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_logs
    ADD CONSTRAINT event_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: job_cards job_cards_locked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_cards
    ADD CONSTRAINT job_cards_locked_by_fkey FOREIGN KEY (locked_by) REFERENCES public.users(id);


--
-- Name: job_cards job_cards_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_cards
    ADD CONSTRAINT job_cards_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: maintenance_categories maintenance_categories_parent_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_categories
    ADD CONSTRAINT maintenance_categories_parent_category_id_fkey FOREIGN KEY (parent_category_id) REFERENCES public.maintenance_categories(id) ON DELETE SET NULL;


--
-- Name: maintenance_categories maintenance_categories_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_categories
    ADD CONSTRAINT maintenance_categories_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: manufacturers manufacturers_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manufacturers
    ADD CONSTRAINT manufacturers_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: meter_readings meter_readings_asset_meter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meter_readings
    ADD CONSTRAINT meter_readings_asset_meter_id_fkey FOREIGN KEY (asset_meter_id) REFERENCES public.asset_meters(id) ON DELETE CASCADE;


--
-- Name: meter_readings meter_readings_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meter_readings
    ADD CONSTRAINT meter_readings_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: meter_readings meter_readings_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meter_readings
    ADD CONSTRAINT meter_readings_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: meter_types meter_types_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meter_types
    ADD CONSTRAINT meter_types_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: orders orders_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: orders orders_part_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_part_id_fkey FOREIGN KEY (part_id) REFERENCES public.parts(id);


--
-- Name: pm_checklist_items pm_checklist_items_pm_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_checklist_items
    ADD CONSTRAINT pm_checklist_items_pm_schedule_id_fkey FOREIGN KEY (pm_schedule_id) REFERENCES public.pm_schedules(id) ON DELETE CASCADE;


--
-- Name: pm_checklist_items pm_checklist_items_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_checklist_items
    ADD CONSTRAINT pm_checklist_items_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: pm_executions pm_executions_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_executions
    ADD CONSTRAINT pm_executions_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(id);


--
-- Name: pm_executions pm_executions_completed_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_executions
    ADD CONSTRAINT pm_executions_completed_by_user_id_fkey FOREIGN KEY (completed_by_user_id) REFERENCES public.users(id);


--
-- Name: pm_executions pm_executions_component_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_executions
    ADD CONSTRAINT pm_executions_component_id_fkey FOREIGN KEY (component_id) REFERENCES public.components(id);


--
-- Name: pm_executions pm_executions_pm_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_executions
    ADD CONSTRAINT pm_executions_pm_schedule_id_fkey FOREIGN KEY (pm_schedule_id) REFERENCES public.pm_schedules(id) ON DELETE CASCADE;


--
-- Name: pm_executions pm_executions_work_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_executions
    ADD CONSTRAINT pm_executions_work_order_id_fkey FOREIGN KEY (work_order_id) REFERENCES public.work_orders(id) ON DELETE SET NULL;


--
-- Name: pm_schedule_components pm_schedule_components_pm_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_schedule_components
    ADD CONSTRAINT pm_schedule_components_pm_schedule_id_fkey FOREIGN KEY (pm_schedule_id) REFERENCES public.pm_schedules(id) ON DELETE CASCADE;


--
-- Name: pm_schedule_components pm_schedule_components_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_schedule_components
    ADD CONSTRAINT pm_schedule_components_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: pm_schedules pm_schedules_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_schedules
    ADD CONSTRAINT pm_schedules_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(id) ON DELETE CASCADE;


--
-- Name: pm_schedules pm_schedules_component_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_schedules
    ADD CONSTRAINT pm_schedules_component_id_fkey FOREIGN KEY (component_id) REFERENCES public.components(id) ON DELETE SET NULL;


--
-- Name: pm_schedules pm_schedules_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_schedules
    ADD CONSTRAINT pm_schedules_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: pm_schedules pm_schedules_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_schedules
    ADD CONSTRAINT pm_schedules_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: pm_schedules pm_schedules_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pm_schedules
    ADD CONSTRAINT pm_schedules_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: priority_codes priority_codes_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.priority_codes
    ADD CONSTRAINT priority_codes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.user_profiles(id) ON DELETE SET NULL;


--
-- Name: sessions sessions_revoked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_revoked_by_fkey FOREIGN KEY (revoked_by) REFERENCES public.users(id);


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: sites sites_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: suppliers suppliers_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: user_profile_assignments user_profile_assignments_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profile_assignments
    ADD CONSTRAINT user_profile_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(id);


--
-- Name: user_profile_assignments user_profile_assignments_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profile_assignments
    ADD CONSTRAINT user_profile_assignments_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE;


--
-- Name: user_profile_assignments user_profile_assignments_revoked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profile_assignments
    ADD CONSTRAINT user_profile_assignments_revoked_by_fkey FOREIGN KEY (revoked_by) REFERENCES public.users(id);


--
-- Name: user_profile_assignments user_profile_assignments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profile_assignments
    ADD CONSTRAINT user_profile_assignments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_profiles user_profiles_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: user_profiles user_profiles_manager_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.users(id);


--
-- Name: user_profiles user_profiles_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.users(id);


--
-- Name: user_tenant_assignments user_tenant_assignments_assigned_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tenant_assignments
    ADD CONSTRAINT user_tenant_assignments_assigned_by_id_fkey FOREIGN KEY (assigned_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_tenant_assignments user_tenant_assignments_default_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tenant_assignments
    ADD CONSTRAINT user_tenant_assignments_default_site_id_fkey FOREIGN KEY (default_site_id) REFERENCES public.sites(id) ON DELETE SET NULL;


--
-- Name: user_tenant_assignments user_tenant_assignments_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tenant_assignments
    ADD CONSTRAINT user_tenant_assignments_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.cmms_user_roles(id) ON DELETE RESTRICT;


--
-- Name: user_tenant_assignments user_tenant_assignments_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tenant_assignments
    ADD CONSTRAINT user_tenant_assignments_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: user_tenant_assignments user_tenant_assignments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tenant_assignments
    ADD CONSTRAINT user_tenant_assignments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE SET NULL;


--
-- Name: work_orders work_orders_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_orders
    ADD CONSTRAINT work_orders_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(id) ON DELETE SET NULL;


--
-- Name: work_orders work_orders_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_orders
    ADD CONSTRAINT work_orders_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: work_orders work_orders_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_orders
    ADD CONSTRAINT work_orders_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: work_orders work_orders_requested_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_orders
    ADD CONSTRAINT work_orders_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: work_orders work_orders_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_orders
    ADD CONSTRAINT work_orders_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: work_orders work_orders_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_orders
    ADD CONSTRAINT work_orders_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: asset_documents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.asset_documents ENABLE ROW LEVEL SECURITY;

--
-- Name: asset_documents asset_documents_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY asset_documents_tenant_isolation ON public.asset_documents USING ((tenant_id = (current_setting('app.current_tenant'::text))::bigint));


--
-- Name: asset_location_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.asset_location_types ENABLE ROW LEVEL SECURITY;

--
-- Name: asset_location_types asset_location_types_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY asset_location_types_tenant_isolation ON public.asset_location_types USING ((tenant_id = (current_setting('app.current_tenant'::text))::bigint));


--
-- Name: asset_locations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.asset_locations ENABLE ROW LEVEL SECURITY;

--
-- Name: asset_locations asset_locations_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY asset_locations_tenant_isolation ON public.asset_locations USING ((tenant_id = (current_setting('app.current_tenant'::text))::bigint));


--
-- Name: asset_meters; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.asset_meters ENABLE ROW LEVEL SECURITY;

--
-- Name: asset_meters asset_meters_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY asset_meters_tenant_isolation ON public.asset_meters USING ((tenant_id = (current_setting('app.current_tenant'::text))::bigint));


--
-- Name: asset_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.asset_types ENABLE ROW LEVEL SECURITY;

--
-- Name: asset_types asset_types_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY asset_types_tenant_isolation ON public.asset_types USING ((tenant_id = (current_setting('app.current_tenant'::text))::bigint));


--
-- Name: assets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;

--
-- Name: assets assets_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY assets_tenant_isolation ON public.assets USING ((tenant_id = (current_setting('app.current_tenant'::text))::bigint));


--
-- Name: custom_field_values; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.custom_field_values ENABLE ROW LEVEL SECURITY;

--
-- Name: custom_field_values custom_field_values_tenant_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY custom_field_values_tenant_policy ON public.custom_field_values TO postgres USING ((tenant_id = (current_setting('app.current_tenant_id'::text, true))::integer));


--
-- Name: custom_fields; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.custom_fields ENABLE ROW LEVEL SECURITY;

--
-- Name: custom_fields custom_fields_tenant_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY custom_fields_tenant_policy ON public.custom_fields TO postgres USING ((tenant_id = (current_setting('app.current_tenant_id'::text, true))::integer));


--
-- Name: departments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;

--
-- Name: departments departments_tenant_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY departments_tenant_policy ON public.departments TO postgres USING ((tenant_id = (current_setting('app.current_tenant_id'::text, true))::integer));


--
-- Name: maintenance_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.maintenance_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: maintenance_categories maintenance_categories_tenant_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY maintenance_categories_tenant_policy ON public.maintenance_categories TO postgres USING ((tenant_id = (current_setting('app.current_tenant_id'::text, true))::integer));


--
-- Name: manufacturers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.manufacturers ENABLE ROW LEVEL SECURITY;

--
-- Name: manufacturers manufacturers_tenant_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY manufacturers_tenant_policy ON public.manufacturers TO postgres USING ((tenant_id = (current_setting('app.current_tenant_id'::text, true))::integer));


--
-- Name: meter_readings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.meter_readings ENABLE ROW LEVEL SECURITY;

--
-- Name: meter_readings meter_readings_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY meter_readings_tenant_isolation ON public.meter_readings USING ((tenant_id = (current_setting('app.current_tenant'::text))::bigint));


--
-- Name: meter_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.meter_types ENABLE ROW LEVEL SECURITY;

--
-- Name: meter_types meter_types_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY meter_types_tenant_isolation ON public.meter_types USING ((tenant_id = (current_setting('app.current_tenant'::text))::bigint));


--
-- Name: pm_checklist_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pm_checklist_items ENABLE ROW LEVEL SECURITY;

--
-- Name: pm_checklist_items pm_checklist_items_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pm_checklist_items_tenant_isolation ON public.pm_checklist_items USING (((tenant_id)::text = current_setting('app.current_tenant_id'::text, true)));


--
-- Name: pm_schedule_components; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pm_schedule_components ENABLE ROW LEVEL SECURITY;

--
-- Name: pm_schedule_components pm_schedule_components_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pm_schedule_components_tenant_isolation ON public.pm_schedule_components USING (((tenant_id)::text = current_setting('app.current_tenant_id'::text, true)));


--
-- Name: pm_schedules; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pm_schedules ENABLE ROW LEVEL SECURITY;

--
-- Name: pm_schedules pm_schedules_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pm_schedules_tenant_isolation ON public.pm_schedules USING (((tenant_id)::text = current_setting('app.current_tenant_id'::text, true)));


--
-- Name: priority_codes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.priority_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: priority_codes priority_codes_tenant_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY priority_codes_tenant_policy ON public.priority_codes TO postgres USING ((tenant_id = (current_setting('app.current_tenant_id'::text, true))::integer));


--
-- Name: sites; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sites ENABLE ROW LEVEL SECURITY;

--
-- Name: suppliers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;

--
-- Name: suppliers suppliers_tenant_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY suppliers_tenant_policy ON public.suppliers TO postgres USING ((tenant_id = (current_setting('app.current_tenant_id'::text, true))::integer));


--
-- Name: tenants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;

--
-- Name: user_tenant_assignments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_tenant_assignments ENABLE ROW LEVEL SECURITY;

--
-- Name: work_orders; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.work_orders ENABLE ROW LEVEL SECURITY;

--
-- Name: work_orders work_orders_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY work_orders_tenant_isolation ON public.work_orders USING (((tenant_id)::text = current_setting('app.current_tenant_id'::text, true)));


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20250909184000);
INSERT INTO public."schema_migrations" (version) VALUES (20250909184105);
INSERT INTO public."schema_migrations" (version) VALUES (20250909184110);
INSERT INTO public."schema_migrations" (version) VALUES (20250909184805);
INSERT INTO public."schema_migrations" (version) VALUES (20250909190000);
INSERT INTO public."schema_migrations" (version) VALUES (20250910145531);
INSERT INTO public."schema_migrations" (version) VALUES (20250911125115);
INSERT INTO public."schema_migrations" (version) VALUES (20250929140254);
INSERT INTO public."schema_migrations" (version) VALUES (20251001183708);
INSERT INTO public."schema_migrations" (version) VALUES (20251002145634);
INSERT INTO public."schema_migrations" (version) VALUES (20251002145642);
INSERT INTO public."schema_migrations" (version) VALUES (20251002145643);
INSERT INTO public."schema_migrations" (version) VALUES (20251002145644);
