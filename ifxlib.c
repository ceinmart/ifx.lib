/*
 * Project: ifxlib
 * File: ifxlib.c
 * Version: 1.4.9
 * Created: 2026-11-18 09:23:03 -0300
 * Created by: ChatGPT - OpenAI
 *
 * Summary:
 *   - sp_cpu(): calls mi_yield() according to a per-session interval.
 *   - sp_cpu(INTEGER): sets the normal interval for the session.
 *   - sp_cpu_apply_policy(INTEGER, INTEGER): applies an administrative
 *     policy to the current session, typically from sysdbopen.
 *   - sp_current2(): returns the current operating-system clock.
 *
 * Target platform: HCL Informix 14.10, Linux x86_64.
 *
 * WARNING:
 *   This library is loaded into an oninit process. Memory errors, incorrect
 *   locking, or unsafe calls can affect the entire Informix instance.
 */

#include <mi.h>
#include <minmmem.h>
#include <stddef.h>
#include <sys/time.h>
#include <time.h>

#if defined(__GNUC__)
#define IFXLIB_EXPORT __attribute__((visibility("default")))
#else
#define IFXLIB_EXPORT
#endif

/*
 * Private ifxlib namespace. The v1 suffix identifies the first session-state
 * structure published under the current module name.
 */
#define SP_CPU_STATE_NAME "ifxlib.sp_cpu.state.v1"

typedef struct sp_cpu_session_state
{
    mi_integer procedure_interval;
    mi_integer admin_interval;
    mi_integer admin_force;
    mi_integer counter;
} sp_cpu_session_state;

/* Retrieve or create a zero-initialized block owned by the current session. */
static sp_cpu_session_state *
sp_cpu_get_state(void)
{
    sp_cpu_session_state *state;
    mi_integer status;

    state = NULL;
    status = mi_named_get((mi_string *)SP_CPU_STATE_NAME,
                          PER_SESSION,
                          (void **)&state);

    if (status == MI_OK)
        return state;

    if (status != MI_NO_SUCH_NAME)
    {
        mi_db_error_raise(NULL, MI_EXCEPTION,
                          "sp_cpu: mi_named_get(PER_SESSION) failed");
        return NULL;
    }

    status = mi_named_zalloc((mi_integer)sizeof(*state),
                             (mi_string *)SP_CPU_STATE_NAME,
                             PER_SESSION,
                             (void **)&state);

    if (status == MI_OK)
        return state;

    /* Another invocation in the same session might have created it first. */
    if (status == MI_NAME_ALREADY_EXISTS)
    {
        state = NULL;
        status = mi_named_get((mi_string *)SP_CPU_STATE_NAME,
                              PER_SESSION,
                              (void **)&state);
        if (status == MI_OK)
            return state;
    }

    mi_db_error_raise(NULL, MI_EXCEPTION,
                      "sp_cpu: unable to allocate PER_SESSION state");
    return NULL;
}

/* Acquire the mutex for the named-memory block. */
static mi_integer
sp_cpu_lock_state(void)
{
    mi_integer status;

    status = mi_lock_memory((mi_string *)SP_CPU_STATE_NAME, PER_SESSION);
    if (status != MI_OK)
    {
        mi_db_error_raise(NULL, MI_EXCEPTION,
                          "sp_cpu: mi_lock_memory(PER_SESSION) failed");
        return MI_ERROR;
    }

    return MI_OK;
}

/* Release the mutex before any operation that can raise an exception. */
static mi_integer
sp_cpu_unlock_state(void)
{
    mi_integer status;

    status = mi_unlock_memory((mi_string *)SP_CPU_STATE_NAME, PER_SESSION);
    if (status != MI_OK)
    {
        mi_db_error_raise(NULL, MI_EXCEPTION,
                          "sp_cpu: mi_unlock_memory(PER_SESSION) failed");
        return MI_ERROR;
    }

    return MI_OK;
}

/*
 * Implementation of the SQL signatures sp_cpu() and sp_yield().
 *
 * effective_interval = admin_force ? admin_interval : procedure_interval
 *
 * An effective interval of -1 returns immediately. Zero yields on every
 * call. A positive value uses the following counter:
 *
 *   counter = counter + 1
 *   if counter >= effective_interval: yield
 *
 * The mutex is released before mi_yield() is called.
 */
IFXLIB_EXPORT void
sp_cpu_noarg(void)
{
    sp_cpu_session_state *state;
    mi_integer effective_interval;
    mi_integer must_yield;

    state = sp_cpu_get_state();
    if (state == NULL)
        return;

    if (sp_cpu_lock_state() != MI_OK)
        return;

    effective_interval = state->admin_force
                             ? state->admin_interval
                             : state->procedure_interval;
    must_yield = 0;

    if (effective_interval == -1)
    {
        /* Disabled mode: do not increment the counter and do not yield. */
    }
    else if (effective_interval == 0)
    {
        must_yield = 1;
    }
    else
    {
        state->counter++;
        if (state->counter >= effective_interval)
        {
            state->counter = 0;
            must_yield = 1;
        }
    }

    if (sp_cpu_unlock_state() != MI_OK)
        return;

    if (must_yield)
        mi_yield();
}

/*
 * Implementation of the SQL signatures sp_cpu(INTEGER) and
 * sp_yield(INTEGER).
 *
 * Interval -1 disables yielding. Without admin_force, this changes the normal
 * interval and resets the counter. With admin_force enabled, the call is
 * ignored so application procedures cannot change the administrative policy.
 */
IFXLIB_EXPORT void
sp_cpu_set(mi_integer interval)
{
    sp_cpu_session_state *state;
    mi_integer must_yield;

    if (interval < -1)
    {
        mi_db_error_raise(NULL, MI_EXCEPTION,
                          "sp_cpu: interval must be -1 or greater");
        return;
    }

    state = sp_cpu_get_state();
    if (state == NULL)
        return;

    if (sp_cpu_lock_state() != MI_OK)
        return;

    must_yield = 0;

    if (!state->admin_force)
    {
        state->procedure_interval = interval;
        state->counter = 0;
        must_yield = (interval == 0);
    }

    if (sp_cpu_unlock_state() != MI_OK)
        return;

    /* Preserve the historical sp_cpu(0) behavior when no policy is forced. */
    if (must_yield)
        mi_yield();
}

/*
 * Apply an administrative policy to the current session.
 *
 * Value -1 disables all calls to mi_yield().
 *
 * admin_force = 1:
 *   admin_interval becomes effective, and sp_cpu(INTEGER) cannot change it or
 *   reset its counter.
 *
 * admin_force = 0:
 *   remove the forced policy and use admin_interval as the session default.
 *   Later calls to sp_cpu(INTEGER) can change it.
 *
 * This function only configures state; it does not call mi_yield().
 */
IFXLIB_EXPORT void
sp_cpu_apply_policy(mi_integer admin_force, mi_integer admin_interval)
{
    sp_cpu_session_state *state;

    if (admin_force != 0 && admin_force != 1)
    {
        mi_db_error_raise(NULL, MI_EXCEPTION,
                          "sp_cpu_apply_policy: admin_force must be 0 or 1");
        return;
    }

    if (admin_interval < -1)
    {
        mi_db_error_raise(NULL, MI_EXCEPTION,
                          "sp_cpu_apply_policy: interval must be -1 or greater");
        return;
    }

    state = sp_cpu_get_state();
    if (state == NULL)
        return;

    if (sp_cpu_lock_state() != MI_OK)
        return;

    state->admin_force = admin_force;
    state->admin_interval = admin_interval;
    state->counter = 0;

    if (!admin_force)
        state->procedure_interval = admin_interval;

    (void)sp_cpu_unlock_state();
}

/*
 * Return current time as DATETIME YEAR TO FRACTION(3).
 *
 * gettimeofday() reads the operating-system clock directly. localtime_r()
 * converts the epoch using the oninit process timezone.
 * mi_string_to_datetime() converts ANSI text into the Informix DATETIME
 * binary format without using CURRENT or dtcurrent().
 */
IFXLIB_EXPORT mi_datetime *
sp_current2(void)
{
    struct timeval current_time;
    struct tm local_time;
    char datetime_text[24];
    long milliseconds;
    mi_datetime *result;

    if (gettimeofday(&current_time, NULL) != 0)
    {
        mi_db_error_raise(NULL, MI_EXCEPTION,
                          "sp_current2: gettimeofday() failed");
        return NULL;
    }

    if (localtime_r(&current_time.tv_sec, &local_time) == NULL)
    {
        mi_db_error_raise(NULL, MI_EXCEPTION,
                          "sp_current2: localtime_r() failed");
        return NULL;
    }

    if (strftime(datetime_text,
                 sizeof(datetime_text),
                 "%Y-%m-%d %H:%M:%S",
                 &local_time) == 0)
    {
        mi_db_error_raise(NULL, MI_EXCEPTION,
                          "sp_current2: strftime() failed");
        return NULL;
    }

    milliseconds = current_time.tv_usec / 1000L;
    if (milliseconds < 0L || milliseconds > 999L)
    {
        mi_db_error_raise(NULL, MI_EXCEPTION,
                          "sp_current2: invalid microsecond value");
        return NULL;
    }

    datetime_text[19] = '.';
    datetime_text[20] = (char)('0' + (milliseconds / 100L));
    datetime_text[21] = (char)('0' + ((milliseconds / 10L) % 10L));
    datetime_text[22] = (char)('0' + (milliseconds % 10L));
    datetime_text[23] = '\0';

    result = mi_string_to_datetime(
        (mi_string *)datetime_text,
        (mi_string *)"datetime year to fraction(3)");

    if (result == NULL)
    {
        mi_db_error_raise(NULL, MI_EXCEPTION,
                          "sp_current2: mi_string_to_datetime() failed");
        return NULL;
    }

    return result;
}
