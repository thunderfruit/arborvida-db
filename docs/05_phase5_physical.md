# Phase 5 — Physical Design

## Output
Complete SQL DDL with data types, constraints, and referential actions.
All tables implemented in PostgreSQL 16, schema `rfo`.

---

## Physical Schema — All Tables with Data Types

### ORGANIZATION
```
organization(
    org_id       SERIAL PRIMARY KEY,
    name         VARCHAR(200) NOT NULL UNIQUE,
    country      VARCHAR(100) NOT NULL,
    founded_date DATE,
    website      VARCHAR(300)
)
```

### ZONE
```
zone(
    zone_id       SERIAL PRIMARY KEY,
    org_id        INTEGER NOT NULL FK → organization ON DELETE RESTRICT,
    name          VARCHAR(200) NOT NULL,
    region        VARCHAR(200) NOT NULL,
    area_hectares NUMERIC(10,2) CHECK > 0,
    latitude      NUMERIC(9,6) CHECK BETWEEN -90 AND 90,
    longitude     NUMERIC(9,6) CHECK BETWEEN -180 AND 180
)
```

### SPECIES
```
species(
    species_id      SERIAL PRIMARY KEY,
    scientific_name VARCHAR(200) NOT NULL UNIQUE,
    common_name     VARCHAR(200) NOT NULL,
    native_region   VARCHAR(200),
    growth_rate     VARCHAR(10) CHECK IN ('slow','medium','fast')
)
```

### VOLUNTEER (Supertype)
```
volunteer(
    volunteer_id SERIAL PRIMARY KEY,
    dni          CHAR(8) NOT NULL UNIQUE CHECK regex [0-9]{8},
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(200) UNIQUE,
    phone        VARCHAR(20),
    join_date    DATE NOT NULL DEFAULT CURRENT_DATE
)
```

### TECHNICAL_VOLUNTEER (Subtype — Strategy B)
```
technical_volunteer(
    volunteer_id       INTEGER PRIMARY KEY FK → volunteer ON DELETE CASCADE,
    specialty          VARCHAR(100) NOT NULL,
    certification_level VARCHAR(20) NOT NULL CHECK IN ('entry','intermediate','expert')
)
```

### GENERAL_VOLUNTEER (Subtype — Strategy B)
```
general_volunteer(
    volunteer_id      INTEGER PRIMARY KEY FK → volunteer ON DELETE CASCADE,
    availability_hours INTEGER NOT NULL CHECK > 0 AND <= 744
)
```

### PLANTING_EVENT
```
planting_event(
    event_id           SERIAL PRIMARY KEY,
    zone_id            INTEGER NOT NULL FK → zone ON DELETE RESTRICT,
    event_date         DATE NOT NULL CHECK <= CURRENT_DATE,
    name               VARCHAR(200),
    weather_conditions VARCHAR(100),
    total_trees        INTEGER NOT NULL CHECK > 0
)
```

### EVENT_SPECIES
```
event_species(
    event_id      INTEGER NOT NULL FK → planting_event ON DELETE RESTRICT,
    species_id    INTEGER NOT NULL FK → species ON DELETE RESTRICT,
    trees_planted INTEGER NOT NULL CHECK > 0,
    PK(event_id, species_id)
)
```

### PARTICIPATION
```
participation(
    participation_id SERIAL PRIMARY KEY,
    event_id         INTEGER NOT NULL FK → planting_event ON DELETE RESTRICT,
    volunteer_id     INTEGER NOT NULL FK → volunteer ON DELETE RESTRICT,
    role             VARCHAR(100),
    hours_worked     NUMERIC(5,2) CHECK > 0,
    UNIQUE(event_id, volunteer_id)
)
```

### MONITORING
```
monitoring(
    monitoring_id   SERIAL PRIMARY KEY,
    event_id        INTEGER NOT NULL,
    species_id      INTEGER NOT NULL,
    monitoring_date DATE NOT NULL,
    survival_rate   NUMERIC(5,2) NOT NULL CHECK BETWEEN 0 AND 100,
    notes           TEXT,
    FK(event_id, species_id) → event_species ON DELETE RESTRICT,
    CHECK: survival_rate >= 80 OR notes IS NOT NULL
)
```

### VOLUNTEER_CERTIFICATION
```
volunteer_certification(
    volunteer_id   INTEGER NOT NULL FK → volunteer ON DELETE CASCADE,
    certification  VARCHAR(200) NOT NULL,
    year_obtained  INTEGER CHECK BETWEEN 2000 AND 2030,
    PK(volunteer_id, certification)
)
```

---

## Data Type Justifications

| Column | Type | Reason |
|---|---|---|
| All PKs | SERIAL | Auto-increment integer — no manual ID management |
| dni | CHAR(8) | Fixed 8-character Peruvian national ID |
| survival_rate | NUMERIC(5,2) | Exact decimal — avoids FLOAT imprecision (e.g. 87.50000001) |
| area_hectares | NUMERIC(10,2) | Exact decimal — geographic measurement requires precision |
| latitude/longitude | NUMERIC(9,6) | 6 decimal places = ~0.1m precision |
| growth_rate | VARCHAR(10) | Controlled vocabulary enforced by CHECK IN |
| certification_level | VARCHAR(20) | Controlled vocabulary: entry/intermediate/expert |
| availability_hours | INTEGER | Whole hours only — no fractional hours needed |
| notes | TEXT | Unlimited length — field observations have no predictable max |
| event_date, join_date | DATE | Date only — no time component needed |

---

## Specialization Design Decision

**Strategy B** (Subtype tables) was chosen for the VOLUNTEER specialization because:

1. The VOLUNTEER table already has data and relationships — Strategy A (single table)
   would require adding nullable columns to existing records.
2. The specialization is Total + Disjoint — every volunteer is either technical
   or general, and cannot be both. Strategy B enforces this at the database level.
3. Subtype-specific queries are clean and don't require filtering by a discriminator column.

**Limitation:** The database does not automatically enforce the Total constraint
(that every volunteer must appear in one subtype). This is enforced by application
logic and data insertion procedures.

---

## Trigger

**trg_monitoring_date_valid** (BEFORE INSERT OR UPDATE on monitoring)

Enforces semantic integrity: `monitoring_date` cannot be earlier than the
`event_date` of the planting event being monitored. This rule cannot be
expressed with a CHECK constraint because it requires accessing a different table
(planting_event) to retrieve the event_date.

---

## Referential Actions Summary

| FK | ON DELETE | ON UPDATE | Reason |
|---|---|---|---|
| zone.org_id | RESTRICT | CASCADE | Cannot delete org with active zones |
| planting_event.zone_id | RESTRICT | CASCADE | Cannot delete zone with event history |
| event_species.event_id | RESTRICT | CASCADE | Cannot delete event with species records |
| event_species.species_id | RESTRICT | CASCADE | Cannot delete species with planting records |
| participation.event_id | RESTRICT | CASCADE | Cannot delete event with participation records |
| participation.volunteer_id | RESTRICT | CASCADE | Cannot delete volunteer with participation history |
| monitoring FK | RESTRICT | CASCADE | Cannot delete planting record with monitoring data |
| volunteer_certification.volunteer_id | CASCADE | CASCADE | Certifications belong to their volunteer |
| technical_volunteer.volunteer_id | CASCADE | CASCADE | Subtype record belongs to its volunteer |
| general_volunteer.volunteer_id | CASCADE | CASCADE | Subtype record belongs to its volunteer |
