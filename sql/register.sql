-- Project: ifxlib
-- File: sql/register.sql
-- Version: 1.4.9
-- Created: 2026-11-18 09:23:03 -0300
-- Created by: ChatGPT - OpenAI
-- Run in a logged local database as a DBA or a user with the EXTEND role.

CREATE OR REPLACE PROCEDURE sp_cpu()
    EXTERNAL NAME '$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld(sp_cpu_noarg)'
    LANGUAGE C;

CREATE OR REPLACE PROCEDURE sp_cpu(INTEGER)
    EXTERNAL NAME '$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld(sp_cpu_set)'
    LANGUAGE C;

CREATE OR REPLACE PROCEDURE sp_cpu_apply_policy(INTEGER, INTEGER)
    EXTERNAL NAME '$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld(sp_cpu_apply_policy)'
    LANGUAGE C;

-- Compatibility aliases.
CREATE OR REPLACE PROCEDURE sp_yield()
    EXTERNAL NAME '$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld(sp_cpu_noarg)'
    LANGUAGE C;

CREATE OR REPLACE PROCEDURE sp_yield(INTEGER)
    EXTERNAL NAME '$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld(sp_cpu_set)'
    LANGUAGE C;

CREATE OR REPLACE FUNCTION sp_current2()
    RETURNS DATETIME YEAR TO FRACTION(3)
    WITH (VARIANT)
    EXTERNAL NAME '$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld(sp_current2)'
    LANGUAGE C;
