# Relational Calculus
## ArborVida Foundation

---

## What is Relational Calculus?

Relational algebra is procedural: it specifies HOW to compute a result
(join first, then filter, then project).

Relational calculus is declarative: it specifies WHAT the result must
look like, without describing the computation steps.

Both are equally expressive — Codd's theorem (1972) proves that any
query expressible in algebra can be expressed in calculus and vice
versa. SQL syntax is influenced by both.

This document uses Tuple Relational Calculus (TRC), where variables
represent entire rows (tuples).

---

## Notation Reference

| Symbol | Meaning |
|---|---|
| { t | condition } | the set of all tuples t such that condition holds |
| R(t) | t is a tuple belonging to relation R |
| t.attr | value of attribute attr in tuple t |
| /\ | AND (logical conjunction) |
| \/ | OR (logical disjunction) |
| - | NOT (logical negation) |
| EXISTS p (...) | there exists a tuple p such that... |
| FORALL p (...) | for all tuples p... |

**Reading rule:**
{ t.attr | R(t) /\ condition }
reads as: "the set of all t.attr such that t is in R AND condition holds"

---

## Expression 1 — Names of all volunteers

**Query:** Get the name of every volunteer.

**TRC:**
```
{ t.name | volunteer(t) }
```

**Reads:** "the set of all t.name such that t is a tuple in volunteer"

**SQL equivalent:**
```sql
SELECT DISTINCT name FROM rfo.volunteer;
```

---

## Expression 2 — Slow and fast growing species (name and growth rate)

**Query:** Get scientific_name and growth_rate of species where
growth_rate is 'slow' or 'fast'.

**TRC:**
```
{ t.scientific_name, t.growth_rate | species(t)
  /\ (t.growth_rate='slow' \/ t.growth_rate='fast') }
```

**Reads:** "the set of all t.scientific_name and t.growth_rate
such that t is a species AND growth_rate is slow OR fast"

Note on multiple attributes: in TRC, multiple projected attributes
are listed with comma in the output set — not with /\.
The /\ symbol belongs only inside the condition after the pipe |.

**SQL equivalent:**
```sql
SELECT scientific_name, growth_rate
FROM rfo.species
WHERE growth_rate = 'slow' OR growth_rate = 'fast';
```

---

## Expression 3 — Volunteers who participated in at least one event

**Query:** Get the name of every volunteer who has at least one
participation record.

**TRC:**
```
{ t.name | volunteer(t)
  /\ EXISTS p (participation(p) /\ p.volunteer_id = t.volunteer_id) }
```

**Reads:** "the set of all t.name such that t is a volunteer AND
there exists a tuple p in participation where p.volunteer_id equals
t.volunteer_id"

**Why EXISTS works here:**
EXISTS p (...) is true if at least one participation tuple p satisfies
the condition. One matching row is enough — it does not matter
how many events the volunteer attended.

**SQL equivalent:**
```sql
SELECT DISTINCT v.name
FROM rfo.volunteer v
WHERE EXISTS (
    SELECT 1 FROM rfo.participation p
    WHERE p.volunteer_id = v.volunteer_id
);
```

---

## Expression 4 — Volunteers who have NEVER participated

**Query:** Find volunteers with zero participation records.

**TRC:**
```
{ t.name | volunteer(t)
  /\ -(EXISTS p (participation(p) /\ p.volunteer_id = t.volunteer_id)) }
```

**Reads:** "the set of all t.name such that t is a volunteer AND
there does NOT exist any participation tuple p where
p.volunteer_id equals t.volunteer_id"

**Compare with Expression 3:**
Expression 3 uses EXISTS — include if at least one match exists.
Expression 4 uses NOT EXISTS — include only if zero matches exist.
This is the fundamental use case for negation in calculus.

**SQL equivalent:**
```sql
SELECT v.name
FROM rfo.volunteer v
WHERE NOT EXISTS (
    SELECT 1 FROM rfo.participation p
    WHERE p.volunteer_id = v.volunteer_id
);
```

---

## Expression 5 — Names of Team Leaders

**Query:** Get the name of volunteers who served as Team Leader
in at least one event.

**TRC:**
```
{ t.name | volunteer(t)
  /\ EXISTS p (participation(p)
               /\ p.volunteer_id = t.volunteer_id
               /\ p.role = 'Team Leader') }
```

**Reads:** "the set of all t.name such that t is a volunteer AND
there exists a tuple p in participation where p.volunteer_id equals
t.volunteer_id AND p.role is Team Leader"

**Note on multiple conditions inside EXISTS:**
All conditions inside EXISTS p (...) refer to the same bound
variable p. Each condition must be connected with /\.

**SQL equivalent:**
```sql
SELECT DISTINCT v.name
FROM rfo.volunteer v
WHERE EXISTS (
    SELECT 1 FROM rfo.participation p
    WHERE p.volunteer_id = v.volunteer_id
    AND p.role = 'Team Leader'
);
```

---

## Expression 6 — Species planted in event 1 with low survival

**Query:** Get the common_name of species planted in event 1
that have at least one monitoring record with survival_rate below 85.

**TRC:**
```
{ s.common_name | species(s)
  /\ EXISTS es (event_species(es)
                /\ es.species_id = s.species_id
                /\ es.event_id = 1
                /\ EXISTS m (monitoring(m)
                             /\ m.event_id = es.event_id
                             /\ m.species_id = es.species_id
                             /\ m.survival_rate < 85)) }
```

**Reads:** "the set of all s.common_name such that s is a species
AND there exists an event_species record es where es.species_id
matches s.species_id AND es.event_id is 1 AND there exists a
monitoring record m where m links to that event_species AND
m.survival_rate is below 85"

**Nested EXISTS:** the inner EXISTS m is evaluated for each
candidate es. Both must be satisfied for the species to appear
in the result.

**SQL equivalent:**
```sql
SELECT DISTINCT s.common_name
FROM rfo.species s
WHERE EXISTS (
    SELECT 1 FROM rfo.event_species es
    WHERE es.species_id = s.species_id
    AND es.event_id = 1
    AND EXISTS (
        SELECT 1 FROM rfo.monitoring m
        WHERE m.event_id = es.event_id
        AND m.species_id = es.species_id
        AND m.survival_rate < 85
    )
);
```

---

## Expression 7 — Technical volunteers with expert level

**Query:** Get the name of technical volunteers whose
certification_level is 'expert'.

**TRC:**
```
{ t.name | volunteer(t)
  /\ EXISTS tv (technical_volunteer(tv)
                /\ tv.volunteer_id = t.volunteer_id
                /\ tv.certification_level = 'expert') }
```

**Reads:** "the set of all t.name such that t is a volunteer AND
there exists a technical_volunteer record tv where tv.volunteer_id
matches t.volunteer_id AND tv.certification_level is expert"

This expression demonstrates querying across the supertype-subtype
relationship from Unit 2.

**SQL equivalent:**
```sql
SELECT v.name
FROM rfo.volunteer v
WHERE EXISTS (
    SELECT 1 FROM rfo.technical_volunteer tv
    WHERE tv.volunteer_id = v.volunteer_id
    AND tv.certification_level = 'expert'
);
```

---

## Algebra vs Calculus Comparison

The same query expressed in both formalisms:

**Query:** Names of Team Leaders.

**Algebra (procedural — HOW):**
```
pi_name(volunteer BOWTIE sigma_role='Team Leader'(participation))
```
Step 1: filter participation. Step 2: join. Step 3: project.
The order of operations is explicit.

**Calculus (declarative — WHAT):**
```
{ t.name | volunteer(t)
  /\ EXISTS p (participation(p)
               /\ p.volunteer_id = t.volunteer_id
               /\ p.role = 'Team Leader') }
```
No steps. Only a logical description of which tuples qualify.
The DBMS decides how to evaluate it.

**SQL (declarative — influenced by calculus):**
```sql
SELECT DISTINCT v.name
FROM rfo.volunteer v
WHERE EXISTS (
    SELECT 1 FROM rfo.participation p
    WHERE p.volunteer_id = v.volunteer_id
    AND p.role = 'Team Leader'
);
```

---

## Summary

| Expression | Key operations | Concept demonstrated |
|---|---|---|
| 1 | simple condition | Basic TRC structure |
| 2 | \/, /\ in condition | OR condition and multi-attribute output |
| 3 | EXISTS | Existence check across tables |
| 4 | NOT EXISTS | Negation — find absences |
| 5 | EXISTS with multiple conditions | Filtering within EXISTS |
| 6 | nested EXISTS | Chained existence across 3 tables |
| 7 | EXISTS on subtype | Querying specialization hierarchy |
| — | algebra vs calculus | HOW vs WHAT comparison |
