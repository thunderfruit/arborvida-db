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
