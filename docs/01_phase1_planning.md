# Phase 1 — Planning Document

## 1. PROJECT IDENTIFICATION

| Field | Value |
|---|---|
| **Title** | Community Reforestation Management System |
| **Organization / Client** | ArborVida Foundation (fictional) |
| **Author** | thunderfruit |
| **Course** | Base de Datos I — 2026-I |
| **Date** | June 08, 2026 |
| **Version** | 0.1.0 |
| **Repository** | https://github.com/thunderfruit/arborvida-db |

---

## 2. PROBLEM STATEMENT

### 2.1 Current Situation
ArborVida Foundation manages reforestation campaigns across multiple countries
in Latin America. The foundation coordinates geographic zones, tree species,
planting events, volunteers, and survival monitoring. Currently, all data is
managed using Excel spreadsheets and Google Sheets, with separate paper forms
for field records and volunteer registration. There is no connection between
office systems and field teams.

### 2.2 Specific Problems

| # | Problem | Description |
|---|---|---|
| 1 | **Data redundancy** | The same volunteer registers in multiple separate files for each campaign, causing duplicated records with inconsistent information |
| 2 | **Data inconsistency** | Tree species are identified only by common name without a standardized catalog, so the same species may appear under different names in different records |
| 3 | **Data dependency** | Changing the format of one spreadsheet requires manual updates across all related files |
| 4 | **No security** | Anyone with access to the shared drive can modify or delete any record with no audit trail |
| 5 | **No historical analysis** | There is no way to query survival rates by species, zone, or season, making it impossible to identify which species perform best in which climates |
| 6 | **Decentralized access** | Field teams record data on paper or photos that must be manually transferred to office spreadsheets, causing delays and transcription errors |
| 7 | **Concurrency problems** | When multiple coordinators update the same spreadsheet simultaneously, changes overwrite each other without warning |

### 2.3 Why a Relational DBMS is the Appropriate Solution
A relational database system solves all seven problems above:
it eliminates redundancy through normalization, enforces data integrity through
constraints and foreign keys, provides role-based security through GRANT/REVOKE,
enables historical queries through SQL, centralizes access for all teams through
a client-server architecture, and handles concurrent access through ACID
transaction management.

---

## 3. OBJECTIVES

### 3.1 General Objective
Design and implement a relational database system for the ArborVida Foundation
that centralizes reforestation data, enforces referential integrity, supports
multi-user concurrent access, and enables analytical reporting on campaign
effectiveness.

### 3.2 Specific Objectives
1. Model the complete domain using the Entity-Relationship methodology,
   producing a validated ER diagram with entities, attributes, relationships,
   cardinalities, and participation constraints.
2. Transform the conceptual model into a normalized relational schema using
   the Navathe 7-step mapping algorithm.
3. Implement the physical model in PostgreSQL 16 with complete DDL including
   appropriate data types, primary keys, foreign keys, check constraints,
   and ON DELETE / ON UPDATE actions.
4. Populate the database with representative test data covering all entities
   and verify that all integrity constraints behave correctly.
5. Implement basic database administration: user management, role-based
   permissions, and a backup procedure.

---

## 4. SCOPE

### 4.1 In Scope
- Organization management (foundation branches or partner organizations)
- Geographic zone registration with coordinates
- Tree species catalog with scientific names
- Planting event management
- Volunteer registration and event participation
- Survival monitoring by species per event
- Basic user management and role-based access control
- Database backup procedure

### 4.2 Out of Scope (this version)
- Mobile application or web interface
- Real-time GPS tracking
- Donor payment processing
- Multi-language interface
- Map visualization
- Automated alerts or notifications

### 4.3 Future Enhancements
- Mobile app for field data entry
- REST API for web dashboard integration
- Carbon offset calculation module
- Integration with national environmental registries

---

## 5. FEASIBILITY ASSESSMENT

### 5.1 Technical Feasibility
The required tools are available and open source: PostgreSQL 16, pgAdmin 4,
and StarUML run on Fedora Linux without cost. The author has completed
theoretical and practical training in relational database design through
the BDI course at UNT and can implement the system at an academic level.

### 5.2 Operational Feasibility
The system targets two primary user groups: field coordinators who register
events and monitoring data, and organization administrators who manage users
and generate reports. Both groups can be trained on a simple database
interface. The system replaces spreadsheets with minimal workflow change.

### 5.3 Academic Limitations
This implementation is an academic exercise. It will not include production
hardening such as SSL encryption, connection pooling, automated failover,
or load balancing. The system will run locally in a two-tier client-server
configuration (pgAdmin client connecting to a local PostgreSQL server)
rather than a distributed deployment.

---

## 6. RESOURCES NEEDED

| Category | Resource |
|---|---|
| **Hardware** | PC with Fedora Linux, 8GB RAM minimum, 20GB free disk |
| **DBMS** | PostgreSQL 16 |
| **Admin tool** | pgAdmin 4 |
| **Modeling tool** | StarUML (full version) |
| **Version control** | Git + GitHub |
| **Text editor** | VS Code or nano |
| **Knowledge** | Relational DB design, SQL DDL/DML, ER modeling, Git basics |

---

## 7. ESTIMATED TIMELINE

| Phase | Activity | Duration |
|---|---|---|
| 1 | Planning | Day 1 |
| 2 | Requirements analysis | Day 1 |
| 3 | Conceptual design — ER diagram in StarUML | Day 1–2 |
| 4 | Logical design — relational schema, Navathe mapping | Day 2 |
| 5 | Physical design — SQL DDL with data types | Day 2–3 |
| 6 | Implementation — PostgreSQL execution, data, testing | Day 3–4 |
| 7 | Maintenance setup + documentation + GitHub | Day 4 |

---

## 8. DELIVERABLES

| # | Artifact | Format | Location |
|---|---|---|---|
| 1 | Planning document | Markdown | `docs/01_phase1_planning.md` |
| 2 | Requirements document | Markdown | `docs/02_phase2_requirements.md` |
| 3 | ER diagram (Crow's Foot) | PNG image | `diagrams/er_diagram.png` |
| 4 | Relational schema | Markdown | `docs/04_phase4_logical.md` |
| 5 | DDL script | SQL | `sql/01_create_tables.sql` |
| 6 | Sample data script | SQL | `sql/02_insert_data.sql` |
| 7 | Verification queries | SQL | `sql/03_verification.sql` |
| 8 | Users and permissions script | SQL | `sql/04_users_permissions.sql` |
| 9 | Backup script | Bash | `sql/05_backup.sh` |
| 10 | README | Markdown | `README.md` |
