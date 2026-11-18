-- Project: ifxlib
-- File: example_sysdbopen.sql
-- Version: 1.4.9
-- Created: 2026-11-18 09:23:03 -0300
-- Created by: ChatGPT - OpenAI
--
-- Conceptual example. Merge this logic into the existing sysdbopen routine.
-- Do not create a second routine with the same owner and name.

CREATE OR REPLACE PROCEDURE public.sysdbopen()
    DEFINE v_admin_force SMALLINT;
    DEFINE v_admin_interval INTEGER;

    -- Default: interval 10000, still overridable by application procedures.
    LET v_admin_force = 0;
    LET v_admin_interval = 10000;

    -- Example: force batch accounts to use interval 1000.
    IF USER IN ('batch_user', 'etl_user') THEN
        LET v_admin_force = 1;
        LET v_admin_interval = 1000;
    END IF;

    -- Example: a regular application account gets an overridable default.
    IF USER = 'application_user' THEN
        LET v_admin_force = 0;
        LET v_admin_interval = 5000;
    END IF;

    -- Example: disable yielding for one specific administrative account.
    IF USER = 'no_yield_user' THEN
        LET v_admin_force = 1;
        LET v_admin_interval = -1;
    END IF;

    EXECUTE PROCEDURE sp_cpu_apply_policy(
        v_admin_force,
        v_admin_interval
    );
END PROCEDURE;
