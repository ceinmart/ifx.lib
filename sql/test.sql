-- Projeto: ifxlib
-- Arquivo: test.sql
-- Versao: 1.4.8
-- Criado em: 2026-11-18 09:03:38 -0300
-- Criado por: ChatGPT - OpenAI

-- Estado inicial da sessao: yield sempre.
EXECUTE PROCEDURE sp_cpu();

-- Yield a cada 1000 chamadas sem parametro.
EXECUTE PROCEDURE sp_cpu(1000);
EXECUTE PROCEDURE sp_cpu();

-- O force administrativo impede alteracao pela procedure.
EXECUTE PROCEDURE sp_cpu_apply_policy(1, 10000);
EXECUTE PROCEDURE sp_cpu(1000);
EXECUTE PROCEDURE sp_cpu();

-- Remove o force e permite novo override.
EXECUTE PROCEDURE sp_cpu_apply_policy(0, 500);
EXECUTE PROCEDURE sp_cpu(1000);
EXECUTE PROCEDURE sp_cpu();

-- -1 desativa completamente o yield para a sessao.
EXECUTE PROCEDURE sp_cpu_apply_policy(1, -1);
EXECUTE PROCEDURE sp_cpu();
EXECUTE PROCEDURE sp_cpu(0);
EXECUTE PROCEDURE sp_cpu();

-- Remove o force; sp_cpu(INTEGER) pode reativar o mecanismo.
EXECUTE PROCEDURE sp_cpu_apply_policy(0, -1);
EXECUTE PROCEDURE sp_cpu();
EXECUTE PROCEDURE sp_cpu(1000);

EXECUTE PROCEDURE sp_yield(10000);
EXECUTE PROCEDURE sp_cpu();
EXECUTE PROCEDURE sp_cpu(0);

EXECUTE FUNCTION sp_current2();

-- Compara o relogio direto do SO com o relogio publicado pelo sysmaster.
-- sh_curtime possui granularidade inferior ao FRACTION(3), portanto pequenas
-- diferencas entre as duas colunas sao esperadas.
SELECT sp_current2() AS sp_current2_os,
       dbinfo('utc_to_datetime', sh_curtime) AS sysmaster_time
  FROM sysmaster:sysshmvals;

SELECT procname, isproc, mode, externalname
  FROM sysprocedures
 WHERE procname IN ('sp_cpu', 'sp_cpu_apply_policy', 'sp_yield', 'sp_current2')
 ORDER BY procname, numargs;
