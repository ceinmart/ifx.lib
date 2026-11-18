-- Project: ifxlib
-- File: example_spl.sql
-- Version: 1.4.9
-- Created: 2026-11-18 09:23:03 -0300
-- Created by: ChatGPT - OpenAI
-- Self-contained example: creates, runs, and removes a demonstration routine.

CREATE OR REPLACE PROCEDURE ifxlib_usage_example()
    RETURNING VARCHAR(40) AS stage,
              INTEGER AS loop_count,
              DATETIME YEAR TO FRACTION(3) AS current_time,
              INTEGER AS cpu_interval;

    DEFINE v_stage VARCHAR(40);
    DEFINE v_loop_count INTEGER;
    DEFINE v_now DATETIME YEAR TO FRACTION(3);
    DEFINE v_interval INTEGER;

    LET v_loop_count = 0;

    -- The setting is session-scoped, and the setter resets its counter.
    LET v_interval = 1000;
    EXECUTE PROCEDURE sp_cpu(v_interval);

    LET v_stage = 'start';
    LET v_now = sp_current2();
    RETURN v_stage, v_loop_count, v_now, v_interval WITH RESUME;

    WHILE v_loop_count < 100000
        LET v_loop_count = v_loop_count + 1;

        -- Replace this comment with the actual procedure workload.
        EXECUTE PROCEDURE sp_cpu();
    END WHILE;

    LET v_stage = 'end of interval 1000';
    LET v_now = sp_current2();
    RETURN v_stage, v_loop_count, v_now, v_interval WITH RESUME;

    LET v_interval = 10000;
    EXECUTE PROCEDURE sp_cpu(v_interval);

    LET v_stage = 'interval changed to 10000';
    LET v_now = sp_current2();
    RETURN v_stage, v_loop_count, v_now, v_interval WITH RESUME;

    WHILE v_loop_count < 200000
        LET v_loop_count = v_loop_count + 1;
        EXECUTE PROCEDURE sp_cpu();
    END WHILE;

    LET v_stage = 'end of interval 10000';
    LET v_now = sp_current2();
    RETURN v_stage, v_loop_count, v_now, v_interval WITH RESUME;

    -- Zero yields on every call.
    LET v_interval = 0;
    EXECUTE PROCEDURE sp_cpu(0);

    LET v_stage = 'yield on every call';
    LET v_now = sp_current2();
    RETURN v_stage, v_loop_count, v_now, v_interval WITH RESUME;

    -- -1 disables yielding until the session changes the setting.
    LET v_interval = -1;
    EXECUTE PROCEDURE sp_cpu(-1);

    LET v_stage = 'yield disabled';
    LET v_now = sp_current2();
    RETURN v_stage, v_loop_count, v_now, v_interval WITH RESUME;

    -- Restore the default behavior before the example exits.
    LET v_interval = 0;
    EXECUTE PROCEDURE sp_cpu(0);

    LET v_stage = 'default restored';
    LET v_now = sp_current2();
    RETURN v_stage, v_loop_count, v_now, v_interval WITH RESUME;
END PROCEDURE;

EXECUTE PROCEDURE ifxlib_usage_example();

DROP PROCEDURE IF EXISTS ifxlib_usage_example;
