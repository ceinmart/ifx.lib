-- Project: ifxlib
-- File: example_benchmark.sql
-- Version: 1.4.9
-- Created: 2026-11-18 09:23:03 -0300
-- Created by: ChatGPT - OpenAI
--
-- Optional benchmark. Install it only in a database dedicated to testing.

CREATE OR REPLACE FUNCTION sp_ifxlib_benchmark(
    p_status_interval INTEGER,
    p_cpu_interval INTEGER
)
RETURNING INTEGER AS loop_count,
          DATETIME YEAR TO FRACTION(3) AS current_time,
          DECIMAL(16,3) AS elapsed_seconds;

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

    -- Configure once. A forced administrative policy takes precedence.
    EXECUTE PROCEDURE sp_cpu(p_cpu_interval);

    RETURN v_loop_count, v_previous, 0.000 WITH RESUME;

    FOR v_iteration IN (1 TO 1000000)

        -- Open and consume one catalog cursor per iteration.
        FOREACH SELECT FIRST 1 tabid
                  INTO v_tabid
                  FROM systables
                 WHERE tabid > 0

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

    IF MOD(v_loop_count, p_status_interval) != 0 THEN
        LET v_now = sp_current2();
        LET v_elapsed = v_now - v_previous;
        LET v_elapsed_seconds =
            v_elapsed::CHAR(20)::DECIMAL(16,3);

        RETURN v_loop_count, v_now, v_elapsed_seconds WITH RESUME;
    END IF;

END FUNCTION;

-- Example executions:
-- SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, -1));
-- SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, 10000));
-- SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, 1000));
-- SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, 0));
