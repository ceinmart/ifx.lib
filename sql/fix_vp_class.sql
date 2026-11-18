-- Project: ifxlib
-- File: sql/fix_vp_class.sql
-- Version: 1.4.9
-- Created: 2026-11-18 09:23:03 -0300
-- Created by: ChatGPT - OpenAI
-- Fix registrations created by versions 1.4.0 through 1.4.2.

ALTER PROCEDURE sp_cpu()
    WITH (DROP CLASS);

ALTER PROCEDURE sp_cpu(INTEGER)
    WITH (DROP CLASS);

ALTER PROCEDURE sp_cpu_apply_policy(INTEGER, INTEGER)
    WITH (DROP CLASS);

ALTER PROCEDURE sp_yield()
    WITH (DROP CLASS);

ALTER PROCEDURE sp_yield(INTEGER)
    WITH (DROP CLASS);

ALTER FUNCTION sp_current2()
    WITH (DROP CLASS);

SELECT procname, numargs, class, externalname
  FROM sysprocedures
 WHERE procname IN
       ('sp_cpu', 'sp_cpu_apply_policy', 'sp_yield', 'sp_current2')
 ORDER BY procname, numargs;
