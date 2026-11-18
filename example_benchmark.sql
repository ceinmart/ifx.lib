-- Projeto: ifxlib
-- Arquivo: example_benchmark.sql
-- Versao: 1.4.8
-- Criado em: 2026-11-18 09:03:38 -0300
-- Criado por: ChatGPT - OpenAI
--
-- Benchmark opcional. Nao faz parte do registro das UDRs e deve ser criado
-- explicitamente apenas no banco usado para o teste.

DROP FUNCTION IF EXISTS sp_ifxlib_benchmark(INTEGER, INTEGER);

CREATE FUNCTION sp_ifxlib_benchmark(
    p_status_interval INTEGER,
    p_cpu_interval INTEGER
)
RETURNING INTEGER,
          DATETIME YEAR TO FRACTION(3),
          DECIMAL(16,3);

    DEFINE v_iteration INTEGER;
    DEFINE v_loop_count INTEGER;
    DEFINE v_tabid INTEGER;
    DEFINE v_now DATETIME YEAR TO FRACTION(3);
    DEFINE v_previous DATETIME YEAR TO FRACTION(3);
    DEFINE v_elapsed INTERVAL SECOND(9) TO FRACTION(3);
    DEFINE v_elapsed_seconds DECIMAL(16,3);

    IF p_status_interval IS NULL OR p_status_interval <= 0 THEN
        RAISE EXCEPTION -746, 0,
            'sp_ifxlib_benchmark: status interval must be greater than zero';
    END IF;

    IF p_cpu_interval IS NULL OR p_cpu_interval < -1 THEN
        RAISE EXCEPTION -746, 0,
            'sp_ifxlib_benchmark: CPU interval must be -1 or greater';
    END IF;

    LET v_loop_count = 0;
    LET v_previous = sp_current2();

    -- Configura o intervalo uma vez. Se existir admin_force na sessao,
    -- a politica administrativa prevalece e esta chamada e ignorada.
    EXECUTE PROCEDURE sp_cpu(p_cpu_interval);

    -- Primeira linha do log: instante inicial do teste.
    RETURN v_loop_count, v_previous, 0.000 WITH RESUME;

    FOR v_iteration IN (1 TO 1000000)

        -- Abre e percorre um cursor do catalogo em cada iteracao. Portanto,
        -- o teste executa 1.000.000 de SELECTs/FOREACH em systables.
        FOREACH SELECT FIRST 1 tabid
                  INTO v_tabid
                  FROM systables
                 WHERE tabid > 0

            -- Usa o intervalo ja definido para esta sessao.
            EXECUTE PROCEDURE sp_cpu();

        END FOREACH;

        LET v_loop_count = v_loop_count + 1;

        IF MOD(v_loop_count, p_status_interval) = 0 THEN
            LET v_now = sp_current2();
            LET v_elapsed = v_now - v_previous;
            LET v_elapsed_seconds =
                v_elapsed::CHAR(20)::DECIMAL(16,3);

            RETURN v_loop_count, v_now, v_elapsed_seconds WITH RESUME;
            LET v_previous = v_now;
        END IF;
    END FOR;

    -- Garante uma linha final quando o intervalo nao divide 1.000.000.
    IF MOD(v_loop_count, p_status_interval) != 0 THEN
        LET v_now = sp_current2();
        LET v_elapsed = v_now - v_previous;
        LET v_elapsed_seconds =
            v_elapsed::CHAR(20)::DECIMAL(16,3);

        RETURN v_loop_count, v_now, v_elapsed_seconds WITH RESUME;
    END IF;

END FUNCTION;

-- Exemplos de execucao:
--
-- SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, -1));
-- SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, 10000));
-- SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, 1000));
-- SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, 0));
