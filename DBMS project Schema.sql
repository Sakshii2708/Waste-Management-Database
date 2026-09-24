
CREATE DATABASE IF NOT EXISTS waste_management;

USE waste_management;


CREATE TABLE IF NOT EXISTS Zone (
    Zone_ID INT PRIMARY KEY AUTO_INCREMENT,

    Zone_Name VARCHAR(50) NOT NULL,

    Area VARCHAR(100) NOT NULL,

    Zone_Officer VARCHAR(50) NOT NULL,

    -- UNIQUE constraint
    CONSTRAINT uq_zone_name
        UNIQUE (Zone_Name),

    -- CHECK constraint
    CONSTRAINT chk_zone_id
        CHECK (Zone_ID > 0)
);



CREATE TABLE IF NOT EXISTS Truck (
    Truck_ID INT PRIMARY KEY AUTO_INCREMENT,

    Truck_No VARCHAR(15) NOT NULL,

    Driver_Name VARCHAR(50) NOT NULL,

    Driver_Phone VARCHAR(15) NOT NULL,

    -- CHECK constraint
    CONSTRAINT chk_truck_id
        CHECK (Truck_ID > 0)
);



-- 3. HOUSEHOLD TABLE

CREATE TABLE IF NOT EXISTS Household (
    Household_ID INT PRIMARY KEY AUTO_INCREMENT,

    Household_Name VARCHAR(100) NOT NULL,

    Address VARCHAR(150) NOT NULL,

    Zone_ID INT NOT NULL,

    -- CHECK constraint
    CONSTRAINT chk_household_id
        CHECK (Household_ID > 0),

    -- FOREIGN KEY with CASCADE
    CONSTRAINT fk_household_zone
        FOREIGN KEY (Zone_ID)
        REFERENCES Zone(Zone_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- 4. COLLECTION TABLE


CREATE TABLE IF NOT EXISTS Collection (
    Collection_ID VARCHAR(10) PRIMARY KEY,

    Collection_Date DATE NOT NULL,

    Household_ID INT NOT NULL,

    Truck_ID INT NOT NULL,

    Waste_Type VARCHAR(15) NOT NULL,

    Weight_kg DECIMAL(6,2) NOT NULL,

    Segregation_Status VARCHAR(15) NOT NULL
        DEFAULT 'Compliant',


    -- CHECK: Weight must be positive
    CONSTRAINT chk_collection_weight
        CHECK (Weight_kg > 0),


    -- CHECK: Household ID must be positive
    CONSTRAINT chk_collection_household
        CHECK (Household_ID > 0),


    -- CHECK: Truck ID must be positive
    CONSTRAINT chk_collection_truck
        CHECK (Truck_ID > 0),


    -- CHECK: Valid segregation status
    CONSTRAINT chk_segregation_status
        CHECK (
            Segregation_Status
            IN ('Compliant', 'Non-Compliant')
        ),


    -- FOREIGN KEY: Household
    CONSTRAINT fk_collection_household
        FOREIGN KEY (Household_ID)
        REFERENCES Household(Household_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,


    -- FOREIGN KEY: Truck
    CONSTRAINT fk_collection_truck
        FOREIGN KEY (Truck_ID)
        REFERENCES Truck(Truck_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- 5. COLLECTION AUDIT LOG TABLE


CREATE TABLE IF NOT EXISTS Collection_Audit_Log (
    Log_ID INT PRIMARY KEY AUTO_INCREMENT,

    Collection_ID VARCHAR(10) NOT NULL,

    Action VARCHAR(20) NOT NULL
        DEFAULT 'INSERT',

    Action_Time DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP,


    -- CHECK: Valid audit action
    CONSTRAINT chk_audit_action
        CHECK (
            Action
            IN ('INSERT', 'UPDATE', 'DELETE')
        ),


    -- FOREIGN KEY with CASCADE
    CONSTRAINT fk_audit_collection
        FOREIGN KEY (Collection_ID)
        REFERENCES Collection(Collection_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- 6. VERIFY TABLES


SHOW TABLES;



-- 7. DESCRIBE TABLES

DESCRIBE Zone;

DESCRIBE Truck;

DESCRIBE Household;

DESCRIBE Collection;

DESCRIBE Collection_Audit_Log;



-- 8. VERIFY CONSTRAINT
SHOW CREATE TABLE Zone;

SHOW CREATE TABLE Truck;

SHOW CREATE TABLE Household;

SHOW CREATE TABLE Collection;

SHOW CREATE TABLE Collection_Audit_Log;