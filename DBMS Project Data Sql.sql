
USE waste_management;



-- 0. ENABLE LOCAL FILE IMPORT

SET GLOBAL local_infile = 1;


-- CSV FILE PATH

-- C:/Users/saksh/Downloads/TAE2_Sakshi_Shinde_Submission/
-- tae2_submission/data/clean/


-- 1. ZONE


LOAD DATA LOCAL INFILE
'C:/Users/saksh/Downloads/TAE2_Sakshi_Shinde_Submission/tae2_submission/data/clean/zone.csv'

INTO TABLE Zone

FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'

LINES TERMINATED BY '\n'

IGNORE 1 ROWS

(
    Zone_ID,
    Zone_Name,
    Area,
    Zone_Officer
);


-- Check Zone records

SELECT COUNT(*) AS total_zones
FROM Zone;

SELECT *
FROM Zone
LIMIT 10;


-- 2. TRUCK

LOAD DATA LOCAL INFILE
'C:/Users/saksh/Downloads/TAE2_Sakshi_Shinde_Submission/tae2_submission/data/clean/truck.csv'

INTO TABLE Truck

FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'

LINES TERMINATED BY '\n'

IGNORE 1 ROWS

(
    Truck_ID,
    Truck_No,
    Driver_Name,
    Driver_Phone
);


-- Check Truck records

SELECT COUNT(*) AS total_trucks
FROM Truck;

SELECT *
FROM Truck
LIMIT 10;


-- ============================================================
-- 3. HOUSEHOLD
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/saksh/Downloads/TAE2_Sakshi_Shinde_Submission/tae2_submission/data/clean/household.csv'

INTO TABLE Household

FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'

LINES TERMINATED BY '\n'

IGNORE 1 ROWS

(
    Household_ID,
    Household_Name,
    Address,
    Zone_ID
);


-- Check Household records

SELECT COUNT(*) AS total_households
FROM Household;

SELECT *
FROM Household
LIMIT 10;

-- 4. COLLECTION

LOAD DATA LOCAL INFILE
'C:/Users/saksh/Downloads/TAE2_Sakshi_Shinde_Submission/tae2_submission/data/clean/collection.csv'

INTO TABLE Collection

FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'

LINES TERMINATED BY '\n'

IGNORE 1 ROWS

(
    Collection_ID,
    @date_raw,
    Household_ID,
    Truck_ID,
    Waste_Type,
    Weight_kg,
    @status_raw
)

SET

    -- Convert different date formats into DATE

    Collection_Date =
        CASE

            -- YYYY-MM-DD
            WHEN @date_raw LIKE '%-%-%'
                 AND LENGTH(@date_raw) = 10
                 AND SUBSTRING(@date_raw,5,1) = '-'

            THEN STR_TO_DATE(
                TRIM(@date_raw),
                '%Y-%m-%d'
            )


            -- DD-MM-YYYY
            WHEN @date_raw LIKE '%-%-%'

            THEN STR_TO_DATE(
                TRIM(@date_raw),
                '%d-%m-%Y'
            )


            -- DD/MM/YY
            WHEN @date_raw LIKE '%/%/%'

            THEN STR_TO_DATE(
                TRIM(@date_raw),
                '%d/%m/%y'
            )


            ELSE NULL

        END,


    -- Standardize segregation status

    Segregation_Status =
        CASE

            WHEN LOWER(TRIM(@status_raw))
                 IN (
                     'non compliant',
                     'non-compliant',
                     'noncompliant'
                 )

            THEN 'Non-Compliant'

            ELSE 'Compliant'

        END;



-- 5. VERIFY COLLECTION DATA


SELECT COUNT(*) AS total_collections
FROM Collection;


SELECT *
FROM Collection
LIMIT 10;


SELECT
    MIN(Collection_Date) AS earliest_date,
    MAX(Collection_Date) AS latest_date
FROM Collection;

-- 6. CHECK DATA CONSISTENCY

-- Check invalid household references

SELECT COUNT(*) AS invalid_households
FROM Collection c
LEFT JOIN Household h
    ON c.Household_ID = h.Household_ID
WHERE h.Household_ID IS NULL;


-- Check invalid truck references

SELECT COUNT(*) AS invalid_trucks
FROM Collection c
LEFT JOIN Truck t
    ON c.Truck_ID = t.Truck_ID
WHERE t.Truck_ID IS NULL;


-- Check invalid zone references

SELECT COUNT(*) AS invalid_zones
FROM Household h
LEFT JOIN Zone z
    ON h.Zone_ID = z.Zone_ID
WHERE z.Zone_ID IS NULL;


-- 7. FINAL ROW COUNT


SELECT
    (SELECT COUNT(*) FROM Zone)
        AS Zone_Rows,

    (SELECT COUNT(*) FROM Truck)
        AS Truck_Rows,

    (SELECT COUNT(*) FROM Household)
        AS Household_Rows,

    (SELECT COUNT(*) FROM Collection)
        AS Collection_Rows;



-- 8. SAMPLE JOIN TO VERIFY IMPORT


SELECT
    z.Zone_Name,
    h.Household_Name,
    t.Truck_No,
    c.Collection_Date,
    c.Waste_Type,
    c.Weight_kg,
    c.Segregation_Status

FROM Collection c

JOIN Household h
    ON c.Household_ID = h.Household_ID

JOIN Zone z
    ON h.Zone_ID = z.Zone_ID

JOIN Truck t
    ON c.Truck_ID = t.Truck_ID

LIMIT 20;


