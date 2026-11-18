-- Projeto: ifxlib
-- Arquivo: fix_vp_class.sql
-- Versao: 1.4.4
-- Criado em: 2026-11-12 16:19:45 -0300
-- Criado por: ChatGPT - OpenAI
-- Corrige registros feitos pelas versoes 1.4.0 a 1.4.2.

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
