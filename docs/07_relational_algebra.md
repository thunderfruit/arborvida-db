# Relational Algebra
## ArborVida Foundation

---

## Notation Reference

| Symbol | Operation | SQL equivalent |
|---|---|---|
| s_condition(R) | Selection — filter rows | WHERE |
| p_attrs(R) | Projection — choose columns | SELECT DISTINCT |
| R U S | Union — combine rows | UNION |
| R - S | Difference — in R but not S | EXCEPT |
| R x S | Cartesian product | CROSS JOIN |
| R JOIN S | Natural join — join on common attrs | JOIN ... ON |
| R JOIN_c S | Condition join | JOIN ... ON condition |
| rename_name(R) | Rename relation | AS alias |

Note: formal symbols used in document below:
    sigma  = selection
    pi     = projection
    bowtie = natural join
    rho    = rename

**Reading rule:** always evaluate from the innermost parentheses outward.

---

## Expression 1 — Names of all volunteers

**Query:** Get the name of every volunteer in the system.

**Algebra:**
```
pi_name(volunteer)
```

**Step by step:**
1. Take the volunteer relation
2. Project (keep) only the name attribute

**SQL equivalent:**
```sql
SET search_path TO rfo;
SELECT DISTINCT name FROM volunteer;
```

---

## Expression 2 — Fast-growing species

**Query:** Get all data for species with growth_rate = 'fast'.

**Algebra:**
```
sigma_growth_rate='fast'(species)
```

**Step by step:**
1. Apply selection to species
2. Keep only rows where growth_rate equals 'fast'

**SQL equivalent:**
```sql
SELECT * FROM species
WHERE growth_rate = 'fast';
```

---

## Expression 3 — Volunteers who participated in at least one event

**Query:** Get the name of every volunteer who has at least one
participation record.

**Algebra:**
```
pi_name(volunteer BOWTIE participation)
```

**Step by step:**
1. volunteer BOWTIE participation: natural join on volunteer_id.
   Only volunteers with a matching row in participation are returned.
   Volunteers with zero events are automatically excluded.
2. pi_name: project only the name column.

**Why join works as a filter here:**
The natural join discards any volunteer row that has no matching
participation row. The result contains only volunteers who
participated in at least one event — no explicit count needed.

**SQL equivalent:**
```sql
SELECT DISTINCT v.name
FROM volunteer v
JOIN participation p ON v.volunteer_id = p.volunteer_id;
```

---

## Expression 4 — Volunteers who have NEVER participated

**Query:** Find volunteers with zero participation records.

**Algebra:**
```
pi_name(volunteer) - pi_name(volunteer BOWTIE participation)
```

**Step by step:**
1. pi_name(volunteer): all volunteer names (complete set)
2. pi_name(volunteer BOWTIE participation): names of volunteers
   who have participated (subset)
3. Difference (-): names in set 1 but not in set 2 =
   volunteers who never participated

**Key rule:** you cannot filter on data from another table directly.
You must join first to bring the data together, then subtract.

**SQL equivalent:**
```sql
SELECT name FROM volunteer
EXCEPT
SELECT DISTINCT v.name
FROM volunteer v
JOIN participation p ON v.volunteer_id = p.volunteer_id;
```

---

## Expression 5 — Names of Team Leaders

**Query:** Get the name of volunteers who served as Team Leader
in at least one event.

**Algebra:**
```
pi_name(volunteer BOWTIE sigma_role='Team Leader'(participation))
```

**Step by step:**
1. sigma_role='Team Leader'(participation): filter participation
   to keep only Team Leader records
2. volunteer BOWTIE ...: join with volunteer on volunteer_id
3. pi_name: project only the name

**Note on operation order:**
Applying selection BEFORE the join is more efficient. It reduces
the size of the participation set before joining. The result is
identical either way:

Alternative (less efficient):
```
pi_name(sigma_role='Team Leader'(volunteer BOWTIE participation))
```

**SQL equivalent:**
```sql
SELECT DISTINCT v.name
FROM volunteer v
JOIN participation p ON v.volunteer_id = p.volunteer_id
WHERE p.role = 'Team Leader';
```

---

## Expression 6 — Species planted in event number 1

**Query:** Get scientific_name and common_name of all species
planted in event number 1.

**Algebra:**
```
pi_scientific_name,common_name(
    species BOWTIE sigma_event_id=1(event_species)
)
```

**Step by step:**
1. sigma_event_id=1(event_species): filter event_species to
   keep only rows for event 1
2. species BOWTIE ...: join with species on species_id
3. pi_scientific_name,common_name: project the two name columns

**SQL equivalent:**
```sql
SELECT DISTINCT s.scientific_name, s.common_name
FROM species s
JOIN event_species es ON s.species_id = es.species_id
WHERE es.event_id = 1;
```

---

## Expression 7 — Zones managed by ArborVida Peru

**Query:** Get the name and region of all zones managed by
the organization named 'ArborVida Peru'.

**Algebra:**
```
pi_zone.name,region(
    zone BOWTIE sigma_name='ArborVida Peru'(organization)
)
```

**Note on attribute conflict:**
Both zone and organization have a column called 'name'.
Using rename to clarify:

```
pi_z.name,z.region(
    rho_z(zone) BOWTIE sigma_o.name='ArborVida Peru'(rho_o(organization))
)
```

**SQL equivalent:**
```sql
SELECT z.name, z.region
FROM zone z
JOIN organization o ON z.org_id = o.org_id
WHERE o.name = 'ArborVida Peru';
```

---

## Expression 8 — Monitoring records with critical survival rate

**Query:** Get monitoring_date, survival_rate, and notes for
all monitoring records where survival_rate is below 85.

**Algebra:**
```
pi_monitoring_date,survival_rate,notes(
    sigma_survival_rate<85(monitoring)
)
```

**Step by step:**
1. sigma_survival_rate<85(monitoring): filter monitoring rows
2. pi_monitoring_date,survival_rate,notes: project three columns

**SQL equivalent:**
```sql
SELECT monitoring_date, survival_rate, notes
FROM monitoring
WHERE survival_rate < 85;
```

---

## Expression 9 — Complete reforestation chain (5-table join)

**Query:** Get organization name, zone name, event name, and
species common_name for all planting events.

**Algebra:**
```
pi_o.name,z.name,pe.name,s.common_name(
    rho_o(organization)
    BOWTIE rho_z(zone)
    BOWTIE rho_pe(planting_event)
    BOWTIE rho_es(event_species)
    BOWTIE species
)
```

**SQL equivalent:**
```sql
SELECT o.name AS organization, z.name AS zone,
       pe.name AS event, s.common_name AS species
FROM organization o
JOIN zone z            ON o.org_id = z.org_id
JOIN planting_event pe ON z.zone_id = pe.zone_id
JOIN event_species es  ON pe.event_id = es.event_id
JOIN species s         ON es.species_id = s.species_id;
```

---

## Summary

| Expression | Operations | Concept demonstrated |
|---|---|---|
| 1 | pi | Simple projection |
| 2 | sigma | Simple selection |
| 3 | BOWTIE, pi | Join as existence filter |
| 4 | BOWTIE, pi, - | Difference to find absences |
| 5 | sigma, BOWTIE, pi | Selection before join (efficiency) |
| 6 | sigma, BOWTIE, pi | Filter intermediate table before join |
| 7 | sigma, BOWTIE, pi, rho | Rename to resolve attribute conflict |
| 8 | sigma, pi | Composed selection and projection |
| 9 | BOWTIE x5, pi, rho | Multi-table chain join |
