--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: schedule_rules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schedule_rules (
    id integer NOT NULL,
    recur character varying(255),
    start date,
    mon boolean,
    tue boolean,
    wed boolean,
    thu boolean,
    fri boolean,
    sat boolean,
    sun boolean,
    schedule_pause_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    scheduleable_id integer,
    scheduleable_type character varying(255),
    halted boolean DEFAULT false,
    week integer DEFAULT 0
);


--
-- Name: is_paused(date, schedule_rules); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_paused(test_date date, schedule_rule schedule_rules) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
  IF EXISTS (SELECT *
     FROM schedule_pauses
     WHERE schedule_pauses.id = schedule_rule.schedule_pause_id
     AND schedule_pauses.start <= test_date
     AND (schedule_pauses.finish > test_date
     OR schedule_pauses.finish IS NULL)) THEN
    return TRUE;
  ELSE
    return FALSE;
  END IF;
END;
$$;


--
-- Name: next_occurrence(date, schedule_rules); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION next_occurrence(from_date date, schedule_rule schedule_rules) RETURNS date
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
  next_date DATE;
BEGIN
  next_date := from_date;
  LOOP
    -- Get the next possible occurrence
    next_date := unpaused_next_occurrence(next_date, schedule_rule);

    -- Test if it falls in a pause, exit if not
    EXIT WHEN NOT is_paused(next_date, schedule_rule);

    -- Apparently that one was in a pause, start looking again from the end of a pause
    next_date := pause_finish(next_date, schedule_rule);

    -- If the pause_finish returns NULL we can assume the pause never finishes, thus there is never a next_occurrence
    EXIT WHEN next_date IS NULL;
  END LOOP;
  return next_date;
END;
$$;


--
-- Name: next_occurrence(date, boolean, boolean, schedule_rules); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION next_occurrence(from_date date, ignore_pauses boolean, ignore_halts boolean, schedule_rule schedule_rules) RETURNS date
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
  next_date DATE;
BEGIN
  next_date := from_date;
  IF NOT ignore_halts AND schedule_rule.halted THEN
    return null;
  ELSE
    LOOP
      -- Get the next possible occurrence
      next_date := unpaused_next_occurrence(next_date, schedule_rule);

      -- Test if it falls in a pause, exit if not
      EXIT WHEN ignore_pauses OR NOT is_paused(next_date, schedule_rule);

      -- Apparently that one was in a pause, start looking again from the end of a pause
      next_date := pause_finish(next_date, schedule_rule);

      -- If the pause_finish returns NULL we can assume the pause never finishes, thus there is never a next_occurrence
      EXIT WHEN next_date IS NULL;
    END LOOP;
    return next_date;
  END IF;
END;
$$;


--
-- Name: on_day(integer, schedule_rules); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION on_day(day integer, schedule_rule schedule_rules) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
  result DATE;
BEGIN
  -- If it is a one off, then it doesn't have a mon -> sun schedule, check the day it starts on
  IF schedule_rule.recur IS NULL OR schedule_rule.recur = 'single' THEN
    return EXTRACT(DOW FROM schedule_rule.start) = day;
  ELSE
    CASE day
      WHEN 0 THEN
        RETURN schedule_rule.sun;
      WHEN 1 THEN
        RETURN schedule_rule.mon;
      WHEN 2 THEN
        RETURN schedule_rule.tue;
      WHEN 3 THEN
        RETURN schedule_rule.wed;
      WHEN 4 THEN
        RETURN schedule_rule.thu;
      WHEN 5 THEN
        RETURN schedule_rule.fri;
      WHEN 6 THEN
        RETURN schedule_rule.sat;
      ELSE
        RETURN FALSE;
    END CASE;
  END IF;
END;
$$;


--
-- Name: pause_finish(date, schedule_rules); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION pause_finish(test_date date, schedule_rule schedule_rules) RETURNS date
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
  result DATE;
BEGIN
  SELECT schedule_pauses.finish
  FROM schedule_pauses
  WHERE schedule_pauses.id = schedule_rule.schedule_pause_id
  AND schedule_pauses.start <= test_date
  AND (schedule_pauses.finish > test_date
  OR schedule_pauses.finish IS NULL)
  ORDER BY schedule_pauses.finish DESC
  LIMIT 1 INTO result;
  RETURN result;
END;
$$;


--
-- Name: unpaused_next_occurrence(date, schedule_rules); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION unpaused_next_occurrence(from_date date, schedule_rule schedule_rules) RETURNS date
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
  from_wday int;
  days_from_now int;
  week_days int[7];
  next_date date;
BEGIN
  -- From which date should we start looking for the next occurrence?  The schedule_rule's start date or the param's from_date
  IF from_date < schedule_rule.start THEN
    from_date := schedule_rule.start;
  END IF;
  
  -- What is the day of the week? Sunday: 0, Monday: 1, etc...
  from_wday := EXTRACT(DOW from from_date);

  CASE schedule_rule.recur
  WHEN 'weekly' THEN
  -- ==================== WEEKLY ====================
    -- Loop until we find the next occurrence
    -- The '0' in 0..6 means we consider the next occurrence today, not tomorrow.
    FOR i IN 0..6 LOOP
      days_from_now := i;
      EXIT WHEN on_day(mod(from_wday + days_from_now, 7), schedule_rule);
    END LOOP;

    return from_date + days_from_now;
  WHEN 'fortnightly' THEN
  -- ==================== FORTNIGHTLY ====================
    -- Loop until we find the next occurrence
    -- The '1' in 1..14 means we consider the next occurrence tomorrow, not today and we check a full fortnightly cycle
    FOR i IN 0..13 LOOP
      days_from_now := i;
      EXIT WHEN on_day(mod(from_wday + days_from_now, 7), schedule_rule) AND
        ((((from_date + days_from_now) - (schedule_rule.start - CAST(EXTRACT(DOW from schedule_rule.start) AS integer))) / 7) % 2) = 0;
    END LOOP;

    return from_date + days_from_now;
  WHEN 'monthly' THEN
  -- ==================== MONTHLY ====================
    -- The first day of the month
    next_date := DATE_TRUNC('month', from_date);

    -- Number of week days (Mondays, Tuesdays and so on)
    week_days := array[0,0,0,0,0,0,0];

    LOOP
      IF next_date >= from_date AND
        -- Delivery day?
        on_day(EXTRACT(DOW FROM next_date)::integer, schedule_rule) AND
        -- Desired nth week day of the month?
        week_days[EXTRACT(DOW FROM next_date)::integer + 1] = schedule_rule.week THEN
        RETURN next_date;
      END IF;

      -- Count the number of week days
      week_days[EXTRACT(DOW FROM next_date)::integer + 1] := week_days[EXTRACT(DOW FROM next_date)::integer + 1] + 1;

      -- Next day
      next_date := next_date + 1;

      -- Reset counters if we hit next month
      IF EXTRACT(DAY FROM next_date)::integer = 1 THEN
        week_days := array[0,0,0,0,0,0,0];
      END IF;
    END LOOP;
  ELSE
    IF schedule_rule.recur IS NULL OR schedule_rule.recur = 'single' THEN
  -- ==================== ONE OFF / SINGLE ====================
      IF from_date > schedule_rule.start THEN
        return NULL;
      ELSE
        RETURN from_date;
      END IF;
    ELSE
      RAISE EXCEPTION 'schedule_rules.recur should be NULL, single, weekly, fortnightly or monthly';
  END IF;
  END CASE;

END;
$$;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE accounts (
    id integer NOT NULL,
    customer_id integer,
    balance_cents integer DEFAULT 0 NOT NULL,
    currency character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE accounts_id_seq OWNED BY accounts.id;


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE addresses (
    id integer NOT NULL,
    customer_id integer,
    address_1 character varying(255),
    address_2 character varying(255),
    suburb character varying(255),
    city character varying(255),
    postcode character varying(255),
    delivery_note text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    mobile_phone character varying(255),
    home_phone character varying(255),
    work_phone character varying(255),
    address_hash character varying(255)
);


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE addresses_id_seq OWNED BY addresses.id;


--
-- Name: admins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE admins (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(128) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE admins_id_seq OWNED BY admins.id;


--
-- Name: bank_information; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bank_information (
    id integer NOT NULL,
    distributor_id integer,
    name character varying(255),
    account_name character varying(255),
    account_number character varying(255),
    customer_message text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    bsb_number character varying(255),
    cod_payment_message text
);


--
-- Name: bank_information_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bank_information_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bank_information_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bank_information_id_seq OWNED BY bank_information.id;


--
-- Name: bank_statements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bank_statements (
    id integer NOT NULL,
    distributor_id integer,
    statement_file character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bank_statements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bank_statements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bank_statements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bank_statements_id_seq OWNED BY bank_statements.id;


--
-- Name: box_extras; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE box_extras (
    id integer NOT NULL,
    box_id integer,
    extra_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: box_extras_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE box_extras_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: box_extras_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE box_extras_id_seq OWNED BY box_extras.id;


--
-- Name: boxes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE boxes (
    id integer NOT NULL,
    distributor_id integer,
    name character varying(255),
    description text,
    likes boolean DEFAULT false NOT NULL,
    dislikes boolean DEFAULT false NOT NULL,
    price_cents integer DEFAULT 0 NOT NULL,
    currency character varying(255),
    available_single boolean DEFAULT false NOT NULL,
    available_weekly boolean DEFAULT false NOT NULL,
    available_fourtnightly boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    box_image character varying(255),
    available_monthly boolean DEFAULT false NOT NULL,
    extras_limit integer DEFAULT 0,
    hidden boolean DEFAULT false NOT NULL,
    exclusions_limit integer DEFAULT 0,
    substitutions_limit integer DEFAULT 0
);


--
-- Name: boxes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE boxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE boxes_id_seq OWNED BY boxes.id;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE countries (
    id integer NOT NULL,
    default_consumer_fee_cents integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    alpha2 character varying(2) DEFAULT ''::character varying NOT NULL
);


--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE countries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE countries_id_seq OWNED BY countries.id;


--
-- Name: credit_card_transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE credit_card_transactions (
    id integer NOT NULL,
    amount integer,
    success boolean,
    reference character varying(255),
    message character varying(255),
    action character varying(255),
    params text,
    test boolean,
    distributor_id integer,
    account_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: credit_card_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE credit_card_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: credit_card_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE credit_card_transactions_id_seq OWNED BY credit_card_transactions.id;


--
-- Name: cron_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cron_logs (
    id integer NOT NULL,
    log text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    details text
);


--
-- Name: cron_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cron_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cron_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cron_logs_id_seq OWNED BY cron_logs.id;


--
-- Name: customer_checkouts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE customer_checkouts (
    id integer NOT NULL,
    distributor_id integer,
    customer_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: customer_checkouts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE customer_checkouts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_checkouts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE customer_checkouts_id_seq OWNED BY customer_checkouts.id;


--
-- Name: customer_logins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE customer_logins (
    id integer NOT NULL,
    distributor_id integer,
    customer_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: customer_logins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE customer_logins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_logins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE customer_logins_id_seq OWNED BY customer_logins.id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE customers (
    id integer NOT NULL,
    first_name character varying(255),
    email character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    last_name character varying(255),
    distributor_id integer,
    route_id integer,
    encrypted_password character varying(128) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    password_salt character varying(255),
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    failed_attempts integer DEFAULT 0,
    unlock_token character varying(255),
    locked_at timestamp without time zone,
    authentication_token character varying(255),
    discount numeric DEFAULT 0 NOT NULL,
    number integer,
    notes text,
    special_order_preference text,
    next_order_id integer,
    next_order_occurrence_date date,
    balance_threshold_cents integer,
    status_halted boolean DEFAULT false,
    via_webstore boolean DEFAULT false
);


--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE customers_id_seq OWNED BY customers.id;


--
-- Name: deductions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE deductions (
    id integer NOT NULL,
    distributor_id integer,
    account_id integer DEFAULT 0 NOT NULL,
    amount_cents integer DEFAULT 0 NOT NULL,
    currency character varying(255),
    kind character varying(255),
    description text,
    reversed boolean,
    reversed_at timestamp without time zone,
    transaction_id integer,
    reversal_transaction_id integer,
    source character varying(255),
    deductable_id integer,
    deductable_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    display_time timestamp without time zone
);


--
-- Name: deductions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deductions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deductions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deductions_id_seq OWNED BY deductions.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    queue character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: deliveries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE deliveries (
    id integer NOT NULL,
    order_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    status character varying(255),
    route_id integer,
    status_change_type character varying(255),
    delivery_list_id integer,
    "position" integer,
    package_id integer,
    delivery_number integer,
    dso integer DEFAULT (-1)
);


--
-- Name: deliveries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deliveries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deliveries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deliveries_id_seq OWNED BY deliveries.id;


--
-- Name: delivery_lists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delivery_lists (
    id integer NOT NULL,
    distributor_id integer,
    date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: delivery_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delivery_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delivery_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delivery_lists_id_seq OWNED BY delivery_lists.id;


--
-- Name: delivery_sequence_orders; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delivery_sequence_orders (
    id integer NOT NULL,
    address_hash character varying(255),
    route_id integer,
    day integer,
    "position" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: delivery_sequence_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delivery_sequence_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delivery_sequence_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delivery_sequence_orders_id_seq OWNED BY delivery_sequence_orders.id;


--
-- Name: distributor_gateways; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE distributor_gateways (
    id integer NOT NULL,
    distributor_id integer,
    gateway_id integer,
    encrypted_login text,
    encrypted_login_salt text,
    encrypted_login_iv text,
    encrypted_password text,
    encrypted_password_salt text,
    encrypted_password_iv text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: distributor_gateways_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE distributor_gateways_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: distributor_gateways_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE distributor_gateways_id_seq OWNED BY distributor_gateways.id;


--
-- Name: distributor_logins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE distributor_logins (
    id integer NOT NULL,
    distributor_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: distributor_logins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE distributor_logins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: distributor_logins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE distributor_logins_id_seq OWNED BY distributor_logins.id;


--
-- Name: distributor_metrics; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE distributor_metrics (
    id integer NOT NULL,
    distributor_id integer,
    distributor_logins integer,
    new_customers integer,
    deliveries_completed integer,
    customer_payments integer,
    webstore_checkouts integer,
    customer_logins integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: distributor_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE distributor_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: distributor_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE distributor_metrics_id_seq OWNED BY distributor_metrics.id;


--
-- Name: distributors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE distributors (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(128) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    password_salt character varying(255),
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    failed_attempts integer DEFAULT 0,
    unlock_token character varying(255),
    locked_at timestamp without time zone,
    authentication_token character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying(255),
    url character varying(255),
    company_logo character varying(255),
    completed_wizard boolean DEFAULT false NOT NULL,
    parameter_name character varying(255),
    invoice_threshold_cents integer DEFAULT 0 NOT NULL,
    bucky_box_percentage numeric NOT NULL,
    separate_bucky_fee boolean DEFAULT false,
    support_email character varying(255),
    time_zone character varying(255),
    advance_hour integer,
    advance_days integer,
    automatic_delivery_hour integer,
    currency character varying(255),
    country_id integer,
    consumer_delivery_fee_cents integer,
    active_webstore boolean DEFAULT false NOT NULL,
    city character varying(255),
    company_team_image character varying(255),
    about text,
    details text,
    facebook_url character varying(255),
    customers_show_intro boolean DEFAULT true NOT NULL,
    deliveries_index_packing_intro boolean DEFAULT true NOT NULL,
    deliveries_index_deliveries_intro boolean DEFAULT true NOT NULL,
    payments_index_intro boolean DEFAULT true NOT NULL,
    customers_index_intro boolean DEFAULT true NOT NULL,
    has_balance_threshold boolean DEFAULT false,
    default_balance_threshold_cents integer DEFAULT 0,
    send_email boolean DEFAULT true,
    send_halted_email boolean,
    feature_spend_limit boolean DEFAULT true,
    contact_name character varying(255),
    customer_can_remove_orders boolean DEFAULT true,
    collect_phone boolean,
    last_seen_at timestamp without time zone,
    notes text,
    payment_cash_on_delivery boolean DEFAULT true,
    payment_bank_deposit boolean DEFAULT true,
    payment_credit_card boolean DEFAULT false,
    require_postcode boolean DEFAULT false NOT NULL,
    require_phone boolean DEFAULT false NOT NULL,
    require_address_1 boolean DEFAULT true NOT NULL,
    require_address_2 boolean DEFAULT false NOT NULL,
    require_suburb boolean DEFAULT false NOT NULL,
    require_city boolean DEFAULT false NOT NULL,
    keep_me_updated boolean DEFAULT true,
    email_templates text,
    phone character varying(255)
);


--
-- Name: distributors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE distributors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: distributors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE distributors_id_seq OWNED BY distributors.id;


--
-- Name: distributors_omni_importers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE distributors_omni_importers (
    id integer NOT NULL,
    distributor_id integer,
    omni_importer_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: distributors_omni_importers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE distributors_omni_importers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: distributors_omni_importers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE distributors_omni_importers_id_seq OWNED BY distributors_omni_importers.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE events (
    id integer NOT NULL,
    distributor_id integer NOT NULL,
    event_category character varying(255) NOT NULL,
    event_type character varying(255) NOT NULL,
    customer_id integer,
    invoice_id integer,
    reconciliation_id integer,
    transaction_id integer,
    delivery_id integer,
    dismissed boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    trigger_on timestamp without time zone
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_id_seq OWNED BY events.id;


--
-- Name: exclusions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE exclusions (
    id integer NOT NULL,
    order_id integer,
    line_item_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: exclusions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE exclusions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exclusions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE exclusions_id_seq OWNED BY exclusions.id;


--
-- Name: extras; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE extras (
    id integer NOT NULL,
    name character varying(255),
    unit character varying(255),
    distributor_id integer,
    price_cents integer DEFAULT 0 NOT NULL,
    currency character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    hidden boolean DEFAULT false
);


--
-- Name: extras_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE extras_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: extras_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE extras_id_seq OWNED BY extras.id;


--
-- Name: gateways; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gateways (
    id integer NOT NULL,
    name character varying(255),
    klass character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: gateways_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gateways_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gateways_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gateways_id_seq OWNED BY gateways.id;


--
-- Name: import_transaction_lists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE import_transaction_lists (
    id integer NOT NULL,
    distributor_id integer,
    draft boolean,
    account_type integer,
    csv_file text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    omni_importer_id integer
);


--
-- Name: import_transaction_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE import_transaction_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: import_transaction_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE import_transaction_lists_id_seq OWNED BY import_transaction_lists.id;


--
-- Name: import_transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE import_transactions (
    id integer NOT NULL,
    customer_id integer,
    transaction_date date,
    amount_cents integer DEFAULT 0 NOT NULL,
    removed boolean,
    description text,
    confidence double precision,
    import_transaction_list_id integer,
    match integer,
    transaction_id integer,
    draft boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    payment_id integer,
    raw_data text
);


--
-- Name: import_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE import_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: import_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE import_transactions_id_seq OWNED BY import_transactions.id;


--
-- Name: invoice_information; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invoice_information (
    id integer NOT NULL,
    distributor_id integer,
    gst_number character varying(255),
    billing_address_1 character varying(255),
    billing_address_2 character varying(255),
    billing_suburb character varying(255),
    billing_city character varying(255),
    billing_postcode character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    phone character varying(255)
);


--
-- Name: invoice_information_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invoice_information_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoice_information_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invoice_information_id_seq OWNED BY invoice_information.id;


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invoices (
    id integer NOT NULL,
    account_id integer,
    number integer,
    amount_cents integer DEFAULT 0 NOT NULL,
    balance_cents integer DEFAULT 0 NOT NULL,
    currency character varying(255),
    date date,
    start_date date,
    end_date date,
    transactions text,
    deliveries text,
    paid boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invoices_id_seq OWNED BY invoices.id;


--
-- Name: line_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE line_items (
    id integer NOT NULL,
    distributor_id integer,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: line_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE line_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: line_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE line_items_id_seq OWNED BY line_items.id;


--
-- Name: localised_addresses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE localised_addresses (
    id integer NOT NULL,
    addressable_id integer NOT NULL,
    addressable_type character varying(255) NOT NULL,
    street character varying(255),
    city character varying(255),
    zip character varying(255),
    state character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: localised_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE localised_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: localised_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE localised_addresses_id_seq OWNED BY localised_addresses.id;


--
-- Name: omni_importers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE omni_importers (
    id integer NOT NULL,
    country_id integer,
    rules text,
    import_transaction_list character varying(255),
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    payment_type character varying(255)
);


--
-- Name: omni_importers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE omni_importers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: omni_importers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE omni_importers_id_seq OWNED BY omni_importers.id;


--
-- Name: order_extras; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE order_extras (
    id integer NOT NULL,
    order_id integer,
    extra_id integer,
    count integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: order_extras_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE order_extras_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_extras_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE order_extras_id_seq OWNED BY order_extras.id;


--
-- Name: order_schedule_transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE order_schedule_transactions (
    id integer NOT NULL,
    order_id integer,
    schedule text,
    delivery_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: order_schedule_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE order_schedule_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_schedule_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE order_schedule_transactions_id_seq OWNED BY order_schedule_transactions.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE orders (
    id integer NOT NULL,
    box_id integer,
    quantity integer DEFAULT 1 NOT NULL,
    completed boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    account_id integer,
    active boolean DEFAULT false NOT NULL,
    extras_one_off boolean DEFAULT true,
    extras_packing_list_id integer
);


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE orders_id_seq OWNED BY orders.id;


--
-- Name: packages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE packages (
    id integer NOT NULL,
    packing_list_id integer,
    "position" integer,
    status character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    order_id integer,
    original_package_id integer,
    packing_method character varying(255),
    archived_address text,
    archived_order_quantity integer,
    archived_box_name character varying(255),
    archived_box_price_cents integer DEFAULT 0 NOT NULL,
    currency character varying(255),
    archived_customer_name character varying(255),
    archived_route_fee_cents integer DEFAULT 0 NOT NULL,
    archived_customer_discount numeric DEFAULT 0 NOT NULL,
    archived_extras text,
    archived_consumer_delivery_fee_cents integer DEFAULT 0,
    archived_substitutions text,
    archived_exclusions text,
    archived_address_details text
);


--
-- Name: packages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE packages_id_seq OWNED BY packages.id;


--
-- Name: packing_lists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE packing_lists (
    id integer NOT NULL,
    distributor_id integer,
    date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: packing_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE packing_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: packing_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE packing_lists_id_seq OWNED BY packing_lists.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE payments (
    id integer NOT NULL,
    distributor_id integer,
    account_id integer,
    amount_cents integer DEFAULT 0 NOT NULL,
    currency character varying(255),
    kind character varying(255),
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    reference character varying(255),
    reversed boolean,
    reversed_at timestamp without time zone,
    transaction_id integer,
    reversal_transaction_id integer,
    source character varying(255),
    display_time timestamp without time zone,
    payable_id integer,
    payable_type character varying(255)
);


--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE payments_id_seq OWNED BY payments.id;


--
-- Name: route_schedule_transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE route_schedule_transactions (
    id integer NOT NULL,
    route_id integer,
    schedule text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: route_schedule_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE route_schedule_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: route_schedule_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE route_schedule_transactions_id_seq OWNED BY route_schedule_transactions.id;


--
-- Name: routes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE routes (
    id integer NOT NULL,
    distributor_id integer,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    fee_cents integer DEFAULT 0 NOT NULL,
    currency character varying(255),
    area_of_service text,
    estimated_delivery_time text
);


--
-- Name: routes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: routes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE routes_id_seq OWNED BY routes.id;


--
-- Name: schedule_pauses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schedule_pauses (
    id integer NOT NULL,
    start date,
    finish date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schedule_pauses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE schedule_pauses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedule_pauses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE schedule_pauses_id_seq OWNED BY schedule_pauses.id;


--
-- Name: schedule_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE schedule_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedule_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE schedule_rules_id_seq OWNED BY schedule_rules.id;


--
-- Name: schedule_transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schedule_transactions (
    id integer NOT NULL,
    schedule_rule text,
    schedule_rule_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schedule_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE schedule_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedule_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE schedule_transactions_id_seq OWNED BY schedule_transactions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: substitutions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE substitutions (
    id integer NOT NULL,
    order_id integer,
    line_item_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: substitutions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE substitutions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: substitutions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE substitutions_id_seq OWNED BY substitutions.id;


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_id integer,
    taggable_type character varying(255),
    tagger_id integer,
    tagger_type character varying(255),
    context character varying(255),
    created_at timestamp without time zone
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE taggings_id_seq OWNED BY taggings.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tags_id_seq OWNED BY tags.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE transactions (
    id integer NOT NULL,
    account_id integer,
    amount_cents integer DEFAULT 0 NOT NULL,
    currency character varying(255),
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    display_time timestamp without time zone,
    transactionable_id integer,
    transactionable_type character varying(255),
    reverse_transactionable_id integer,
    reverse_transactionable_type character varying(255)
);


--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transactions_id_seq OWNED BY transactions.id;


--
-- Name: webstore_orders; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE webstore_orders (
    id integer NOT NULL,
    account_id integer,
    box_id integer,
    order_id integer,
    exclusions text,
    substitutions text,
    extras text,
    status character varying(255),
    remote_ip character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    schedule text,
    frequency character varying(255),
    extras_one_off boolean,
    distributor_id integer,
    route_id integer,
    payment_method character varying(255)
);


--
-- Name: webstore_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE webstore_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: webstore_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE webstore_orders_id_seq OWNED BY webstore_orders.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts ALTER COLUMN id SET DEFAULT nextval('accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY admins ALTER COLUMN id SET DEFAULT nextval('admins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_information ALTER COLUMN id SET DEFAULT nextval('bank_information_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_statements ALTER COLUMN id SET DEFAULT nextval('bank_statements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY box_extras ALTER COLUMN id SET DEFAULT nextval('box_extras_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY boxes ALTER COLUMN id SET DEFAULT nextval('boxes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY countries ALTER COLUMN id SET DEFAULT nextval('countries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY credit_card_transactions ALTER COLUMN id SET DEFAULT nextval('credit_card_transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cron_logs ALTER COLUMN id SET DEFAULT nextval('cron_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY customer_checkouts ALTER COLUMN id SET DEFAULT nextval('customer_checkouts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY customer_logins ALTER COLUMN id SET DEFAULT nextval('customer_logins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY customers ALTER COLUMN id SET DEFAULT nextval('customers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deductions ALTER COLUMN id SET DEFAULT nextval('deductions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deliveries ALTER COLUMN id SET DEFAULT nextval('deliveries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delivery_lists ALTER COLUMN id SET DEFAULT nextval('delivery_lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delivery_sequence_orders ALTER COLUMN id SET DEFAULT nextval('delivery_sequence_orders_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY distributor_gateways ALTER COLUMN id SET DEFAULT nextval('distributor_gateways_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY distributor_logins ALTER COLUMN id SET DEFAULT nextval('distributor_logins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY distributor_metrics ALTER COLUMN id SET DEFAULT nextval('distributor_metrics_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY distributors ALTER COLUMN id SET DEFAULT nextval('distributors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY distributors_omni_importers ALTER COLUMN id SET DEFAULT nextval('distributors_omni_importers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY exclusions ALTER COLUMN id SET DEFAULT nextval('exclusions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY extras ALTER COLUMN id SET DEFAULT nextval('extras_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gateways ALTER COLUMN id SET DEFAULT nextval('gateways_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_transaction_lists ALTER COLUMN id SET DEFAULT nextval('import_transaction_lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_transactions ALTER COLUMN id SET DEFAULT nextval('import_transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY invoice_information ALTER COLUMN id SET DEFAULT nextval('invoice_information_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY invoices ALTER COLUMN id SET DEFAULT nextval('invoices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY line_items ALTER COLUMN id SET DEFAULT nextval('line_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY localised_addresses ALTER COLUMN id SET DEFAULT nextval('localised_addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY omni_importers ALTER COLUMN id SET DEFAULT nextval('omni_importers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY order_extras ALTER COLUMN id SET DEFAULT nextval('order_extras_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY order_schedule_transactions ALTER COLUMN id SET DEFAULT nextval('order_schedule_transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY orders ALTER COLUMN id SET DEFAULT nextval('orders_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY packages ALTER COLUMN id SET DEFAULT nextval('packages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY packing_lists ALTER COLUMN id SET DEFAULT nextval('packing_lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY payments ALTER COLUMN id SET DEFAULT nextval('payments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY route_schedule_transactions ALTER COLUMN id SET DEFAULT nextval('route_schedule_transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY routes ALTER COLUMN id SET DEFAULT nextval('routes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY schedule_pauses ALTER COLUMN id SET DEFAULT nextval('schedule_pauses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY schedule_rules ALTER COLUMN id SET DEFAULT nextval('schedule_rules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY schedule_transactions ALTER COLUMN id SET DEFAULT nextval('schedule_transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY substitutions ALTER COLUMN id SET DEFAULT nextval('substitutions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY taggings ALTER COLUMN id SET DEFAULT nextval('taggings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY transactions ALTER COLUMN id SET DEFAULT nextval('transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY webstore_orders ALTER COLUMN id SET DEFAULT nextval('webstore_orders_id_seq'::regclass);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: bank_information_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bank_information
    ADD CONSTRAINT bank_information_pkey PRIMARY KEY (id);


--
-- Name: bank_statements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bank_statements
    ADD CONSTRAINT bank_statements_pkey PRIMARY KEY (id);


--
-- Name: box_extras_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY box_extras
    ADD CONSTRAINT box_extras_pkey PRIMARY KEY (id);


--
-- Name: boxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boxes
    ADD CONSTRAINT boxes_pkey PRIMARY KEY (id);


--
-- Name: countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: credit_card_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY credit_card_transactions
    ADD CONSTRAINT credit_card_transactions_pkey PRIMARY KEY (id);


--
-- Name: cron_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cron_logs
    ADD CONSTRAINT cron_logs_pkey PRIMARY KEY (id);


--
-- Name: customer_checkouts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY customer_checkouts
    ADD CONSTRAINT customer_checkouts_pkey PRIMARY KEY (id);


--
-- Name: customer_logins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY customer_logins
    ADD CONSTRAINT customer_logins_pkey PRIMARY KEY (id);


--
-- Name: customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: deductions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY deductions
    ADD CONSTRAINT deductions_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY deliveries
    ADD CONSTRAINT deliveries_pkey PRIMARY KEY (id);


--
-- Name: delivery_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delivery_lists
    ADD CONSTRAINT delivery_lists_pkey PRIMARY KEY (id);


--
-- Name: delivery_sequence_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delivery_sequence_orders
    ADD CONSTRAINT delivery_sequence_orders_pkey PRIMARY KEY (id);


--
-- Name: distributor_gateways_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY distributor_gateways
    ADD CONSTRAINT distributor_gateways_pkey PRIMARY KEY (id);


--
-- Name: distributor_logins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY distributor_logins
    ADD CONSTRAINT distributor_logins_pkey PRIMARY KEY (id);


--
-- Name: distributor_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY distributor_metrics
    ADD CONSTRAINT distributor_metrics_pkey PRIMARY KEY (id);


--
-- Name: distributors_omni_importers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY distributors_omni_importers
    ADD CONSTRAINT distributors_omni_importers_pkey PRIMARY KEY (id);


--
-- Name: distributors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY distributors
    ADD CONSTRAINT distributors_pkey PRIMARY KEY (id);


--
-- Name: events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: exclusions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY exclusions
    ADD CONSTRAINT exclusions_pkey PRIMARY KEY (id);


--
-- Name: extras_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY extras
    ADD CONSTRAINT extras_pkey PRIMARY KEY (id);


--
-- Name: gateways_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY gateways
    ADD CONSTRAINT gateways_pkey PRIMARY KEY (id);


--
-- Name: import_transaction_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY import_transaction_lists
    ADD CONSTRAINT import_transaction_lists_pkey PRIMARY KEY (id);


--
-- Name: import_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY import_transactions
    ADD CONSTRAINT import_transactions_pkey PRIMARY KEY (id);


--
-- Name: invoice_information_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY invoice_information
    ADD CONSTRAINT invoice_information_pkey PRIMARY KEY (id);


--
-- Name: invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: line_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY line_items
    ADD CONSTRAINT line_items_pkey PRIMARY KEY (id);


--
-- Name: localised_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY localised_addresses
    ADD CONSTRAINT localised_addresses_pkey PRIMARY KEY (id);


--
-- Name: omni_importers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY omni_importers
    ADD CONSTRAINT omni_importers_pkey PRIMARY KEY (id);


--
-- Name: order_extras_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY order_extras
    ADD CONSTRAINT order_extras_pkey PRIMARY KEY (id);


--
-- Name: order_schedule_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY order_schedule_transactions
    ADD CONSTRAINT order_schedule_transactions_pkey PRIMARY KEY (id);


--
-- Name: orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY packages
    ADD CONSTRAINT packages_pkey PRIMARY KEY (id);


--
-- Name: packing_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY packing_lists
    ADD CONSTRAINT packing_lists_pkey PRIMARY KEY (id);


--
-- Name: payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: route_schedule_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY route_schedule_transactions
    ADD CONSTRAINT route_schedule_transactions_pkey PRIMARY KEY (id);


--
-- Name: routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY routes
    ADD CONSTRAINT routes_pkey PRIMARY KEY (id);


--
-- Name: schedule_pauses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schedule_pauses
    ADD CONSTRAINT schedule_pauses_pkey PRIMARY KEY (id);


--
-- Name: schedule_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schedule_rules
    ADD CONSTRAINT schedule_rules_pkey PRIMARY KEY (id);


--
-- Name: schedule_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schedule_transactions
    ADD CONSTRAINT schedule_transactions_pkey PRIMARY KEY (id);


--
-- Name: substitutions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY substitutions
    ADD CONSTRAINT substitutions_pkey PRIMARY KEY (id);


--
-- Name: taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: webstore_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY webstore_orders
    ADD CONSTRAINT webstore_orders_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX delayed_jobs_priority ON delayed_jobs USING btree (priority, run_at);


--
-- Name: index_accounts_on_customer_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_accounts_on_customer_id ON accounts USING btree (customer_id);


--
-- Name: index_addresses_on_address_hash; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_addresses_on_address_hash ON addresses USING btree (address_hash);


--
-- Name: index_addresses_on_customer_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_addresses_on_customer_id ON addresses USING btree (customer_id);


--
-- Name: index_admins_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_admins_on_email ON admins USING btree (email);


--
-- Name: index_admins_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_admins_on_reset_password_token ON admins USING btree (reset_password_token);


--
-- Name: index_bank_information_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_bank_information_on_distributor_id ON bank_information USING btree (distributor_id);


--
-- Name: index_bank_statements_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_bank_statements_on_distributor_id ON bank_statements USING btree (distributor_id);


--
-- Name: index_boxes_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_boxes_on_distributor_id ON boxes USING btree (distributor_id);


--
-- Name: index_countries_on_alpha2; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_countries_on_alpha2 ON countries USING btree (alpha2);


--
-- Name: index_customers_on_authentication_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_customers_on_authentication_token ON customers USING btree (authentication_token);


--
-- Name: index_customers_on_confirmation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_customers_on_confirmation_token ON customers USING btree (confirmation_token);


--
-- Name: index_customers_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_customers_on_email ON customers USING btree (email);


--
-- Name: index_customers_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_customers_on_reset_password_token ON customers USING btree (reset_password_token);


--
-- Name: index_customers_on_route_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_customers_on_route_id ON customers USING btree (route_id);


--
-- Name: index_customers_on_unlock_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_customers_on_unlock_token ON customers USING btree (unlock_token);


--
-- Name: index_deductions_on_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_deductions_on_account_id ON deductions USING btree (account_id);


--
-- Name: index_deductions_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_deductions_on_distributor_id ON deductions USING btree (distributor_id);


--
-- Name: index_deliveries_on_delivery_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_deliveries_on_delivery_list_id ON deliveries USING btree (delivery_list_id);


--
-- Name: index_deliveries_on_package_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_deliveries_on_package_id ON deliveries USING btree (package_id);


--
-- Name: index_deliveries_on_route_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_deliveries_on_route_id ON deliveries USING btree (route_id);


--
-- Name: index_delivery_lists_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_delivery_lists_on_distributor_id ON delivery_lists USING btree (distributor_id);


--
-- Name: index_distributors_on_authentication_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_distributors_on_authentication_token ON distributors USING btree (authentication_token);


--
-- Name: index_distributors_on_confirmation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_distributors_on_confirmation_token ON distributors USING btree (confirmation_token);


--
-- Name: index_distributors_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_distributors_on_email ON distributors USING btree (email);


--
-- Name: index_distributors_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_distributors_on_reset_password_token ON distributors USING btree (reset_password_token);


--
-- Name: index_distributors_on_unlock_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_distributors_on_unlock_token ON distributors USING btree (unlock_token);


--
-- Name: index_events_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_events_on_distributor_id ON events USING btree (distributor_id);


--
-- Name: index_exclusions_on_line_item_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_exclusions_on_line_item_id ON exclusions USING btree (line_item_id);


--
-- Name: index_exclusions_on_order_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_exclusions_on_order_id ON exclusions USING btree (order_id);


--
-- Name: index_import_draft; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_import_draft ON import_transactions USING btree (import_transaction_list_id, draft);


--
-- Name: index_import_match; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_import_match ON import_transactions USING btree (import_transaction_list_id, match);


--
-- Name: index_import_removed; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_import_removed ON import_transactions USING btree (import_transaction_list_id, removed);


--
-- Name: index_import_transaction_lists_on_distributor_id_and_draft; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_import_transaction_lists_on_distributor_id_and_draft ON import_transaction_lists USING btree (distributor_id, draft);


--
-- Name: index_import_transactions_on_import_transaction_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_import_transactions_on_import_transaction_list_id ON import_transactions USING btree (import_transaction_list_id);


--
-- Name: index_invoice_information_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invoice_information_on_distributor_id ON invoice_information USING btree (distributor_id);


--
-- Name: index_line_items_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_line_items_on_distributor_id ON line_items USING btree (distributor_id);


--
-- Name: index_order_schedule_transactions_on_delivery_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_order_schedule_transactions_on_delivery_id ON order_schedule_transactions USING btree (delivery_id);


--
-- Name: index_order_schedule_transactions_on_order_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_order_schedule_transactions_on_order_id ON order_schedule_transactions USING btree (order_id);


--
-- Name: index_orders_on_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_orders_on_account_id ON orders USING btree (account_id);


--
-- Name: index_orders_on_box_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_orders_on_box_id ON orders USING btree (box_id);


--
-- Name: index_packages_on_order_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_packages_on_order_id ON packages USING btree (order_id);


--
-- Name: index_packages_on_original_package_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_packages_on_original_package_id ON packages USING btree (original_package_id);


--
-- Name: index_packages_on_packing_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_packages_on_packing_list_id ON packages USING btree (packing_list_id);


--
-- Name: index_packing_lists_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_packing_lists_on_distributor_id ON packing_lists USING btree (distributor_id);


--
-- Name: index_payments_on_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_payments_on_account_id ON payments USING btree (account_id);


--
-- Name: index_payments_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_payments_on_distributor_id ON payments USING btree (distributor_id);


--
-- Name: index_route_schedule_transactions_on_route_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_route_schedule_transactions_on_route_id ON route_schedule_transactions USING btree (route_id);


--
-- Name: index_routes_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_routes_on_distributor_id ON routes USING btree (distributor_id);


--
-- Name: index_substitutions_on_line_item_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_substitutions_on_line_item_id ON substitutions USING btree (line_item_id);


--
-- Name: index_substitutions_on_order_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_substitutions_on_order_id ON substitutions USING btree (order_id);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_taggings_on_tag_id ON taggings USING btree (tag_id);


--
-- Name: index_taggings_on_taggable_id_and_taggable_type_and_context; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_taggings_on_taggable_id_and_taggable_type_and_context ON taggings USING btree (taggable_id, taggable_type, context);


--
-- Name: index_transactions_on_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transactions_on_account_id ON transactions USING btree (account_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20111129095356');

INSERT INTO schema_migrations (version) VALUES ('20111130231744');

INSERT INTO schema_migrations (version) VALUES ('20111201005231');

INSERT INTO schema_migrations (version) VALUES ('20111201065712');

INSERT INTO schema_migrations (version) VALUES ('20111201080900');

INSERT INTO schema_migrations (version) VALUES ('20111201095437');

INSERT INTO schema_migrations (version) VALUES ('20111202014435');

INSERT INTO schema_migrations (version) VALUES ('20111202030831');

INSERT INTO schema_migrations (version) VALUES ('20111202203846');

INSERT INTO schema_migrations (version) VALUES ('20111202223623');

INSERT INTO schema_migrations (version) VALUES ('20111203023947');

INSERT INTO schema_migrations (version) VALUES ('20111203043450');

INSERT INTO schema_migrations (version) VALUES ('20111203044422');

INSERT INTO schema_migrations (version) VALUES ('20111203124951');

INSERT INTO schema_migrations (version) VALUES ('20111205001329');

INSERT INTO schema_migrations (version) VALUES ('20111205004252');

INSERT INTO schema_migrations (version) VALUES ('20111205005039');

INSERT INTO schema_migrations (version) VALUES ('20111205082509');

INSERT INTO schema_migrations (version) VALUES ('20111205230751');

INSERT INTO schema_migrations (version) VALUES ('20111213104609');

INSERT INTO schema_migrations (version) VALUES ('20111216002214');

INSERT INTO schema_migrations (version) VALUES ('20111216003519');

INSERT INTO schema_migrations (version) VALUES ('20111216041303');

INSERT INTO schema_migrations (version) VALUES ('20111216044030');

INSERT INTO schema_migrations (version) VALUES ('20111216112600');

INSERT INTO schema_migrations (version) VALUES ('20111218221013');

INSERT INTO schema_migrations (version) VALUES ('20111219234909');

INSERT INTO schema_migrations (version) VALUES ('20111220042841');

INSERT INTO schema_migrations (version) VALUES ('20111220115128');

INSERT INTO schema_migrations (version) VALUES ('20111228012130');

INSERT INTO schema_migrations (version) VALUES ('20120104235552');

INSERT INTO schema_migrations (version) VALUES ('20120108085002');

INSERT INTO schema_migrations (version) VALUES ('20120110034608');

INSERT INTO schema_migrations (version) VALUES ('20120110035632');

INSERT INTO schema_migrations (version) VALUES ('20120110113524');

INSERT INTO schema_migrations (version) VALUES ('20120114105104');

INSERT INTO schema_migrations (version) VALUES ('20120114115648');

INSERT INTO schema_migrations (version) VALUES ('20120115034534');

INSERT INTO schema_migrations (version) VALUES ('20120119010559');

INSERT INTO schema_migrations (version) VALUES ('20120119011621');

INSERT INTO schema_migrations (version) VALUES ('20120119034927');

INSERT INTO schema_migrations (version) VALUES ('20120119234154');

INSERT INTO schema_migrations (version) VALUES ('20120119234748');

INSERT INTO schema_migrations (version) VALUES ('20120120001658');

INSERT INTO schema_migrations (version) VALUES ('20120120020534');

INSERT INTO schema_migrations (version) VALUES ('20120123215057');

INSERT INTO schema_migrations (version) VALUES ('20120124085202');

INSERT INTO schema_migrations (version) VALUES ('20120124100740');

INSERT INTO schema_migrations (version) VALUES ('20120124215818');

INSERT INTO schema_migrations (version) VALUES ('20120124224311');

INSERT INTO schema_migrations (version) VALUES ('20120124224707');

INSERT INTO schema_migrations (version) VALUES ('20120125020712');

INSERT INTO schema_migrations (version) VALUES ('20120126102057');

INSERT INTO schema_migrations (version) VALUES ('20120129003124');

INSERT INTO schema_migrations (version) VALUES ('20120129041416');

INSERT INTO schema_migrations (version) VALUES ('20120129220207');

INSERT INTO schema_migrations (version) VALUES ('20120130030201');

INSERT INTO schema_migrations (version) VALUES ('20120131081149');

INSERT INTO schema_migrations (version) VALUES ('20120201002517');

INSERT INTO schema_migrations (version) VALUES ('20120201233808');

INSERT INTO schema_migrations (version) VALUES ('20120202022849');

INSERT INTO schema_migrations (version) VALUES ('20120207040356');

INSERT INTO schema_migrations (version) VALUES ('20120215011432');

INSERT INTO schema_migrations (version) VALUES ('20120215013339');

INSERT INTO schema_migrations (version) VALUES ('20120215013725');

INSERT INTO schema_migrations (version) VALUES ('20120216100258');

INSERT INTO schema_migrations (version) VALUES ('20120223062300');

INSERT INTO schema_migrations (version) VALUES ('20120223234648');

INSERT INTO schema_migrations (version) VALUES ('20120226211014');

INSERT INTO schema_migrations (version) VALUES ('20120227092736');

INSERT INTO schema_migrations (version) VALUES ('20120228003940');

INSERT INTO schema_migrations (version) VALUES ('20120228033613');

INSERT INTO schema_migrations (version) VALUES ('20120228081323');

INSERT INTO schema_migrations (version) VALUES ('20120228210358');

INSERT INTO schema_migrations (version) VALUES ('20120229005336');

INSERT INTO schema_migrations (version) VALUES ('20120229043436');

INSERT INTO schema_migrations (version) VALUES ('20120302024839');

INSERT INTO schema_migrations (version) VALUES ('20120306032019');

INSERT INTO schema_migrations (version) VALUES ('20120307040041');

INSERT INTO schema_migrations (version) VALUES ('20120307232215');

INSERT INTO schema_migrations (version) VALUES ('20120320030645');

INSERT INTO schema_migrations (version) VALUES ('20120329013333');

INSERT INTO schema_migrations (version) VALUES ('20120329014157');

INSERT INTO schema_migrations (version) VALUES ('20120329014224');

INSERT INTO schema_migrations (version) VALUES ('20120329014401');

INSERT INTO schema_migrations (version) VALUES ('20120329014533');

INSERT INTO schema_migrations (version) VALUES ('20120410023926');

INSERT INTO schema_migrations (version) VALUES ('20120417225545');

INSERT INTO schema_migrations (version) VALUES ('20120426220552');

INSERT INTO schema_migrations (version) VALUES ('20120430023506');

INSERT INTO schema_migrations (version) VALUES ('20120430024101');

INSERT INTO schema_migrations (version) VALUES ('20120501015452');

INSERT INTO schema_migrations (version) VALUES ('20120501031349');

INSERT INTO schema_migrations (version) VALUES ('20120501032413');

INSERT INTO schema_migrations (version) VALUES ('20120516044556');

INSERT INTO schema_migrations (version) VALUES ('20120517001659');

INSERT INTO schema_migrations (version) VALUES ('20120517011651');

INSERT INTO schema_migrations (version) VALUES ('20120521041038');

INSERT INTO schema_migrations (version) VALUES ('20120522033509');

INSERT INTO schema_migrations (version) VALUES ('20120530080733');

INSERT INTO schema_migrations (version) VALUES ('20120605050350');

INSERT INTO schema_migrations (version) VALUES ('20120607032427');

INSERT INTO schema_migrations (version) VALUES ('20120607041557');

INSERT INTO schema_migrations (version) VALUES ('20120611011844');

INSERT INTO schema_migrations (version) VALUES ('20120611015841');

INSERT INTO schema_migrations (version) VALUES ('20120613015239');

INSERT INTO schema_migrations (version) VALUES ('20120613082157');

INSERT INTO schema_migrations (version) VALUES ('20120614000606');

INSERT INTO schema_migrations (version) VALUES ('20120617101936');

INSERT INTO schema_migrations (version) VALUES ('20120627235129');

INSERT INTO schema_migrations (version) VALUES ('20120627235203');

INSERT INTO schema_migrations (version) VALUES ('20120629013033');

INSERT INTO schema_migrations (version) VALUES ('20120718235146');

INSERT INTO schema_migrations (version) VALUES ('20120724025411');

INSERT INTO schema_migrations (version) VALUES ('20120726014507');

INSERT INTO schema_migrations (version) VALUES ('20120730233824');

INSERT INTO schema_migrations (version) VALUES ('20120812232427');

INSERT INTO schema_migrations (version) VALUES ('20120815061732');

INSERT INTO schema_migrations (version) VALUES ('20120815081106');

INSERT INTO schema_migrations (version) VALUES ('20120815093134');

INSERT INTO schema_migrations (version) VALUES ('20120820040446');

INSERT INTO schema_migrations (version) VALUES ('20120822031706');

INSERT INTO schema_migrations (version) VALUES ('20120829004318');

INSERT INTO schema_migrations (version) VALUES ('20120830003818');

INSERT INTO schema_migrations (version) VALUES ('20120831022656');

INSERT INTO schema_migrations (version) VALUES ('20120904051101');

INSERT INTO schema_migrations (version) VALUES ('20120904052651');

INSERT INTO schema_migrations (version) VALUES ('20120909041708');

INSERT INTO schema_migrations (version) VALUES ('20120910034809');

INSERT INTO schema_migrations (version) VALUES ('20120911033835');

INSERT INTO schema_migrations (version) VALUES ('20120917054659');

INSERT INTO schema_migrations (version) VALUES ('20120918113919');

INSERT INTO schema_migrations (version) VALUES ('20120919000442');

INSERT INTO schema_migrations (version) VALUES ('20120920231722');

INSERT INTO schema_migrations (version) VALUES ('20120923230255');

INSERT INTO schema_migrations (version) VALUES ('20120927040432');

INSERT INTO schema_migrations (version) VALUES ('20120927042204');

INSERT INTO schema_migrations (version) VALUES ('20120927055104');

INSERT INTO schema_migrations (version) VALUES ('20120927224520');

INSERT INTO schema_migrations (version) VALUES ('20120929040236');

INSERT INTO schema_migrations (version) VALUES ('20121002212248');

INSERT INTO schema_migrations (version) VALUES ('20121003205726');

INSERT INTO schema_migrations (version) VALUES ('20121010231051');

INSERT INTO schema_migrations (version) VALUES ('20121010232812');

INSERT INTO schema_migrations (version) VALUES ('20121010236717');

INSERT INTO schema_migrations (version) VALUES ('20121018021812');

INSERT INTO schema_migrations (version) VALUES ('20121024025935');

INSERT INTO schema_migrations (version) VALUES ('20121102225050');

INSERT INTO schema_migrations (version) VALUES ('20121112232854');

INSERT INTO schema_migrations (version) VALUES ('20121114225113');

INSERT INTO schema_migrations (version) VALUES ('20121116015952');

INSERT INTO schema_migrations (version) VALUES ('20121119000156');

INSERT INTO schema_migrations (version) VALUES ('20121119005042');

INSERT INTO schema_migrations (version) VALUES ('20121128005022');

INSERT INTO schema_migrations (version) VALUES ('20121204015243');

INSERT INTO schema_migrations (version) VALUES ('20121211024951');

INSERT INTO schema_migrations (version) VALUES ('20121211222422');

INSERT INTO schema_migrations (version) VALUES ('20121212212609');

INSERT INTO schema_migrations (version) VALUES ('20130110013104');

INSERT INTO schema_migrations (version) VALUES ('20130116031833');

INSERT INTO schema_migrations (version) VALUES ('20130122003352');

INSERT INTO schema_migrations (version) VALUES ('20130123022020');

INSERT INTO schema_migrations (version) VALUES ('20130125004824');

INSERT INTO schema_migrations (version) VALUES ('20130128022723');

INSERT INTO schema_migrations (version) VALUES ('20130130220514');

INSERT INTO schema_migrations (version) VALUES ('20130213020709');

INSERT INTO schema_migrations (version) VALUES ('20130213224528');

INSERT INTO schema_migrations (version) VALUES ('20130218060217');

INSERT INTO schema_migrations (version) VALUES ('20130219014308');

INSERT INTO schema_migrations (version) VALUES ('20130220234725');

INSERT INTO schema_migrations (version) VALUES ('20130222011927');

INSERT INTO schema_migrations (version) VALUES ('20130226231819');

INSERT INTO schema_migrations (version) VALUES ('20130227051525');

INSERT INTO schema_migrations (version) VALUES ('20130228205052');

INSERT INTO schema_migrations (version) VALUES ('20130305134300');

INSERT INTO schema_migrations (version) VALUES ('20130306001542');

INSERT INTO schema_migrations (version) VALUES ('20130306002347');

INSERT INTO schema_migrations (version) VALUES ('20130306003517');

INSERT INTO schema_migrations (version) VALUES ('20130306003632');

INSERT INTO schema_migrations (version) VALUES ('20130307233033');

INSERT INTO schema_migrations (version) VALUES ('20130308022028');

INSERT INTO schema_migrations (version) VALUES ('20130311224428');

INSERT INTO schema_migrations (version) VALUES ('20130313051530');

INSERT INTO schema_migrations (version) VALUES ('20130315034909');

INSERT INTO schema_migrations (version) VALUES ('20130321040949');

INSERT INTO schema_migrations (version) VALUES ('20130409022821');

INSERT INTO schema_migrations (version) VALUES ('20130416022347');

INSERT INTO schema_migrations (version) VALUES ('20130417021024');

INSERT INTO schema_migrations (version) VALUES ('20130417025820');

INSERT INTO schema_migrations (version) VALUES ('20130423225325');

INSERT INTO schema_migrations (version) VALUES ('20130429060902');

INSERT INTO schema_migrations (version) VALUES ('20130430034158');

INSERT INTO schema_migrations (version) VALUES ('20130430034231');

INSERT INTO schema_migrations (version) VALUES ('20130508035922');

INSERT INTO schema_migrations (version) VALUES ('20130509012650');

INSERT INTO schema_migrations (version) VALUES ('20130510023753');

INSERT INTO schema_migrations (version) VALUES ('20130514032841');

INSERT INTO schema_migrations (version) VALUES ('20130514034901');

INSERT INTO schema_migrations (version) VALUES ('20130515012606');

INSERT INTO schema_migrations (version) VALUES ('20130610041926');

INSERT INTO schema_migrations (version) VALUES ('20130610110940');

INSERT INTO schema_migrations (version) VALUES ('20130610121509');

INSERT INTO schema_migrations (version) VALUES ('20130616094641');

INSERT INTO schema_migrations (version) VALUES ('20130703031111');

INSERT INTO schema_migrations (version) VALUES ('20130703055630');

INSERT INTO schema_migrations (version) VALUES ('20130705011742');