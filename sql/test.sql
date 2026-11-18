-- Project: ifxlib
-- File: sql/test.sql
-- Version: 1.4.9
-- Created: 2026-11-18 09:23:03 -0300
-- Created by: ChatGPT - OpenAI

-- Initial session state: yield on every call.
EXECUTE PROCEDURE sp_cpu();

-- Yield every 1000 no-argument calls.
EXECUTE PROCEDURE sp_cpu(1000);
EXECUTE PROCEDURE sp_cpu();

-- A forced administrative policy blocks procedure-level changes.
EXECUTE PROCEDURE sp_cpu_apply_policy(1, 10000);
EXECUTE PROCEDURE sp_cpu(1000);
EXECUTE PROCEDURE sp_cpu();

-- Remove the force and allow a new override.
EXECUTE PROCEDURE sp_cpu_apply_policy(0, 500);
EXECUTE PROCEDURE sp_cpu(1000);
EXECUTE PROCEDURE sp_cpu();

-- -1 disables yielding for the session.
EXECUTE PROCEDURE sp_cpu_apply_policy(1, -1);
EXECUTE PROCEDURE sp_cpu();
EXECUTE PROCEDURE sp_cpu(0);
EXECUTE PROCEDURE sp_cpu();

-- Remove the force; sp_cpu(INTEGER) can enable yielding again.
EXECUTE PROCEDURE sp_cpu_apply_policy(0, -1);
EXECUTE PROCEDURE sp_cpu();
EXECUTE PROCEDURE sp_cpu(1000);

EXECUTE PROCEDURE sp_yield(10000);
EXECUTE PROCEDURE sp_cpu();
EXECUTE PROCEDURE sp_cpu(0);

EXECUTE FUNCTION sp_current2();

-- Compare the operating-system clock with the clock exposed by sysmaster.
-- sh_curtime has less precision than FRACTION(3), so small differences are
-- expected.
SELECT sp_current2() AS sp_current2_os,
       dbinfo('utc_to_datetime', sh_curtime) AS sysmaster_time
  FROM sysmaster:sysshmvals;

SELECT procname, isproc, mode, externalname
  FROM sysprocedures
 WHERE procname IN ('sp_cpu', 'sp_cpu_apply_policy', 'sp_yield', 'sp_current2')
 ORDER BY procname, numargs;
