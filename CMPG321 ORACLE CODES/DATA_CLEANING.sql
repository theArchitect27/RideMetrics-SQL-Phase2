
-- 03: DATA TYPES, CONSTRAINTS, INDEXES
-- Confirm stored values match the constraint lists below.

SELECT DISTINCT TRIP_STATUS
FROM TRIP_HEADERS
ORDER BY 1;

SELECT DISTINCT CANCELLATION_REASON
FROM TRIP_HEADERS
ORDER BY 1;

SELECT DISTINCT RIDE_CATEGORY
FROM TRIP_HEADERS
ORDER BY 1;

SELECT DISTINCT PAYMENT_METHOD
FROM TRIP_FARE_BREAKDOWN
ORDER BY 1;

SELECT DISTINCT PREFERRED_PAYMENT
FROM SA_RIDERS
ORDER BY 1;

SELECT DISTINCT PROVINCE
FROM SA_RIDERS
ORDER BY 1;

SELECT DISTINCT CITY
FROM PRICING_SURGE_ZONES
ORDER BY 1;


SET SERVEROUTPUT ON SIZE UNLIMITED

-- 1: ALIGN RELATED COLUMN DATA TYPES

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
    run_ddl(
        'ALTER TABLE TRIP_REVIEWS MODIFY (TRIP_ID VARCHAR2(50))'
    );
    run_ddl(
        'ALTER TABLE TRIP_HEADERS MODIFY (ZONE_ID VARCHAR2(50))'
    );
END;
/

-- 2: DOMAIN (CATEGORY) CHECK CONSTRAINTS

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
        CHECK (TRIP_STATUS IN (
            'COMPLETED',
            'CANCELLED_BY_RIDER',
            'CANCELLED_BY_DRIVER'
        ))]');

    -- Completed trips use N/A in the supplied dataset.
    run_ddl(q'[ALTER TABLE TRIP_HEADERS ADD CONSTRAINT CK_TRIPS_REASON_DOMAIN
        CHECK (
            CANCELLATION_REASON = 'N/A'
            OR CANCELLATION_REASON IN (
                'CHANGED_MIND',
                'DRIVER_TOO_FAR',
                'SAFETY_CONCERN',
                'RIDER_NO_SHOW',
                'PRICING_SURGE',
                'TRAFFIC_DELAY'
            )
        )]');

    -- Completed trips must use N/A.
    -- Cancelled trips must have one of the six valid reasons.
    run_ddl(q'[ALTER TABLE TRIP_HEADERS ADD CONSTRAINT CK_TRIPS_REASON_LOGIC
        CHECK (
            (
                TRIP_STATUS = 'COMPLETED'
                AND CANCELLATION_REASON = 'N/A'
            )
            OR
            (
                TRIP_STATUS IN (
                    'CANCELLED_BY_RIDER',
                    'CANCELLED_BY_DRIVER'
                )
                AND CANCELLATION_REASON IN (
                    'CHANGED_MIND',
                    'DRIVER_TOO_FAR',
                    'SAFETY_CONCERN',
                    'RIDER_NO_SHOW',
                    'PRICING_SURGE',
                    'TRAFFIC_DELAY'
                )
            )
        )]');

    run_ddl(q'[ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_PAYMENT
        CHECK (PAYMENT_METHOD IN (
            'CASH', 'CREDIT_CARD', 'DEBIT_CARD',
            'EFT_OZOW', 'IN_APP_WALLET'
        ))]');

    run_ddl(q'[ALTER TABLE SA_RIDERS ADD CONSTRAINT CK_RIDERS_PREF_PAYMENT
        CHECK (PREFERRED_PAYMENT IN (
            'CASH', 'CREDIT_CARD', 'DEBIT_CARD',
            'EFT_OZOW', 'IN_APP_WALLET'
        ))]');
END;
/

-- 3: NUMERIC RANGE CHECK CONSTRAINTS

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
    run_ddl(
        'ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_TIP CHECK (TIP_ZAR >= 0)'
    );

    run_ddl(
        'ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_SURGE CHECK (SURGE_MULTIPLIER >= 1)'
    );

    run_ddl(
        'ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_TOLLS CHECK (TOLLS_ZAR >= 0)'
    );

    run_ddl(
        'ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_BASE CHECK (BASE_FARE_ZAR >= 0)'
    );

    run_ddl(
        'ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_COMMISSION CHECK (PLATFORM_COMMISSION_ZAR >= 0)'
    );

    run_ddl(
        'ALTER TABLE TRIP_FARE_BREAKDOWN ADD CONSTRAINT CK_FARES_PAYOUT CHECK (DRIVER_PAYOUT_ZAR >= 0)'
    );

    -- Commission percentage is stored as a fraction (0 to 1).
    run_ddl(
        'ALTER TABLE SA_DRIVERS ADD CONSTRAINT CK_DRIVERS_COMMISSION CHECK (PLATFORM_COMMISSION_PCT BETWEEN 0 AND 1)'
    );

    run_ddl(
        'ALTER TABLE VEHICLES ADD CONSTRAINT CK_VEHICLES_YEAR CHECK (YEAR BETWEEN 1990 AND 2030)'
    );
END;
/

-- 4: NOT NULL ON THE ANALYSIS COLUMNS

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

-- 5: INDEXES

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
    run_ddl(
        'CREATE INDEX IDX_TRIPS_RIDER_TIME ON TRIP_HEADERS (RIDER_ID, REQUEST_TIMESTAMP)'
    );
    run_ddl(
        'CREATE INDEX IDX_TRIPS_DRIVER ON TRIP_HEADERS (DRIVER_ID)'
    );
    run_ddl(
        'CREATE INDEX IDX_TRIPS_ZONE ON TRIP_HEADERS (ZONE_ID)'
    );
    run_ddl(
        'CREATE INDEX IDX_TRIPS_TIME ON TRIP_HEADERS (REQUEST_TIMESTAMP)'
    );
    run_ddl(
        'CREATE INDEX IDX_TRIPS_STATUS_TIME ON TRIP_HEADERS (TRIP_STATUS, REQUEST_TIMESTAMP)'
    );
    run_ddl(
        'CREATE INDEX IDX_VEH_DRIVER ON VEHICLES (DRIVER_ID)'
    );
    run_ddl(
        'CREATE INDEX IDX_REVIEWS_TRIP ON TRIP_REVIEWS (TRIP_ID)'
    );
    run_ddl(
        'CREATE INDEX IDX_RIDERS_CITY ON SA_RIDERS (HOME_CITY, PROVINCE)'
    );
END;
/

BEGIN
    DBMS_STATS.GATHER_SCHEMA_STATS(ownname => USER);
END;
/

-- 6: PROOF QUERIES

-- 6a. Constraints on the seven tables
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
WHERE c.TABLE_NAME IN (
    'SA_DRIVERS', 'SA_RIDERS', 'VEHICLES',
    'PRICING_SURGE_ZONES', 'TRIP_HEADERS',
    'TRIP_FARE_BREAKDOWN', 'TRIP_REVIEWS'
)
ORDER BY c.TABLE_NAME, c.CONSTRAINT_TYPE, c.CONSTRAINT_NAME;

-- 6b. Indexes on the seven tables
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
    'SA_DRIVERS', 'SA_RIDERS', 'VEHICLES',
    'PRICING_SURGE_ZONES', 'TRIP_HEADERS',
    'TRIP_FARE_BREAKDOWN', 'TRIP_REVIEWS'
)
GROUP BY i.TABLE_NAME, i.INDEX_NAME, i.UNIQUENESS
ORDER BY i.TABLE_NAME, i.INDEX_NAME;

-- 6c. Related key column data types
SELECT TABLE_NAME,
       COLUMN_NAME,
       DATA_TYPE,
       DATA_LENGTH,
       NULLABLE
FROM USER_TAB_COLUMNS
WHERE COLUMN_NAME IN ('TRIP_ID', 'RIDER_ID', 'DRIVER_ID', 'ZONE_ID')
  AND TABLE_NAME IN (
      'SA_DRIVERS', 'SA_RIDERS', 'VEHICLES',
      'PRICING_SURGE_ZONES', 'TRIP_HEADERS',
      'TRIP_FARE_BREAKDOWN', 'TRIP_REVIEWS'
  )
ORDER BY COLUMN_NAME, TABLE_NAME;

-- 6d. Verify cancellation reasons by trip status
SELECT
    TRIP_STATUS,
    NVL(CANCELLATION_REASON, '<NULL>') AS CANCELLATION_REASON,
    COUNT(*) AS TRIP_COUNT
FROM TRIP_HEADERS
GROUP BY TRIP_STATUS, CANCELLATION_REASON
ORDER BY TRIP_STATUS, CANCELLATION_REASON;

---------------------------------------------------------------------------
--1. Verify the constraints
---------------------------------------------------------------------------
SELECT TABLE_NAME,
       CONSTRAINT_NAME,
       CONSTRAINT_TYPE,
       STATUS,
       VALIDATED
FROM USER_CONSTRAINTS
WHERE CONSTRAINT_NAME IN (
    'CK_TRIPS_STATUS',
    'CK_TRIPS_REASON_DOMAIN',
    'CK_TRIPS_REASON_LOGIC',
    'CK_FARES_PAYMENT',
    'CK_RIDERS_PREF_PAYMENT',
    'CK_FARES_TIP',
    'CK_FARES_SURGE',
    'CK_FARES_TOLLS',
    'CK_FARES_BASE',
    'CK_FARES_COMMISSION',
    'CK_FARES_PAYOUT',
    'CK_DRIVERS_COMMISSION',
    'CK_VEHICLES_YEAR'
)
ORDER BY TABLE_NAME, CONSTRAINT_NAME;
---------------------------------------------------------------------------
--2.Verify the eight indexes
---------------------------------------------------------------------------
SELECT i.TABLE_NAME,
       i.INDEX_NAME,
       i.UNIQUENESS,
       i.STATUS,
       LISTAGG(ic.COLUMN_NAME, ', ')
           WITHIN GROUP (ORDER BY ic.COLUMN_POSITION) AS INDEXED_COLUMNS
FROM USER_INDEXES i
JOIN USER_IND_COLUMNS ic
    ON i.INDEX_NAME = ic.INDEX_NAME
   AND i.TABLE_NAME = ic.TABLE_NAME
WHERE i.INDEX_NAME IN (
    'IDX_TRIPS_RIDER_TIME',
    'IDX_TRIPS_DRIVER',
    'IDX_TRIPS_ZONE',
    'IDX_TRIPS_TIME',
    'IDX_TRIPS_STATUS_TIME',
    'IDX_VEH_DRIVER',
    'IDX_REVIEWS_TRIP',
    'IDX_RIDERS_CITY'
)
GROUP BY i.TABLE_NAME,
         i.INDEX_NAME,
         i.UNIQUENESS,
         i.STATUS
ORDER BY i.TABLE_NAME, i.INDEX_NAME;
