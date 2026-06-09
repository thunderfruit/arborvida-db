# Phase 4 — Logical Design

## Output
Complete relational schema derived from the ER diagram using the
Navathe 7-step mapping algorithm.

---

## Navathe 7-Step Mapping

### Step 1 — Strong Entities
One table per strong entity. All simple attributes become columns.

    ORGANIZATION(org_id PK, name, country, founded_date, website)

    ZONE(zone_id PK, name, region, area_hectares, latitude, longitude)

    PLANTING_EVENT(event_id PK, event_date, name, weather_conditions, total_trees)

    VOLUNTEER(volunteer_id PK, dni, name, email, phone, join_date)

    SPECIES(species_id PK, scientific_name, common_name, native_region, growth_rate)

    MONITORING(monitoring_id PK, monitoring_date, survival_rate, notes)

### Step 2 — Weak Entities
None in this system.

### Step 3 — Binary 1:1 Relationships
None in this system.

### Step 4 — Binary 1:N Relationships
Add the PK of the "1" side as FK in the "N" side table.

    ZONE adds:
      org_id FK -> ORGANIZATION(org_id)
      One organization manages many zones.

    PLANTING_EVENT adds:
      zone_id FK -> ZONE(zone_id)
      One zone hosts many planting events.

    MONITORING adds:
      (event_id, species_id) composite FK -> EVENT_SPECIES(event_id, species_id)
      One event_species combination is tracked by many monitoring records.

### Step 5 — Binary N:M Relationships
Create intermediate table with FK from each participating entity.

    EVENT_SPECIES(
      event_id   FK -> PLANTING_EVENT(event_id),
      species_id FK -> SPECIES(species_id),
      trees_planted,
      PK(event_id, species_id)
    )
    Resolves N:M between PLANTING_EVENT and SPECIES.
    Business rule: composite PK prevents the same species from being
    registered twice in the same event.

    PARTICIPATION(
      participation_id PK,
      event_id   FK -> PLANTING_EVENT(event_id),
      volunteer_id FK -> VOLUNTEER(volunteer_id),
      role,
      hours_worked,
      UNIQUE(event_id, volunteer_id)
    )
    Resolves N:M between PLANTING_EVENT and VOLUNTEER.
    Surrogate PK used to allow future tables to reference participation records.
    UNIQUE constraint enforces one registration per volunteer per event.

### Step 6 — Multivalued Attributes
Create separate table with FK to the owning entity.

    VOLUNTEER_CERTIFICATION(
      volunteer_id FK -> VOLUNTEER(volunteer_id),
      certification,
      year_obtained,
      PK(volunteer_id, certification)
    )
    Resolves multivalued attribute: a volunteer can hold multiple certifications.
    Composite PK prevents duplicate certifications per volunteer.

### Step 7 — N-ary Relationships
None in this system.

---

## Complete Relational Schema

    ORGANIZATION(org_id PK, name, country, founded_date, website)

    ZONE(zone_id PK, name, region, area_hectares, latitude, longitude,
         org_id FK -> ORGANIZATION)

    SPECIES(species_id PK, scientific_name, common_name, native_region, growth_rate)

    PLANTING_EVENT(event_id PK, event_date, name, weather_conditions, total_trees,
                   zone_id FK -> ZONE)

    VOLUNTEER(volunteer_id PK, dni, name, email, phone, join_date)

    EVENT_SPECIES(event_id FK -> PLANTING_EVENT, species_id FK -> SPECIES,
                  trees_planted, PK(event_id, species_id))

    PARTICIPATION(participation_id PK, event_id FK -> PLANTING_EVENT,
                  volunteer_id FK -> VOLUNTEER, role, hours_worked,
                  UNIQUE(event_id, volunteer_id))

    MONITORING(monitoring_id PK, monitoring_date, survival_rate, notes,
               event_id FK -> EVENT_SPECIES, species_id FK -> EVENT_SPECIES)

    VOLUNTEER_CERTIFICATION(volunteer_id FK -> VOLUNTEER, certification,
                            year_obtained, PK(volunteer_id, certification))

Total: 9 tables

---

## Design Decisions

1. EVENT_SPECIES uses composite PK (event_id, species_id) because
   MONITORING references it with a composite FK. A surrogate PK would
   not enforce the constraint that only planted species can be monitored.

2. PARTICIPATION uses surrogate PK (participation_id) to allow future
   tables to reference individual participation records cleanly.

3. MONITORING uses a composite FK (event_id, species_id) referencing
   EVENT_SPECIES to enforce business rule BR06: monitoring can only
   target species that were actually planted in a given event.

4. VOLUNTEER_CERTIFICATION uses composite PK (volunteer_id, certification)
   to prevent a volunteer from holding duplicate certification records.

5. total_trees in PLANTING_EVENT is valid denormalization.
   Field coordinators record the total count first; species breakdown
   is added separately via EVENT_SPECIES. See Phase 3 design decisions.
