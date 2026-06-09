-- ArborVida — Users and Permissions
-- Phase 7: Maintenance
SET search_path TO rfo;

CREATE ROLE read_only_role;
GRANT SELECT ON ALL TABLES IN SCHEMA rfo TO read_only_role;

CREATE ROLE field_coordinator_role;
GRANT SELECT ON ALL TABLES IN SCHEMA rfo TO field_coordinator_role;
GRANT INSERT, UPDATE ON planting_event, event_species,
    participation, monitoring TO field_coordinator_role;
GRANT INSERT ON volunteer TO field_coordinator_role;

CREATE USER analyst_user     WITH PASSWORD 'analyst2026';
CREATE USER coordinator_user WITH PASSWORD 'coord2026';

GRANT read_only_role         TO analyst_user;
GRANT field_coordinator_role TO coordinator_user;
