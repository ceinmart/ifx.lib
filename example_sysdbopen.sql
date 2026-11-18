-- Projeto: ifxlib
-- Arquivo: example_sysdbopen.sql
-- Versao: 1.4.1
-- Criado em: 2026-11-12 14:56:27 -0300
-- Criado por: ChatGPT - OpenAI
--
-- Exemplo conceitual. Integre esta logica ao sysdbopen existente.
-- Nao crie uma segunda rotina com o mesmo owner/nome.

CREATE PROCEDURE public.sysdbopen()
    DEFINE v_admin_force SMALLINT;
    DEFINE v_admin_interval INTEGER;

    -- Default: configura 10000 na sessao, mas deixa a procedure alterar.
    LET v_admin_force = 0;
    LET v_admin_interval = 10000;

    -- Exemplo: usuarios batch ficam obrigatoriamente no intervalo 1000.
    IF USER IN ('batchusr', 'etlusr') THEN
        LET v_admin_force = 1;
        LET v_admin_interval = 1000;
    END IF;

    -- Exemplo: usuario online usa default 5000, sem force.
    IF USER = 'onlineusr' THEN
        LET v_admin_force = 0;
        LET v_admin_interval = 5000;
    END IF;

    -- Exemplo: desativa completamente o yield para um usuario especifico.
    IF USER = 'noyieldusr' THEN
        LET v_admin_force = 1;
        LET v_admin_interval = -1;
    END IF;

    EXECUTE PROCEDURE sp_cpu_apply_policy(
        v_admin_force,
        v_admin_interval
    );
END PROCEDURE;
