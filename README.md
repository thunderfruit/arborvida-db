# ArborVida Foundation — Community Reforestation Management System

A complete relational database design and implementation project for a
fictional environmental foundation managing reforestation campaigns across
Latin America.

Built following the complete database lifecycle: from problem statement
through conceptual design, logical mapping, physical implementation,
and database administration.

---

## Project Overview

**Problem:** ArborVida Foundation managed reforestation data using
disconnected spreadsheets and paper records, causing redundancy,
inconsistency, no historical analysis capability, and no concurrent
access control.

**Solution:** A normalized relational database system that centralizes
all reforestation data, enforces referential integrity, supports
multi-user access with role-based permissions, and enables analytical
reporting on campaign effectiveness.

---

## Tech Stack

| Tool | Version | Purpose |
|---|---|---|
| PostgreSQL | 16 | DBMS |
| pgAdmin | 4 | Database administration |
| StarUML | Full | ER diagram modeling |
| Git + GitHub | — | Version control |
| Fedora Linux | — | Development environment |

---

## Database Schema

**11 tables** organized across 4 dependency layers:

    Layer 1 (independent):        organization, species, volunteer
    Layer 2 (specialization):     technical_volunteer, general_volunteer
    Layer 3 (1:N FKs):            zone, planting_event
    Layer 4 (N:M + monitoring):   event_species, participation,
                                   monitoring, volunteer_certification

**Entity-Relationship Diagram:**

![ER Diagram](diagrams/er_diagram.jpg)

**Key design decisions:**

- VOLUNTEER specializes into TECHNICAL_VOLUNTEER and GENERAL_VOLUNTEER
  using Strategy B (subtype tables), with Total + Disjoint constraints.

- EVENT_SPECIES uses a composite PK (event_id, species_id) because
  MONITORING references it with a composite FK, enforcing that only
  planted species can be monitored.

- PARTICIPATION uses a surrogate PK to allow future tables to
  reference individual participation records cleanly.

- survival_rate and area_hectares use NUMERIC instead of FLOAT
  to avoid floating-point imprecision in field measurements.

- All FKs on historical data use ON DELETE RESTRICT to prevent
  accidental deletion of reforestation records.

- Trigger trg_monitoring_date_valid enforces semantic integrity:
  monitoring_date cannot be earlier than the planting event_date.

---

## Project Structure

    arborvida-db/
    ├── docs/
    │   ├── 01_phase1_planning.md        Phase 1: Planning
    │   ├── 02_phase2_requirements.md    Phase 2: Requirements analysis
    │   ├── 03_phase3_conceptual.md      Phase 3: Conceptual design
    │   ├── 04_phase4_logical.md         Phase 4: Logical design
    │   └── 05_phase5_physical.md        Phase 5: Physical design
    ├── diagrams/
    │   └── er_diagram.jpg               Crow's Foot ER diagram
    ├── sql/
    │   ├── 01_create_tables.sql         DDL — all 11 tables + trigger
    │   ├── 02_insert_data.sql           Sample data
    │   ├── 03_verification_queries.sql  Business queries + constraint tests
    │   ├── 04_users_permissions.sql     Roles and users
    │   └── 05_backup.sh                 Backup script
    └── backup/

---

## Setup Instructions

Requirements: PostgreSQL 16, pgAdmin 4

Step 1 - Create the database:
    CREATE DATABASE arborvida;

Step 2 - Connect to arborvida and run sql/01_create_tables.sql

Step 3 - Load sample data: run sql/02_insert_data.sql

Step 4 - Create users and roles: run sql/04_users_permissions.sql

Step 5 - Run verification queries: run sql/03_verification_queries.sql
    Section 1-2 should succeed.
    Section 3 tests should all fail (constraint enforcement).

---

## Sample Queries

Total trees planted per organization:

    SET search_path TO rfo;
    SELECT o.name, SUM(pe.total_trees) AS total_trees
    FROM organization o
    JOIN zone z ON o.org_id = z.org_id
    JOIN planting_event pe ON z.zone_id = pe.zone_id
    GROUP BY o.name
    ORDER BY total_trees DESC;

Average survival rate per species:

    SELECT s.common_name, ROUND(AVG(m.survival_rate), 2) AS avg_survival
    FROM species s
    JOIN monitoring m ON s.species_id = m.species_id
    GROUP BY s.common_name
    ORDER BY avg_survival DESC;

Volunteers with their subtype (specialization query):

    SELECT v.name,
           CASE
               WHEN tv.volunteer_id IS NOT NULL THEN 'Technical'
               WHEN gv.volunteer_id IS NOT NULL THEN 'General'
           END AS subtype,
           tv.specialty,
           tv.certification_level,
           gv.availability_hours
    FROM volunteer v
    LEFT JOIN technical_volunteer tv ON v.volunteer_id = tv.volunteer_id
    LEFT JOIN general_volunteer gv ON v.volunteer_id = gv.volunteer_id
    ORDER BY v.name;

---

## Database Lifecycle Phases

| Phase | Description | Output |
|---|---|---|
| 1. Planning | Project scope, objectives, feasibility | docs/01_phase1_planning.md |
| 2. Requirements | Functional/non-functional requirements, business rules | docs/02_phase2_requirements.md |
| 3. Conceptual Design | ER diagram in Crow's Foot notation | diagrams/er_diagram.jpg |
| 4. Logical Design | Relational schema via Navathe 7-step mapping | docs/04_phase4_logical.md |
| 5. Physical Design | SQL DDL with data types, constraints, trigger | docs/05_phase5_physical.md |
| 6. Implementation | Data population and integrity verification | sql/02_insert_data.sql |
| 7. Maintenance | Users, permissions, backup | sql/04_users_permissions.sql |

---

## Author

thunderfruit
