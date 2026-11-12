--PERFROMANCE OPTIMISATION

SET SERVEROUTPUT ON SIZE UNLIMITED


-- ------------------------------------------------------------
-- 1: remove the date indexes so we can measure "before"
-- ------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX IDX_TRIPS_TIME';
    DBMS_OUTPUT.PUT_LINE('IDX_TRIPS_TIME dropped for the BEFORE test.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('IDX_TRIPS_TIME did not exist: ' || SQLERRM);
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX IDX_TRIPS_STATUS_TIME';
    DBMS_OUTPUT.PUT_LINE('IDX_TRIPS_STATUS_TIME dropped for the test.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('IDX_TRIPS_STATUS_TIME did not exist: ' || SQLERRM);
END;
/

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(ownname => USER, tabname => 'TRIP_HEADERS');
END;
/


-- ------------------------------------------------------------
-- 2: BEFORE - plan for a one-day lookup
-- ------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'BEFORE_INDEX' FOR
SELECT t.TRIP_ID, t.RIDER_ID, t.TRIP_STATUS, f.TOTAL_FARE_ZAR
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
WHERE t.REQUEST_TIMESTAMP >= DATE '2025-07-01'
  AND t.REQUEST_TIMESTAMP <  DATE '2025-07-02';

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'BEFORE_INDEX', 'TYPICAL'));


-- ------------------------------------------------------------
-- 3: create the index and refresh statistics
-- ------------------------------------------------------------
CREATE INDEX IDX_TRIPS_TIME ON TRIP_HEADERS (REQUEST_TIMESTAMP);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(ownname => USER, tabname => 'TRIP_HEADERS');
END;
/


-- ------------------------------------------------------------
-- 4: AFTER - same query, new plan
-- ------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'AFTER_INDEX' FOR
SELECT t.TRIP_ID, t.RIDER_ID, t.TRIP_STATUS, f.TOTAL_FARE_ZAR
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
WHERE t.REQUEST_TIMESTAMP >= DATE '2025-07-01'
  AND t.REQUEST_TIMESTAMP <  DATE '2025-07-02';

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'AFTER_INDEX', 'TYPICAL'));


-- ------------------------------------------------------------
--5: a second example - one rider's trip history

-- ------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'RIDER_HISTORY' FOR
SELECT t.TRIP_ID, t.REQUEST_TIMESTAMP, f.PAYMENT_METHOD, f.TOTAL_FARE_ZAR
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
WHERE t.RIDER_ID = 'RIDER_000001'
  AND t.REQUEST_TIMESTAMP >= DATE '2025-06-01'
ORDER BY t.REQUEST_TIMESTAMP;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'RIDER_HISTORY', 'TYPICAL'));


-- ------------------------------------------------------------

-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- STEP 6: restore the index dropped for the test
-- ------------------------------------------------------------
CREATE INDEX IDX_TRIPS_STATUS_TIME ON TRIP_HEADERS (TRIP_STATUS, REQUEST_TIMESTAMP);


-- ------------------------------------------------------------
-- STEP 7: current index list 
-- ------------------------------------------------------------
SELECT i.TABLE_NAME,
       i.INDEX_NAME,
       i.UNIQUENESS,
       LISTAGG(ic.COLUMN_NAME, ', ')
           WITHIN GROUP (ORDER BY ic.COLUMN_POSITION) AS INDEXED_COLUMNS
FROM USER_INDEXES i
JOIN USER_IND_COLUMNS ic
    ON i.INDEX_NAME = ic.INDEX_NAME
   AND i.TABLE_NAME = ic.TABLE_NAME
WHERE i.TABLE_NAME IN (
    'TRIP_HEADERS',
    'TRIP_FARE_BREAKDOWN',
    'TRIP_REVIEWS',
    'SA_RIDERS',
    'VEHICLES'
)
GROUP BY i.TABLE_NAME, i.INDEX_NAME, i.UNIQUENESS
ORDER BY i.TABLE_NAME, i.INDEX_NAME;

