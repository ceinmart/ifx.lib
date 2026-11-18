# ifxlib

Versao 1.4.8 - criada em 2026-11-18 09:03:38 -0300 pelo ChatGPT - OpenAI.

Biblioteca de UDRs C para HCL Informix 14.10 em Linux x86_64.

## Aviso critico sobre atualizacoes

Nunca sobrescreva `ifxlib.bld` enquanto a instancia Informix estiver ativa.
Um shared object carregado permanece no mapa de memoria do servidor. Se o
arquivo for sobrescrito, o servidor pode falhar na proxima chamada de uma UDR.

O `install.sh` bloqueia esse caso a partir da versao 1.4.7. Se encontrar uma
instalacao anterior, oferece estas opcoes:

1. Instalar em um novo diretorio, recomendado para atualizacao online.
2. Sobrescrever o diretorio existente, permitido somente com a instancia offline.
3. Cancelar sem alterar a instalacao.

## Rotinas fornecidas

| Rotina | Finalidade |
| --- | --- |
| `sp_cpu()` | Executa `mi_yield()` conforme o intervalo mantido na sessao. |
| `sp_cpu(INTEGER)` | Define o intervalo normal da sessao. |
| `sp_cpu_apply_policy(INTEGER, INTEGER)` | Aplica uma politica administrativa na sessao. |
| `sp_yield()` e `sp_yield(INTEGER)` | Aliases de compatibilidade para `sp_cpu`. |
| `sp_current2()` | Retorna o relogio atual do sistema operacional com milissegundos. |

## Pre-requisitos

- HCL Informix Server/CSDK 14.10 de 64 bits.
- Compilador C suportado pelas machine notes da versao instalada.
- `INFORMIXDIR`, `INFORMIXSERVER` e `PATH` configurados.
- Permissao de gravacao em `$INFORMIXDIR/extend`.
- Usuario DBA e role `EXTEND` quando `IFX_EXTEND_ROLE=1`.
- Banco local com logging para registrar as UDRs.
- Se `DB_LIBRARY_PATH` estiver configurado, ele deve incluir
  `$INFORMIXDIR/extend`.

## Instalacao nova

### 1. Prepare o ambiente

```bash
# Projeto: ifxlib
# Finalidade: ambiente para instalacao nova
# Versao: 1.4.8
# Criado em: 2026-11-18 09:03:38 -0300
# Criado por: ChatGPT - OpenAI

export INFORMIXDIR=/opt/informix
export INFORMIXSERVER=servidor
export PATH="$INFORMIXDIR/bin:$PATH"
```

### 2. Compile e implante

```bash
# Projeto: ifxlib
# Finalidade: compilacao e deploy
# Versao: 1.4.8
# Criado em: 2026-11-18 09:03:38 -0300
# Criado por: ChatGPT - OpenAI

./install.sh
```

Sem instalacao anterior, o destino default e:

```text
$INFORMIXDIR/extend/ifxlib.1.4.UC1/
```

### 3. Registre as UDRs no banco

O registro e feito separadamente em cada banco que utilizar as rotinas:

```bash
# Projeto: ifxlib
# Finalidade: registro em banco novo
# Versao: 1.4.8
# Criado em: 2026-11-18 09:03:38 -0300
# Criado por: ChatGPT - OpenAI

$INFORMIXDIR/extend/ifxlib.1.4.UC1/register.sh nome_do_banco
```

Nao execute `register.sh` novamente durante uma atualizacao quando as rotinas
ja estiverem registradas.

### 4. Valide

```bash
# Projeto: ifxlib
# Finalidade: teste posterior ao registro
# Versao: 1.4.8
# Criado em: 2026-11-18 09:03:38 -0300
# Criado por: ChatGPT - OpenAI

dbaccess nome_do_banco \
  "$INFORMIXDIR/extend/ifxlib.1.4.UC1/test.sql"
```

O teste verifica as assinaturas, os modos de `sp_cpu()` e compara
`sp_current2()` com `sysmaster:sysshmvals`.

## Atualizacao de uma instalacao existente

Escolha o procedimento conforme o estado da instancia:

| Situacao | Procedimento |
| --- | --- |
| Pode reiniciar a instancia | Atualizacao offline no mesmo diretorio. |
| Nao pode reiniciar | Novo diretorio e `IFX_REPLACE_MODULE`. |
| `ifxlib.bld` ja foi sobrescrito online | Reinicio controlado antes de usar novamente as UDRs. |

### Recuperacao apos sobrescrita com o Informix online

Se `ifxlib.bld` foi sobrescrito enquanto o `oninit` estava ativo:

1. Interrompa temporariamente as chamadas a `sp_cpu`, `sp_yield` e
   `sp_current2`.
2. Verifique o `online.log` e o estado da instancia.
3. Encerre a instancia de forma controlada conforme o procedimento operacional
   do ambiente.
4. Garanta que a instancia chegou ao modo offline, removendo a shared memory.
5. Inicie novamente a instancia.
6. Execute `test.sql` antes de liberar as rotinas.

Exemplo para uma instancia standalone, sem HDR/RSS/SDS:

```bash
# Projeto: ifxlib
# Finalidade: recuperacao apos sobrescrita online
# Versao: 1.4.8
# Criado em: 2026-11-18 09:03:38 -0300
# Criado por: ChatGPT - OpenAI

onstat -
onmode -s
onmode -ky
oninit
onstat -

dbaccess nome_do_banco \
  "$INFORMIXDIR/extend/ifxlib.1.4.UC1/test.sql"
```

`onmode -s` aguarda as sessoes terminarem e leva a instancia a quiescent.
`onmode -ky` leva a instancia a offline e remove a shared memory. Em ambiente
HDR, RSS ou SDS, use o procedimento de parada e failover especifico do cluster.

Nao tente corrigir esse caso chamando `IFX_REPLACE_MODULE` com o mesmo caminho.
O Informix documenta que nomes completos iguais podem produzir resultados
imprevisiveis.

### Atualizacao offline no mesmo diretorio

Use quando a instancia puder ser parada:

1. Pare a instancia e confirme o modo offline.
2. Extraia a nova versao da ifxlib.
3. Execute o instalador e escolha a opcao de sobrescrita.
4. Inicie a instancia.
5. Execute `test.sql` em cada banco que utiliza as rotinas.

Tambem e possivel selecionar a opcao sem interacao:

```bash
# Projeto: ifxlib
# Finalidade: atualizacao offline automatizada
# Versao: 1.4.8
# Criado em: 2026-11-18 09:03:38 -0300
# Criado por: ChatGPT - OpenAI

export IFXLIB_INSTALL_MODE=overwrite
./install.sh
```

O instalador exige `INFORMIXSERVER` e executa `onstat -`. Se a instancia
responder como ativa, a sobrescrita e recusada.

Como o caminho e as assinaturas permanecem iguais, nao execute novamente
`register.sh`.

### Atualizacao online em novo diretorio

Execute o instalador com a instancia ativa e escolha a opcao 1:

```bash
# Projeto: ifxlib
# Finalidade: deploy online em novo diretorio
# Versao: 1.4.8
# Criado em: 2026-11-18 09:03:38 -0300
# Criado por: ChatGPT - OpenAI

./install.sh
```

O instalador encontra o proximo sufixo disponivel. Por exemplo, se `UC1` ja
existe, instala em `ifxlib.1.4.UC2`. Essa copia ainda nao fica ativa.

Ative o novo modulo uma unica vez na instancia, usando caminhos absolutos:

```sql
-- Projeto: ifxlib
-- Finalidade: troca online do modulo
-- Versao: 1.4.8
-- Criado em: 2026-11-18 09:03:38 -0300
-- Criado por: ChatGPT - OpenAI

EXECUTE FUNCTION ifx_replace_module(
    '/opt/informix/extend/ifxlib.1.4.UC1/ifxlib.bld',
    '/opt/informix/extend/ifxlib.1.4.UC2/ifxlib.bld',
    'C'
);
```

O retorno esperado e zero. Depois altere o caminho persistente em cada banco
que possui as UDRs registradas:

```sql
-- Projeto: ifxlib
-- Finalidade: persistencia do novo EXTERNAL NAME
-- Versao: 1.4.8
-- Criado em: 2026-11-18 09:03:38 -0300
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

Valide os caminhos persistidos:

```sql
-- Projeto: ifxlib
-- Finalidade: verificacao posterior a atualizacao
-- Versao: 1.4.8
-- Criado em: 2026-11-18 09:03:38 -0300
-- Criado por: ChatGPT - OpenAI

SELECT procname, numargs, externalname
  FROM sysprocedures
 WHERE procname IN
       ('sp_cpu', 'sp_cpu_apply_policy', 'sp_yield', 'sp_current2')
 ORDER BY procname, numargs;
```

Por fim, execute o `test.sql` do novo diretorio. Nao remova `UC1` ate validar
todos os bancos e garantir que nenhuma rotina ainda aponta para ele.

## Comportamento do instalador

### Execucao interativa

Quando encontra um `ifxlib.bld` existente, `install.sh` mostra o caminho e
solicita uma escolha. Cancelar e a opcao default.

### Execucao nao interativa

Use uma destas variaveis:

```bash
# Projeto: ifxlib
# Finalidade: modos nao interativos do instalador
# Versao: 1.4.8
# Criado em: 2026-11-18 09:03:38 -0300
# Criado por: ChatGPT - OpenAI

# Novo diretorio UCn; seguro com a instancia online.
IFXLIB_INSTALL_MODE=new ./install.sh

# Mesmo diretorio; somente com a instancia offline.
IFXLIB_INSTALL_MODE=overwrite ./install.sh

# Havendo varios diretorios, identifique exatamente qual sera sobrescrito.
IFXLIB_INSTALL_MODE=overwrite \
IFXLIB_OVERWRITE_VERSION=1.4.UC2 \
./install.sh
```

`make deploy` tambem recusa sobrescrever um binario existente. O uso direto
de `ALLOW_OVERWRITE=1` deve ficar restrito a automacao que ja confirmou que a
instancia esta offline.

## Exemplos de uso

O arquivo `example_spl.sql` e autocontido: cria uma procedure de demonstracao,
executa-a, exibe linhas de acompanhamento por `RETURN WITH RESUME` e executa o
`DROP PROCEDURE IF EXISTS` ao final. As colunas retornadas sao etapa, contador, horario
obtido por `sp_current2()` e intervalo aplicado ao `sp_cpu()`.

### Horario corrente dentro de SPL

```sql
-- Projeto: ifxlib
-- Finalidade: uso de sp_current2
-- Versao: 1.4.8
-- Criado em: 2026-11-18 09:03:38 -0300
-- Criado por: ChatGPT - OpenAI

DEFINE v_agora DATETIME YEAR TO FRACTION(3);
LET v_agora = sp_current2();
```

`sp_current2()` usa `gettimeofday()` e `localtime_r()`. O fuso horario e o do
ambiente do processo `oninit`.

### Controle de yield

```sql
-- Projeto: ifxlib
-- Finalidade: configuracao de sp_cpu
-- Versao: 1.4.8
-- Criado em: 2026-11-18 09:03:38 -0300
-- Criado por: ChatGPT - OpenAI

-- Desativado: nunca executa mi_yield().
EXECUTE PROCEDURE sp_cpu(-1);

-- Executa mi_yield() em toda chamada.
EXECUTE PROCEDURE sp_cpu(0);

-- Executa mi_yield() a cada 1000 chamadas.
EXECUTE PROCEDURE sp_cpu(1000);

-- Usa o intervalo mantido na sessao.
EXECUTE PROCEDURE sp_cpu();
```

Para intervalo positivo, `sp_cpu()` incrementa um contador, executa o yield
quando `counter >= intervalo` e zera o contador.

### Politica administrativa

```sql
-- Projeto: ifxlib
-- Finalidade: politica administrativa da sessao
-- Versao: 1.4.8
-- Criado em: 2026-11-18 09:03:38 -0300
-- Criado por: ChatGPT - OpenAI

-- Forca yield a cada 1000 chamadas; sp_cpu(N) sera ignorado.
EXECUTE PROCEDURE sp_cpu_apply_policy(1, 1000);

-- Forca o mecanismo desativado.
EXECUTE PROCEDURE sp_cpu_apply_policy(1, -1);

-- Remove o force e define 10000 como default alteravel.
EXECUTE PROCEDURE sp_cpu_apply_policy(0, 10000);
```

Adapte `example_sysdbopen.sql` para aplicar a politica durante a abertura da
sessao.

## Benchmark opcional

`example_benchmark.sql` cria `sp_ifxlib_benchmark()`, que executa 1.000.000 de
`FOREACH SELECT` em `systables`, chama `sp_cpu()` em cada iteracao e retorna o
progresso com `sp_current2()` e `RETURN WITH RESUME`.

```bash
# Projeto: ifxlib
# Finalidade: instalacao do benchmark opcional
# Versao: 1.4.8
# Criado em: 2026-11-18 09:03:38 -0300
# Criado por: ChatGPT - OpenAI

dbaccess nome_do_banco \
  "$INFORMIXDIR/extend/ifxlib.1.4.UC1/example_benchmark.sql"
```

Exemplos de comparacao:

```sql
-- Projeto: ifxlib
-- Finalidade: comparacao dos intervalos de yield
-- Versao: 1.4.8
-- Criado em: 2026-11-18 09:03:38 -0300
-- Criado por: ChatGPT - OpenAI

SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, -1));
SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, 10000));
SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, 1000));
SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, 0));
```

O benchmark e pesado de proposito e nao e executado por `test.sql`.

## Correcao do erro de VP das versoes 1.4.0 a 1.4.2

Essas versoes registravam incorretamente `CLASS='cpu vp'`, causando o erro
`-9799`. Para corrigir o registro sem recriar as UDRs:

```bash
# Projeto: ifxlib
# Finalidade: remocao da classe de VP invalida
# Versao: 1.4.8
# Criado em: 2026-11-18 09:03:38 -0300
# Criado por: ChatGPT - OpenAI

dbaccess nome_do_banco sql/fix_vp_class.sql
```

## Remocao de uma versao antiga

Antes de remover um diretorio, confirme em todos os bancos que nenhum
`externalname` aponta para ele. Em seguida, descarregue o modulo quando ele nao
estiver em uso:

```sql
-- Projeto: ifxlib
-- Finalidade: descarga de modulo antigo
-- Versao: 1.4.8
-- Criado em: 2026-11-18 09:03:38 -0300
-- Criado por: ChatGPT - OpenAI

EXECUTE FUNCTION ifx_unload_module(
    '/opt/informix/extend/ifxlib.1.4.UC1/ifxlib.bld',
    'C'
);
```

O modulo somente pode ser descarregado quando nenhuma instrucao estiver usando
suas UDRs. Depois de validar a nova versao, mova o diretorio antigo para
quarentena antes de exclui-lo.

## Desinstalacao completa

1. Execute `unregister.sh banco` em todos os bancos que registraram as UDRs.
2. Confirme em `sysprocedures` que nenhuma rotina referencia `ifxlib.bld`.
3. Execute `IFX_UNLOAD_MODULE` ou reinicie a instancia.
4. Remova o diretorio somente depois de confirmar que o modulo nao esta em uso.

## Autorregistro

`ifxlib` e uma extensao definida pelo usuario e nao participa do autorregistro
reservado aos DataBlades padrao fornecidos com o servidor. O registro deve ser
executado explicitamente em cada banco.

## Referencias oficiais

- [Substituicao de shared object carregado](https://help.hcl-software.com/hclinformix/15.0/dbdk/ids_dbdk_274.html)
- [IFX_REPLACE_MODULE](https://help.hcl-software.com/hclinformix/1410/sqs/ids_sqs_1802.html)
- [IFX_UNLOAD_MODULE](https://help.hcl-software.com/hclinformix/1410/sqs/ids_sqs_1803.html)
- [Modos do servidor e onmode](https://help.hcl-software.com/hclinformix/1410/adr/ids_adr_0422.html)
- [CLASS de UDR C](https://help.hcl-software.com/hclinformix/1410/sqs/ids_sqs_1722.html)
- [mi_yield()](https://www.ibm.com/docs/en/informix-servers/14.10?topic=descriptions-mi-yield-function)
- [Chamadas de sistema seguras em C UDRs](https://help.hcl-software.com/hclinformix/1410/dapip/ids_dapip_0678.html)
- [Conversao de DATETIME](https://help.hcl-software.com/hclinformix/1410/dapip/ids_dapip_0150.html)
