# ifxlib

Versao 1.4.1 - criada em 2026-11-12 14:56:27 -0300 pelo ChatGPT - OpenAI.

Biblioteca C para HCL Informix 14.10, empacotada no estilo de um modulo
DataBlade para Linux x86_64.

## Funcoes fornecidas

- `sp_cpu()` e `sp_cpu(INTEGER)`: controlam a frequencia de `mi_yield()` por sessao.
- `sp_cpu_apply_policy(INTEGER, INTEGER)`: aplica uma politica administrativa na sessao.
- `sp_yield()` e `sp_yield(INTEGER)`: aliases de compatibilidade para `sp_cpu`.
- `sp_current2()`: retorna a data/hora corrente por meio de `dtcurrent()`.

## Estrutura de implantacao

O processo gera e instala esta estrutura:

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

O nome do projeto e da biblioteca e `ifxlib`. O sufixo `1.4.UC1` pertence ao
diretorio de release do modulo: versao 1.4, plataforma UNIX, build C1. Manter o
diretorio versionado evita sobrescrever um shared object que ainda possa estar
carregado por um processo `oninit`.

O binario usa a extensao `.bld`, tradicional para bibliotecas DataBlade. Ele e
um shared object ELF e e compilado com `-shared` e `-fPIC`.

## Por que nao existe mais `install.sql.in`

O antigo arquivo `.in` era um template. Antes do registro, `sed` substituia
`@LIBRARY_PATH@` pelo caminho absoluto da biblioteca e gerava `install.sql`.

Nesta versao, `register.sql` referencia diretamente:

```text
$INFORMIXDIR/extend/ifxlib.1.4.UC1/ifxlib.bld
```

O Informix resolve `$INFORMIXDIR` no `EXTERNAL NAME`; portanto, nao ha etapa de
substituicao e o arquivo SQL pode ser executado diretamente.

## Instalacao rapida

Execute no servidor Informix com um usuario que possa gravar em
`$INFORMIXDIR/extend`:

```bash
# Projeto: ifxlib
# Instalacao rapida
# Versao: 1.4.1
# Criado em: 2026-11-12 14:56:27 -0300
# Criado por: ChatGPT - OpenAI

export INFORMIXDIR=/opt/informix
export INFORMIXSERVER=servidor
export PATH="$INFORMIXDIR/bin:$PATH"

./install.sh
./register.sh nome_do_banco
dbaccess nome_do_banco "$INFORMIXDIR/extend/ifxlib.1.4.UC1/test.sql"
```

O banco deve possuir logging e a rotina deve ser registrada localmente no
servidor primario. Use um usuario DBA e, quando `IFX_EXTEND_ROLE=1`, conceda a
role `EXTEND` ao usuario que executara o registro.

Se `DB_LIBRARY_PATH` estiver configurado no `onconfig`, ele deve incluir
`$INFORMIXDIR/extend`.

## Instalacao por Makefile

Os mesmos passos podem ser executados separadamente:

```bash
# Projeto: ifxlib
# Compilacao e deploy
# Versao: 1.4.1
# Criado em: 2026-11-12 14:56:27 -0300
# Criado por: ChatGPT - OpenAI

make clean
make CC=gcc check
make deploy
make register DB=nome_do_banco
make test DB=nome_do_banco
```

Para gerar um pacote contendo somente o diretorio pronto para ser copiado para
`$INFORMIXDIR/extend`:

```bash
make package
```

O arquivo resultante sera `dist/ifxlib.1.4.UC1.tar.gz`.

## Remocao do banco

```bash
./unregister.sh nome_do_banco
```

Remova o diretorio fisico somente depois de eliminar as UDRs de todos os bancos
que o referenciam e garantir que nenhum processo `oninit` ainda carregue o
modulo.

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

## Registro no estilo DataBlade

Este pacote segue o layout operacional de DataBlade: modulo `.bld` e scripts
SQL dentro de um diretorio versionado sob `$INFORMIXDIR/extend`. O registro e
feito explicitamente por `dbaccess` usando `register.sql`.

Ele nao utiliza BladeManager nem `SYSBldPrepare()`. O suporte ao BladeManager e
ao DataBlade Developers Kit foi removido a partir do Informix 14.10.xC6; alem
disso, um pacote gerenciado por `SYSBldPrepare()` exige metadados de registro
gerados pelo DBDK. Os scripts explicitos evitam simular esses metadados.

## Migracao da versao 1.3

1. Execute o `uninstall.sql` da versao 1.3 no banco.
2. Compile e implante a versao 1.4 com `./install.sh`.
3. Registre com `./register.sh nome_do_banco`.
4. Integre `example_sysdbopen.sql` ao `sysdbopen` existente, se aplicavel.
5. Mantenha a biblioteca 1.3 enquanto algum `oninit` puder referencia-la.

## Limitacao de validacao

Este ambiente nao possui headers e binarios proprietarios do Informix/CSDK. O
fonte e o fluxo de build foram validados com interfaces simuladas; a compilacao
e o teste finais devem ser feitos com a versao exata do Informix/CSDK.

## Referencias oficiais

- [Instalacao de um DataBlade](https://help.hcl-software.com/hclinformix/1410/dbdk/ids_dbdk_278.html)
- [Registro com SYSBldPrepare](https://help.hcl-software.com/hclinformix/1410/dmir/ids_dmir_017.html)
- [Gerenciamento de memoria nomeada](https://help.hcl-software.com/hclinformix/1410/dapip/ids_dapip_0755.html)
- [Concorrencia em memoria nomeada](https://help.hcl-software.com/hclinformix/1410/dapip/ids_dapip_0758.html)
- [mi_yield()](https://www.ibm.com/docs/en/informix-servers/14.10?topic=descriptions-mi-yield-function)
- [dtcurrent()](https://www.ibm.com/docs/en/informix-servers/14.10.0?topic=descriptions-dtcurrent-function)
