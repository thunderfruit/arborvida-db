# Phase 2 — Requirements Analysis Document

**Project:** Community Reforestation Management System
**Organization:** ArborVida Foundation (fictional)
**Author:** thunderfruit
**Date:** June 08, 2026
**Version:** 0.1.0

---

## 1. INTRODUCTION

### 1.1 Purpose of the Document
This document defines the complete requirements for the ArborVida
reforestation management database system. It establishes the
information quality standards, functional and non-functional
requirements, business rules, user access levels, and transaction
requirements that the system must satisfy. This document serves as
the contract between the design phase and the implementation phase.

### 1.2 Context and Background
ArborVida Foundation currently manages reforestation campaigns across
Latin America using Excel spreadsheets and paper records. Field teams
and office staff have no shared system, causing data redundancy,
inconsistency, and loss of historical analysis capability. This
requirements document defines what the replacement database system
must do to solve those problems, as identified in Phase 1.

---

## 2. INFORMATION QUALITIES

The following five qualities define what "good information" means
in the context of the ArborVida system.

| Quality | Application to ArborVida |
|---|---|
| **Precision** | Tree species must be identified by their scientific name (e.g., *Cedrela odorata*) rather than common names, which vary by region and cause ambiguity. The system enforces a single standardized species catalog. |
| **Opportunity** | Field coordinators must be able to register a planting event and query survival rates immediately — the system must provide access to current data without delays caused by manual data transfer from paper to spreadsheet. |
| **Completeness** | Each planting event record must include zone, date, species, quantities, and the responsible coordinator. Incomplete records prevent analysis of which species survive best in which zones and seasons. |
| **Significance** | Information presented to each user must be relevant to their role. A field coordinator does not need donor financial data; a data analyst does not need volunteer contact details. Each user sees only what supports their decisions. |
| **Integrity** | All stored values must be logically valid. Tree quantities must be positive integers. Survival rates must fall between 0 and 100. Monitoring dates cannot precede the planting event date. The DBMS enforces these rules automatically through constraints. |

---

## 3. FUNCTIONAL REQUIREMENTS

Functional requirements describe what the system must DO.
Format: "The system shall [action] [object] [condition]."

### 3.1 Organization Management
- FR01: The system shall allow the DBA to register foundation
  organizations with name, country, founding date, and website.
- FR02: The system shall allow the DBA to associate geographic
  zones to a specific organization.

### 3.2 Zone Management
- FR03: The system shall allow field coordinators to register
  geographic zones with name, region, area in hectares, and
  GPS coordinates.
- FR04: The system shall prevent deletion of a zone that has
  existing planting events associated with it.

### 3.3 Species Catalog
- FR05: The system shall maintain a catalog of tree species
  identified by scientific name, common name, native region,
  and growth rate.
- FR06: The system shall prevent duplicate entries for the
  same scientific name.

### 3.4 Planting Event Management
- FR07: The system shall allow field coordinators to register
  planting events with date, zone, weather conditions, and
  total tree count.
- FR08: The system shall allow field coordinators to associate
  one or more species with a planting event, recording the
  number of trees planted per species.

### 3.5 Volunteer Management
- FR09: The system shall allow field coordinators to register
  volunteers with DNI, name, email, and phone number.
- FR10: The system shall allow field coordinators to record
  volunteer participation in planting events, including their
  role and hours worked.
- FR11: The system shall prevent the same volunteer from being
  registered twice for the same event.

### 3.6 Survival Monitoring
- FR12: The system shall allow field coordinators to record
  monitoring entries per species per planting event, including
  monitoring date, survival rate percentage, and notes.
- FR13: The system shall prevent monitoring records for
  species that were not planted in the referenced event.

### 3.7 Reporting
- FR14: The system shall allow data analysts to query the
  average survival rate per species across all events.
- FR15: The system shall allow data analysts to query total
  trees planted per organization per year.
- FR16: The system shall allow data analysts to query
  volunteers by total hours contributed.

### 3.8 Administration
- FR17: The system shall allow the DBA to create, modify, and
  delete user accounts.
- FR18: The system shall allow the DBA to assign role-based
  permissions to users.
- FR19: The system shall allow the DBA to perform full and
  schema-only database backups using pg_dump.

---

## 4. NON-FUNCTIONAL REQUIREMENTS

Non-functional requirements describe how the system must PERFORM.

### 4.1 Performance
- NFR01: The system shall respond to standard SELECT queries
  on tables with fewer than 100,000 rows in under 2 seconds
  on the target hardware.
- NFR02: The system shall complete INSERT operations for a
  single planting event and its associated species in under
  1 second.

### 4.2 Security
- NFR03: The system shall require password authentication for
  all user connections (md5 or scram-sha-256 in pg_hba.conf).
- NFR04: The system shall enforce role-based access control —
  no user shall be able to perform operations outside their
  defined role permissions.
- NFR05: No user account shall use the PostgreSQL superuser
  role for day-to-day operations.

### 4.3 Availability
- NFR06: The system shall support at least 5 simultaneous
  user connections without performance degradation (academic
  scope).
- NFR07: A full database backup shall be executable without
  taking the system offline.

### 4.4 Integrity
- NFR08: The system shall enforce referential integrity on
  all foreign key relationships using PostgreSQL FK constraints.
- NFR09: The system shall reject any data that violates a
  defined CHECK constraint before committing the transaction.

### 4.5 Maintainability
- NFR10: All SQL scripts shall include comments explaining
  the purpose of each table and constraint.
- NFR11: The database schema and all scripts shall be
  version-controlled using Git and published on GitHub.

### 4.6 Academic Limitations
- NFR12: This version runs in a local two-tier configuration
  (pgAdmin client + local PostgreSQL server) and does not
  include network security, SSL, or connection pooling.

---

## 5. BUSINESS RULES / INTEGRITY RESTRICTIONS

| # | Business Rule | SQL Constraint |
|---|---|---|
| BR01 | A planting event must reference an existing zone | `FOREIGN KEY (zone_id) REFERENCES zone(zone_id) ON DELETE RESTRICT` |
| BR02 | A volunteer participation must reference an existing event and an existing volunteer | `FK on event_id` and `FK on volunteer_id` |
| BR03 | The number of trees planted per species must be a positive integer | `CHECK (trees_planted > 0)` and `INTEGER` data type |
| BR04 | Survival rate must be between 0 and 100 | `CHECK (survival_rate BETWEEN 0 AND 100)` |
| BR05 | A volunteer cannot register twice for the same event | `UNIQUE (event_id, volunteer_id)` in participation table |
| BR06 | A monitoring record can only reference a species that was actually planted in that event | `FOREIGN KEY (event_id, species_id) REFERENCES event_species(event_id, species_id)` — composite FK |
| BR07 | Hours worked by a volunteer must be a positive number | `CHECK (hours_worked > 0)` |
| BR08 | A species scientific name must be unique in the catalog | `UNIQUE (scientific_name)` in species table |

---

## 6. USER TYPES AND ACCESS LEVELS

| User Type | Can Do | Cannot Do |
|---|---|---|
| **DBA** | Everything — schema changes, user management, backups, all tables | — |
| **Field Coordinator** | Register volunteers, create events, record species per event, record monitoring data, view all operational data | Delete historical records, manage user accounts, view financial or donor data |
| **Data Analyst** | SELECT on all tables, run aggregate queries and reports | INSERT, UPDATE, or DELETE any record |
| **Organization Director** | View summary reports, view campaign effectiveness, view volunteer statistics | Modify records, manage user accounts, access technical schema or configuration |

### PostgreSQL Role Implementation
```sql
CREATE ROLE read_only_role;
GRANT SELECT ON ALL TABLES IN SCHEMA rfo TO read_only_role;

CREATE ROLE field_coordinator_role;
GRANT SELECT ON ALL TABLES IN SCHEMA rfo TO field_coordinator_role;
GRANT INSERT, UPDATE ON volunteer, planting_event,
    event_species, participation, monitoring
    TO field_coordinator_role;

GRANT read_only_role TO analyst_user;
GRANT field_coordinator_role TO coordinator_user;
```

---

## 7. CONCURRENCY AND TRANSACTION REQUIREMENTS

### 7.1 Operations That Must Be Atomic

| Operation | Why it must be atomic |
|---|---|
| Register a planting event with its species | If the event INSERT succeeds but one species INSERT fails, the database is left with a partial event that has no species — meaningless data |
| Record volunteer participation with hours | If the participation record saves but the hours do not, the record is incomplete and cannot be corrected without knowing what was intended |
| Delete a volunteer and all their participations | Should either complete fully or not at all — partial deletion leaves orphan records |

### 7.2 Concurrency Scenarios

**Scenario 1 — Duplicate volunteer registration**
Two field coordinators register the same volunteer for the same
event at exactly the same time. Without isolation, both INSERT
statements succeed and the volunteer appears twice in the
participation table.
*Solution:* Isolation + `UNIQUE(event_id, volunteer_id)` constraint.
The second INSERT is rejected with a unique violation error.

**Scenario 2 — Lost update on survival rate**
Two coordinators open the same monitoring record and each updates
the survival rate with a different value. The second write silently
overwrites the first.
*Solution:* Isolation level READ COMMITTED (PostgreSQL default)
ensures each transaction sees only committed data. Optimistic
locking at the application layer prevents silent overwrites.

**Scenario 3 — Zone deletion during event creation**
Coordinator A is creating a new planting event for Zone 5.
At the same moment, the DBA deletes Zone 5.
Without referential integrity, the event saves with a reference
to a non-existent zone.
*Solution:* Consistency + `ON DELETE RESTRICT` on the zone FK
prevents the zone from being deleted while events reference it.
The DBA receives an FK violation error.

### 7.3 ACID Summary for This System

| Property | How it protects ArborVida data |
|---|---|
| **Atomicity** | Partial event registrations are automatically rolled back on failure |
| **Consistency** | FK constraints, CHECK constraints, and UNIQUE constraints prevent invalid states |
| **Isolation** | Concurrent coordinators cannot corrupt each other's registrations |
| **Durability** | WAL ensures committed planting records survive a system crash |

---

## 8. DATA VOLUME ESTIMATES

| Table | Expected records (first year) | Growth rate |
|---|---|---|
| organization | 5–10 | Low — stable |
| zone | 20–50 | Low |
| species | 50–200 | Low — catalog grows slowly |
| volunteer | 100–500 | Medium |
| planting_event | 20–100 | Medium |
| event_species | 50–300 | Medium |
| participation | 200–1,000 | High |
| monitoring | 100–500 | High |
| volunteer_certification | 50–200 | Low |

These are academic estimates. A production system would require
capacity planning based on real campaign data from the foundation.
