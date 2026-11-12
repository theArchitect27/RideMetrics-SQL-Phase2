-- FILE 01: CREATE TABLES (reference DDL, as built)

 
-- ---------- 1. PRICING_SURGE_ZONES --------------------------
CREATE TABLE PRICING_SURGE_ZONES (
    ZONE_ID           VARCHAR2(50)  NOT NULL,
    ZONE_NAME         VARCHAR2(128),
    CITY              VARCHAR2(26),
    BASE_FARE_ZAR     NUMBER(38),
    PER_KM_RATE_ZAR   NUMBER(38,1),
    PER_MIN_RATE_ZAR  NUMBER(38,2),
    CONSTRAINT PK_PRICING_SURGE_ZONES PRIMARY KEY (ZONE_ID)
);
 
-- ---------- 2. SA_DRIVERS -----------------------------------
CREATE TABLE SA_DRIVERS (
    DRIVER_ID                VARCHAR2(26) NOT NULL,
    FIRST_NAME               VARCHAR2(26),
    LAST_NAME                VARCHAR2(26),
    OPERATING_CITY           VARCHAR2(26),
    PLATFORM_AFFILIATION     VARCHAR2(26),
    PLATFORM_COMMISSION_PCT  NUMBER(38,2),
    DRIVER_RATING            NUMBER(38,2),
    TOTAL_LIFETIME_TRIPS     NUMBER(38),
    ONBOARDING_DATE          DATE,
    CONSTRAINT PK_SA_DRIVERS PRIMARY KEY (DRIVER_ID),
    CONSTRAINT CK_DRIVERS_RATING
        CHECK (DRIVER_RATING BETWEEN 0 AND 5)
);
 
-- ---------- 3. SA_RIDERS ------------------------------------
CREATE TABLE SA_RIDERS (
    RIDER_ID              VARCHAR2(26) NOT NULL,
    FIRST_NAME            VARCHAR2(26),
    LAST_NAME             VARCHAR2(26),
    MOBILE_NUMBER         NUMBER(38),
    HOME_CITY             VARCHAR2(26),
    PROVINCE              VARCHAR2(26),
    PREFERRED_PAYMENT     VARCHAR2(26),
    ACCOUNT_CREATED_DATE  DATE,
    CONSTRAINT PK_SA_RIDERS PRIMARY KEY (RIDER_ID)
);
 
-- ---------- 4. VEHICLES -------------------------------------
CREATE TABLE VEHICLES (
    VEHICLE_ID     VARCHAR2(26) NOT NULL,
    DRIVER_ID      VARCHAR2(26) NOT NULL,
    MAKE           VARCHAR2(26),
    MODEL          VARCHAR2(26),
    YEAR           NUMBER(38),
    LICENSE_PLATE  VARCHAR2(26) NOT NULL,
    CATEGORY_TYPE  VARCHAR2(128),
    CONSTRAINT PK_VEHICLES PRIMARY KEY (VEHICLE_ID),
    CONSTRAINT UQ_VEHICLES_LICENSE_PLATE UNIQUE (LICENSE_PLATE),
    CONSTRAINT FK_VEHICLES_DRIVERS
        FOREIGN KEY (DRIVER_ID) REFERENCES SA_DRIVERS (DRIVER_ID)
);
 
-- ---------- 5. TRIP_HEADERS --------------------------------
CREATE TABLE TRIP_HEADERS (
    TRIP_ID              VARCHAR2(50)  NOT NULL,
    RIDER_ID             VARCHAR2(26)  NOT NULL,
    DRIVER_ID            VARCHAR2(26)  NOT NULL,
    ZONE_ID              VARCHAR2(50)  NOT NULL,
    RIDE_CATEGORY        VARCHAR2(128),
    REQUEST_TIMESTAMP    DATE,
    TRIP_STATUS          VARCHAR2(26),
    CANCELLATION_REASON  VARCHAR2(26),
    CONSTRAINT PK_TRIP_HEADERS PRIMARY KEY (TRIP_ID),
    CONSTRAINT FK_TRIPS_RIDERS
        FOREIGN KEY (RIDER_ID)  REFERENCES SA_RIDERS (RIDER_ID),
    CONSTRAINT FK_TRIPS_DRIVERS
        FOREIGN KEY (DRIVER_ID) REFERENCES SA_DRIVERS (DRIVER_ID),
    CONSTRAINT FK_TRIPS_ZONES
        FOREIGN KEY (ZONE_ID)   REFERENCES PRICING_SURGE_ZONES (ZONE_ID)
);
 
-- ---------- 6. TRIP_FARE_BREAKDOWN (1:1 with TRIP_HEADERS) --
CREATE TABLE TRIP_FARE_BREAKDOWN (
    TRIP_ID                  VARCHAR2(50) NOT NULL,
    DISTANCE_KM              NUMBER(38,2),
    DURATION_MINUTES         NUMBER(38),
    SURGE_MULTIPLIER         NUMBER(38,1),
    BASE_FARE_ZAR            NUMBER(38),
    TOLLS_ZAR                NUMBER(38,1),
    TIP_ZAR                  NUMBER(38),
    TOTAL_FARE_ZAR           NUMBER(38,2),
    PLATFORM_COMMISSION_ZAR  NUMBER(38,2),
    DRIVER_PAYOUT_ZAR        NUMBER(38,2),
    PAYMENT_METHOD           VARCHAR2(26),
    CONSTRAINT PK_TRIP_FARE_BREAKDOWN PRIMARY KEY (TRIP_ID),
    CONSTRAINT FK_FARES_TRIPS
        FOREIGN KEY (TRIP_ID) REFERENCES TRIP_HEADERS (TRIP_ID),
    CONSTRAINT CK_FARES_DISTANCE CHECK (DISTANCE_KM >= 0),
    CONSTRAINT CK_FARES_DURATION CHECK (DURATION_MINUTES >= 0),
    CONSTRAINT CK_FARES_TOTAL    CHECK (TOTAL_FARE_ZAR >= 0)
);
 
-- ---------- 7. TRIP_REVIEWS ---------------------------------
CREATE TABLE TRIP_REVIEWS (
    REVIEW_ID               VARCHAR2(50) NOT NULL,
    TRIP_ID                 VARCHAR2(50) NOT NULL,
    RIDER_RATING_OF_DRIVER  NUMBER(38),
    DRIVER_RATING_OF_RIDER  NUMBER(38),
    FEEDBACK_COMMENT        VARCHAR2(128),
    CONSTRAINT PK_TRIP_REVIEWS PRIMARY KEY (REVIEW_ID),
    CONSTRAINT FK_REVIEWS_TRIPS
        FOREIGN KEY (TRIP_ID) REFERENCES TRIP_HEADERS (TRIP_ID),
    CONSTRAINT CK_REVIEWS_RIDER_RATING
        CHECK (RIDER_RATING_OF_DRIVER BETWEEN 0 AND 5),
    CONSTRAINT CK_REVIEWS_DRIVER_RATING
        CHECK (DRIVER_RATING_OF_RIDER BETWEEN 0 AND 5)
);
 
-- >>>>>>>>>>>>>>>> 02_load_and_verify.sql <<<<<<<<<<<<<<<<
-- ============================================================
-- RIDEMETRICS PHASE 2  |  CMPG321
-- FILE 02: DATA LOADING AND POST-LOAD VERIFICATION
-- Database: Oracle (SQL Developer)
-- ============================================================
-- PART A  How the data is loaded (document this in the report)
-- PART B  Optional staging-table template (only if you reload)
-- PART C  Post-load verification  <-- run this one
--         (row counts + date ranges, checked against Phase 1)
-- ============================================================
 
 
-- ============================================================
-- PART A: LOADING METHOD
-- ============================================================
-- Load order (parents first, so foreign keys are satisfied):
--   1. PRICING_SURGE_ZONES      (pricing_surge_zones.csv)
--   2. SA_DRIVERS               (sa_drivers.csv)
--   3. SA_RIDERS                (sa_riders.csv)
--   4. VEHICLES                 (vehicles.csv)
--   5. TRIP_HEADERS             (trip_headers.csv)
--   6. TRIP_FARE_BREAKDOWN      (trip_fare_breakdown.csv)
--   7. TRIP_REVIEWS             (trip_reviews.csv)
--
-- In SQL Developer: right-click the table > Import Data...
--   - choose the CSV, header row = yes
--   - map date columns using the format that matches the file:
--       REQUEST_TIMESTAMP     YYYY-MM-DD HH24:MI:SS
--       ACCOUNT_CREATED_DATE  YYYY/MM/DD
--   - commit when the import finishes
-- (Edit the notes above if you loaded differently.)
 
 
-- ============================================================
-- PART B: OPTIONAL STAGING-TABLE TEMPLATE
-- Only needed if you ever have to reload with date conversion.
-- Import the CSV into an all-text staging table, then convert.
-- ============================================================
-- CREATE TABLE STG_TRIP_HEADERS (
--     TRIP_ID VARCHAR2(50), RIDER_ID VARCHAR2(26),
--     DRIVER_ID VARCHAR2(26), ZONE_ID VARCHAR2(50),
--     RIDE_CATEGORY VARCHAR2(128), REQUEST_TIMESTAMP VARCHAR2(30),
--     TRIP_STATUS VARCHAR2(26), CANCELLATION_REASON VARCHAR2(26)
-- );
--
-- INSERT INTO TRIP_HEADERS
--     (TRIP_ID, RIDER_ID, DRIVER_ID, ZONE_ID, RIDE_CATEGORY,
--      REQUEST_TIMESTAMP, TRIP_STATUS, CANCELLATION_REASON)
-- SELECT TRIP_ID, RIDER_ID, DRIVER_ID, ZONE_ID, RIDE_CATEGORY,
--        TO_DATE(REQUEST_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS'),
--        TRIP_STATUS, CANCELLATION_REASON
-- FROM STG_TRIP_HEADERS;
-- COMMIT;
-- DROP TABLE STG_TRIP_HEADERS PURGE;
--
-- Same idea for SA_RIDERS:
--   TO_DATE(ACCOUNT_CREATED_DATE, 'YYYY/MM/DD')
 
 
-- ============================================================
-- PART C: POST-LOAD VERIFICATION
-- Expected values were counted directly from the CSV files the
-- lecturer supplied (1,200 riders, 50,000 trips). NOTE: the Phase 1
-- report quoted 2,000 riders and 60,000 trips; those figures do not
-- match the supplied files. Every RESULT should say PASS.
-- ============================================================
 
-- C1. Row counts in all seven tables vs the supplied CSV files
SELECT TABLE_NAME, EXPECTED_ROWS, ACTUAL_ROWS,
       CASE WHEN EXPECTED_ROWS = ACTUAL_ROWS
            THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (
    SELECT 'PRICING_SURGE_ZONES' AS TABLE_NAME, 9 AS EXPECTED_ROWS,
           COUNT(*) AS ACTUAL_ROWS FROM PRICING_SURGE_ZONES
    UNION ALL
    SELECT 'SA_DRIVERS', 800, COUNT(*) FROM SA_DRIVERS
    UNION ALL
    SELECT 'SA_RIDERS', 1200, COUNT(*) FROM SA_RIDERS
    UNION ALL
    SELECT 'VEHICLES', 800, COUNT(*) FROM VEHICLES
    UNION ALL
    SELECT 'TRIP_HEADERS', 50000, COUNT(*) FROM TRIP_HEADERS
    UNION ALL
    SELECT 'TRIP_FARE_BREAKDOWN', 50000, COUNT(*) FROM TRIP_FARE_BREAKDOWN
    UNION ALL
    SELECT 'TRIP_REVIEWS', 25055, COUNT(*) FROM TRIP_REVIEWS
)
ORDER BY TABLE_NAME;
 
 
-- C2. Date ranges vs Phase 1 (trips: 2025-03-01 to 2026-03-31;
--     rider accounts: 2023-01-01 to 2025-06-19; both confirmed in the CSVs)
SELECT 'TRIP_HEADERS.REQUEST_TIMESTAMP' AS COLUMN_CHECKED,
       TO_CHAR(MIN(REQUEST_TIMESTAMP), 'YYYY-MM-DD HH24:MI:SS') AS EARLIEST,
       TO_CHAR(MAX(REQUEST_TIMESTAMP), 'YYYY-MM-DD HH24:MI:SS') AS LATEST
FROM TRIP_HEADERS
UNION ALL
SELECT 'SA_RIDERS.ACCOUNT_CREATED_DATE',
       TO_CHAR(MIN(ACCOUNT_CREATED_DATE), 'YYYY-MM-DD'),
       TO_CHAR(MAX(ACCOUNT_CREATED_DATE), 'YYYY-MM-DD')
FROM SA_RIDERS;
 
 
-- C3. Reconcile loaded values with counts taken from the CSV files
SELECT CHECK_NAME, EXPECTED, ACTUAL,
       CASE WHEN EXPECTED = ACTUAL THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (
    SELECT 'Completed trips' AS CHECK_NAME, 33331 AS EXPECTED,
           COUNT(*) AS ACTUAL
    FROM TRIP_HEADERS WHERE TRIP_STATUS = 'COMPLETED'
    UNION ALL
    SELECT 'Cancelled by rider', 8417, COUNT(*)
    FROM TRIP_HEADERS WHERE TRIP_STATUS = 'CANCELLED_BY_RIDER'
    UNION ALL
    SELECT 'Cancelled by driver', 8252, COUNT(*)
    FROM TRIP_HEADERS WHERE TRIP_STATUS = 'CANCELLED_BY_DRIVER'
    UNION ALL
    SELECT 'Trips paid CASH', 10505, COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE PAYMENT_METHOD = 'CASH'
    UNION ALL
    SELECT 'Trips paid CREDIT_CARD', 10353, COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE PAYMENT_METHOD = 'CREDIT_CARD'
    UNION ALL
    SELECT 'Trips paid DEBIT_CARD', 9863, COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE PAYMENT_METHOD = 'DEBIT_CARD'
    UNION ALL
    SELECT 'Trips paid EFT_OZOW', 9704, COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE PAYMENT_METHOD = 'EFT_OZOW'
    UNION ALL
    SELECT 'Trips paid IN_APP_WALLET', 9575, COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE PAYMENT_METHOD = 'IN_APP_WALLET'
    UNION ALL
    SELECT 'Riders preferring CASH', 254, COUNT(*)
    FROM SA_RIDERS WHERE PREFERRED_PAYMENT = 'CASH'
    UNION ALL
    SELECT 'Riders preferring CREDIT_CARD', 246, COUNT(*)
    FROM SA_RIDERS WHERE PREFERRED_PAYMENT = 'CREDIT_CARD'
    UNION ALL
    SELECT 'Riders preferring DEBIT_CARD', 238, COUNT(*)
    FROM SA_RIDERS WHERE PREFERRED_PAYMENT = 'DEBIT_CARD'
    UNION ALL
    SELECT 'Riders preferring EFT_OZOW', 233, COUNT(*)
    FROM SA_RIDERS WHERE PREFERRED_PAYMENT = 'EFT_OZOW'
    UNION ALL
    SELECT 'Riders preferring IN_APP_WALLET', 229, COUNT(*)
    FROM SA_RIDERS WHERE PREFERRED_PAYMENT = 'IN_APP_WALLET'
);
 
 
-- C4. Mobile numbers: length summary only (no raw numbers shown)
SELECT COUNT(*) AS TOTAL_NON_NULL_NUMBERS,
       MIN(LENGTH(TO_CHAR(MOBILE_NUMBER))) AS SHORTEST_LENGTH,
       MAX(LENGTH(TO_CHAR(MOBILE_NUMBER))) AS LONGEST_LENGTH
FROM SA_RIDERS
WHERE MOBILE_NUMBER IS NOT NULL;
 
-- >>>>>>>>>>>>>>>> 03_constraints_and_indexes.sql <<<<<<<<<<<<<<<<
-- ============================================================
-- RIDEMETRICS PHASE 2  |  CMPG321
-- FILE 03: DESIGN HARDENING - DATA TYPES, CONSTRAINTS, INDEXES
-- Database: Oracle (SQL Developer)
--
-- Run with "Run Script" (F5), not statement by statement.
--
-- Every change runs through a helper that PRINTS what happened
-- and carries on if a statement fails or was already applied
-- (for example "name already used by an existing constraint").
-- That makes this file safe to run more than once.
-- Read the output in the "Script Output" panel and screenshot it
-- as proof for the report.
--
-- Already in your database (from the Worksheet 3 audit), so NOT
-- repeated here: all 7 primary keys, all 6 foreign keys,
-- UQ_VEHICLES_LICENSE_PLATE, CK_DRIVERS_RATING, CK_FARES_DISTANCE,
-- CK_FARES_DURATION, CK_FARES_TOTAL, CK_REVIEWS_RIDER_RATING,
-- CK_REVIEWS_DRIVER_RATING and the NOT NULL on the key columns.
-- ============================================================
 
 
-- ============================================================
-- STEP 0: LOOK BEFORE YOU CONSTRAIN
-- Confirm the stored values match the constraint lists below.
-- ============================================================
SELECT DISTINCT TRIP_STATUS FROM TRIP_HEADERS ORDER BY 1;
SELECT DISTINCT CANCELLATION_REASON FROM TRIP_HEADERS ORDER BY 1;
SELECT DISTINCT RIDE_CATEGORY FROM TRIP_HEADERS ORDER BY 1;
SELECT DISTINCT PAYMENT_METHOD FROM TRIP_FARE_BREAKDOWN ORDER BY 1;
SELECT DISTINCT PREFERRED_PAYMENT FROM SA_RIDERS ORDER BY 1;
SELECT DISTINCT PROVINCE FROM SA_RIDERS ORDER BY 1;
SELECT DISTINCT CITY FROM PRICING_SURGE_ZONES ORDER BY 1;
 
 
-- ============================================================
-- STEP 1: ALIGN KEY COLUMN DATA TYPES
-- The ERD showed two mismatches:
--   TRIP_REVIEWS.TRIP_ID  VARCHAR2(26) vs TRIP_HEADERS 50
--   TRIP_HEADERS.ZONE_ID  VARCHAR2(26) vs PRICING_SURGE_ZONES 50
-- Widening a column is safe; no data is lost.
-- ============================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
 
DECLARE
    PROCEDURE run_ddl(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('OK      : ' || p_sql);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('SKIPPED : ' || p_sql);
            DBMS_OUTPUT.PUT_LINE('          -> ' || SQLERRM);
    END run_ddl;
BEGIN
    run_ddl('ALTER TABLE TRIP_REVIEWS MODIFY (TRIP_ID VARCHAR2(50))');
    run_ddl('ALTER TABLE TRIP_HEADERS MODIFY (ZONE_ID VARCHAR2(50))');
END;
/
 
 
-- ============================================================
-- STEP 2: DOMAIN (CATEGORY) CHECK CONSTRAINTS
-- Lists come from the Phase 1 data dictionary (section 3.5).
-- RIDE_CATEGORY and PROVINCE are left unconstrained on purpose:
-- confirm their exact stored values with the STEP 0 queries
-- first, then add a CHECK if you want one.
-- ============================================================
DECLARE
    PROCEDURE run_ddl(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('OK      : ' || SUBSTR(p_sql, 1, 100));
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('SKIPPED : ' || SUBSTR(p_sql, 1, 100));
            DBMS_OUTPUT.PUT_LINE('          -> ' || SQLERRM);
    END run_ddl;
BEGIN
    run_ddl(q'[ALTER TABLE TRIP_HEADERS ADD CONSTRAINT CK_TRIPS_STATUS
               CHECK (TRIP_STATUS IN ('COMPLETED',
                      'CANCELLED_BY_RIDER','CANCELLED_BY_DRIVER'))]');
 
    run_ddl(q'[ALTER TABLE TRIP_HEADERS ADD CONSTRAINT CK_TRIPS_REASON_DOMAIN
               CHECK (CANCELLATION_REASON IS NULL OR CANCELLATION_REASON IN
                      ('CHANGED_MIND','DRIVER_TOO_FAR','SAFETY_CONCERN',
                       'RIDER_NO_SHOW','PRICING_SURGE','TRAFFIC_DELAY'))]');
 
    -- A reason is recorded only on cancelled trips (Phase 1: the
    -- 33,331 NULL reasons are exactly the completed trips).
    run_ddl(q'[ALTER TABLE TRIP_HEADERS ADD CONSTRAINT CK_TRIPS_REASON_LOGIC
               CHECK ((TRIP_STATUS = 'COMPLETED' AND CANCELLATION_REASON IS NULL)
                   OR (TRIP_STATUS <> 'COMPLETED' AND CANCELLATION_REASON IS NOT NULL))]');
 
    run_ddl(q'[ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_PAYMENT
               CHECK (PAYMENT_METHOD IN ('CASH','CREDIT_CARD','DEBIT_CARD',
                      'EFT_OZOW','IN_APP_WALLET'))]');
 
    run_ddl(q'[ALTER TABLE SA_RIDERS ADD CONSTRAINT CK_RIDERS_PREF_PAYMENT
               CHECK (PREFERRED_PAYMENT IN ('CASH','CREDIT_CARD','DEBIT_CARD',
                      'EFT_OZOW','IN_APP_WALLET'))]');
END;
/
 
 
-- ============================================================
-- STEP 3: NUMERIC RANGE CHECK CONSTRAINTS
-- ============================================================
DECLARE
    PROCEDURE run_ddl(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('OK      : ' || SUBSTR(p_sql, 1, 100));
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('SKIPPED : ' || SUBSTR(p_sql, 1, 100));
            DBMS_OUTPUT.PUT_LINE('          -> ' || SQLERRM);
    END run_ddl;
BEGIN
    run_ddl('ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_TIP CHECK (TIP_ZAR >= 0)');
    run_ddl('ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_SURGE CHECK (SURGE_MULTIPLIER >= 1)');
    run_ddl('ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_TOLLS CHECK (TOLLS_ZAR >= 0)');
    run_ddl('ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_BASE CHECK (BASE_FARE_ZAR >= 0)');
    run_ddl('ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_COMMISSION CHECK (PLATFORM_COMMISSION_ZAR >= 0)');
    run_ddl('ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_PAYOUT CHECK (DRIVER_PAYOUT_ZAR >= 0)');
    -- Stored as a fraction (0.20-0.25 in the CSV), not as 20-25
    run_ddl('ALTER TABLE SA_DRIVERS ADD CONSTRAINT CK_DRIVERS_COMMISSION CHECK (PLATFORM_COMMISSION_PCT BETWEEN 0 AND 1)');
    run_ddl('ALTER TABLE VEHICLES ADD CONSTRAINT CK_VEHICLES_YEAR CHECK (YEAR BETWEEN 1990 AND 2030)');
END;
/
 
 
-- ============================================================
-- STEP 4: NOT NULL ON THE ANALYSIS COLUMNS
-- Phase 1 found no missing values in these columns.
-- ORA-01442 ("already NOT NULL") is expected and is skipped.
-- ============================================================
DECLARE
    PROCEDURE run_ddl(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('OK      : ' || p_sql);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('SKIPPED : ' || p_sql);
            DBMS_OUTPUT.PUT_LINE('          -> ' || SQLERRM);
    END run_ddl;
BEGIN
    run_ddl('ALTER TABLE TRIP_HEADERS MODIFY (TRIP_STATUS NOT NULL)');
    run_ddl('ALTER TABLE TRIP_HEADERS MODIFY (RIDE_CATEGORY NOT NULL)');
    run_ddl('ALTER TABLE TRIP_HEADERS MODIFY (REQUEST_TIMESTAMP NOT NULL)');
    run_ddl('ALTER TABLE TRIP_FARE_BREAKDOWN MODIFY (PAYMENT_METHOD NOT NULL)');
    run_ddl('ALTER TABLE TRIP_FARE_BREAKDOWN MODIFY (TOTAL_FARE_ZAR NOT NULL)');
    run_ddl('ALTER TABLE TRIP_FARE_BREAKDOWN MODIFY (TIP_ZAR NOT NULL)');
    run_ddl('ALTER TABLE SA_RIDERS MODIFY (HOME_CITY NOT NULL)');
    run_ddl('ALTER TABLE SA_RIDERS MODIFY (PROVINCE NOT NULL)');
    run_ddl('ALTER TABLE SA_RIDERS MODIFY (PREFERRED_PAYMENT NOT NULL)');
    run_ddl('ALTER TABLE PRICING_SURGE_ZONES MODIFY (CITY NOT NULL)');
END;
/
 
 
-- ============================================================
-- STEP 5: INDEXES
-- Oracle does NOT index foreign key columns automatically.
-- These support the joins, filters and GROUP BYs used in the
-- research-question queries (file 05).
--   IDX_TRIPS_RIDER_TIME  rider lookups / per-rider history
--                         (also covers the RIDER_ID foreign key)
--   IDX_TRIPS_DRIVER      FK column
--   IDX_TRIPS_ZONE        joins to zones / city grouping
--   IDX_TRIPS_TIME        date-range filters, monthly trends
--   IDX_TRIPS_STATUS_TIME status filter + date
--   IDX_VEH_DRIVER        FK column
--   IDX_REVIEWS_TRIP      FK column / LEFT JOIN to reviews
--   IDX_RIDERS_CITY       city / province segmentation
-- ============================================================
DECLARE
    PROCEDURE run_ddl(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('OK      : ' || p_sql);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('SKIPPED : ' || p_sql);
            DBMS_OUTPUT.PUT_LINE('          -> ' || SQLERRM);
    END run_ddl;
BEGIN
    run_ddl('CREATE INDEX IDX_TRIPS_RIDER_TIME ON TRIP_HEADERS (RIDER_ID, REQUEST_TIMESTAMP)');
    run_ddl('CREATE INDEX IDX_TRIPS_DRIVER ON TRIP_HEADERS (DRIVER_ID)');
    run_ddl('CREATE INDEX IDX_TRIPS_ZONE ON TRIP_HEADERS (ZONE_ID)');
    run_ddl('CREATE INDEX IDX_TRIPS_TIME ON TRIP_HEADERS (REQUEST_TIMESTAMP)');
    run_ddl('CREATE INDEX IDX_TRIPS_STATUS_TIME ON TRIP_HEADERS (TRIP_STATUS, REQUEST_TIMESTAMP)');
    run_ddl('CREATE INDEX IDX_VEH_DRIVER ON VEHICLES (DRIVER_ID)');
    run_ddl('CREATE INDEX IDX_REVIEWS_TRIP ON TRIP_REVIEWS (TRIP_ID)');
    run_ddl('CREATE INDEX IDX_RIDERS_CITY ON SA_RIDERS (HOME_CITY, PROVINCE)');
END;
/
 
-- Refresh optimiser statistics after loading and indexing
BEGIN
    DBMS_STATS.GATHER_SCHEMA_STATS(ownname => USER);
END;
/
 
 
-- ============================================================
-- STEP 6: OPTIONAL - STORE MOBILE NUMBERS AS TEXT
-- MOBILE_NUMBER is NUMBER, so a leading zero or "+" cannot be kept.
-- Your length check (file 02, section C4) showed every number is
-- 11 digits long. That pattern is usually the South African
-- country code 27 + a 9-digit number (e.g. 27XXXXXXXXX), NOT a
-- number with a missing leading 0. Check the prefix first:
--
--   SELECT SUBSTR(TO_CHAR(MOBILE_NUMBER), 1, 2) AS PREFIX, COUNT(*)
--   FROM SA_RIDERS WHERE MOBILE_NUMBER IS NOT NULL
--   GROUP BY SUBSTR(TO_CHAR(MOBILE_NUMBER), 1, 2);
--
-- If the prefix is 27 for every row, converting to text with a
-- "+" in front is safe. Left commented out; it is optional.
-- ============================================================
-- ALTER TABLE SA_RIDERS ADD (MOBILE_NUMBER_TXT VARCHAR2(15));
-- UPDATE SA_RIDERS
--    SET MOBILE_NUMBER_TXT = '+' || TO_CHAR(MOBILE_NUMBER)
--  WHERE MOBILE_NUMBER IS NOT NULL;
-- COMMIT;
-- ALTER TABLE SA_RIDERS DROP COLUMN MOBILE_NUMBER;
-- ALTER TABLE SA_RIDERS RENAME COLUMN MOBILE_NUMBER_TXT TO MOBILE_NUMBER;
 
 
-- ============================================================
-- STEP 7: PROOF QUERIES (screenshot these for the report)
-- ============================================================
 
-- 7a. Every constraint on the seven tables
SELECT c.TABLE_NAME,
       c.CONSTRAINT_NAME,
       CASE c.CONSTRAINT_TYPE
            WHEN 'P' THEN 'PRIMARY KEY'
            WHEN 'R' THEN 'FOREIGN KEY'
            WHEN 'U' THEN 'UNIQUE'
            WHEN 'C' THEN 'CHECK / NOT NULL'
       END AS CONSTRAINT_KIND,
       c.STATUS
FROM USER_CONSTRAINTS c
WHERE c.TABLE_NAME IN ('SA_DRIVERS','SA_RIDERS','VEHICLES',
                       'PRICING_SURGE_ZONES','TRIP_HEADERS',
                       'TRIP_FARE_BREAKDOWN','TRIP_REVIEWS')
ORDER BY c.TABLE_NAME, c.CONSTRAINT_TYPE, c.CONSTRAINT_NAME;
 
-- 7b. Every index on the seven tables
SELECT i.TABLE_NAME, i.INDEX_NAME, i.UNIQUENESS,
       LISTAGG(ic.COLUMN_NAME, ', ')
           WITHIN GROUP (ORDER BY ic.COLUMN_POSITION) AS INDEXED_COLUMNS
FROM USER_INDEXES i
JOIN USER_IND_COLUMNS ic ON i.INDEX_NAME = ic.INDEX_NAME
WHERE i.TABLE_NAME IN ('SA_DRIVERS','SA_RIDERS','VEHICLES',
                       'PRICING_SURGE_ZONES','TRIP_HEADERS',
                       'TRIP_FARE_BREAKDOWN','TRIP_REVIEWS')
GROUP BY i.TABLE_NAME, i.INDEX_NAME, i.UNIQUENESS
ORDER BY i.TABLE_NAME, i.INDEX_NAME;
 
-- 7c. Key column data types now match across related tables
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, DATA_LENGTH, NULLABLE
FROM USER_TAB_COLUMNS
WHERE COLUMN_NAME IN ('TRIP_ID','RIDER_ID','DRIVER_ID','ZONE_ID')
  AND TABLE_NAME IN ('SA_DRIVERS','SA_RIDERS','VEHICLES',
                     'PRICING_SURGE_ZONES','TRIP_HEADERS',
                     'TRIP_FARE_BREAKDOWN','TRIP_REVIEWS')
ORDER BY COLUMN_NAME, TABLE_NAME;
 
-- >>>>>>>>>>>>>>>> 04_validation_checks.sql <<<<<<<<<<<<<<<<
-- ============================================================
-- RIDEMETRICS PHASE 2  |  CMPG321
-- FILE 04: DATA VALIDATION AND QUALITY CHECKS
-- Database: Oracle (SQL Developer)
--
-- Consolidates Worksheets 1-3. Run each query with Ctrl+Enter
-- to see the result grid. Every RESULT column should say PASS.
-- ============================================================
 
 

-- V1. PRIMARY KEY QUALITY

SELECT TABLE_NAME, TOTAL_ROWS, NON_NULL_KEYS, UNIQUE_KEYS,
       CASE WHEN TOTAL_ROWS = NON_NULL_KEYS
             AND TOTAL_ROWS = UNIQUE_KEYS
            THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (
    SELECT 'SA_DRIVERS' AS TABLE_NAME, COUNT(*) AS TOTAL_ROWS,
           COUNT(DRIVER_ID) AS NON_NULL_KEYS,
           COUNT(DISTINCT DRIVER_ID) AS UNIQUE_KEYS
    FROM SA_DRIVERS
    UNION ALL
    SELECT 'SA_RIDERS', COUNT(*), COUNT(RIDER_ID),
           COUNT(DISTINCT RIDER_ID) FROM SA_RIDERS
    UNION ALL
    SELECT 'VEHICLES', COUNT(*), COUNT(VEHICLE_ID),
           COUNT(DISTINCT VEHICLE_ID) FROM VEHICLES
    UNION ALL
    SELECT 'PRICING_SURGE_ZONES', COUNT(*), COUNT(ZONE_ID),
           COUNT(DISTINCT ZONE_ID) FROM PRICING_SURGE_ZONES
    UNION ALL
    SELECT 'TRIP_HEADERS', COUNT(*), COUNT(TRIP_ID),
           COUNT(DISTINCT TRIP_ID) FROM TRIP_HEADERS
    UNION ALL
    SELECT 'TRIP_FARE_BREAKDOWN', COUNT(*), COUNT(TRIP_ID),
           COUNT(DISTINCT TRIP_ID) FROM TRIP_FARE_BREAKDOWN
    UNION ALL
    SELECT 'TRIP_REVIEWS', COUNT(*), COUNT(REVIEW_ID),
           COUNT(DISTINCT REVIEW_ID) FROM TRIP_REVIEWS
)
ORDER BY TABLE_NAME;
 
 

-- V2. REFERENTIAL INTEGRITY (orphaned child records)

SELECT RELATIONSHIP, UNMATCHED_RECORDS,
       CASE WHEN UNMATCHED_RECORDS = 0
            THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (
    SELECT 'TRIP_HEADERS -> SA_RIDERS' AS RELATIONSHIP,
           COUNT(*) AS UNMATCHED_RECORDS
    FROM TRIP_HEADERS t
    WHERE NOT EXISTS (SELECT 1 FROM SA_RIDERS r
                      WHERE r.RIDER_ID = t.RIDER_ID)
    UNION ALL
    SELECT 'TRIP_HEADERS -> SA_DRIVERS', COUNT(*)
    FROM TRIP_HEADERS t
    WHERE NOT EXISTS (SELECT 1 FROM SA_DRIVERS d
                      WHERE d.DRIVER_ID = t.DRIVER_ID)
    UNION ALL
    SELECT 'TRIP_HEADERS -> PRICING_SURGE_ZONES', COUNT(*)
    FROM TRIP_HEADERS t
    WHERE NOT EXISTS (SELECT 1 FROM PRICING_SURGE_ZONES z
                      WHERE z.ZONE_ID = t.ZONE_ID)
    UNION ALL
    SELECT 'VEHICLES -> SA_DRIVERS', COUNT(*)
    FROM VEHICLES v
    WHERE NOT EXISTS (SELECT 1 FROM SA_DRIVERS d
                      WHERE d.DRIVER_ID = v.DRIVER_ID)
    UNION ALL
    SELECT 'TRIP_FARE_BREAKDOWN -> TRIP_HEADERS', COUNT(*)
    FROM TRIP_FARE_BREAKDOWN f
    WHERE NOT EXISTS (SELECT 1 FROM TRIP_HEADERS t
                      WHERE t.TRIP_ID = f.TRIP_ID)
    UNION ALL
    SELECT 'TRIP_REVIEWS -> TRIP_HEADERS', COUNT(*)
    FROM TRIP_REVIEWS rv
    WHERE NOT EXISTS (SELECT 1 FROM TRIP_HEADERS t
                      WHERE t.TRIP_ID = rv.TRIP_ID)
    UNION ALL
    -- Phase 1 says every trip has exactly one fare record (1:1)
    SELECT 'TRIP_HEADERS without a fare record', COUNT(*)
    FROM TRIP_HEADERS t
    WHERE NOT EXISTS (SELECT 1 FROM TRIP_FARE_BREAKDOWN f
                      WHERE f.TRIP_ID = t.TRIP_ID)
);
 
 
-- ============================================================
-- V3. MISSING VALUES IN THE ANALYSIS COLUMNS
-- Phase 1: no missing values in the core columns.
-- CANCELLATION_REASON is checked separately (V5).
-- ============================================================
SELECT CHECK_NAME, MISSING_VALUES,
       CASE WHEN MISSING_VALUES = 0
            THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (
    SELECT 'SA_RIDERS.HOME_CITY' AS CHECK_NAME, COUNT(*) AS MISSING_VALUES
    FROM SA_RIDERS WHERE HOME_CITY IS NULL
    UNION ALL
    SELECT 'SA_RIDERS.PROVINCE', COUNT(*)
    FROM SA_RIDERS WHERE PROVINCE IS NULL
    UNION ALL
    SELECT 'SA_RIDERS.PREFERRED_PAYMENT', COUNT(*)
    FROM SA_RIDERS WHERE PREFERRED_PAYMENT IS NULL
    UNION ALL
    SELECT 'TRIP_HEADERS.RIDE_CATEGORY', COUNT(*)
    FROM TRIP_HEADERS WHERE RIDE_CATEGORY IS NULL
    UNION ALL
    SELECT 'TRIP_HEADERS.REQUEST_TIMESTAMP', COUNT(*)
    FROM TRIP_HEADERS WHERE REQUEST_TIMESTAMP IS NULL
    UNION ALL
    SELECT 'TRIP_HEADERS.TRIP_STATUS', COUNT(*)
    FROM TRIP_HEADERS WHERE TRIP_STATUS IS NULL
    UNION ALL
    SELECT 'TRIP_FARE_BREAKDOWN.PAYMENT_METHOD', COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE PAYMENT_METHOD IS NULL
    UNION ALL
    SELECT 'TRIP_FARE_BREAKDOWN.TOTAL_FARE_ZAR', COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE TOTAL_FARE_ZAR IS NULL
    UNION ALL
    SELECT 'TRIP_FARE_BREAKDOWN.TIP_ZAR', COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE TIP_ZAR IS NULL
    UNION ALL
    SELECT 'PRICING_SURGE_ZONES.CITY', COUNT(*)
    FROM PRICING_SURGE_ZONES WHERE CITY IS NULL
);
 
 
-- ============================================================
-- V4. DOMAIN CHECKS (values outside the documented lists)
-- ============================================================
SELECT CHECK_NAME, INVALID_ROWS,
       CASE WHEN INVALID_ROWS = 0
            THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (
    SELECT 'TRIP_STATUS' AS CHECK_NAME, COUNT(*) AS INVALID_ROWS
    FROM TRIP_HEADERS
    WHERE TRIP_STATUS NOT IN ('COMPLETED','CANCELLED_BY_RIDER',
                              'CANCELLED_BY_DRIVER')
    UNION ALL
    SELECT 'PAYMENT_METHOD', COUNT(*)
    FROM TRIP_FARE_BREAKDOWN
    WHERE PAYMENT_METHOD NOT IN ('CASH','CREDIT_CARD','DEBIT_CARD',
                                 'EFT_OZOW','IN_APP_WALLET')
    UNION ALL
    SELECT 'PREFERRED_PAYMENT', COUNT(*)
    FROM SA_RIDERS
    WHERE PREFERRED_PAYMENT NOT IN ('CASH','CREDIT_CARD','DEBIT_CARD',
                                    'EFT_OZOW','IN_APP_WALLET')
    UNION ALL
    SELECT 'CANCELLATION_REASON', COUNT(*)
    FROM TRIP_HEADERS
    WHERE CANCELLATION_REASON IS NOT NULL
      AND CANCELLATION_REASON NOT IN ('CHANGED_MIND','DRIVER_TOO_FAR',
            'SAFETY_CONCERN','RIDER_NO_SHOW','PRICING_SURGE',
            'TRAFFIC_DELAY')
);
 
 
-- ============================================================
-- V5. CANCELLATION REASON LOGIC
-- Reason must be NULL on completed trips and present on
-- cancelled trips (a structural NULL, not a data error).
-- ============================================================
SELECT TRIP_STATUS,
       COUNT(*) AS TRIPS,
       SUM(CASE WHEN CANCELLATION_REASON IS NULL THEN 1 ELSE 0 END)
           AS NULL_REASONS,
       SUM(CASE WHEN CANCELLATION_REASON IS NOT NULL THEN 1 ELSE 0 END)
           AS REASONS_PRESENT
FROM TRIP_HEADERS
GROUP BY TRIP_STATUS
ORDER BY TRIP_STATUS;
 
 
-- ============================================================
-- V6. NUMERIC RANGE CHECKS (Phase 1 observed ranges)
-- ============================================================
SELECT CHECK_NAME, INVALID_ROWS,
       CASE WHEN INVALID_ROWS = 0
            THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (
    SELECT 'DRIVER_RATING outside 0-5' AS CHECK_NAME, COUNT(*) AS INVALID_ROWS
    FROM SA_DRIVERS
    WHERE DRIVER_RATING NOT BETWEEN 0 AND 5
    UNION ALL
    SELECT 'PLATFORM_COMMISSION_PCT outside 0-1 (stored as a fraction)', COUNT(*)
    FROM SA_DRIVERS
    WHERE PLATFORM_COMMISSION_PCT NOT BETWEEN 0 AND 1
    UNION ALL
    SELECT 'DISTANCE_KM negative', COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE DISTANCE_KM < 0
    UNION ALL
    SELECT 'DURATION_MINUTES negative', COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE DURATION_MINUTES < 0
    UNION ALL
    SELECT 'TOTAL_FARE_ZAR negative', COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE TOTAL_FARE_ZAR < 0
    UNION ALL
    SELECT 'TIP_ZAR negative', COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE TIP_ZAR < 0
    UNION ALL
    SELECT 'SURGE_MULTIPLIER below 1.0', COUNT(*)
    FROM TRIP_FARE_BREAKDOWN WHERE SURGE_MULTIPLIER < 1
    UNION ALL
    SELECT 'RIDER_RATING_OF_DRIVER outside 0-5', COUNT(*)
    FROM TRIP_REVIEWS
    WHERE RIDER_RATING_OF_DRIVER NOT BETWEEN 0 AND 5
    UNION ALL
    SELECT 'DRIVER_RATING_OF_RIDER outside 0-5', COUNT(*)
    FROM TRIP_REVIEWS
    WHERE DRIVER_RATING_OF_RIDER NOT BETWEEN 0 AND 5
);
 
-- Observed ranges, to compare with the Phase 1 data dictionary
SELECT MIN(DISTANCE_KM) AS MIN_KM, MAX(DISTANCE_KM) AS MAX_KM,
       MIN(DURATION_MINUTES) AS MIN_MIN, MAX(DURATION_MINUTES) AS MAX_MIN,
       MIN(SURGE_MULTIPLIER) AS MIN_SURGE, MAX(SURGE_MULTIPLIER) AS MAX_SURGE,
       MIN(TOTAL_FARE_ZAR) AS MIN_FARE, MAX(TOTAL_FARE_ZAR) AS MAX_FARE,
       ROUND(AVG(TOTAL_FARE_ZAR), 2) AS AVG_FARE
FROM TRIP_FARE_BREAKDOWN;
 
SELECT TIP_ZAR, COUNT(*) AS TRIPS
FROM TRIP_FARE_BREAKDOWN
GROUP BY TIP_ZAR
ORDER BY TIP_ZAR;
 
 
-- ============================================================
-- V7. DUPLICATES
-- ============================================================
-- Duplicate licence plates (should return no rows)
SELECT LICENSE_PLATE, COUNT(*) AS OCCURRENCES
FROM VEHICLES
GROUP BY LICENSE_PLATE
HAVING COUNT(*) > 1;
 
-- Duplicate mobile numbers (should return no rows)
SELECT MOBILE_NUMBER, COUNT(*) AS OCCURRENCES
FROM SA_RIDERS
GROUP BY MOBILE_NUMBER
HAVING COUNT(*) > 1;
 
 
-- ============================================================
-- V8. ZERO-VALUE FARES (Phase 1 limitation: treat with care)
-- Shows where zero fares sit, so spend metrics use the right
-- scope (all trips vs completed trips only).
-- ============================================================
SELECT t.TRIP_STATUS,
       COUNT(*) AS TRIPS,
       SUM(CASE WHEN f.TOTAL_FARE_ZAR = 0 THEN 1 ELSE 0 END) AS ZERO_FARE_TRIPS,
       SUM(CASE WHEN f.DISTANCE_KM = 0 AND f.DURATION_MINUTES = 0
                THEN 1 ELSE 0 END) AS ZERO_DISTANCE_AND_DURATION
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
GROUP BY t.TRIP_STATUS
ORDER BY t.TRIP_STATUS;
 
 
-- ============================================================
-- V9. FARE ARITHMETIC (does the fare add up?)
-- Informational: compares the recorded total with the sum of
-- its components. Differences are a finding to report, not
-- necessarily an error (distance/time charges are not stored).
-- ============================================================
SELECT COUNT(*) AS TRIPS_CHECKED,
       SUM(CASE WHEN ABS(TOTAL_FARE_ZAR
                  - (PLATFORM_COMMISSION_ZAR + DRIVER_PAYOUT_ZAR)) <= 0.05
                THEN 1 ELSE 0 END) AS TOTAL_EQUALS_COMMISSION_PLUS_PAYOUT,
       SUM(CASE WHEN ABS(TOTAL_FARE_ZAR
                  - (PLATFORM_COMMISSION_ZAR + DRIVER_PAYOUT_ZAR)) > 0.05
                THEN 1 ELSE 0 END) AS DIFFERENT
FROM TRIP_FARE_BREAKDOWN
WHERE TOTAL_FARE_ZAR > 0;
 
-- >>>>>>>>>>>>>>>> 05_queries_rq1_rq12.sql <<<<<<<<<<<<<<<<
-- ============================================================
-- RIDEMETRICS PHASE 2  |  CMPG321
-- FILE 05: SQL QUERY DEVELOPMENT  (Research Questions RQ1-RQ12)
-- Focus: Rider Purchasing Patterns & Payment Channel Preferences
-- Database: Oracle (SQL Developer)
--
-- Run each query on its own (Ctrl+Enter) so the result grid
-- appears. Export grids to Excel/CSV for the report charts
-- (right-click the grid > Export).
--
-- Conventions (from Phase 1, section 3.8):
--   * "Spend" metrics use COMPLETED trips unless the query says
--     ALL TRIPS, because cancelled trips carry zero-value fares.
--   * HOME_CITY / PROVINCE = the rider's home location.
--     ZONE CITY (z.CITY)    = where the trip happened.
--     They are different concepts and are kept separate.
--   * Payment PREFERENCE (SA_RIDERS) is not the same as the
--     payment METHOD actually used (TRIP_FARE_BREAKDOWN).
--   * There is no payment-failure column, so results are
--     reported as associations with cancellation status only.
--
-- Techniques demonstrated (for the marker):
--   inner/left/full outer joins, GROUP BY/HAVING, ROLLUP,
--   subqueries, CTEs, RANK, NTILE, LAG, SUM() OVER,
--   MEDIAN, PERCENTILE_CONT, CORR, CASE bucketing, views.
-- ============================================================
 
 
-- ############################################################
-- PART A: DESCRIPTIVE ANALYSES (from Worksheets 4 and 5)
-- ############################################################
 
-- A1. Rider trip frequency and spending (top 50 spenders, all trips)
SELECT r.RIDER_ID, r.HOME_CITY, r.PROVINCE, r.PREFERRED_PAYMENT,
       COUNT(t.TRIP_ID)                     AS TOTAL_TRIPS,
       COUNT(f.TOTAL_FARE_ZAR)              AS TRIPS_WITH_FARES,
       ROUND(SUM(f.TOTAL_FARE_ZAR), 2)      AS TOTAL_SPENDING_ZAR,
       ROUND(AVG(f.TOTAL_FARE_ZAR), 2)      AS AVERAGE_FARE_ZAR
FROM SA_RIDERS r
LEFT JOIN TRIP_HEADERS t         ON r.RIDER_ID = t.RIDER_ID
LEFT JOIN TRIP_FARE_BREAKDOWN f  ON t.TRIP_ID  = f.TRIP_ID
GROUP BY r.RIDER_ID, r.HOME_CITY, r.PROVINCE, r.PREFERRED_PAYMENT
ORDER BY TOTAL_SPENDING_ZAR DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;
 
 
-- A2. Payment method performance (ALL TRIPS) with share of spend
SELECT f.PAYMENT_METHOD,
       COUNT(*)                          AS TOTAL_TRIPS,
       ROUND(SUM(f.TOTAL_FARE_ZAR), 2)   AS TOTAL_SPENDING_ZAR,
       ROUND(AVG(f.TOTAL_FARE_ZAR), 2)   AS AVERAGE_FARE_ZAR,
       ROUND(100 * SUM(f.TOTAL_FARE_ZAR)
             / SUM(SUM(f.TOTAL_FARE_ZAR)) OVER (), 2) AS PCT_OF_TOTAL_SPEND
FROM TRIP_FARE_BREAKDOWN f
GROUP BY f.PAYMENT_METHOD
ORDER BY TOTAL_SPENDING_ZAR DESC;
 
 
-- A3. Payment method performance (COMPLETED TRIPS ONLY)
SELECT f.PAYMENT_METHOD,
       COUNT(*)                          AS COMPLETED_TRIPS,
       ROUND(SUM(f.TOTAL_FARE_ZAR), 2)   AS TOTAL_SPENDING_ZAR,
       ROUND(AVG(f.TOTAL_FARE_ZAR), 2)   AS AVERAGE_FARE_ZAR,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)
                                         AS PCT_OF_COMPLETED_TRIPS
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
WHERE t.TRIP_STATUS = 'COMPLETED'
GROUP BY f.PAYMENT_METHOD
ORDER BY COMPLETED_TRIPS DESC;
 
 
-- A4. Trip status summary with percentages
SELECT TRIP_STATUS,
       COUNT(*) AS NUMBER_OF_TRIPS,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS PCT_OF_TRIPS
FROM TRIP_HEADERS
GROUP BY TRIP_STATUS
ORDER BY NUMBER_OF_TRIPS DESC;
 
 
-- A5. Fare values by trip status (shows the zero-fare issue)
SELECT t.TRIP_STATUS,
       COUNT(*)                                            AS TOTAL_TRIPS,
       SUM(CASE WHEN f.TOTAL_FARE_ZAR = 0 THEN 1 ELSE 0 END) AS ZERO_FARE_TRIPS,
       ROUND(SUM(f.TOTAL_FARE_ZAR), 2)                     AS TOTAL_FARES_ZAR,
       ROUND(AVG(f.TOTAL_FARE_ZAR), 2)                     AS AVERAGE_FARE_ZAR
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
GROUP BY t.TRIP_STATUS
ORDER BY t.TRIP_STATUS;
 
 
-- A6. Overall findings: completion and cancellation rates
SELECT COUNT(*) AS TOTAL_TRIPS,
       SUM(CASE WHEN TRIP_STATUS = 'COMPLETED' THEN 1 ELSE 0 END)
           AS COMPLETED_TRIPS,
       SUM(CASE WHEN TRIP_STATUS = 'CANCELLED_BY_RIDER' THEN 1 ELSE 0 END)
           AS RIDER_CANCELLATIONS,
       SUM(CASE WHEN TRIP_STATUS = 'CANCELLED_BY_DRIVER' THEN 1 ELSE 0 END)
           AS DRIVER_CANCELLATIONS,
       ROUND(100 * SUM(CASE WHEN TRIP_STATUS = 'COMPLETED' THEN 1 ELSE 0 END)
             / COUNT(*), 2) AS COMPLETION_RATE_PERCENT,
       ROUND(100 * SUM(CASE WHEN TRIP_STATUS <> 'COMPLETED' THEN 1 ELSE 0 END)
             / COUNT(*), 2) AS CANCELLATION_RATE_PERCENT
FROM TRIP_HEADERS;
 
-- A6b. Completed-trip totals
SELECT COUNT(*)                        AS COMPLETED_TRIPS,
       ROUND(SUM(f.TOTAL_FARE_ZAR), 2) AS TOTAL_SPENDING_ZAR,
       ROUND(AVG(f.TOTAL_FARE_ZAR), 2) AS AVERAGE_FARE_ZAR
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
WHERE t.TRIP_STATUS = 'COMPLETED';
 
 
-- A7. OUTER JOIN: review coverage and ratings by payment method
-- (only some trips are reviewed, so LEFT JOIN keeps the rest)
SELECT f.PAYMENT_METHOD,
       COUNT(t.TRIP_ID)                      AS COMPLETED_TRIPS,
       COUNT(rv.REVIEW_ID)                   AS REVIEWED_TRIPS,
       ROUND(100 * COUNT(rv.REVIEW_ID) / COUNT(t.TRIP_ID), 2)
                                             AS REVIEW_RATE_PCT,
       ROUND(AVG(rv.RIDER_RATING_OF_DRIVER), 2) AS AVG_RATING_OF_DRIVER
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f      ON t.TRIP_ID = f.TRIP_ID
LEFT JOIN TRIP_REVIEWS rv       ON t.TRIP_ID = rv.TRIP_ID
WHERE t.TRIP_STATUS = 'COMPLETED'
GROUP BY f.PAYMENT_METHOD
ORDER BY REVIEW_RATE_PCT DESC;
 
 
-- ############################################################
-- PART B: RESEARCH QUESTIONS
-- ############################################################
 
-- ============================================================
-- RQ1. What are the overall distributions of rider payment
--      preferences and observed trip payment methods?
-- Techniques: CTEs, FULL OUTER JOIN, window percentages
-- ============================================================
WITH PREF AS (
    SELECT PREFERRED_PAYMENT AS METHOD, COUNT(*) AS RIDERS
    FROM SA_RIDERS
    GROUP BY PREFERRED_PAYMENT
),
OBS AS (
    SELECT PAYMENT_METHOD AS METHOD, COUNT(*) AS TRIPS
    FROM TRIP_FARE_BREAKDOWN
    GROUP BY PAYMENT_METHOD
)
SELECT NVL(p.METHOD, o.METHOD) AS PAYMENT_METHOD,
       p.RIDERS                AS RIDERS_PREFERRING,
       ROUND(100 * p.RIDERS / SUM(p.RIDERS) OVER (), 2) AS PCT_OF_RIDERS,
       o.TRIPS                 AS TRIPS_PAID_WITH,
       ROUND(100 * o.TRIPS / SUM(o.TRIPS) OVER (), 2)   AS PCT_OF_TRIPS
FROM PREF p
FULL OUTER JOIN OBS o ON p.METHOD = o.METHOD
ORDER BY PAYMENT_METHOD;
 
 
-- ============================================================
-- RQ2. To what extent does a rider's stated preferred payment
--      predict the method actually used?
-- Techniques: joins, conditional aggregation, ROLLUP, CTEs
-- ============================================================
 
-- RQ2a. Match rate by preferred method, with an overall row
SELECT CASE WHEN GROUPING(r.PREFERRED_PAYMENT) = 1
            THEN 'ALL RIDERS' ELSE r.PREFERRED_PAYMENT END AS PREFERRED_PAYMENT,
       COUNT(*) AS TRIPS,
       SUM(CASE WHEN f.PAYMENT_METHOD = r.PREFERRED_PAYMENT
                THEN 1 ELSE 0 END) AS TRIPS_USING_PREFERRED,
       ROUND(100 * SUM(CASE WHEN f.PAYMENT_METHOD = r.PREFERRED_PAYMENT
                            THEN 1 ELSE 0 END) / COUNT(*), 2) AS MATCH_RATE_PCT
FROM SA_RIDERS r
JOIN TRIP_HEADERS t        ON r.RIDER_ID = t.RIDER_ID
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID  = f.TRIP_ID
GROUP BY ROLLUP (r.PREFERRED_PAYMENT)
ORDER BY GROUPING(r.PREFERRED_PAYMENT), MATCH_RATE_PCT DESC;
 
-- RQ2b. Preferred vs actual crosstab (rows = preference)
SELECT r.PREFERRED_PAYMENT,
       f.PAYMENT_METHOD AS ACTUAL_PAYMENT_METHOD,
       COUNT(*) AS TRIPS,
       ROUND(100 * COUNT(*) / SUM(COUNT(*))
             OVER (PARTITION BY r.PREFERRED_PAYMENT), 2) AS PCT_OF_PREFERENCE_GROUP
FROM SA_RIDERS r
JOIN TRIP_HEADERS t        ON r.RIDER_ID = t.RIDER_ID
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID  = f.TRIP_ID
GROUP BY r.PREFERRED_PAYMENT, f.PAYMENT_METHOD
ORDER BY r.PREFERRED_PAYMENT, TRIPS DESC;
 
-- RQ2c. Per-rider consistency: how many riders mostly use
--       their stated preference?
WITH RIDER_MATCH AS (
    SELECT r.RIDER_ID,
           COUNT(*) AS TRIPS,
           AVG(CASE WHEN f.PAYMENT_METHOD = r.PREFERRED_PAYMENT
                    THEN 1 ELSE 0 END) AS MATCH_RATE
    FROM SA_RIDERS r
    JOIN TRIP_HEADERS t        ON r.RIDER_ID = t.RIDER_ID
    JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID  = f.TRIP_ID
    GROUP BY r.RIDER_ID
),
BANDED AS (
    SELECT RIDER_ID, TRIPS, MATCH_RATE,
           CASE WHEN MATCH_RATE >= 0.75 THEN '4) 75-100% match'
                WHEN MATCH_RATE >= 0.50 THEN '3) 50-74% match'
                WHEN MATCH_RATE >= 0.25 THEN '2) 25-49% match'
                ELSE '1) 0-24% match' END AS MATCH_BAND
    FROM RIDER_MATCH
)
SELECT MATCH_BAND,
       COUNT(*) AS RIDERS,
       ROUND(AVG(TRIPS), 1) AS AVG_TRIPS_PER_RIDER,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS PCT_OF_RIDERS
FROM BANDED
GROUP BY MATCH_BAND
ORDER BY MATCH_BAND;
 
 
-- ============================================================
-- RQ3. How do average, median and total spend differ across
--      payment methods?
-- Techniques: MEDIAN, STDDEV, UNION ALL (all vs completed)
-- ============================================================
SELECT 'ALL TRIPS' AS SCOPE,
       f.PAYMENT_METHOD,
       COUNT(*)                           AS TRIPS,
       ROUND(SUM(f.TOTAL_FARE_ZAR), 2)    AS TOTAL_SPEND_ZAR,
       ROUND(AVG(f.TOTAL_FARE_ZAR), 2)    AS AVG_FARE_ZAR,
       ROUND(MEDIAN(f.TOTAL_FARE_ZAR), 2) AS MEDIAN_FARE_ZAR,
       ROUND(STDDEV(f.TOTAL_FARE_ZAR), 2) AS STDDEV_FARE_ZAR
FROM TRIP_FARE_BREAKDOWN f
GROUP BY f.PAYMENT_METHOD
UNION ALL
SELECT 'COMPLETED ONLY',
       f.PAYMENT_METHOD,
       COUNT(*),
       ROUND(SUM(f.TOTAL_FARE_ZAR), 2),
       ROUND(AVG(f.TOTAL_FARE_ZAR), 2),
       ROUND(MEDIAN(f.TOTAL_FARE_ZAR), 2),
       ROUND(STDDEV(f.TOTAL_FARE_ZAR), 2)
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
WHERE t.TRIP_STATUS = 'COMPLETED'
GROUP BY f.PAYMENT_METHOD
ORDER BY SCOPE, TOTAL_SPEND_ZAR DESC;
 
 
-- ============================================================
-- RQ4. How do trip distance and duration differ by payment
--      method, and how are they associated with total fare?
-- Techniques: CORR, ROLLUP, CASE bucketing (associations only,
-- no causal claims - see Phase 1 limitations)
-- ============================================================
 
-- RQ4a. By payment method, with an overall row (completed trips)
SELECT CASE WHEN GROUPING(f.PAYMENT_METHOD) = 1
            THEN 'ALL METHODS' ELSE f.PAYMENT_METHOD END AS PAYMENT_METHOD,
       COUNT(*) AS COMPLETED_TRIPS,
       ROUND(AVG(f.DISTANCE_KM), 2)        AS AVG_DISTANCE_KM,
       ROUND(AVG(f.DURATION_MINUTES), 2)   AS AVG_DURATION_MIN,
       ROUND(AVG(f.TOTAL_FARE_ZAR), 2)     AS AVG_FARE_ZAR,
       ROUND(SUM(f.TOTAL_FARE_ZAR)
             / NULLIF(SUM(f.DISTANCE_KM), 0), 2) AS FARE_PER_KM,
       ROUND(CORR(f.DISTANCE_KM, f.TOTAL_FARE_ZAR), 3)      AS CORR_DISTANCE_FARE,
       ROUND(CORR(f.DURATION_MINUTES, f.TOTAL_FARE_ZAR), 3) AS CORR_DURATION_FARE
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
WHERE t.TRIP_STATUS = 'COMPLETED'
GROUP BY ROLLUP (f.PAYMENT_METHOD)
ORDER BY GROUPING(f.PAYMENT_METHOD), PAYMENT_METHOD;
 
-- RQ4b. Payment mix and average fare by distance band
WITH BANDED AS (
    SELECT f.PAYMENT_METHOD, f.TOTAL_FARE_ZAR,
           CASE WHEN f.DISTANCE_KM < 5  THEN '1) under 5 km'
                WHEN f.DISTANCE_KM < 10 THEN '2) 5-10 km'
                WHEN f.DISTANCE_KM < 20 THEN '3) 10-20 km'
                WHEN f.DISTANCE_KM < 30 THEN '4) 20-30 km'
                ELSE '5) 30 km and over' END AS DISTANCE_BAND
    FROM TRIP_HEADERS t
    JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
    WHERE t.TRIP_STATUS = 'COMPLETED'
)
SELECT DISTANCE_BAND,
       PAYMENT_METHOD,
       COUNT(*) AS TRIPS,
       ROUND(100 * COUNT(*) / SUM(COUNT(*))
             OVER (PARTITION BY DISTANCE_BAND), 2) AS PCT_OF_BAND,
       ROUND(AVG(TOTAL_FARE_ZAR), 2) AS AVG_FARE_ZAR
FROM BANDED
GROUP BY DISTANCE_BAND, PAYMENT_METHOD
ORDER BY DISTANCE_BAND, TRIPS DESC;
 
 
-- ============================================================
-- RQ5. Are riders who tip more frequently or generously
--      concentrated in particular cities, categories or channels?
-- Techniques: conditional aggregation, HAVING, RANK, CTEs, NTILE
-- ============================================================
 
-- RQ5a. Tip rate by trip city, payment method and ride category
SELECT z.CITY,
       f.PAYMENT_METHOD,
       t.RIDE_CATEGORY,
       COUNT(*) AS COMPLETED_TRIPS,
       SUM(CASE WHEN f.TIP_ZAR > 0 THEN 1 ELSE 0 END) AS TIPPED_TRIPS,
       ROUND(100 * SUM(CASE WHEN f.TIP_ZAR > 0 THEN 1 ELSE 0 END)
             / COUNT(*), 2) AS TIP_RATE_PCT,
       ROUND(AVG(CASE WHEN f.TIP_ZAR > 0 THEN f.TIP_ZAR END), 2)
             AS AVG_TIP_WHEN_TIPPED_ZAR,
       RANK() OVER (
           PARTITION BY z.CITY
           ORDER BY SUM(CASE WHEN f.TIP_ZAR > 0 THEN 1 ELSE 0 END)
                    / COUNT(*) DESC
       ) AS TIP_RATE_RANK_IN_CITY
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
JOIN PRICING_SURGE_ZONES z ON t.ZONE_ID = z.ZONE_ID
WHERE t.TRIP_STATUS = 'COMPLETED'
GROUP BY z.CITY, f.PAYMENT_METHOD, t.RIDE_CATEGORY
HAVING COUNT(*) >= 50
ORDER BY z.CITY, TIP_RATE_RANK_IN_CITY;
 
-- RQ5b. Rider-level tipper segments by home city
--       (top quartile of riders by personal tip rate)
WITH RIDER_TIP AS (
    SELECT r.RIDER_ID, r.HOME_CITY,
           COUNT(*) AS TRIPS,
           SUM(CASE WHEN f.TIP_ZAR > 0 THEN 1 ELSE 0 END) AS TIPPED_TRIPS,
           SUM(f.TIP_ZAR) AS TOTAL_TIPS
    FROM SA_RIDERS r
    JOIN TRIP_HEADERS t        ON r.RIDER_ID = t.RIDER_ID
    JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID  = f.TRIP_ID
    WHERE t.TRIP_STATUS = 'COMPLETED'
    GROUP BY r.RIDER_ID, r.HOME_CITY
    HAVING COUNT(*) >= 5
),
QUARTILED AS (
    SELECT rt.*,
           TIPPED_TRIPS / TRIPS AS TIP_RATE,
           NTILE(4) OVER (ORDER BY TIPPED_TRIPS / TRIPS DESC) AS TIP_QUARTILE
    FROM RIDER_TIP rt
)
SELECT HOME_CITY,
       COUNT(*) AS RIDERS,
       SUM(CASE WHEN TIP_QUARTILE = 1 THEN 1 ELSE 0 END) AS TOP_QUARTILE_TIPPERS,
       ROUND(100 * SUM(CASE WHEN TIP_QUARTILE = 1 THEN 1 ELSE 0 END)
             / COUNT(*), 2) AS PCT_RIDERS_IN_TOP_QUARTILE,
       ROUND(100 * AVG(TIP_RATE), 2) AS AVG_TIP_RATE_PCT,
       ROUND(SUM(TOTAL_TIPS) / SUM(TRIPS), 2) AS AVG_TIP_PER_TRIP_ZAR
FROM QUARTILED
GROUP BY HOME_CITY
ORDER BY PCT_RIDERS_IN_TOP_QUARTILE DESC;
 
 
-- ============================================================
-- RQ6. Which cities/provinces have the highest and lowest
--      adoption of each payment channel, and how does that
--      compare with stated preference?
-- Techniques: CTEs, window percentages, RANK, outer join
-- ============================================================
 
-- RQ6a. Rider home city: observed vs preferred share per method
WITH PREF AS (
    SELECT HOME_CITY, PREFERRED_PAYMENT AS METHOD,
           ROUND(100 * COUNT(*) / SUM(COUNT(*))
                 OVER (PARTITION BY HOME_CITY), 2) AS PREF_PCT
    FROM SA_RIDERS
    GROUP BY HOME_CITY, PREFERRED_PAYMENT
),
OBS AS (
    SELECT r.HOME_CITY, f.PAYMENT_METHOD AS METHOD,
           COUNT(*) AS TRIPS,
           ROUND(100 * COUNT(*) / SUM(COUNT(*))
                 OVER (PARTITION BY r.HOME_CITY), 2) AS OBS_PCT
    FROM SA_RIDERS r
    JOIN TRIP_HEADERS t        ON r.RIDER_ID = t.RIDER_ID
    JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID  = f.TRIP_ID
    GROUP BY r.HOME_CITY, f.PAYMENT_METHOD
)
SELECT o.HOME_CITY,
       o.METHOD AS PAYMENT_METHOD,
       p.PREF_PCT AS PREFERRED_PCT,
       o.OBS_PCT  AS ACTUAL_TRIP_PCT,
       ROUND(o.OBS_PCT - p.PREF_PCT, 2) AS GAP_PERCENTAGE_POINTS,
       RANK() OVER (PARTITION BY o.HOME_CITY ORDER BY o.OBS_PCT DESC)
           AS ADOPTION_RANK_IN_CITY
FROM OBS o
LEFT JOIN PREF p ON o.HOME_CITY = p.HOME_CITY AND o.METHOD = p.METHOD
ORDER BY o.HOME_CITY, ADOPTION_RANK_IN_CITY;
 
-- RQ6b. Rider province: adoption share, completed trips only
SELECT r.PROVINCE,
       f.PAYMENT_METHOD,
       COUNT(*) AS COMPLETED_TRIPS,
       ROUND(100 * COUNT(*) / SUM(COUNT(*))
             OVER (PARTITION BY r.PROVINCE), 2) AS PCT_OF_PROVINCE_TRIPS,
       ROUND(AVG(f.TOTAL_FARE_ZAR), 2) AS AVG_FARE_ZAR,
       RANK() OVER (PARTITION BY r.PROVINCE ORDER BY COUNT(*) DESC)
           AS ADOPTION_RANK_IN_PROVINCE
FROM SA_RIDERS r
JOIN TRIP_HEADERS t        ON r.RIDER_ID = t.RIDER_ID
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID  = f.TRIP_ID
WHERE t.TRIP_STATUS = 'COMPLETED'
GROUP BY r.PROVINCE, f.PAYMENT_METHOD
ORDER BY r.PROVINCE, ADOPTION_RANK_IN_PROVINCE;
 
-- RQ6c. TRIP zone city (where the trip happened), not home city
SELECT z.CITY AS TRIP_CITY,
       f.PAYMENT_METHOD,
       COUNT(*) AS COMPLETED_TRIPS,
       ROUND(100 * COUNT(*) / SUM(COUNT(*))
             OVER (PARTITION BY z.CITY), 2) AS PCT_OF_CITY_TRIPS,
       RANK() OVER (PARTITION BY z.CITY ORDER BY COUNT(*) DESC)
           AS ADOPTION_RANK_IN_CITY
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
JOIN PRICING_SURGE_ZONES z ON t.ZONE_ID = z.ZONE_ID
WHERE t.TRIP_STATUS = 'COMPLETED'
GROUP BY z.CITY, f.PAYMENT_METHOD
ORDER BY z.CITY, ADOPTION_RANK_IN_CITY;
 
 
-- ============================================================
-- RQ7. How do average fare and spend distributions differ
--      across ride categories and payment methods?
-- Techniques: MEDIAN, PERCENTILE_CONT (quartiles), window share
-- ============================================================
SELECT t.RIDE_CATEGORY,
       f.PAYMENT_METHOD,
       COUNT(*) AS COMPLETED_TRIPS,
       ROUND(100 * COUNT(*) / SUM(COUNT(*))
             OVER (PARTITION BY t.RIDE_CATEGORY), 2) AS PCT_OF_CATEGORY_TRIPS,
       ROUND(AVG(f.TOTAL_FARE_ZAR), 2) AS AVG_FARE_ZAR,
       ROUND(MEDIAN(f.TOTAL_FARE_ZAR), 2) AS MEDIAN_FARE_ZAR,
       ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP
             (ORDER BY f.TOTAL_FARE_ZAR), 2) AS Q1_FARE_ZAR,
       ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP
             (ORDER BY f.TOTAL_FARE_ZAR), 2) AS Q3_FARE_ZAR,
       ROUND(SUM(f.TOTAL_FARE_ZAR), 2) AS TOTAL_SPEND_ZAR
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
WHERE t.TRIP_STATUS = 'COMPLETED'
GROUP BY t.RIDE_CATEGORY, f.PAYMENT_METHOD
ORDER BY t.RIDE_CATEGORY, TOTAL_SPEND_ZAR DESC;
 
 
-- ============================================================
-- RQ8. Do cancellation rates differ between payment methods,
--      and is rider- or driver-initiated cancellation more
--      strongly linked to a specific channel?
-- Techniques: conditional aggregation, ROLLUP, RANK
-- Note: association with payment METHOD only. The dataset has
-- no payment-failure field (Phase 1, section 3.8).
-- ============================================================
SELECT CASE WHEN GROUPING(f.PAYMENT_METHOD) = 1
            THEN 'ALL METHODS' ELSE f.PAYMENT_METHOD END AS PAYMENT_METHOD,
       COUNT(*) AS TOTAL_TRIPS,
       SUM(CASE WHEN t.TRIP_STATUS = 'CANCELLED_BY_RIDER'  THEN 1 ELSE 0 END)
           AS RIDER_CANCELLED,
       SUM(CASE WHEN t.TRIP_STATUS = 'CANCELLED_BY_DRIVER' THEN 1 ELSE 0 END)
           AS DRIVER_CANCELLED,
       ROUND(100 * SUM(CASE WHEN t.TRIP_STATUS = 'CANCELLED_BY_RIDER'
                            THEN 1 ELSE 0 END) / COUNT(*), 2) AS RIDER_CANCEL_PCT,
       ROUND(100 * SUM(CASE WHEN t.TRIP_STATUS = 'CANCELLED_BY_DRIVER'
                            THEN 1 ELSE 0 END) / COUNT(*), 2) AS DRIVER_CANCEL_PCT,
       ROUND(100 * SUM(CASE WHEN t.TRIP_STATUS <> 'COMPLETED'
                            THEN 1 ELSE 0 END) / COUNT(*), 2) AS TOTAL_CANCEL_PCT
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
GROUP BY ROLLUP (f.PAYMENT_METHOD)
ORDER BY GROUPING(f.PAYMENT_METHOD), TOTAL_CANCEL_PCT DESC;
 
 
-- ============================================================
-- RQ9. Among cancelled trips, which reasons are most common for
--      each payment method and in each city?
-- Techniques: RANK, SUM() OVER, inline view to keep the top reason
-- ============================================================
 
-- RQ9a. Reason mix by payment method (all cities)
SELECT f.PAYMENT_METHOD,
       t.CANCELLATION_REASON,
       COUNT(*) AS CANCELLED_TRIPS,
       ROUND(100 * COUNT(*) / SUM(COUNT(*))
             OVER (PARTITION BY f.PAYMENT_METHOD), 2) AS PCT_OF_METHOD_CANCELLATIONS,
       RANK() OVER (PARTITION BY f.PAYMENT_METHOD ORDER BY COUNT(*) DESC)
           AS REASON_RANK
FROM TRIP_HEADERS t
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
WHERE t.TRIP_STATUS <> 'COMPLETED'
GROUP BY f.PAYMENT_METHOD, t.CANCELLATION_REASON
ORDER BY f.PAYMENT_METHOD, REASON_RANK;
 
-- RQ9b. Most common reason per trip city and payment method
SELECT CITY, PAYMENT_METHOD, CANCELLATION_REASON,
       CANCELLED_TRIPS, PCT_OF_GROUP
FROM (
    SELECT z.CITY,
           f.PAYMENT_METHOD,
           t.CANCELLATION_REASON,
           COUNT(*) AS CANCELLED_TRIPS,
           ROUND(100 * COUNT(*) / SUM(COUNT(*))
                 OVER (PARTITION BY z.CITY, f.PAYMENT_METHOD), 2) AS PCT_OF_GROUP,
           RANK() OVER (PARTITION BY z.CITY, f.PAYMENT_METHOD
                        ORDER BY COUNT(*) DESC) AS REASON_RANK
    FROM TRIP_HEADERS t
    JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
    JOIN PRICING_SURGE_ZONES z ON t.ZONE_ID = z.ZONE_ID
    WHERE t.TRIP_STATUS <> 'COMPLETED'
    GROUP BY z.CITY, f.PAYMENT_METHOD, t.CANCELLATION_REASON
)
WHERE REASON_RANK = 1
ORDER BY CITY, PAYMENT_METHOD;
 
 
-- ============================================================
-- RQ10. How does the surge multiplier affect spending and tip
--       behaviour across payment methods?
-- Techniques: CASE bands, LAG, CTE, conditional aggregation
-- ============================================================
 
-- RQ10a. Fare and tipping by surge band, change vs previous band
WITH BANDED AS (
    SELECT CASE WHEN f.SURGE_MULTIPLIER <= 1.0 THEN '1) No surge (1.0)'
                WHEN f.SURGE_MULTIPLIER <  1.5 THEN '2) Low (1.1-1.4)'
                WHEN f.SURGE_MULTIPLIER <  2.0 THEN '3) Medium (1.5-1.9)'
                ELSE '4) High (2.0+)' END AS SURGE_BAND,
           f.TOTAL_FARE_ZAR, f.TIP_ZAR, f.PAYMENT_METHOD
    FROM TRIP_HEADERS t
    JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
    WHERE t.TRIP_STATUS = 'COMPLETED'
)
SELECT SURGE_BAND,
       COUNT(*) AS COMPLETED_TRIPS,
       ROUND(AVG(TOTAL_FARE_ZAR), 2) AS AVG_FARE_ZAR,
       ROUND(100 * SUM(CASE WHEN TIP_ZAR > 0 THEN 1 ELSE 0 END)
             / COUNT(*), 2) AS TIP_RATE_PCT,
       ROUND(AVG(TIP_ZAR), 2) AS AVG_TIP_ZAR,
       ROUND(AVG(TOTAL_FARE_ZAR)
             - LAG(AVG(TOTAL_FARE_ZAR)) OVER (ORDER BY SURGE_BAND), 2)
             AS FARE_CHANGE_VS_PREVIOUS_BAND
FROM BANDED
GROUP BY SURGE_BAND
ORDER BY SURGE_BAND;
 
-- RQ10b. Same bands split by payment method
WITH BANDED AS (
    SELECT CASE WHEN f.SURGE_MULTIPLIER <= 1.0 THEN '1) No surge (1.0)'
                WHEN f.SURGE_MULTIPLIER <  1.5 THEN '2) Low (1.1-1.4)'
                WHEN f.SURGE_MULTIPLIER <  2.0 THEN '3) Medium (1.5-1.9)'
                ELSE '4) High (2.0+)' END AS SURGE_BAND,
           f.TOTAL_FARE_ZAR, f.TIP_ZAR, f.PAYMENT_METHOD
    FROM TRIP_HEADERS t
    JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
    WHERE t.TRIP_STATUS = 'COMPLETED'
)
SELECT PAYMENT_METHOD, SURGE_BAND,
       COUNT(*) AS COMPLETED_TRIPS,
       ROUND(AVG(TOTAL_FARE_ZAR), 2) AS AVG_FARE_ZAR,
       ROUND(100 * SUM(CASE WHEN TIP_ZAR > 0 THEN 1 ELSE 0 END)
             / COUNT(*), 2) AS TIP_RATE_PCT
FROM BANDED
GROUP BY PAYMENT_METHOD, SURGE_BAND
ORDER BY PAYMENT_METHOD, SURGE_BAND;
 
-- RQ10c. Does surge go with more cancellations? (ALL TRIPS)
WITH BANDED AS (
    SELECT CASE WHEN f.SURGE_MULTIPLIER <= 1.0 THEN '1) No surge (1.0)'
                WHEN f.SURGE_MULTIPLIER <  1.5 THEN '2) Low (1.1-1.4)'
                WHEN f.SURGE_MULTIPLIER <  2.0 THEN '3) Medium (1.5-1.9)'
                ELSE '4) High (2.0+)' END AS SURGE_BAND,
           t.TRIP_STATUS, t.CANCELLATION_REASON
    FROM TRIP_HEADERS t
    JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
)
SELECT SURGE_BAND,
       COUNT(*) AS TOTAL_TRIPS,
       ROUND(100 * SUM(CASE WHEN TRIP_STATUS <> 'COMPLETED' THEN 1 ELSE 0 END)
             / COUNT(*), 2) AS CANCEL_RATE_PCT,
       SUM(CASE WHEN CANCELLATION_REASON = 'PRICING_SURGE' THEN 1 ELSE 0 END)
           AS PRICING_SURGE_CANCELLATIONS
FROM BANDED
GROUP BY SURGE_BAND
ORDER BY SURGE_BAND;
 
 
-- ============================================================
-- RQ11. What characteristics define the top 10% of riders by
--       cumulative spend?
-- Techniques: chained CTEs, NTILE, cumulative window SUM
-- ============================================================
 
-- RQ11a. Profile of the top spend decile by home city and
--        preferred payment method
WITH RIDER_SPEND AS (
    SELECT r.RIDER_ID, r.HOME_CITY, r.PREFERRED_PAYMENT,
           COUNT(*) AS TRIPS,
           SUM(f.TOTAL_FARE_ZAR) AS TOTAL_SPEND
    FROM SA_RIDERS r
    JOIN TRIP_HEADERS t        ON r.RIDER_ID = t.RIDER_ID
    JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID  = f.TRIP_ID
    WHERE t.TRIP_STATUS = 'COMPLETED'
    GROUP BY r.RIDER_ID, r.HOME_CITY, r.PREFERRED_PAYMENT
),
RANKED AS (
    SELECT rs.*,
           NTILE(10) OVER (ORDER BY TOTAL_SPEND DESC) AS SPEND_DECILE
    FROM RIDER_SPEND rs
)
SELECT HOME_CITY,
       PREFERRED_PAYMENT,
       COUNT(*) AS TOP_DECILE_RIDERS,
       ROUND(AVG(TOTAL_SPEND), 2) AS AVG_SPEND_ZAR,
       ROUND(AVG(TRIPS), 1) AS AVG_TRIPS
FROM RANKED
WHERE SPEND_DECILE = 1
GROUP BY HOME_CITY, PREFERRED_PAYMENT
ORDER BY TOP_DECILE_RIDERS DESC;
 
-- RQ11b. Spend concentration: share of total spend by decile
WITH RIDER_SPEND AS (
    SELECT r.RIDER_ID,
           SUM(f.TOTAL_FARE_ZAR) AS TOTAL_SPEND,
           COUNT(*) AS TRIPS
    FROM SA_RIDERS r
    JOIN TRIP_HEADERS t        ON r.RIDER_ID = t.RIDER_ID
    JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID  = f.TRIP_ID
    WHERE t.TRIP_STATUS = 'COMPLETED'
    GROUP BY r.RIDER_ID
),
RANKED AS (
    SELECT rs.*,
           NTILE(10) OVER (ORDER BY TOTAL_SPEND DESC) AS SPEND_DECILE
    FROM RIDER_SPEND rs
)
SELECT SPEND_DECILE,
       COUNT(*) AS RIDERS,
       ROUND(SUM(TOTAL_SPEND), 2) AS DECILE_SPEND_ZAR,
       ROUND(AVG(TRIPS), 1) AS AVG_TRIPS,
       ROUND(100 * SUM(TOTAL_SPEND) / SUM(SUM(TOTAL_SPEND)) OVER (), 2)
           AS PCT_OF_TOTAL_SPEND,
       ROUND(100 * SUM(SUM(TOTAL_SPEND)) OVER (ORDER BY SPEND_DECILE)
             / SUM(SUM(TOTAL_SPEND)) OVER (), 2) AS CUMULATIVE_PCT
FROM RANKED
GROUP BY SPEND_DECILE
ORDER BY SPEND_DECILE;
 
-- RQ11c. What do top-decile riders actually ride and pay with?
WITH RIDER_SPEND AS (
    SELECT r.RIDER_ID, SUM(f.TOTAL_FARE_ZAR) AS TOTAL_SPEND
    FROM SA_RIDERS r
    JOIN TRIP_HEADERS t        ON r.RIDER_ID = t.RIDER_ID
    JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID  = f.TRIP_ID
    WHERE t.TRIP_STATUS = 'COMPLETED'
    GROUP BY r.RIDER_ID
),
TOP_DECILE AS (
    SELECT RIDER_ID
    FROM (SELECT RIDER_ID,
                 NTILE(10) OVER (ORDER BY TOTAL_SPEND DESC) AS SPEND_DECILE
          FROM RIDER_SPEND)
    WHERE SPEND_DECILE = 1
)
SELECT t.RIDE_CATEGORY,
       f.PAYMENT_METHOD,
       COUNT(*) AS TRIPS,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS PCT_OF_TOP_DECILE_TRIPS
FROM TOP_DECILE d
JOIN TRIP_HEADERS t        ON d.RIDER_ID = t.RIDER_ID
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID  = f.TRIP_ID
WHERE t.TRIP_STATUS = 'COMPLETED'
GROUP BY t.RIDE_CATEGORY, f.PAYMENT_METHOD
ORDER BY TRIPS DESC;
 
 
-- ============================================================
-- RQ12. Do payment-method patterns change over time across
--       March 2025 - March 2026?
-- Techniques: TRUNC to month, LAG, window share, CTE
-- ============================================================
WITH MONTHLY AS (
    SELECT TRUNC(t.REQUEST_TIMESTAMP, 'MM') AS MONTH_START,
           f.PAYMENT_METHOD,
           COUNT(*) AS TRIPS,
           SUM(f.TOTAL_FARE_ZAR) AS SPEND
    FROM TRIP_HEADERS t
    JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID = f.TRIP_ID
    WHERE t.TRIP_STATUS = 'COMPLETED'
    GROUP BY TRUNC(t.REQUEST_TIMESTAMP, 'MM'), f.PAYMENT_METHOD
)
SELECT TO_CHAR(MONTH_START, 'YYYY-MM') AS TRIP_MONTH,
       PAYMENT_METHOD,
       TRIPS,
       ROUND(SPEND, 2) AS SPEND_ZAR,
       ROUND(100 * TRIPS / SUM(TRIPS) OVER (PARTITION BY MONTH_START), 2)
           AS SHARE_OF_MONTH_PCT,
       LAG(TRIPS) OVER (PARTITION BY PAYMENT_METHOD ORDER BY MONTH_START)
           AS PREVIOUS_MONTH_TRIPS,
       ROUND(100 * (TRIPS - LAG(TRIPS) OVER
                    (PARTITION BY PAYMENT_METHOD ORDER BY MONTH_START))
             / NULLIF(LAG(TRIPS) OVER
                    (PARTITION BY PAYMENT_METHOD ORDER BY MONTH_START), 0), 2)
           AS MOM_CHANGE_PCT
FROM MONTHLY
ORDER BY PAYMENT_METHOD, MONTH_START;
 
 

-- PART C: REUSABLE VIEW FOR REPORTING AND CHARTS

CREATE OR REPLACE VIEW V_TRIP_FACTS AS
SELECT t.TRIP_ID,
       t.REQUEST_TIMESTAMP,
       TRUNC(t.REQUEST_TIMESTAMP, 'MM') AS TRIP_MONTH,
       t.TRIP_STATUS,
       t.CANCELLATION_REASON,
       t.RIDE_CATEGORY,
       r.RIDER_ID,
       r.HOME_CITY,
       r.PROVINCE,
       r.PREFERRED_PAYMENT,
       z.CITY      AS ZONE_CITY,
       z.ZONE_NAME,
       f.PAYMENT_METHOD,
       f.DISTANCE_KM,
       f.DURATION_MINUTES,
       f.SURGE_MULTIPLIER,
       f.TIP_ZAR,
       f.TOTAL_FARE_ZAR
FROM TRIP_HEADERS t
JOIN SA_RIDERS r           ON t.RIDER_ID = r.RIDER_ID
JOIN PRICING_SURGE_ZONES z ON t.ZONE_ID  = z.ZONE_ID
JOIN TRIP_FARE_BREAKDOWN f ON t.TRIP_ID  = f.TRIP_ID;
 
-- Example use of the view (chart data: spend by city and method)
SELECT ZONE_CITY, PAYMENT_METHOD,
       COUNT(*) AS COMPLETED_TRIPS,
       ROUND(SUM(TOTAL_FARE_ZAR), 2) AS TOTAL_SPEND_ZAR
FROM V_TRIP_FACTS
WHERE TRIP_STATUS = 'COMPLETED'
GROUP BY ZONE_CITY, PAYMENT_METHOD
ORDER BY ZONE_CITY, TOTAL_SPEND_ZAR DESC;
 
-- >>>>>>>>>>>>>>>> 06_transactions.sql <<<<<<<<<<<<<<<<

SET SERVEROUTPUT ON SIZE UNLIMITED
 
 
-- ------------------------------------------------------------
-- SETUP: throw-away copy of 500 fare rows
-- ------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE FARE_TXN_DEMO PURGE';
EXCEPTION
    WHEN OTHERS THEN NULL;   -- table did not exist yet
END;
/
 
CREATE TABLE FARE_TXN_DEMO AS
SELECT TRIP_ID, PAYMENT_METHOD, TIP_ZAR, TOTAL_FARE_ZAR
FROM TRIP_FARE_BREAKDOWN
WHERE ROWNUM <= 500;
 
-- BASELINE
SELECT COUNT(*)            AS ROWS_IN_DEMO,
       SUM(TIP_ZAR)        AS TOTAL_TIPS,
       SUM(CASE WHEN PAYMENT_METHOD = 'CASH' THEN TIP_ZAR ELSE 0 END)
                           AS CASH_TIPS,
       SUM(CASE WHEN PAYMENT_METHOD = 'CREDIT_CARD' THEN TIP_ZAR ELSE 0 END)
                           AS CARD_TIPS
FROM FARE_TXN_DEMO;
 
 
-- ------------------------------------------------------------
-- DEMO 1: SAVEPOINT and partial ROLLBACK
-- Step 1 is kept; step 2 is undone with ROLLBACK TO SAVEPOINT.
-- ------------------------------------------------------------
 
-- Step 1: add R5 to every CASH tip
UPDATE FARE_TXN_DEMO
   SET TIP_ZAR = TIP_ZAR + 5
 WHERE PAYMENT_METHOD = 'CASH';
 
SAVEPOINT AFTER_CASH_UPDATE;
 
-- Step 2: (mistake) wipe all CREDIT_CARD tips
UPDATE FARE_TXN_DEMO
   SET TIP_ZAR = 0
 WHERE PAYMENT_METHOD = 'CREDIT_CARD';
 
-- Check: card tips are now 0, cash tips are up
SELECT 'BEFORE ROLLBACK TO SAVEPOINT' AS STAGE,
       SUM(CASE WHEN PAYMENT_METHOD = 'CASH' THEN TIP_ZAR ELSE 0 END) AS CASH_TIPS,
       SUM(CASE WHEN PAYMENT_METHOD = 'CREDIT_CARD' THEN TIP_ZAR ELSE 0 END) AS CARD_TIPS
FROM FARE_TXN_DEMO;
 
-- Undo only step 2
ROLLBACK TO SAVEPOINT AFTER_CASH_UPDATE;
 
-- Check: card tips restored, cash increase still there
SELECT 'AFTER ROLLBACK TO SAVEPOINT' AS STAGE,
       SUM(CASE WHEN PAYMENT_METHOD = 'CASH' THEN TIP_ZAR ELSE 0 END) AS CASH_TIPS,
       SUM(CASE WHEN PAYMENT_METHOD = 'CREDIT_CARD' THEN TIP_ZAR ELSE 0 END) AS CARD_TIPS
FROM FARE_TXN_DEMO;
 
-- Make step 1 permanent
COMMIT;
 
 
-- ------------------------------------------------------------
-- DEMO 2: full ROLLBACK
-- A bad delete is undone completely.
-- ------------------------------------------------------------
SELECT COUNT(*) AS ROWS_BEFORE_DELETE FROM FARE_TXN_DEMO;
 
DELETE FROM FARE_TXN_DEMO WHERE PAYMENT_METHOD = 'EFT_OZOW';
 
SELECT COUNT(*) AS ROWS_AFTER_DELETE_UNCOMMITTED FROM FARE_TXN_DEMO;
 
ROLLBACK;
 
SELECT COUNT(*) AS ROWS_AFTER_ROLLBACK FROM FARE_TXN_DEMO;
 
 
-- ------------------------------------------------------------
-- DEMO 3: atomic business transaction in PL/SQL
-- Apply a tip adjustment to ONE payment method. If anything
-- fails, or nothing was updated, undo the whole thing.
-- ------------------------------------------------------------
DECLARE
    v_rows_updated NUMBER;
BEGIN
    SAVEPOINT START_ADJUSTMENT;
 
    UPDATE FARE_TXN_DEMO
       SET TIP_ZAR = TIP_ZAR + 10
     WHERE PAYMENT_METHOD = 'IN_APP_WALLET';
 
    v_rows_updated := SQL%ROWCOUNT;
 
    IF v_rows_updated = 0 THEN
        ROLLBACK TO SAVEPOINT START_ADJUSTMENT;
        DBMS_OUTPUT.PUT_LINE('No rows matched - transaction rolled back.');
    ELSE
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Committed. Rows updated: ' || v_rows_updated);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error - transaction rolled back: ' || SQLERRM);
END;
/
 
 
-- ------------------------------------------------------------
-- DEMO 4: constraints protect integrity inside a transaction

-- ------------------------------------------------------------
BEGIN
    INSERT INTO TRIP_HEADERS
        (TRIP_ID, RIDER_ID, DRIVER_ID, ZONE_ID, RIDE_CATEGORY,
         REQUEST_TIMESTAMP, TRIP_STATUS, CANCELLATION_REASON)
    VALUES
        ('TEST_TRIP_0001', 'RIDER_DOES_NOT_EXIST', 'DRIVER_DOES_NOT_EXIST',
         'ZONE_DOES_NOT_EXIST', 'TEST', SYSDATE, 'COMPLETED', NULL);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Unexpected: the insert was accepted.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Rejected as expected: ' || SQLERRM);
END;
/
 
-- Prove nothing was inserted (should be 0)
SELECT COUNT(*) AS TEST_TRIPS_IN_REAL_TABLE
FROM TRIP_HEADERS
WHERE TRIP_ID = 'TEST_TRIP_0001';
 
 
-- ------------------------------------------------------------
-- CLEAN UP (DDL, so it also commits)
-- ------------------------------------------------------------
DROP TABLE FARE_TXN_DEMO PURGE;

-- ============================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
 
 
-- ------------------------------------------------------------
-- STEP 1: remove the date index so we can measure "before"
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
    DBMS_STATS.GATHER_TABLE_STATS(ownname => USER, tabname => 'TRIP_HEADERS');
END;
/
 
 
-- ------------------------------------------------------------
-- STEP 2: BEFORE - plan for a one-day lookup
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
-- STEP 3: create the index and refresh statistics
-- ------------------------------------------------------------
CREATE INDEX IDX_TRIPS_TIME ON TRIP_HEADERS (REQUEST_TIMESTAMP);
 
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(ownname => USER, tabname => 'TRIP_HEADERS');
END;

 

-- ------------------------------------------------------------
-- STEP 4: AFTER - same query, new plan
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
-- STEP 5: a second example - one rider's trip history
-- Uses the composite index IDX_TRIPS_RIDER_TIME (RIDER_ID,
-- REQUEST_TIMESTAMP). Expect an INDEX RANGE SCAN.
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
-- STEP 7: current index list (for the report)
-- ------------------------------------------------------------
SELECT i.TABLE_NAME, i.INDEX_NAME, i.UNIQUENESS,
       LISTAGG(ic.COLUMN_NAME, ', ')
           WITHIN GROUP (ORDER BY ic.COLUMN_POSITION) AS INDEXED_COLUMNS
FROM USER_INDEXES i
JOIN USER_IND_COLUMNS ic ON i.INDEX_NAME = ic.INDEX_NAME
WHERE i.TABLE_NAME IN ('TRIP_HEADERS','TRIP_FARE_BREAKDOWN',
                       'TRIP_REVIEWS','SA_RIDERS','VEHICLES')
GROUP BY i.TABLE_NAME, i.INDEX_NAME, i.UNIQUENESS
ORDER BY i.TABLE_NAME, i.INDEX_NAME;
 
