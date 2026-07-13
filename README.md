# ArborVida Foundation — Community Reforestation Management System

A complete relational database design and implementation project for a
fictional environmental foundation managing reforestation campaigns across
Latin America.

Built following the complete database lifecycle across two units:
Unit 2 covered conceptual, logical, physical design and implementation.
Unit 3 adds normalization justification, relational algebra, relational
calculus, and extended queries.

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
- EVENT_SPECIES uses composite PK (event_id, species_id) enforcing that
  only planted species can be monitored (BR-06).
- All FKs on historical data use ON DELETE RESTRICT.
- Trigger trg_monitoring_date_valid enforces semantic integrity:
  monitoring_date cannot be earlier than event_date.
- All 11 tables are in 3NF (see docs/06_normalization.md).

---

## Project Structure

    arborvida-db/
    ├── docs/
    │   ├── 01_phase1_planning.md        Phase 1: Planning
    │   ├── 02_phase2_requirements.md    Phase 2: Requirements analysis
    │   ├── 03_phase3_conceptual.md      Phase 3: Conceptual design
    │   ├── 04_phase4_logical.md         Phase 4: Logical design (Navathe)
    │   ├── 05_phase5_physical.md        Phase 5: Physical design
    │   ├── 06_normalization.md          Unit 3: 3NF justification
    │   ├── 07_relational_algebra.md     Unit 3: Relational algebra
    │   └── 08_relational_calculus.md    Unit 3: Relational calculus (TRC)
    ├── diagrams/
    │   └── er_diagram.jpg               Crow's Foot ER diagram
    ├── sql/
    │   ├── 01_create_tables.sql         DDL: 11 tables + trigger
    │   ├── 02_insert_data.sql           Sample data
    │   ├── 03_verification_queries.sql  Queries: algebra, calculus, analytical
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

Step 4 - Run queries: run sql/03_verification_queries.sql

Step 5 - Create users and roles: run sql/04_users_permissions.sql

---

## Key Queries

**Total trees planted and survival rate per organization:**

    SET search_path TO rfo;
    SELECT o.name, SUM(es.trees_planted) AS total_trees,
           ROUND(AVG(m.survival_rate), 2) AS avg_survival
    FROM organization o
    JOIN zone z            ON o.org_id = z.org_id
    JOIN planting_event pe ON z.zone_id = pe.zone_id
    JOIN event_species es  ON pe.event_id = es.event_id
    LEFT JOIN monitoring m ON es.event_id = m.event_id
                          AND es.species_id = m.species_id
    GROUP BY o.org_id, o.name;

**Volunteers who have never participated (NOT EXISTS):**

    SELECT v.name FROM volunteer v
    WHERE NOT EXISTS (
        SELECT 1 FROM participation p
        WHERE p.volunteer_id = v.volunteer_id
    );

**Full report with survival status label:**

    SELECT pe.name AS event, s.common_name, m.survival_rate,
        CASE
            WHEN m.survival_rate IS NULL THEN 'Not monitored'
            WHEN m.survival_rate >= 90   THEN 'Excellent'
            WHEN m.survival_rate >= 80   THEN 'Good'
            WHEN m.survival_rate >= 70   THEN 'At risk'
            ELSE                              'Critical'
        END AS survival_status
    FROM planting_event pe
    JOIN event_species es  ON pe.event_id = es.event_id
    JOIN species s         ON es.species_id = s.species_id
    LEFT JOIN monitoring m ON es.event_id = m.event_id
                          AND es.species_id = m.species_id;

---

## Database Lifecycle Phases

| Phase | Description | Output |
|---|---|---|
| 1. Planning | Project scope, objectives, feasibility | docs/01_phase1_planning.md |
| 2. Requirements | Functional requirements, business rules | docs/02_phase2_requirements.md |
| 3. Conceptual Design | ER diagram in Crow's Foot notation | diagrams/er_diagram.jpg |
| 4. Logical Design | Relational schema via Navathe 7-step | docs/04_phase4_logical.md |
| 5. Physical Design | SQL DDL with data types and constraints | docs/05_phase5_physical.md |
| 6. Implementation | Data population and integrity verification | sql/02_insert_data.sql |
| 7. Maintenance | Users, permissions, backup | sql/04_users_permissions.sql |

## Unit 3 Additions

| Document | Description |
|---|---|
| docs/06_normalization.md | 3NF justification for all 11 tables |
| docs/07_relational_algebra.md | 9 algebra expressions with SQL equivalents |
| docs/08_relational_calculus.md | 7 TRC expressions with SQL equivalents |
| sql/03_verification_queries.sql | Extended queries: algebra, calculus, analytical, DML |

---

## Author

thunderfruit
