
USE waste_management;

-- 1.1 INNER JOIN

SELECT
    h.Household_Name,
    c.Waste_Type,
    c.Weight_kg,
    c.Segregation_Status

FROM Collection c

INNER JOIN Household h
    ON c.Household_ID = h.Household_ID

LIMIT 20;

-- 1.2 MULTI-TABLE INNER JOIN

SELECT
    z.Zone_Name,
    h.Household_Name,
    t.Truck_No,
    t.Driver_Name,
    c.Collection_Date,
    c.Waste_Type,
    c.Weight_kg,
    c.Segregation_Status

FROM Collection c

INNER JOIN Household h
    ON c.Household_ID = h.Household_ID

INNER JOIN Zone z
    ON h.Zone_ID = z.Zone_ID

INNER JOIN Truck t
    ON c.Truck_ID = t.Truck_ID

LIMIT 20;

-- 1.3 LEFT JOIN

SELECT
    h.Household_ID,
    h.Household_Name,
    COUNT(c.Collection_ID) AS Total_Collections

FROM Household h

LEFT JOIN Collection c
    ON h.Household_ID = c.Household_ID

GROUP BY
    h.Household_ID,
    h.Household_Name

ORDER BY Total_Collections ASC

LIMIT 20;

-- 1.4 RIGHT JOIN


SELECT
    z.Zone_Name,
    h.Household_Name

FROM Household h

RIGHT JOIN Zone z
    ON h.Zone_ID = z.Zone_ID

LIMIT 20;

-- 1.5 SELF JOIN
SELECT
    h1.Household_Name AS Household_A,
    h2.Household_Name AS Household_B,
    h1.Zone_ID

FROM Household h1

INNER JOIN Household h2
    ON h1.Zone_ID = h2.Zone_ID
    AND h1.Household_ID < h2.Household_ID

LIMIT 20;

-- 1.6 SELF JOIN ON COLLECTION
-- Trucks working on same date

SELECT DISTINCT
    c1.Truck_ID AS Truck_A,
    c2.Truck_ID AS Truck_B,
    c1.Collection_Date

FROM Collection c1

INNER JOIN Collection c2
    ON c1.Collection_Date = c2.Collection_Date
    AND c1.Truck_ID < c2.Truck_ID

LIMIT 20;

-- 2. AGGREGATE FUNCTIONS + GROUP BY + HAVING

-- 2.1 ZONE-WISE WASTE


SELECT
    z.Zone_Name,
    COUNT(c.Collection_ID) AS Total_Collections,
    SUM(c.Weight_kg) AS Total_Waste

FROM Zone z

INNER JOIN Household h
    ON z.Zone_ID = h.Zone_ID

INNER JOIN Collection c
    ON h.Household_ID = c.Household_ID

GROUP BY
    z.Zone_ID,
    z.Zone_Name

ORDER BY Total_Waste DESC;



-- 2.2 GROUP BY + HAVING


SELECT
    z.Zone_Name,
    COUNT(c.Collection_ID) AS Total_Collections,
    SUM(c.Weight_kg) AS Total_Waste

FROM Zone z

INNER JOIN Household h
    ON z.Zone_ID = h.Zone_ID

INNER JOIN Collection c
    ON h.Household_ID = c.Household_ID

GROUP BY
    z.Zone_ID,
    z.Zone_Name

HAVING COUNT(c.Collection_ID) > 100

ORDER BY Total_Waste DESC;


-- 2.3 WASTE TYPE ANALYSIS

SELECT
    Waste_Type,
    COUNT(*) AS Total_Records,
    SUM(Weight_kg) AS Total_Weight,
    AVG(Weight_kg) AS Average_Weight,
    MAX(Weight_kg) AS Maximum_Weight,
    MIN(Weight_kg) AS Minimum_Weight

FROM Collection

GROUP BY Waste_Type;


-- 3. CORRELATED SUBQUERIES




-- 3.1 Household average > overall average

SELECT
    h.Household_ID,
    h.Household_Name

FROM Household h

WHERE
(
    SELECT AVG(c.Weight_kg)

    FROM Collection c

    WHERE c.Household_ID = h.Household_ID
)
>
(
    SELECT AVG(Weight_kg)

    FROM Collection
)

LIMIT 20;

-- 3.2 Latest collection is Non-Compliant

SELECT
    h.Household_ID,
    h.Household_Name

FROM Household h

WHERE 'Non-Compliant' =
(
    SELECT c.Segregation_Status

    FROM Collection c

    WHERE c.Household_ID = h.Household_ID

    ORDER BY c.Collection_Date DESC

    LIMIT 1
)

LIMIT 20;


SELECT
    t.Truck_ID,
    t.Truck_No,

    (
        SELECT AVG(c.Weight_kg)

        FROM Collection c

        WHERE c.Truck_ID = t.Truck_ID
    ) AS Truck_Average_Weight

FROM Truck t

WHERE
(
    SELECT AVG(c.Weight_kg)

    FROM Collection c

    WHERE c.Truck_ID = t.Truck_ID
)
>
(
    SELECT AVG(Weight_kg)

    FROM Collection
)

LIMIT 20;



-- 4. VIEWS


CREATE OR REPLACE VIEW NonCompliant_Summary AS

SELECT
    h.Household_ID,
    h.Household_Name,
    z.Zone_Name,
    COUNT(*) AS Non_Compliant_Count

FROM Collection c

INNER JOIN Household h
    ON c.Household_ID = h.Household_ID

INNER JOIN Zone z
    ON h.Zone_ID = z.Zone_ID

WHERE c.Segregation_Status = 'Non-Compliant'

GROUP BY
    h.Household_ID,
    h.Household_Name,
    z.Zone_Name;


SELECT *
FROM NonCompliant_Summary

ORDER BY Non_Compliant_Count DESC

LIMIT 10;




-- 4.2 ZONE DAILY SUMMARY

CREATE OR REPLACE VIEW Zone_Daily_Summary AS

SELECT
    z.Zone_Name,
    c.Collection_Date,
    SUM(c.Weight_kg) AS Total_Weight,
    COUNT(*) AS Total_Collections

FROM Collection c

INNER JOIN Household h
    ON c.Household_ID = h.Household_ID

INNER JOIN Zone z
    ON h.Zone_ID = z.Zone_ID

GROUP BY
    z.Zone_Name,
    c.Collection_Date;


SELECT *
FROM Zone_Daily_Summary

LIMIT 10;


-- 4.3 TRUCK PERFORMANCE


CREATE OR REPLACE VIEW Truck_Performance AS

SELECT
    t.Truck_ID,
    t.Truck_No,
    t.Driver_Name,
    COUNT(c.Collection_ID) AS Total_Collections,
    COALESCE(SUM(c.Weight_kg), 0) AS Total_Weight

FROM Truck t

LEFT JOIN Collection c
    ON t.Truck_ID = c.Truck_ID

GROUP BY
    t.Truck_ID,
    t.Truck_No,
    t.Driver_Name;


SELECT *
FROM Truck_Performance

ORDER BY Total_Weight DESC

LIMIT 10;

-- 5. TRIGGERS

-- 5.1 BEFORE INSERT TRIGGER


DROP TRIGGER IF EXISTS trg_before_collection_insert;

DELIMITER //

CREATE TRIGGER trg_before_collection_insert

BEFORE INSERT ON Collection

FOR EACH ROW

BEGIN

    IF NEW.Weight_kg <= 0 THEN

        SIGNAL SQLSTATE '45000'

        SET MESSAGE_TEXT =
        'Weight must be greater than zero';

    END IF;


    IF NEW.Waste_Type = 'Hazardous'
       AND NEW.Weight_kg > 4 THEN

        SET NEW.Segregation_Status =
        'Non-Compliant';

    END IF;

END //

DELIMITER ;



-- 5.2 AFTER INSERT AUDIT TRIGGER


DROP TRIGGER IF EXISTS trg_after_collection_insert;

DELIMITER //

CREATE TRIGGER trg_after_collection_insert

AFTER INSERT ON Collection

FOR EACH ROW

BEGIN

    INSERT INTO Collection_Audit_Log
    (
        Collection_ID,
        Action
    )

    VALUES
    (
        NEW.Collection_ID,
        'INSERT'
    );

END //

DELIMITER ;




-- 6. STORED PROCEDURE
-- ============================================================

DROP PROCEDURE IF EXISTS RecordCollection;

DELIMITER //

CREATE PROCEDURE RecordCollection
(
    IN p_household INT,
    IN p_truck INT,
    IN p_type VARCHAR(15),
    IN p_weight DECIMAL(6,2),
    IN p_status VARCHAR(15)
)

BEGIN

    DECLARE new_id VARCHAR(10);
    DECLARE next_number INT;


    -- Find the next numeric Collection_ID

    SELECT
        COALESCE(
            MAX(
                CAST(
                    SUBSTRING(Collection_ID, 2)
                    AS UNSIGNED
                )
            ),
            0
        ) + 1

    INTO next_number

    FROM Collection;


    -- Create ID like C20001

    SET new_id =
        CONCAT(
            'C',
            LPAD(next_number, 6, '0')
        );


    -- Insert collection

    INSERT INTO Collection
    (
        Collection_ID,
        Collection_Date,
        Household_ID,
        Truck_ID,
        Waste_Type,
        Weight_kg,
        Segregation_Status
    )

    VALUES
    (
        new_id,
        CURDATE(),
        p_household,
        p_truck,
        p_type,
        p_weight,
        p_status
    );


    -- Show generated ID

    SELECT new_id AS New_Collection_ID;

END //

DELIMITER ;




-- 6.1 TEST STORED PROCEDURE


CALL RecordCollection
(
    1,
    1,
    'Wet',
    2.5,
    'Compliant'
);

-- 6.2 CHECK NEW COLLECTION


SELECT *

FROM Collection

ORDER BY Collection_ID DESC

LIMIT 5;



-- 6.3 CHECK AUDIT LOG


SELECT *

FROM Collection_Audit_Log

ORDER BY Log_ID DESC

LIMIT 5;



-- 7. INDEXING + EXPLAIN



-- 7.1 BEFORE INDEXING


EXPLAIN

SELECT
    h.Household_Name,
    c.Weight_kg

FROM Collection c

INNER JOIN Household h
    ON c.Household_ID = h.Household_ID

WHERE c.Household_ID = 500;



EXPLAIN

SELECT *

FROM Collection

WHERE Segregation_Status = 'Non-Compliant';
-- 7.2 CREATE INDEXES


CREATE INDEX idx_collection_household

ON Collection(Household_ID);



CREATE INDEX idx_collection_truck

ON Collection(Truck_ID);



CREATE INDEX idx_household_zone

ON Household(Zone_ID);



CREATE INDEX idx_collection_status

ON Collection(Segregation_Status);



CREATE INDEX idx_collection_household_status

ON Collection
(
    Household_ID,
    Segregation_Status
);


-- 7.3 AFTER INDEXING


EXPLAIN

SELECT
    h.Household_Name,
    c.Weight_kg

FROM Collection c

INNER JOIN Household h
    ON c.Household_ID = h.Household_ID

WHERE c.Household_ID = 500;



EXPLAIN

SELECT *

FROM Collection

WHERE Segregation_Status = 'Non-Compliant';




-- 7.4 VERIFY INDEXES


SHOW INDEX FROM Collection;

SHOW INDEX FROM Household;



-- 8. COMPLEX PERFORMANCE QUERY


EXPLAIN

SELECT
    z.Zone_Name,
    COUNT(c.Collection_ID) AS Total_Collections,
    SUM(c.Weight_kg) AS Total_Waste

FROM Zone z

INNER JOIN Household h
    ON z.Zone_ID = h.Zone_ID

INNER JOIN Collection c
    ON h.Household_ID = c.Household_ID

GROUP BY
    z.Zone_ID,
    z.Zone_Name

HAVING SUM(c.Weight_kg) > 1000

ORDER BY Total_Waste DESC;
