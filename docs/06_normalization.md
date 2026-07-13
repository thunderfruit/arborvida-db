# Normalization Analysis
## ArborVida Foundation — Justification of 3NF Compliance

---

## Theoretical Background

### Functional Dependency Notation

    A -> B  reads as: "A functionally determines B"
    Meaning: for every value of A there is exactly one value of B.

### Normal Forms

**1NF (First Normal Form)**
Every attribute contains only atomic (indivisible) values.
No repeating groups or multi-valued attributes in a single column.

**2NF (Second Normal Form)**
The table is in 1NF AND every non-key attribute is fully functionally
dependent on the entire primary key.
Partial dependency: a non-key attribute depends on only PART of a
composite primary key.
Tables with a single-column primary key are automatically in 2NF —
partial dependencies are impossible when there is nothing to be
partial about.

**3NF (Third Normal Form)**
The table is in 2NF AND no non-key attribute is transitively dependent
on the primary key.
Transitive dependency: PK -> A -> B, where A is a non-key attribute.
In 3NF every non-key attribute must depend directly on the primary key,
not through another non-key attribute.

---

## Table-by-Table Analysis

---

### 1. ORGANIZATION

    organization(org_id PK, name, country, founded_date, website)

**1NF:** Every attribute contains a single atomic value.
org_id: integer. name: single string. country: single string.
founded_date: single date. website: single URL string.

**2NF:** Primary key is single column (org_id).
Partial dependencies are impossible with a single-column primary key.

**3NF:** Functional dependencies:
    org_id -> name
    org_id -> country
    org_id -> founded_date
    org_id -> website

Does name -> country? No. Two organizations can share the same name
in different countries (e.g. ArborVida Peru, ArborVida Bolivia).
Does country -> founded_date? No. Country is a geographic label,
not a determinant of when the organization was founded.
Does website -> name? Not enforced. website is just a URL string,
not a canonical identifier in this schema.

Every non-key attribute depends directly on org_id. No transitive
chain exists.

**Conclusion: ORGANIZATION is in 3NF.**

---

### 2. ZONE

    zone(zone_id PK, org_id FK, name, region, area_hectares,
         latitude, longitude)

**1NF:** All attributes are single atomic values.
GPS coordinates are stored as two separate NUMERIC columns
(latitude, longitude), not as a combined string.

**2NF:** Primary key is single column (zone_id). Automatic.

**3NF:** Functional dependencies:
    zone_id -> org_id
    zone_id -> name
    zone_id -> region
    zone_id -> area_hectares
    zone_id -> latitude
    zone_id -> longitude

Potential transitive chain 1: zone_id -> org_id -> region?
Does org_id determine region? No. ArborVida Peru manages zones in
Loreto, Ucayali, and Madre de Dios — three different regions.
One organization manages multiple regions. org_id does NOT determine
region.

Potential transitive chain 2: zone_id -> (latitude, longitude) -> name?
Does (latitude, longitude) determine name? No. Zone names are
administratively assigned labels, not derived from GPS coordinates.
Additionally, (latitude, longitude) is not defined as a UNIQUE
constraint in this schema.

Every non-key attribute depends directly on zone_id.

**Conclusion: ZONE is in 3NF.**

---

### 3. SPECIES

    species(species_id PK, scientific_name, common_name,
            native_region, growth_rate)

**1NF:** All attributes are single atomic values.

**2NF:** Primary key is single column (species_id). Automatic.

**3NF:** Functional dependencies:
    species_id -> scientific_name
    species_id -> common_name
    species_id -> native_region
    species_id -> growth_rate

Does scientific_name -> common_name? In botanical taxonomy a
scientific name could theoretically determine a common name.
However in this schema common_name is treated as a display label
stored per species record, not derived from scientific_name.
Common names vary by country and language.

Does native_region -> growth_rate? No. Multiple species with
different growth rates share the same native region
(e.g. Cedro slow and Balsa fast are both from Amazonia).

Every non-key attribute depends directly on species_id.

**Conclusion: SPECIES is in 3NF.**

---

### 4. VOLUNTEER (Supertype)

    volunteer(volunteer_id PK, dni, name, email, phone, join_date)

**1NF:** All attributes are single atomic values.
phone stores one phone number per record. If multiple phones were
needed a separate table would be required. In this schema one phone
per volunteer is the defined business rule.

**2NF:** Primary key is single column (volunteer_id). Automatic.

**3NF:** Functional dependencies:
    volunteer_id -> dni
    volunteer_id -> name
    volunteer_id -> email
    volunteer_id -> phone
    volunteer_id -> join_date

Does dni -> name? No. Two volunteers could share the same name but
have different DNIs (common in Peru).
Does email -> name? No. Email is a contact attribute, not a
canonical identifier of personal identity in this schema.
Does name -> join_date? No. Join date is independent of name.

Note on dni: dni has a UNIQUE constraint making it a candidate key.
A candidate key determining other attributes is not a 3NF violation.
Only non-key attributes determining other non-key attributes
would be a violation.

Every non-key attribute depends directly on volunteer_id.

**Conclusion: VOLUNTEER is in 3NF.**

---

### 5. TECHNICAL_VOLUNTEER (Subtype — Strategy B)

    technical_volunteer(volunteer_id PK FK, specialty,
                        certification_level)

**1NF:** All attributes are single atomic values.

**2NF:** Primary key is single column (volunteer_id). Automatic.

**3NF:** Functional dependencies:
    volunteer_id -> specialty
    volunteer_id -> certification_level

Does specialty -> certification_level? No. Two botanists could have
different certification levels (one entry, one expert). Specialty
and level are independent attributes of the technical volunteer.

**Conclusion: TECHNICAL_VOLUNTEER is in 3NF.**

---

### 6. GENERAL_VOLUNTEER (Subtype — Strategy B)

    general_volunteer(volunteer_id PK FK, availability_hours)

**1NF:** Single atomic value per attribute.
**2NF:** Single-column primary key. Automatic.
**3NF:** Only one non-key attribute. Transitive dependencies require
at least two non-key attributes forming a chain. Impossible here.

**Conclusion: GENERAL_VOLUNTEER is trivially in 3NF.**

---

### 7. PLANTING_EVENT

    planting_event(event_id PK, zone_id FK, event_date, name,
                   weather_conditions, total_trees)

**1NF:** All attributes are single atomic values.

**2NF:** Primary key is single column (event_id). Automatic.

**3NF:** Functional dependencies:
    event_id -> zone_id
    event_id -> event_date
    event_id -> name
    event_id -> weather_conditions
    event_id -> total_trees

Potential chain: event_id -> zone_id -> name?
Does zone_id determine event name? No. Event names are assigned
independently of their zone (e.g. "Dia de la Tierra 2026" is a
campaign name, not derived from zone identity).

Potential chain: event_id -> event_date -> weather_conditions?
Does event_date determine weather? No. Different dates in the same
region can have different weather, and the same date in different
zones will have different weather.

Note on total_trees: this is valid denormalization. The total tree
count is recorded by field coordinators at event time before the
species breakdown is entered via event_species. It is a direct
property of the event, not derivable from other non-key attributes
without aggregating event_species. It does not create a transitive
dependency.

Every non-key attribute depends directly on event_id.

**Conclusion: PLANTING_EVENT is in 3NF.**

---

### 8. EVENT_SPECIES

    event_species(event_id FK, species_id FK, trees_planted)
    PK: (event_id, species_id)

**1NF:** All attributes are single atomic values.

**2NF:** Composite primary key: (event_id, species_id).
Partial dependency check:

Does event_id alone -> trees_planted? No. One event plants multiple
species with different tree counts. Knowing only the event does not
determine how many trees of a specific species were planted.

Does species_id alone -> trees_planted? No. The same species appears
in multiple events with different tree counts.

Only the full composite key determines trees_planted. No partial
dependency exists.

**3NF:** Only one non-key attribute (trees_planted).
Transitive dependencies require at least two non-key attributes.
Impossible here.

**Conclusion: EVENT_SPECIES is in 2NF and 3NF.**

---

### 9. PARTICIPATION

    participation(participation_id PK, event_id FK, volunteer_id FK,
                  role, hours_worked)
    UNIQUE(event_id, volunteer_id)

**1NF:** All attributes are single atomic values.

**2NF:** Primary key is single column (participation_id). Automatic.

**3NF:** Functional dependencies:
    participation_id -> event_id
    participation_id -> volunteer_id
    participation_id -> role
    participation_id -> hours_worked

Does role -> hours_worked? No. Two Team Leaders in different events
can work different hours. Role is a label, not a determinant of
work duration.

Does volunteer_id -> role? No. The same volunteer appears as
Team Leader in one event and Planter in another. Role is specific
to each participation record, not to the volunteer globally.

Every non-key attribute depends directly on participation_id.

**Conclusion: PARTICIPATION is in 3NF.**

---

### 10. MONITORING

    monitoring(monitoring_id PK, event_id FK, species_id FK,
               monitoring_date, survival_rate, notes)
    FK: (event_id, species_id) -> event_species

**1NF:** All attributes are single atomic values. notes is TEXT
containing a single observation string per record.

**2NF:** Primary key is single column (monitoring_id). Automatic.

**3NF:** Functional dependencies:
    monitoring_id -> event_id
    monitoring_id -> species_id
    monitoring_id -> monitoring_date
    monitoring_id -> survival_rate
    monitoring_id -> notes

Does survival_rate -> notes? Not functionally. Low survival rates
require notes (enforced by CHECK constraint) but the constraint
does not make survival_rate a functional determinant of notes
content. Notes are written independently by field observers.

Does monitoring_date -> survival_rate? No. The same date can yield
different survival rates in different zones or for different species.
Date is a temporal marker, not a determinant of biological outcome.

Every non-key attribute depends directly on monitoring_id.

**Conclusion: MONITORING is in 3NF.**

---

### 11. VOLUNTEER_CERTIFICATION

    volunteer_certification(volunteer_id FK, certification,
                            year_obtained)
    PK: (volunteer_id, certification)

**1NF:** All attributes are single atomic values.

**2NF:** Composite primary key: (volunteer_id, certification).
Partial dependency check:

Does volunteer_id alone -> year_obtained? No. The same volunteer
obtains different certifications in different years.

Does certification alone -> year_obtained? No. Different volunteers
obtain the same certification in different years.

Only the full composite key determines year_obtained. No partial
dependency exists.

**3NF:** Only one non-key attribute (year_obtained).
Transitive dependencies are impossible.

**Conclusion: VOLUNTEER_CERTIFICATION is in 2NF and 3NF.**

---

## Summary

| Table | 1NF | 2NF | 3NF | Key observation |
|---|---|---|---|---|
| organization | Yes | Yes | Yes | No non-key determines another |
| zone | Yes | Yes | Yes | org_id does not determine region |
| species | Yes | Yes | Yes | scientific_name not canonical FK |
| volunteer | Yes | Yes | Yes | dni is candidate key, not a violation |
| technical_volunteer | Yes | Yes | Yes | specialty independent of cert level |
| general_volunteer | Yes | Yes | Yes | Single non-key attribute |
| planting_event | Yes | Yes | Yes | total_trees is valid denormalization |
| event_species | Yes | Yes | Yes | trees_planted needs full composite PK |
| participation | Yes | Yes | Yes | role does not determine hours_worked |
| monitoring | Yes | Yes | Yes | survival_rate does not determine notes |
| volunteer_certification | Yes | Yes | Yes | year_obtained needs full composite PK |

**All 11 tables satisfy 1NF, 2NF, and 3NF.**

The Navathe 7-step mapping algorithm produces relations in at least
3NF when the original ER diagram is correctly designed. Each entity
maps to a table with its primary key, and relationship tables receive
composite primary keys formed from the foreign keys of participating
entities, ensuring no non-key attribute depends on a subset of the key.
