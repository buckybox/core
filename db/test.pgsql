-- -h localhost -U jordan -d bucky_box_development

--DROP FUNCTION IF EXISTS next_occurrence(from_date DATE, schedule_rule schedule_rules);

CREATE OR REPLACE FUNCTION next_occurrence(
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
  
  CASE schedule_rule.recur
  WHEN 'weekly' THEN
    -- RECUR WEEKLY
    -- What is the day of the week? Sunday: 0, Monday: 1, etc...
    from_wday := EXTRACT(DOW from from_date);

    -- Loop until we find the next occurrence
    FOR i IN 0..6 LOOP
      days_from_now := mod(from_wday + i, 6);
      EXIT WHEN on_day(days_from_now, schedule_rule);
    END LOOP;

    return from_date + days_from_now;
  WHEN 'fortnightly' THEN
    -- RECUR FORTNIGHTLY
    return from_date;
  WHEN 'monthly' THEN
    -- RECUR MONTHLY
    return from_date;
  ELSE
    IF schedule_rule.recur IS NULL THEN
      -- ONE OFF
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

--CREATE OR REPLACE FUNCTION on_day(
--  day int, schedule_rule schedule_rules
--)
--  RETURNS BOOLEAN
--  LANGUAGE plpgsql IMMUTABLE
--  AS $BODY$
--DECLARE
--  result DATE;
--BEGIN
--  -- If it is a one off, then it doesn't have a mon -> sun schedule, check the day it starts on
--  IF schedule_rule.recur IS NULL THEN
--    return EXTRACT(DOW FROM schedule_rule.start) = day;
--  ELSE
--    CASE day
--      WHEN 0 THEN
--        RETURN schedule_rule.sun;
--      WHEN 1 THEN
--        RETURN schedule_rule.mon;
--      WHEN 2 THEN
--        RETURN schedule_rule.tue;
--      WHEN 3 THEN
--        RETURN schedule_rule.wed;
--      WHEN 4 THEN
--        RETURN schedule_rule.thu;
--      WHEN 5 THEN
--        RETURN schedule_rule.fri;
--      WHEN 6 THEN
--        RETURN schedule_rule.sat;
--      ELSE
--        RETURN FALSE;
--    END CASE;
--  END IF;
--END;
--$BODY$;
