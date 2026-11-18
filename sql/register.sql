-- Projeto: ifxlib
-- Arquivo: register.sql
-- Versao: 1.4.0
-- Criado em: 2026-11-12 10:45:57 -0300
-- Criado por: ChatGPT - OpenAI
-- Registre no banco local com logging, usando um usuario DBA/EXTEND.

CREATE PROCEDURE sp_cpu()
    WITH (CLASS = 'cpu vp')
    EXTERNAL NAME '$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld(sp_cpu_noarg)'
    LANGUAGE C;

CREATE PROCEDURE sp_cpu(INTEGER)
    WITH (CLASS = 'cpu vp')
    EXTERNAL NAME '$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld(sp_cpu_set)'
    LANGUAGE C;

CREATE PROCEDURE sp_cpu_apply_policy(INTEGER, INTEGER)
    WITH (CLASS = 'cpu vp')
    EXTERNAL NAME '$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld(sp_cpu_apply_policy)'
    LANGUAGE C;

-- Aliases de compatibilidade.
CREATE PROCEDURE sp_yield()
    WITH (CLASS = 'cpu vp')
    EXTERNAL NAME '$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld(sp_cpu_noarg)'
    LANGUAGE C;

CREATE PROCEDURE sp_yield(INTEGER)
    WITH (CLASS = 'cpu vp')
    EXTERNAL NAME '$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld(sp_cpu_set)'
    LANGUAGE C;

CREATE FUNCTION sp_current2()
    RETURNS DATETIME YEAR TO FRACTION(3)
    WITH (VARIANT, CLASS = 'cpu vp')
    EXTERNAL NAME '$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld(sp_current2)'
    LANGUAGE C;
