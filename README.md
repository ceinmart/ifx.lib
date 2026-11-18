# ifxlib

Versao 1.4.2 - criada em 2026-11-12 15:02:56 -0300 pelo ChatGPT - OpenAI.

Biblioteca de UDRs C para HCL Informix 14.10 em Linux x86_64.

## Rotinas fornecidas

- `sp_cpu()` e `sp_cpu(INTEGER)`: controlam a frequencia de `mi_yield()` por sessao.
- `sp_cpu_apply_policy(INTEGER, INTEGER)`: aplica uma politica administrativa na sessao.
- `sp_yield()` e `sp_yield(INTEGER)`: aliases de compatibilidade para `sp_cpu`.
- `sp_current2()`: retorna a data/hora corrente por meio de `dtcurrent()`.

## Pre-requisitos

- HCL Informix Server/CSDK 14.10 de 64 bits.
- Compilador C suportado pelas machine notes da versao instalada.
- `INFORMIXDIR` e `INFORMIXSERVER` configurados.
- Usuario com permissao de gravacao em `$INFORMIXDIR/extend`.
- Usuario DBA e role `EXTEND` quando `IFX_EXTEND_ROLE=1`.
- Banco local com logging para o registro das UDRs.
- Se `DB_LIBRARY_PATH` estiver configurado, deve incluir `$INFORMIXDIR/extend`.

## Estrutura instalada

```text
$INFORMIXDIR/extend/ifxlib.1.4.UC1/
|-- ifxlib.bld
|-- register.sql
|-- unregister.sql
|-- test.sql
|-- register.sh
|-- unregister.sh
|-- example_spl.sql
|-- example_sysdbopen.sql
`-- README.md
```

`ifxlib.bld` e um shared object ELF compilado com `-shared` e `-fPIC`.

## Compilacao, deploy e registro

```bash
# Projeto: ifxlib
# Instalacao
# Versao: 1.4.2
# Criado em: 2026-11-12 15:02:56 -0300
# Criado por: ChatGPT - OpenAI

export INFORMIXDIR=/opt/informix
export INFORMIXSERVER=servidor
export PATH="$INFORMIXDIR/bin:$PATH"

./install.sh
./register.sh nome_do_banco
dbaccess nome_do_banco "$INFORMIXDIR/extend/ifxlib.1.4.UC1/test.sql"
```

Alternativamente:

```bash
# Projeto: ifxlib
# Compilacao e deploy por Makefile
# Versao: 1.4.2
# Criado em: 2026-11-12 15:02:56 -0300
# Criado por: ChatGPT - OpenAI

make clean
make CC=gcc check
make deploy
make register DB=nome_do_banco
make test DB=nome_do_banco
```

As UDRs sao registradas separadamente em cada banco que for utiliza-las.

## Autorregistro

O autorregistro do Informix e restrito aos DataBlades padrao instalados com o
servidor, como TimeSeries, e depende do admin task scheduler em execucao.

`ifxlib` e uma extensao definida pelo usuario e nao participa desse
autorregistro. Nao existe um parametro de configuracao que habilite o
autorregistro para ela.

Nesta distribuicao, o registro deve ser executado explicitamente em cada banco:

```bash
# Projeto: ifxlib
# Registro em um banco
# Versao: 1.4.2
# Criado em: 2026-11-12 15:02:56 -0300
# Criado por: ChatGPT - OpenAI

./register.sh nome_do_banco
```

Um DataBlade definido pelo usuario pode ser preparado para registro manual por
`SYSBldPrepare()`, mas isso exige os metadados completos de empacotamento do
DataBlade. Mesmo nesse formato, ele continuaria exigindo uma chamada manual de
`SYSBldPrepare()`; nao receberia o autorregistro reservado aos módulos padrao.

## Atualizacao de uma instalacao existente

Antes de atualizar, consulte em cada banco qual biblioteca esta registrada:

```sql
-- Projeto: ifxlib
-- Verificacao antes da atualizacao
-- Versao: 1.4.2
-- Criado em: 2026-11-12 15:02:56 -0300
-- Criado por: ChatGPT - OpenAI

SELECT procname, numargs, externalname
  FROM sysprocedures
 WHERE procname IN
       ('sp_cpu', 'sp_cpu_apply_policy', 'sp_yield', 'sp_current2')
 ORDER BY procname, numargs;
```

### Atualizacao com reinicio da instancia

Use este procedimento quando o codigo C mudar, mas as assinaturas SQL
continuarem iguais:

1. Pare a instancia Informix em uma janela de manutencao.
2. Guarde uma copia do diretorio e do `ifxlib.bld` atuais.
3. Compile e implante a nova biblioteca no mesmo caminho.
4. Inicie a instancia.
5. Execute `test.sql` nos bancos que utilizam a biblioteca.

Como o modulo anterior foi descarregado durante o shutdown e as assinaturas e
o caminho permaneceram iguais, nao e necessario registrar novamente as UDRs.

Nunca sobrescreva um `ifxlib.bld` carregado com a instancia online.

### Atualizacao online para outro diretorio

Para atualizar sem reiniciar, instale a nova biblioteca em um diretorio com
versao diferente. Exemplo:

```bash
# Projeto: ifxlib
# Instalacao online do novo binario
# Versao: 1.4.2
# Criado em: 2026-11-12 15:02:56 -0300
# Criado por: ChatGPT - OpenAI

make clean
make CC=gcc check

new_dir="$INFORMIXDIR/extend/ifxlib.1.4.UC2"
install -d -m 0755 "$new_dir"
install -m 0755 ifxlib.bld "$new_dir/ifxlib.bld"
```

Use caminhos absolutos em `IFX_REPLACE_MODULE`:

```sql
-- Projeto: ifxlib
-- Troca online do modulo carregado
-- Versao: 1.4.2
-- Criado em: 2026-11-12 15:02:56 -0300
-- Criado por: ChatGPT - OpenAI

-- Substitua /opt/informix pelo INFORMIXDIR real.
EXECUTE FUNCTION ifx_replace_module(
    '/opt/informix/extend/ifxlib.1.4.UC1/ifxlib.bld',
    '/opt/informix/extend/ifxlib.1.4.UC2/ifxlib.bld',
    'C'
);
```

Depois, altere o caminho persistente de todas as rotinas em cada banco:

```sql
-- Projeto: ifxlib
-- Atualizacao persistente dos caminhos das UDRs
-- Versao: 1.4.2
-- Criado em: 2026-11-12 15:02:56 -0300
-- Criado por: ChatGPT - OpenAI

ALTER PROCEDURE sp_cpu()
    WITH (MODIFY EXTERNAL NAME =
    '$INFORMIXDIR/extend/ifxlib.1.4.UC2/ifxlib.bld(sp_cpu_noarg)');

ALTER PROCEDURE sp_cpu(INTEGER)
    WITH (MODIFY EXTERNAL NAME =
    '$INFORMIXDIR/extend/ifxlib.1.4.UC2/ifxlib.bld(sp_cpu_set)');

ALTER PROCEDURE sp_cpu_apply_policy(INTEGER, INTEGER)
    WITH (MODIFY EXTERNAL NAME =
    '$INFORMIXDIR/extend/ifxlib.1.4.UC2/ifxlib.bld(sp_cpu_apply_policy)');

ALTER PROCEDURE sp_yield()
    WITH (MODIFY EXTERNAL NAME =
    '$INFORMIXDIR/extend/ifxlib.1.4.UC2/ifxlib.bld(sp_cpu_noarg)');

ALTER PROCEDURE sp_yield(INTEGER)
    WITH (MODIFY EXTERNAL NAME =
    '$INFORMIXDIR/extend/ifxlib.1.4.UC2/ifxlib.bld(sp_cpu_set)');

ALTER FUNCTION sp_current2()
    WITH (MODIFY EXTERNAL NAME =
    '$INFORMIXDIR/extend/ifxlib.1.4.UC2/ifxlib.bld(sp_current2)');
```

`ALTER PROCEDURE` e `ALTER FUNCTION` preservam a identidade, as permissoes e
as dependencias das rotinas. Execute `test.sql` e confirme `externalname` em
`sysprocedures` antes de retirar a versao anterior.

Se uma assinatura SQL mudar, trate-a como alteracao de interface: revise as
dependencias e use `CREATE OR REPLACE` quando a assinatura continuar
identificando a mesma rotina. Para remover ou mudar parametros/retorno, pode
ser necessario executar `DROP` e `CREATE` e reaplicar permissoes.

## Exclusao de uma versao anterior

Antes da exclusao fisica, execute a consulta de `sysprocedures` em todos os
bancos da instancia e confirme que nenhum `externalname` aponta para o
diretorio antigo.

Descarregue o modulo antigo quando ele nao estiver sendo executado:

```sql
-- Projeto: ifxlib
-- Descarga do modulo anterior
-- Versao: 1.4.2
-- Criado em: 2026-11-12 15:02:56 -0300
-- Criado por: ChatGPT - OpenAI

-- Use o caminho absoluto real.
EXECUTE FUNCTION ifx_unload_module(
    '/opt/informix/extend/ifxlib.1.4.UC1/ifxlib.bld',
    'C'
);
```

Se o retorno indicar que o modulo esta em uso, aguarde as instrucoes que usam
as UDRs terminarem ou reinicie a instancia antes de continuar.

Primeiro mova o diretorio para quarentena:

```bash
# Projeto: ifxlib
# Coloca a versao anterior em quarentena
# Versao: 1.4.2
# Criado em: 2026-11-12 15:02:56 -0300
# Criado por: ChatGPT - OpenAI

old_dir="$INFORMIXDIR/extend/ifxlib.1.4.UC1"
test -d "$old_dir" || exit 1
mv "$old_dir" "${old_dir}.retired"
```

Apos validar a nova versao e, preferencialmente, apos um reinicio da instancia,
exclua somente o diretorio colocado em quarentena:

```bash
# Projeto: ifxlib
# Exclui a versao anterior em quarentena
# Versao: 1.4.2
# Criado em: 2026-11-12 15:02:56 -0300
# Criado por: ChatGPT - OpenAI

old_dir="$INFORMIXDIR/extend/ifxlib.1.4.UC1.retired"
test -d "$old_dir" || exit 1
rm -rf -- "$old_dir"
```

## Desinstalacao completa

1. Execute `./unregister.sh nome_do_banco` em todos os bancos que registraram as UDRs.
2. Confirme em `sysprocedures` que nenhuma rotina referencia `ifxlib.bld`.
3. Execute `IFX_UNLOAD_MODULE` ou reinicie a instancia.
4. Mova o diretorio para `.retired` e valide a instancia.
5. Exclua o diretorio em quarentena.

## Calculo de `sp_cpu`

A cada chamada de `sp_cpu()` sem parametro:

1. Seleciona o intervalo efetivo da sessao.
2. Intervalo `-1`: retorna sem incrementar o contador e sem `mi_yield()`.
3. Intervalo `0`: executa `mi_yield()` em toda chamada.
4. Intervalo positivo: incrementa o contador.
5. Executa `mi_yield()` quando `counter % intervalo == 0` e zera o contador.

Quanto menor o intervalo positivo, mais frequente e o yield.

## Politica administrativa

| Chamada | Efeito na sessao |
| --- | --- |
| `sp_cpu_apply_policy(1, N)` | Forca `N`; chamadas posteriores de `sp_cpu(N)` sao ignoradas. |
| `sp_cpu_apply_policy(1, -1)` | Forca o mecanismo desativado. |
| `sp_cpu_apply_policy(1, 0)` | Forca yield em toda chamada. |
| `sp_cpu_apply_policy(0, N)` | Define `N` como default alteravel por `sp_cpu(N)`. |
| `sp_cpu_apply_policy(0, -1)` | Define desativado como default alteravel. |

O estado usa memoria nomeada `PER_SESSION` e o acesso e protegido por
`mi_lock_memory()` e `mi_unlock_memory()`.

## Referencias oficiais

- [Autorregistro de DataBlades padrao](https://help.hcl-software.com/hclinformix/1410/dmir/ids_dmir_autoregister.html)
- [Registro com SYSBldPrepare](https://help.hcl-software.com/hclinformix/1410/dmir/ids_dmir_017.html)
- [ALTER ROUTINE](https://help.hcl-software.com/hclinformix/1410/sqs/ids_sqs_0273.html)
- [IFX_REPLACE_MODULE](https://help.hcl-software.com/hclinformix/1410/sqs/ids_sqs_1802.html)
- [IFX_UNLOAD_MODULE](https://help.hcl-software.com/hclinformix/1410/sqs/ids_sqs_1803.html)
- [Gerenciamento de memoria nomeada](https://help.hcl-software.com/hclinformix/1410/dapip/ids_dapip_0755.html)
- [Concorrencia em memoria nomeada](https://help.hcl-software.com/hclinformix/1410/dapip/ids_dapip_0758.html)
- [mi_yield()](https://www.ibm.com/docs/en/informix-servers/14.10?topic=descriptions-mi-yield-function)
- [dtcurrent()](https://www.ibm.com/docs/en/informix-servers/14.10.0?topic=descriptions-dtcurrent-function)
