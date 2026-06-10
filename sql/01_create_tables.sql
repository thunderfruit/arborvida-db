-- ============================================================
-- ArborVida Foundation
-- Community Reforestation Management System
-- Phase 5: Physical Design — DDL Script
-- Author: thunderfruit
-- Date: June 2026
-- DBMS: PostgreSQL 16
-- Schema: rfo
-- ============================================================

-- Run this first in psql or pgAdmin:
-- CREATE DATABASE arborvida;
-- Then connect to arborvida and run the rest.

CREATE SCHEMA IF NOT EXISTS rfo;
SET search_path TO rfo;

-- ============================================================
-- BLOCK 1: INDEPENDENT TABLES (no foreign keys)
-- Create these first — other tables depend on them.
-- ============================================================

CREATE TABLE organization (
    org_id       SERIAL          PRIMARY KEY,
    name         VARCHAR(200)    NOT NULL UNIQUE,
    country      VARCHAR(100)    NOT NULL,
    founded_date DATE,
    website      VARCHAR(300),

    CONSTRAINT chk_org_name_length
        CHECK (LENGTH(name) >= 2)
);

COMMENT ON TABLE organization IS
    'Foundation branches or partner organizations managing reforestation zones.';

-- ------------------------------------------------------------

CREATE TABLE species (
    species_id      SERIAL          PRIMARY KEY,
    scientific_name VARCHAR(200)    NOT NULL UNIQUE,
    common_name     VARCHAR(200)    NOT NULL,
    native_region   VARCHAR(200),
    growth_rate     VARCHAR(10)
                    CHECK (growth_rate IN ('slow', 'medium', 'fast')),

    CONSTRAINT chk_scientific_name_length
        CHECK (LENGTH(scientific_name) >= 5)
);

COMMENT ON TABLE species IS
    'Standardized tree species catalog. Scientific name enforces uniqueness
     and avoids regional naming ambiguity (see Phase 2, BR04).';

-- ------------------------------------------------------------

CREATE TABLE volunteer (
    volunteer_id SERIAL          PRIMARY KEY,
    dni          CHAR(8)         NOT NULL UNIQUE,
    name         VARCHAR(100)    NOT NULL,
    email        VARCHAR(200)    UNIQUE,
    phone        VARCHAR(20),
    join_date    DATE            NOT NULL DEFAULT CURRENT_DATE,

    CONSTRAINT chk_dni_numeric
        CHECK (dni ~ '^[0-9]{8}$')
);

COMMENT ON TABLE volunteer IS
    'People who participate in planting events. DNI is the national ID number.';

-- ============================================================
-- BLOCK 2: SPECIALIZATION TABLES (Strategy B — subtype tables)
-- Each subtype stores only its own attributes + PK/FK to supertype.
-- Total constraint: every volunteer must appear in one subtype table.
-- Disjoint constraint: a volunteer cannot appear in both subtype tables.
-- ============================================================
 
CREATE TABLE technical_volunteer (
    volunteer_id       INTEGER         PRIMARY KEY
                                       REFERENCES volunteer(volunteer_id)
                                       ON DELETE CASCADE
                                       ON UPDATE CASCADE,
    specialty          VARCHAR(100)    NOT NULL,
    certification_level VARCHAR(20)   NOT NULL
                                       CHECK (certification_level IN ('entry', 'intermediate', 'expert')),
 
    CONSTRAINT chk_specialty_not_empty
        CHECK (LENGTH(TRIM(specialty)) > 0)
);
 
COMMENT ON TABLE technical_volunteer IS
    'Subtype of volunteer. Technical volunteers have a defined specialty
     (e.g. Botanist, Field Coordinator) and a certification level.
     Strategy B: stores only subtype attributes + PK/FK to volunteer.
     ON DELETE CASCADE: if the volunteer is deleted, their subtype record
     is also deleted.';

-- ------------------------------------------------------------

CREATE TABLE general_volunteer (
    volunteer_id      INTEGER         PRIMARY KEY
                                      REFERENCES volunteer(volunteer_id)
                                      ON DELETE CASCADE
                                      ON UPDATE CASCADE,
    availability_hours INTEGER        NOT NULL
                                      CHECK (availability_hours > 0 AND availability_hours <= 744),
 
    CONSTRAINT chk_availability_positive
        CHECK (availability_hours > 0)
);
 
COMMENT ON TABLE general_volunteer IS
    'Subtype of volunteer. General volunteers declare monthly availability in hours.
     Strategy B: stores only subtype attributes + PK/FK to volunteer.
     Disjoint: a volunteer_id cannot appear in both technical_volunteer
     and general_volunteer simultaneously.';

-- ============================================================
-- BLOCK 3: TABLES WITH FKs TO BLOCK 1
-- ============================================================

CREATE TABLE zone (
    zone_id       SERIAL          PRIMARY KEY,
    org_id        INTEGER         NOT NULL
                                  REFERENCES organization(org_id)
                                  ON DELETE RESTRICT
                                  ON UPDATE CASCADE,
    name          VARCHAR(200)    NOT NULL,
    region        VARCHAR(200)    NOT NULL,
    area_hectares NUMERIC(10,2)   CHECK (area_hectares > 0),
    latitude      NUMERIC(9,6),
    longitude     NUMERIC(9,6),

    CONSTRAINT chk_latitude_range
        CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_longitude_range
        CHECK (longitude BETWEEN -180 AND 180)
);

COMMENT ON TABLE zone IS
    'Geographic areas for planting. Belongs to exactly one organization.
     ON DELETE RESTRICT: cannot delete an organization that has zones.';

-- ------------------------------------------------------------

CREATE TABLE planting_event (
    event_id           SERIAL          PRIMARY KEY,
    zone_id            INTEGER         NOT NULL
                                       REFERENCES zone(zone_id)
                                       ON DELETE RESTRICT
                                       ON UPDATE CASCADE,
    event_date         DATE            NOT NULL,
    name               VARCHAR(200),
    weather_conditions VARCHAR(100),
    total_trees        INTEGER         NOT NULL
                                       CHECK (total_trees > 0),

    CONSTRAINT chk_event_date_not_future
        CHECK (event_date <= CURRENT_DATE)
);

COMMENT ON TABLE planting_event IS
    'Individual planting campaign in a specific zone.
     ON DELETE RESTRICT: cannot delete a zone that has events.
     total_trees is valid denormalization — recorded in field before
     species breakdown is completed in event_species.';

-- ============================================================
-- BLOCK 4: N:M INTERMEDIATE TABLES
-- ============================================================

CREATE TABLE event_species (
    event_id      INTEGER         NOT NULL
                                  REFERENCES planting_event(event_id)
                                  ON DELETE RESTRICT
                                  ON UPDATE CASCADE,
    species_id    INTEGER         NOT NULL
                                  REFERENCES species(species_id)
                                  ON DELETE RESTRICT
                                  ON UPDATE CASCADE,
    trees_planted INTEGER         NOT NULL
                                  CHECK (trees_planted > 0),

    CONSTRAINT pk_event_species
        PRIMARY KEY (event_id, species_id)
);

COMMENT ON TABLE event_species IS
    'Resolves N:M between planting_event and species.
     Composite PK prevents the same species being registered twice per event.
     ON DELETE RESTRICT on both FKs: preserves planting history.
     Referenced by monitoring via composite FK.';

-- ------------------------------------------------------------

CREATE TABLE participation (
    participation_id SERIAL      PRIMARY KEY,
    event_id         INTEGER     NOT NULL
                                 REFERENCES planting_event(event_id)
                                 ON DELETE RESTRICT
                                 ON UPDATE CASCADE,
    volunteer_id     INTEGER     NOT NULL
                                 REFERENCES volunteer(volunteer_id)
                                 ON DELETE RESTRICT
                                 ON UPDATE CASCADE,
    role             VARCHAR(100),
    hours_worked     NUMERIC(5,2) CHECK (hours_worked > 0),

    CONSTRAINT uq_volunteer_per_event
        UNIQUE (event_id, volunteer_id)
);

COMMENT ON TABLE participation IS
    'Resolves N:M between planting_event and volunteer.
     UNIQUE(event_id, volunteer_id) enforces one registration per volunteer per event.
     Surrogate PK allows future tables to reference this record.';

-- ============================================================
-- BLOCK 5: MONITORING
-- References composite FK from event_species.
-- Must be created AFTER event_species.
-- ============================================================

CREATE TABLE monitoring (
    monitoring_id   SERIAL          PRIMARY KEY,
    event_id        INTEGER         NOT NULL,
    species_id      INTEGER         NOT NULL,
    monitoring_date DATE            NOT NULL,
    survival_rate   NUMERIC(5,2)    NOT NULL
                                    CHECK (survival_rate BETWEEN 0 AND 100),
    notes           TEXT,

    CONSTRAINT fk_monitoring_event_species
        FOREIGN KEY (event_id, species_id)
        REFERENCES event_species(event_id, species_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_monitoring_date_valid
        CHECK (monitoring_date >= CURRENT_DATE - INTERVAL '10 years')
);

COMMENT ON TABLE monitoring IS
    'Survival rate checks after planting.
     Composite FK (event_id, species_id) references event_species — enforces
     business rule BR06: only planted species can be monitored.
     NUMERIC(5,2) used instead of FLOAT to avoid floating-point imprecision.';

-- ============================================================
-- BLOCK 6: MULTIVALUED ATTRIBUTE
-- ============================================================

CREATE TABLE volunteer_certification (
    volunteer_id   INTEGER         NOT NULL
                                   REFERENCES volunteer(volunteer_id)
                                   ON DELETE CASCADE
                                   ON UPDATE CASCADE,
    certification  VARCHAR(200)    NOT NULL,
    year_obtained  INTEGER
                   CHECK (year_obtained BETWEEN 2000 AND 2030),

    CONSTRAINT pk_volunteer_certification
        PRIMARY KEY (volunteer_id, certification)
);

COMMENT ON TABLE volunteer_certification IS
    'Certifications held by volunteers — multivalued attribute of volunteer.
     Composite PK prevents duplicate certifications per volunteer.
     ON DELETE CASCADE: if a volunteer is deleted, their certifications go too.';

-- ============================================================
-- TRIGGER: monitoring_date cannot be before event_date
-- ============================================================
 
CREATE OR REPLACE FUNCTION fn_check_monitoring_date()
RETURNS TRIGGER AS $$
DECLARE
    v_event_date DATE;
BEGIN
    SELECT pe.event_date INTO v_event_date
    FROM planting_event pe
    JOIN event_species es ON pe.event_id = es.event_id
    WHERE es.event_id = NEW.event_id
      AND es.species_id = NEW.species_id
    LIMIT 1;
 
    IF NEW.monitoring_date < v_event_date THEN
        RAISE EXCEPTION
            'monitoring_date (%) cannot be before event_date (%)',
            NEW.monitoring_date, v_event_date;
    END IF;
 
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER trg_monitoring_date_valid
    BEFORE INSERT OR UPDATE ON monitoring
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_monitoring_date();
 