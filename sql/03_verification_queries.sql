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


# Other Interesting Queries
## ArborVida Foundation

This file contains queries organized in three sections:
1. Relational algebra equivalents (direct SQL translations from doc 07)
2. Relational calculus equivalents using EXISTS (from doc 08)
3. Additional analytical queries

Run after 02_insert_data.sql. Schema: rfo.

---

SET search_path TO rfo;

-- ============================================================
-- SECTION 1: RELATIONAL ALGEBRA EQUIVALENTS
-- Each query maps directly to an expression in 07_relational_algebra.md
-- ============================================================

-- A1: Names of all volunteers
-- Algebra: pi_name(volunteer)
SELECT DISTINCT name
FROM volunteer;

-- A2: Fast-growing species
-- Algebra: sigma_growth_rate='fast'(species)
SELECT *
FROM species
WHERE growth_rate = 'fast';

-- A3: Volunteers who participated in at least one event
-- Algebra: pi_name(volunteer BOWTIE participation)
SELECT DISTINCT v.name
FROM volunteer v
JOIN participation p ON v.volunteer_id = p.volunteer_id;

-- A4: Volunteers who have NEVER participated
-- Algebra: pi_name(volunteer) - pi_name(volunteer BOWTIE participation)
SELECT name
FROM volunteer
EXCEPT
SELECT DISTINCT v.name
FROM volunteer v
JOIN participation p ON v.volunteer_id = p.volunteer_id;

-- A5: Names of Team Leaders
-- Algebra: pi_name(volunteer BOWTIE sigma_role='Team Leader'(participation))
SELECT DISTINCT v.name
FROM volunteer v
JOIN participation p ON v.volunteer_id = p.volunteer_id
WHERE p.role = 'Team Leader';

-- A6: Species planted in event 1
-- Algebra: pi_scientific_name,common_name(species BOWTIE sigma_event_id=1(event_species))
SELECT DISTINCT s.scientific_name, s.common_name
FROM species s
JOIN event_species es ON s.species_id = es.species_id
WHERE es.event_id = 1;

-- A7: Zones managed by ArborVida Peru
-- Algebra: pi_zone.name,region(zone BOWTIE sigma_name='ArborVida Peru'(organization))
SELECT z.name AS zone, z.region
FROM zone z
JOIN organization o ON z.org_id = o.org_id
WHERE o.name = 'ArborVida Peru';

-- A8: Monitoring records with critical survival rate
-- Algebra: pi_monitoring_date,survival_rate,notes(sigma_survival_rate<85(monitoring))
SELECT monitoring_date, survival_rate, notes
FROM monitoring
WHERE survival_rate < 85;

-- A9: Complete reforestation chain (5-table join)
-- Algebra: pi_o.name,z.name,pe.name,s.common_name(organization BOWTIE zone BOWTIE planting_event BOWTIE event_species BOWTIE species)
SELECT o.name          AS organization,
       z.name          AS zone,
       pe.name         AS event,
       s.common_name   AS species
FROM organization o
JOIN zone z            ON o.org_id = z.org_id
JOIN planting_event pe ON z.zone_id = pe.zone_id
JOIN event_species es  ON pe.event_id = es.event_id
JOIN species s         ON es.species_id = s.species_id;

-- ============================================================
-- SECTION 2: RELATIONAL CALCULUS EQUIVALENTS
-- Each query uses EXISTS / NOT EXISTS from doc 08
-- ============================================================

-- C1: Slow or fast growing species
-- TRC: { t.scientific_name, t.growth_rate | species(t) /\ (t.growth_rate='slow' \/ t.growth_rate='fast') }
SELECT scientific_name, growth_rate
FROM species
WHERE growth_rate = 'slow' OR growth_rate = 'fast';

-- C2: Volunteers who participated in at least one event (EXISTS form)
-- TRC: { t.name | volunteer(t) /\ EXISTS p (participation(p) /\ p.volunteer_id = t.volunteer_id) }
SELECT v.name
FROM volunteer v
WHERE EXISTS (
    SELECT 1 FROM participation p
    WHERE p.volunteer_id = v.volunteer_id
);

-- C3: Volunteers who have NEVER participated (NOT EXISTS form)
-- TRC: { t.name | volunteer(t) /\ -(EXISTS p (participation(p) /\ p.volunteer_id = t.volunteer_id)) }
SELECT v.name
FROM volunteer v
WHERE NOT EXISTS (
    SELECT 1 FROM participation p
    WHERE p.volunteer_id = v.volunteer_id
);

-- C4: Team Leaders (EXISTS with multiple conditions)
-- TRC: { t.name | volunteer(t) /\ EXISTS p (participation(p) /\ p.volunteer_id = t.volunteer_id /\ p.role = 'Team Leader') }
SELECT v.name
FROM volunteer v
WHERE EXISTS (
    SELECT 1 FROM participation p
    WHERE p.volunteer_id = v.volunteer_id
    AND p.role = 'Team Leader'
);

-- C5: Species planted in event 1 with survival rate below 85 (nested EXISTS)
-- TRC: { s.common_name | species(s) /\ EXISTS es (...) /\ EXISTS m (...) }
SELECT DISTINCT s.common_name
FROM species s
WHERE EXISTS (
    SELECT 1 FROM event_species es
    WHERE es.species_id = s.species_id
    AND es.event_id = 1
    AND EXISTS (
        SELECT 1 FROM monitoring m
        WHERE m.event_id = es.event_id
        AND m.species_id = es.species_id
        AND m.survival_rate < 85
    )
);

-- C6: Expert technical volunteers
-- TRC: { t.name | volunteer(t) /\ EXISTS tv (technical_volunteer(tv) /\ tv.volunteer_id = t.volunteer_id /\ tv.certification_level = 'expert') }
SELECT v.name
FROM volunteer v
WHERE EXISTS (
    SELECT 1 FROM technical_volunteer tv
    WHERE tv.volunteer_id = v.volunteer_id
    AND tv.certification_level = 'expert'
);

-- ============================================================
-- SECTION 3: ADDITIONAL ANALYTICAL QUERIES
-- ============================================================

-- Q1: Total trees planted and average survival rate per organization
SELECT
    o.name                              AS organization,
    SUM(es.trees_planted)               AS total_trees_planted,
    ROUND(AVG(m.survival_rate), 2)      AS avg_survival_rate,
    COUNT(DISTINCT pe.event_id)         AS total_events,
    COUNT(DISTINCT p.volunteer_id)      AS total_volunteers
FROM organization o
JOIN zone z             ON o.org_id = z.org_id
JOIN planting_event pe  ON z.zone_id = pe.zone_id
JOIN event_species es   ON pe.event_id = es.event_id
LEFT JOIN monitoring m  ON es.event_id = m.event_id
                       AND es.species_id = m.species_id
LEFT JOIN participation p ON pe.event_id = p.event_id
GROUP BY o.org_id, o.name
ORDER BY total_trees_planted DESC;

-- Q2: Average survival rate per species across all events
SELECT
    s.common_name,
    s.scientific_name,
    ROUND(AVG(m.survival_rate), 2)  AS avg_survival_rate,
    MIN(m.survival_rate)            AS min_survival_rate,
    MAX(m.survival_rate)            AS max_survival_rate,
    COUNT(m.monitoring_id)          AS monitoring_records
FROM species s
JOIN monitoring m ON s.species_id = m.species_id
GROUP BY s.species_id, s.common_name, s.scientific_name
ORDER BY avg_survival_rate DESC;

-- Q3: Volunteers ranked by total hours worked
SELECT
    v.name                          AS volunteer,
    COUNT(p.participation_id)       AS total_events,
    SUM(p.hours_worked)             AS total_hours,
    ROUND(AVG(p.hours_worked), 2)   AS avg_hours_per_event
FROM volunteer v
JOIN participation p ON v.volunteer_id = p.volunteer_id
GROUP BY v.volunteer_id, v.name
ORDER BY total_hours DESC;

-- Q4: Events with no monitoring records yet
-- Identifies planting events that still need follow-up
SELECT
    pe.name         AS event,
    pe.event_date,
    z.name          AS zone,
    pe.total_trees
FROM planting_event pe
JOIN zone z ON pe.zone_id = z.zone_id
WHERE NOT EXISTS (
    SELECT 1 FROM monitoring m
    WHERE m.event_id = pe.event_id
);

-- Q5: Species that have never been monitored
SELECT
    s.common_name,
    s.scientific_name
FROM species s
WHERE NOT EXISTS (
    SELECT 1 FROM monitoring m
    WHERE m.species_id = s.species_id
);

-- Q6: All volunteers with their subtype and certifications
SELECT
    v.name                                      AS volunteer,
    v.join_date,
    CASE
        WHEN tv.volunteer_id IS NOT NULL THEN 'Technical'
        WHEN gv.volunteer_id IS NOT NULL THEN 'General'
    END                                         AS subtype,
    tv.specialty,
    tv.certification_level,
    gv.availability_hours,
    COUNT(vc.certification)                     AS total_certifications
FROM volunteer v
LEFT JOIN technical_volunteer tv ON v.volunteer_id = tv.volunteer_id
LEFT JOIN general_volunteer gv   ON v.volunteer_id = gv.volunteer_id
LEFT JOIN volunteer_certification vc ON v.volunteer_id = vc.volunteer_id
GROUP BY v.volunteer_id, v.name, v.join_date,
         tv.volunteer_id, tv.specialty, tv.certification_level,
         gv.volunteer_id, gv.availability_hours
ORDER BY subtype, v.name;

-- Q7: Full reforestation report with survival status label
SELECT
    o.name          AS organization,
    z.name          AS zone,
    pe.name         AS event,
    pe.event_date,
    s.common_name   AS species,
    es.trees_planted,
    m.survival_rate,
    m.monitoring_date,
    CASE
        WHEN m.survival_rate IS NULL    THEN 'Not monitored'
        WHEN m.survival_rate >= 90      THEN 'Excellent'
        WHEN m.survival_rate >= 80      THEN 'Good'
        WHEN m.survival_rate >= 70      THEN 'At risk'
        ELSE                                 'Critical'
    END                                 AS survival_status
FROM organization o
JOIN zone z             ON o.org_id = z.org_id
JOIN planting_event pe  ON z.zone_id = pe.zone_id
JOIN event_species es   ON pe.event_id = es.event_id
JOIN species s          ON es.species_id = s.species_id
LEFT JOIN monitoring m  ON es.event_id = m.event_id
                       AND es.species_id = m.species_id
ORDER BY o.name, pe.event_date, s.common_name;

-- Q8: Disjoint constraint verification (should return 0 rows)
-- Verifies no volunteer appears in both subtypes simultaneously
SELECT v.name AS volunteer_in_both_subtypes
FROM volunteer v
JOIN technical_volunteer tv ON v.volunteer_id = tv.volunteer_id
JOIN general_volunteer gv   ON v.volunteer_id = gv.volunteer_id;

-- Q9: Total constraint verification
-- Shows volunteers without any subtype (should return 0 rows)
SELECT v.name AS volunteer_without_subtype
FROM volunteer v
WHERE NOT EXISTS (
    SELECT 1 FROM technical_volunteer tv
    WHERE tv.volunteer_id = v.volunteer_id
)
AND NOT EXISTS (
    SELECT 1 FROM general_volunteer gv
    WHERE gv.volunteer_id = v.volunteer_id
);

-- ============================================================
-- SECTION 4: OTHER ACTIONS (DML)
-- ============================================================

-- UPDATE: adjust availability hours for a general volunteer
UPDATE general_volunteer
SET availability_hours = 32
WHERE volunteer_id = (
    SELECT volunteer_id FROM volunteer WHERE name = 'Luis Mamani'
);

-- Verify the update
SELECT v.name, gv.availability_hours
FROM volunteer v
JOIN general_volunteer gv ON v.volunteer_id = gv.volunteer_id
WHERE v.name = 'Luis Mamani';

-- INSERT: add a new monitoring record for an unmonitored species
INSERT INTO monitoring (event_id, species_id, monitoring_date,
                        survival_rate, notes)
VALUES (4, 5, '2026-07-06', 88.00,
        'Good adaptation after initial transplant shock. Recommend second check in 30 days.');

-- Verify the insert
SELECT pe.name AS event, s.common_name, m.monitoring_date,
       m.survival_rate, m.notes
FROM monitoring m
JOIN event_species es  ON m.event_id = es.event_id
                       AND m.species_id = es.species_id
JOIN planting_event pe ON es.event_id = pe.event_id
JOIN species s         ON es.species_id = s.species_id
WHERE m.event_id = 4 AND m.species_id = 5;

-- DELETE: remove a test monitoring record (using the one just inserted)
DELETE FROM monitoring
WHERE event_id = 4 AND species_id = 5
AND monitoring_date = '2026-07-06';

-- Verify the delete
SELECT COUNT(*) AS remaining_monitoring_records FROM monitoring;
