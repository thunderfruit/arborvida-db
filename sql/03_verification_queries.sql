-- ============================================================
-- ArborVida Foundation
-- Community Reforestation Management System
-- Phase 6: Implementation — Verification Queries
-- Author: thunderfruit
-- Date: June 2026
-- ============================================================
-- Run AFTER 02_insert_data.sql
-- Each query verifies a specific business requirement.
-- ============================================================

SET search_path TO rfo;

-- ============================================================
-- SECTION 1: DATA COMPLETENESS CHECKS
-- Verify all tables were populated correctly.
-- ============================================================

-- Count rows in every table
SELECT 'organization'           AS table_name, COUNT(*) AS rows FROM organization
UNION ALL
SELECT 'zone',                  COUNT(*) FROM zone
UNION ALL
SELECT 'species',               COUNT(*) FROM species
UNION ALL
SELECT 'volunteer',             COUNT(*) FROM volunteer
UNION ALL
SELECT 'volunteer_certification', COUNT(*) FROM volunteer_certification
UNION ALL
SELECT 'planting_event',        COUNT(*) FROM planting_event
UNION ALL
SELECT 'event_species',         COUNT(*) FROM event_species
UNION ALL
SELECT 'participation',         COUNT(*) FROM participation
UNION ALL
SELECT 'monitoring',            COUNT(*) FROM monitoring
ORDER BY table_name;

-- ============================================================
-- SECTION 2: BUSINESS QUERIES
-- Verify the system answers real operational questions.
-- ============================================================

-- Q1: Total trees planted per organization
SELECT
    o.name          AS organization,
    SUM(pe.total_trees) AS total_trees_planted
FROM organization o
JOIN zone z             ON o.org_id = z.org_id
JOIN planting_event pe  ON z.zone_id = pe.zone_id
GROUP BY o.name
ORDER BY total_trees_planted DESC;

-- Q2: Average survival rate per species across all events
SELECT
    s.common_name,
    s.scientific_name,
    ROUND(AVG(m.survival_rate), 2)  AS avg_survival_rate,
    COUNT(m.monitoring_id)          AS monitoring_records
FROM species s
JOIN monitoring m ON s.species_id = m.species_id
GROUP BY s.species_id, s.common_name, s.scientific_name
ORDER BY avg_survival_rate DESC;

-- Q3: Volunteers with total hours and events attended
SELECT
    v.name                          AS volunteer,
    COUNT(p.participation_id)       AS events_attended,
    SUM(p.hours_worked)             AS total_hours,
    MAX(p.role)                     AS last_role
FROM volunteer v
JOIN participation p ON v.volunteer_id = p.volunteer_id
GROUP BY v.volunteer_id, v.name
ORDER BY total_hours DESC;

-- Q4: Planting events with no monitoring records yet
SELECT
    pe.name         AS event_name,
    pe.event_date,
    z.name          AS zone,
    pe.total_trees
FROM planting_event pe
JOIN zone z ON pe.zone_id = z.zone_id
LEFT JOIN monitoring m ON pe.event_id = m.event_id
WHERE m.monitoring_id IS NULL;

-- Q5: Species survival rates below 85% (needs attention)
SELECT
    s.common_name,
    pe.name         AS event_name,
    pe.event_date,
    z.region,
    m.survival_rate,
    m.notes
FROM monitoring m
JOIN event_species es   ON m.event_id = es.event_id
                       AND m.species_id = es.species_id
JOIN planting_event pe  ON es.event_id = pe.event_id
JOIN zone z             ON pe.zone_id = z.zone_id
JOIN species s          ON es.species_id = s.species_id
WHERE m.survival_rate < 85
ORDER BY m.survival_rate ASC;

-- Q6: Volunteers and their certifications
SELECT
    v.name                  AS volunteer,
    vc.certification,
    vc.year_obtained
FROM volunteer v
JOIN volunteer_certification vc ON v.volunteer_id = vc.volunteer_id
ORDER BY v.name, vc.year_obtained;

-- ============================================================
-- SECTION 3: INTEGRITY CONSTRAINT TESTS
-- Each test SHOULD FAIL with an error.
-- Verify the DBMS enforces the business rules.
-- ============================================================

-- TEST 1: Insert a zone for a non-existent organization (BR01)
-- Expected: ERROR - FK violation on org_id
INSERT INTO zone (org_id, name, region, area_hectares)
VALUES (999, 'Zona Fantasma', 'Ninguna', 10.0);

-- TEST 2: Insert a planting event for a non-existent zone (BR01)
-- Expected: ERROR - FK violation on zone_id
INSERT INTO planting_event (zone_id, event_date, name, total_trees)
VALUES (999, '2026-06-01', 'Evento Fantasma', 100);

-- TEST 3: Insert a negative tree count (BR03)
-- Expected: ERROR - CHECK constraint violation
INSERT INTO event_species (event_id, species_id, trees_planted)
VALUES (1, 5, -50);

-- TEST 4: Register the same volunteer twice for the same event (BR05)
-- Expected: ERROR - UNIQUE constraint violation
INSERT INTO participation (event_id, volunteer_id, role, hours_worked)
VALUES (1, 1, 'Duplicate Role', 4.0);

-- TEST 5: Monitor a species that was never planted in that event (BR06)
-- Event 1 has species 1 and 2. Species 5 was never planted in event 1.
-- Expected: ERROR - composite FK violation
INSERT INTO monitoring (event_id, species_id, monitoring_date, survival_rate)
VALUES (1, 5, '2026-05-01', 80.0);

-- TEST 6: Insert a survival rate above 100 (BR04)
-- Expected: ERROR - CHECK constraint violation
INSERT INTO monitoring (event_id, species_id, monitoring_date, survival_rate)
VALUES (1, 1, '2026-06-01', 150.0);
