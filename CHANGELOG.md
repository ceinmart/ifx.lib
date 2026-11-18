# Changelog - ifxlib

Versao do documento: 1.4.1.
Criado em: 2026-11-12 14:56:27 -0300.
Criado por: ChatGPT - OpenAI.

## 1.4.1 - 2026-11-12

- Corrigida a validacao de `datetime.h` para aceitar `incl/public`, `incl/esql` ou `incl`.
- Removida a execucao duplicada de `make check` pelo `install.sh`.
- Mantido o diretorio de modulo `ifxlib.1.4.UC1`; nenhuma alteracao foi feita no codigo funcional das UDRs.

## 1.4.0 - 2026-11-12

- Projeto renomeado para `ifxlib`.
- Fonte principal renomeada para `ifxlib.c`.
- Biblioteca compilada como `ifxlib.bld`.
- Adicionado deploy em `$INFORMIXDIR/extend/ifxlib.1.4.UC1`.
- Removido o template `install.sql.in` e a substituicao por `sed`.
- Adicionados `sql/register.sql`, `sql/unregister.sql` e `sql/test.sql`.
- Adicionados `install.sh`, `register.sh` e `unregister.sh`.
- Adicionados targets `deploy`, `register`, `unregister`, `test` e `package`.
- Alterado o identificador interno da memoria nomeada para o namespace `ifxlib`.

## 1.3.0 - 2026-10-29

- Reservado o intervalo `-1` para desativar completamente o yield.
- `sp_cpu()` no modo `-1` retorna sem incrementar contador.
- `sp_cpu(-1)` desativa o yield quando nao existe force administrativo.
- `sp_cpu_apply_policy(1, -1)` forca a desativacao na sessao.
- `sp_cpu_apply_policy(0, -1)` define a desativacao como default alteravel.
- Valores menores que `-1` continuam invalidos.

## 1.2.0 - 2026-10-29

- Adicionada `sp_cpu_apply_policy(admin_force, admin_interval)`.
- Implementada prioridade administrativa por sessao, sem tabela de controle.
- Definido que `admin_force=0` aplica o intervalo como default alteravel.
- Definido que `admin_force=1` ignora completamente `sp_cpu(INTEGER)`.
- Adicionado exemplo de integracao por `IF` no `sysdbopen`.
- Adicionado locking com `mi_lock_memory()` e `mi_unlock_memory()`.
- Substituida a alocacao por `mi_named_zalloc()` e incluido `minmmem.h`.
- Alterado o nome interno do bloco para `state.v2` por compatibilidade.

## 1.1.0 - 2026-09-09

- Renomeada a funcao de horario para `sp_current2()`.
- Renomeada a procedure de yield para `sp_cpu()`.
- Adicionada a sobrecarga `sp_cpu(INTEGER)` para configurar o intervalo por sessao.
- Adicionado estado nomeado `PER_SESSION`, sem variavel global compartilhada.
- Adicionados os aliases `sp_yield()` e `sp_yield(INTEGER)`.
- Definido que zero significa yield sempre e valor negativo retorna erro.

## 1.0.0 - 2026-09-09

- Implementada `ifx_yield_cpu()` com `mi_yield()`.
- Implementada `ifx_current_realtime()` com `dtcurrent()`.
- Adicionados Makefile, SQL de registro, teste, exemplo SPL e remocao.
