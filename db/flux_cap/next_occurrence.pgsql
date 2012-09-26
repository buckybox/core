--h localhost -U jordan -d bucky_box_development

CREATE OR REPLACE FUNCTION next_occurrence(
  from_date DATE, schedule_rule schedule_rules
)
  RETURNS DATE
  LANGUAGE plpgsql STABLE
  AS $BODY$
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
$BODY$;

CREATE OR REPLACE FUNCTION pause_finish(
  test_date DATE, schedule_rule schedule_rules
)
  RETURNS DATE
  LANGUAGE plpgsql STABLE
  AS $BODY$
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
$BODY$;

CREATE OR REPLACE FUNCTION is_paused(
  test_date DATE, schedule_rule schedule_rules
)
  RETURNS BOOLEAN
  LANGUAGE plpgsql STABLE
  AS $BODY$
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
$BODY$;

CREATE OR REPLACE FUNCTION unpaused_next_occurrence(
  from_date DATE, schedule_rule schedule_rules
)
  RETURNS DATE
  LANGUAGE plpgsql IMMUTABLE
  AS $BODY$
DECLARE
  from_wday int;
  days_from_now int;
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
    -- If we go above the 7th of a month, we skip to the next month
    IF date_part('day', from_date) > 7 THEN
      from_date := date(date_part('year', from_date + '1 month'::interval)::text || '-' || date_part('month', from_date + '1 month'::interval)::text || '-01');
    END IF;
    FOR i IN 0..6 LOOP
      -- If we go above the 7th of a month, we skip to the next month
      IF date_part('day', from_date) > 7 THEN
        from_date := date(date_part('year', from_date + '1 month'::interval)::text || '-' || date_part('month', from_date + '1 month'::interval)::text || '-01');
      END IF;

      EXIT WHEN on_day(EXTRACT(DOW FROM from_date)::integer, schedule_rule);
      from_date := from_date + 1;
    END LOOP;

    return from_date;
  ELSE
    IF schedule_rule.recur IS NULL THEN
  -- ==================== ONE OFF / SINGLE ====================
      IF from_date > schedule_rule.start THEN
        return NULL;
      ELSE
        RETURN from_date;
      END IF;
    ELSE
      RAISE EXCEPTION 'schedule_rules.recur should be NULL, weekly, fortnightly or monthly';
  END IF;
  END CASE;

END;
$BODY$;

CREATE OR REPLACE FUNCTION on_day(
  day int, schedule_rule schedule_rules
)
  RETURNS BOOLEAN
  LANGUAGE plpgsql IMMUTABLE
  AS $BODY$
DECLARE
  result DATE;
BEGIN
  -- If it is a one off, then it doesn't have a mon -> sun schedule, check the day it starts on
  IF schedule_rule.recur IS NULL THEN
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
$BODY$;
