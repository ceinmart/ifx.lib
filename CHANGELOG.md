# Changelog - ifxlib

Versao do documento: 1.4.3.
Criado em: 2026-11-12 15:55:58 -0300.
Criado por: ChatGPT - OpenAI.

## 1.4.3 - 2026-11-12

- Corrigido o registro das UDRs: removida a classe invalida `cpu vp`.
- As UDRs C passam a usar a CPU VP padrao pela ausencia do modificador `CLASS`.
- Adicionado `fix_vp_class.sql` para corrigir bancos registrados pelas versoes 1.4.0 a 1.4.2.
- Adicionados exemplos de uso de todas as rotinas ao README.

## 1.4.2 - 2026-11-12

- Revisado o README para manter apenas documentacao operacional.
- Documentados os procedimentos de atualizacao com reinicio e online.
- Documentadas a retirada e a exclusao segura de uma versao anterior.
- Documentada a desinstalacao completa.
- Esclarecido que o autorregistro e exclusivo dos DataBlades padrao instalados com o servidor.

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
