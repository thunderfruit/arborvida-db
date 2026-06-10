# Phase 3 — Conceptual Design

## Output
ER diagram in Crow's Foot notation (see `diagrams/er_diagram.png`)

## Entities (6 strong entities)

- ORGANIZATION — foundation branches or partner organizations
- ZONE — geographic areas for planting campaigns
- SPECIES — tree species catalog with scientific names
- PLANTING_EVENT — individual planting campaign instances
- VOLUNTEER — people who participate in events
- MONITORING — survival rate checks after planting

## Intermediate tables (N:M resolutions)
- EVENT_SPECIES — resolves PLANTING_EVENT ↔ SPECIES
- PARTICIPATION — resolves PLANTING_EVENT ↔ VOLUNTEER

## Multivalued attribute
- VOLUNTEER_CERTIFICATION — certifications held by volunteers

## Relationships
| Relationship | Cardinality | Label |
|---|---|---|
| ORGANIZATION → ZONE | 1:N | manages |
| ZONE → PLANTING_EVENT | 1:N | hosts |
| PLANTING_EVENT → EVENT_SPECIES | 1:N | includes |
| EVENT_SPECIES → SPECIES | N:1 | contains |
| PLANTING_EVENT → PARTICIPATION | 1:N | joins |
| PARTICIPATION → VOLUNTEER | N:1 | participates_in |
| EVENT_SPECIES → MONITORING | 1:N | tracks |
| VOLUNTEER → VOLUNTEER_CERTIFICATION | 1:N | obtain |

## Design Decisions
- `total_trees` in PLANTING_EVENT is kept as valid denormalization.
  Field coordinators record the total count first; species breakdown
  is added separately via EVENT_SPECIES.
- MONITORING references EVENT_SPECIES (not PLANTING_EVENT directly)
  to enforce the constraint that only planted species can be monitored.
- VOLUNTEER_CERTIFICATION uses a composite PK (volunteer_id,
  certification) to prevent duplicate certifications per volunteer.
# Phase 3 — Conceptual Design (Updated)

## Update Note
This document was updated after the original Phase 3 to incorporate
the generalization/specialization relationship identified during
the Phase 4 logical design review.

---

## Original content remains unchanged above this section.

---

## Addition: Generalization / Specialization

During Phase 4 mapping, a generalization/specialization relationship
was identified in the VOLUNTEER entity. ArborVida Foundation has two
distinct categories of volunteers with different data requirements.

### Supertype
VOLUNTEER — stores all shared attributes applicable to every volunteer.

### Subtypes
TECHNICAL_VOLUNTEER — volunteers with formal technical qualifications:
- specialty: area of technical expertise (Botanist, Field Coordinator, etc.)
- certification_level: entry / intermediate / expert

GENERAL_VOLUNTEER — volunteers without formal technical qualifications:
- availability_hours: monthly availability in hours

### Constraints
- **Total:** every volunteer must belong to exactly one subtype
- **Disjoint:** a volunteer cannot belong to both subtypes simultaneously

### Notation in diagram
StarUML ER notation does not include a native generalization arrow.
The relationship is represented using dashed lines with the label
"inheritance Total, Disjoint" connecting VOLUNTEER to each subtype.

### Updated entity count
Original diagram: 8 entities (organization, zone, species,
planting_event, volunteer, participation, event_species, monitoring)
+ 1 multivalued attribute table (volunteer_certification)

Updated diagram: adds 2 subtype entities (technical_volunteer,
general_volunteer) → total 11 tables in the physical model.
