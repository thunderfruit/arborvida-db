-- ============================================================
-- ArborVida Foundation
-- Community Reforestation Management System
-- Phase 6: Implementation — Sample Data
-- Author: thunderfruit
-- Date: June 2026
-- ============================================================
-- Run AFTER 01_create_tables.sql
-- Order respects FK dependencies: parent tables first.
-- ============================================================

SET search_path TO rfo;

-- ============================================================
-- BLOCK 1: ORGANIZATIONS
-- ============================================================

INSERT INTO organization (name, country, founded_date, website) VALUES
    ('ArborVida Peru',    'Peru',     '2015-03-10', 'arborvida.pe'),
    ('ArborVida Bolivia', 'Bolivia',  '2018-07-22', 'arborvida.bo'),
    ('ArborVida Colombia','Colombia', '2020-01-15', 'arborvida.co');

-- ============================================================
-- BLOCK 2: SPECIES
-- ============================================================

INSERT INTO species (scientific_name, common_name, native_region, growth_rate) VALUES
    ('Cedrela odorata',       'Cedro',       'Amazonia peruana',  'slow'),
    ('Swietenia macrophylla', 'Caoba',       'Amazonia peruana',  'slow'),
    ('Guazuma ulmifolia',     'Mutamba',     'Costa peruana',     'fast'),
    ('Triplaris americana',   'Tangarana',   'Selva alta',        'medium'),
    ('Ochroma pyramidale',    'Balsa',       'Amazonia',          'fast');

-- ============================================================
-- BLOCK 3: VOLUNTEERS
-- ============================================================

INSERT INTO volunteer (dni, name, email, phone, join_date) VALUES
    ('12345678', 'Carlos Quispe',   'carlos@mail.com',  '987654321', '2023-01-15'),
    ('87654321', 'Maria Lopez',     'maria@mail.com',   '912345678', '2023-03-20'),
    ('11223344', 'Ana Torres',      'ana@mail.com',     '956789012', '2024-02-01'),
    ('44332211', 'Luis Mamani',     'luis@mail.com',    '934567890', '2024-05-10'),
    ('55667788', 'Rosa Flores',     'rosa@mail.com',    NULL,        '2025-01-08');

-- ============================================================
-- BLOCK 4: VOLUNTEER CERTIFICATIONS (multivalued)
-- ============================================================

INSERT INTO volunteer_certification (volunteer_id, certification, year_obtained) VALUES
    (1, 'Reforestation Technician',  2022),
    (1, 'First Aid',                 2023),
    (2, 'Environmental Education',   2021),
    (2, 'Reforestation Technician',  2023),
    (3, 'First Aid',                 2024);

-- ============================================================
-- BLOCK 5: ZONES
-- ============================================================

INSERT INTO zone (org_id, name, region, area_hectares, latitude, longitude) VALUES
    (1, 'Zona Norte Loreto',     'Loreto',       45.50,  -3.7437,  -73.2516),
    (1, 'Zona Ucayali Central',  'Ucayali',      30.00,  -8.3791,  -74.5539),
    (1, 'Zona Madre de Dios',    'Madre de Dios',60.00, -12.5931,  -69.1891),
    (2, 'Zona Chapare',          'Cochabamba',   40.00, -16.7234,  -65.3456);

-- ============================================================
-- BLOCK 6: PLANTING EVENTS
-- ============================================================

INSERT INTO planting_event (zone_id, event_date, name, weather_conditions, total_trees) VALUES
    (1, '2026-03-15', 'Siembra Primavera 2026',    'Soleado',  500),
    (1, '2026-04-20', 'Dia de la Tierra 2026',     'Nublado',  300),
    (2, '2026-05-10', 'Reforestacion Ucayali',     'Lluvioso', 400),
    (3, '2026-02-28', 'Siembra Verano Madre Dios', 'Soleado',  250);

-- ============================================================
-- BLOCK 7: EVENT_SPECIES (N:M resolution)
-- ============================================================

INSERT INTO event_species (event_id, species_id, trees_planted) VALUES
    (1, 1, 200),  -- Event 1: 200 Cedro
    (1, 2, 300),  -- Event 1: 300 Caoba
    (2, 3, 200),  -- Event 2: 200 Mutamba
    (2, 4, 100),  -- Event 2: 100 Tangarana
    (3, 1, 150),  -- Event 3: 150 Cedro
    (3, 3, 250),  -- Event 3: 250 Mutamba
    (4, 2, 100),  -- Event 4: 100 Caoba
    (4, 5, 150);  -- Event 4: 150 Balsa

-- ============================================================
-- BLOCK 8: PARTICIPATION (N:M resolution)
-- ============================================================

INSERT INTO participation (event_id, volunteer_id, role, hours_worked) VALUES
    (1, 1, 'Team Leader',  8.0),
    (1, 2, 'Planter',      6.5),
    (1, 3, 'Logistics',    5.0),
    (2, 1, 'Planter',      5.0),
    (2, 4, 'Logistics',    4.0),
    (3, 2, 'Team Leader',  7.5),
    (3, 5, 'Planter',      6.0),
    (4, 3, 'Planter',      8.0),
    (4, 4, 'Team Leader',  7.0);

-- ============================================================
-- BLOCK 9: MONITORING
-- ============================================================

INSERT INTO monitoring (event_id, species_id, monitoring_date, survival_rate, notes) VALUES
    (1, 1, '2026-04-15', 92.50, 'Good growth, adequate rainfall'),
    (1, 2, '2026-04-15', 88.00, 'Some trees show signs of drought stress'),
    (2, 3, '2026-05-20', 95.00, 'Excellent adaptation to terrain'),
    (2, 4, '2026-05-20', 78.50, 'Partial loss due to flooding in lower area'),
    (3, 1, '2026-06-05', 90.00, 'Recovery after initial transplant shock'),
    (4, 2, '2026-04-10', 85.00, 'Good conditions, dry season favorable for caoba');
	
-- ============================================================
-- BLOCK 10: SPECIALIZATION DATA
-- Assign each existing volunteer to one subtype (Total constraint)
-- Disjoint: no volunteer appears in both tables
--
-- Technical volunteers: those with formal technical roles + certifications
-- General volunteers: those with general participation roles
-- ============================================================
 
-- TECHNICAL VOLUNTEERS
-- Carlos Quispe (volunteer_id=1): Team Leader, has Reforestation + First Aid certs
INSERT INTO technical_volunteer (volunteer_id, specialty, certification_level)
VALUES (1, 'Reforestation Specialist', 'expert');
 
-- Maria Lopez (volunteer_id=2): Team Leader, has Environmental Education + Reforestation
INSERT INTO technical_volunteer (volunteer_id, specialty, certification_level)
VALUES (2, 'Environmental Educator', 'intermediate');
 
-- Ana Torres (volunteer_id=3): Planter, has First Aid cert
INSERT INTO technical_volunteer (volunteer_id, specialty, certification_level)
VALUES (3, 'Field Medic', 'entry');
 
-- GENERAL VOLUNTEERS
-- Luis Mamani (volunteer_id=4): Logistics, no certifications
INSERT INTO general_volunteer (volunteer_id, availability_hours)
VALUES (4, 40);
 
-- Rosa Flores (volunteer_id=5): Planter, no certifications
INSERT INTO general_volunteer (volunteer_id, availability_hours)
VALUES (5, 24);
 
-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================
 
-- All volunteers with their subtype
SELECT
    v.name,
    v.dni,
    CASE
        WHEN tv.volunteer_id IS NOT NULL THEN 'Technical'
        WHEN gv.volunteer_id IS NOT NULL THEN 'General'
        ELSE 'UNASSIGNED — violates Total constraint'
    END AS subtype,
    tv.specialty,
    tv.certification_level,
    gv.availability_hours
FROM volunteer v
LEFT JOIN technical_volunteer tv ON v.volunteer_id = tv.volunteer_id
LEFT JOIN general_volunteer gv ON v.volunteer_id = gv.volunteer_id
ORDER BY v.name;
 
-- Verify disjoint: should return 0 rows (no volunteer in both subtypes)
SELECT v.name
FROM volunteer v
JOIN technical_volunteer tv ON v.volunteer_id = tv.volunteer_id
JOIN general_volunteer gv ON v.volunteer_id = gv.volunteer_id;
 