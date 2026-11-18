/*
 * Projeto: ifxlib
 * Arquivo: ifxlib.c
 * Versao: 1.4.6
 * Criado em: 2026-11-13 10:28:59 -0300
 * Criado por: ChatGPT - OpenAI
 *
 * Resumo:
 *   - sp_cpu(): chama mi_yield() conforme um intervalo mantido por sessao.
 *   - sp_cpu(INTEGER): configura o intervalo normal da procedure.
 *   - sp_cpu_apply_policy(INTEGER, INTEGER): aplica, na sessao atual, uma
 *     politica administrativa definida pelo sysdbopen.
 *   - sp_current2(): retorna o relogio corrente do sistema operacional.
 *
 * Plataforma-alvo: HCL Informix 14.10, Linux x86_64.
 *
 * AVISO:
 *   Esta biblioteca e carregada dentro de um processo oninit. Erros de
 *   memoria, locking ou chamadas inseguras podem afetar toda a instancia.
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
 * Namespace proprio da ifxlib. O sufixo v1 identifica a primeira estrutura
 * de estado publicada com o novo nome do modulo.
 */
#define SP_CPU_STATE_NAME "ifxlib.sp_cpu.state.v1"

typedef struct sp_cpu_session_state
{
    mi_integer procedure_interval;
    mi_integer admin_interval;
    mi_integer admin_force;
    mi_integer counter;
} sp_cpu_session_state;

/* Recupera ou cria um bloco zerado pertencente a sessao atual. */
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

    /* Outra invocacao da mesma sessao pode ter criado o bloco primeiro. */
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

/* Obtem o mutex do bloco de memoria nomeada. */
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

/* Libera o mutex. Nenhuma chamada que possa gerar excecao ocorre antes dela. */
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
 * Implementacao das assinaturas SQL sp_cpu() e sp_yield().
 *
 * intervalo_efetivo = admin_force ? admin_interval : procedure_interval
 *
 * Se o intervalo efetivo for -1, retorna sem fazer nada. Se for zero,
 * executa yield sempre. Se for positivo:
 *
 *   counter = counter + 1
 *   if counter >= intervalo_efetivo: yield
 *
 * O mutex e liberado antes de chamar mi_yield().
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
        /* Modo desativado: nao incrementa contador e nao executa yield. */
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
 * Implementacao das assinaturas SQL sp_cpu(INTEGER) e sp_yield(INTEGER).
 *
 * O intervalo -1 desativa o yield. Sem admin_force, altera o intervalo normal
 * e zera o contador. Com
 * admin_force ativo, a chamada e ignorada completamente para que a procedure
 * nao consiga alterar nem o intervalo nem a contagem administrativa.
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

    /* Mantem a semantica historica de sp_cpu(0), mas somente sem force. */
    if (must_yield)
        mi_yield();
}

/*
 * Aplica a politica administrativa na sessao atual.
 *
 * O valor -1 significa modo desativado, sem chamadas a mi_yield().
 *
 * admin_force = 1:
 *   admin_interval passa a ser o intervalo efetivo e sp_cpu(INTEGER) nao
 *   consegue altera-lo nem reiniciar seu contador.
 *
 * admin_force = 0:
 *   remove o force e usa admin_interval como intervalo inicial/default da
 *   sessao. Chamadas posteriores de sp_cpu(INTEGER) podem altera-lo.
 *
 * Esta funcao apenas configura o estado; ela nao chama mi_yield().
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
 * Retorna a data/hora atual como DATETIME YEAR TO FRACTION(3).
 *
 * gettimeofday() consulta diretamente o relogio do sistema operacional.
 * localtime_r() converte o epoch para o fuso horario do processo oninit.
 * mi_string_to_datetime() converte o texto ANSI para o formato binario do
 * DATETIME Informix, sem usar CURRENT ou dtcurrent().
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
