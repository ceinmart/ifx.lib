# ifxlib

Version 1.4.9 — created on 2026-11-18 09:23:03 -0300 by ChatGPT - OpenAI.

## About

`ifxlib` is a small collection of C user-defined routines (UDRs) for HCL
Informix 14.10 on 64-bit Linux. It provides cooperative CPU yielding for
long-running SPL loops and a real-time clock function that does not inherit the
statement-stable behavior of `CURRENT` inside SPL.

The module is loaded into an `oninit` process. Test every release in a
non-production instance before deployment. This is an independent community
project and is not an HCL product or an officially supported Informix module.

## License

`ifxlib` is free and open-source software distributed under the permissive
[MIT License](LICENSE). You may use, modify, and redistribute it, including in
commercial environments, subject to the license terms. The software is
provided without warranty.

## Provided routines

| Routine | Purpose |
| --- | --- |
| `sp_cpu()` | Calls `mi_yield()` according to the interval stored in the current session. |
| `sp_cpu(INTEGER)` | Changes the normal session interval and resets its internal counter. |
| `sp_cpu_apply_policy(INTEGER, INTEGER)` | Applies a session policy, optionally forcing an administrative interval. |
| `sp_yield()` / `sp_yield(INTEGER)` | Compatibility aliases for `sp_cpu`. |
| `sp_current2()` | Returns the operating-system clock as `DATETIME YEAR TO FRACTION(3)`. |

`sp_cpu` interval meanings:

| Value | Behavior |
| ---: | --- |
| `-1` | Disabled; `mi_yield()` is never called. |
| `0` | `mi_yield()` is called on every invocation. This is also the initial session default. |
| `N > 0` | `mi_yield()` is called after every `N` no-argument invocations. |

Examples:

- [SPL usage and `RETURN WITH RESUME`](example_spl.sql)
- [Optional one-million-query benchmark](example_benchmark.sql)
- [Administrative policy through `sysdbopen`](example_sysdbopen.sql)
- [Registration SQL](sql/register.sql)
- [Validation SQL](sql/test.sql)

## Prerequisites

- HCL Informix Server or Client SDK 14.10, 64-bit.
- Linux x86_64.
- A C compiler supported by the machine notes for the installed Informix
  release.
- `INFORMIXDIR`, `INFORMIXSERVER`, and `PATH` configured.
- Write permission under `$INFORMIXDIR/extend`.
- DBA privileges and, when `IFX_EXTEND_ROLE=1`, the `EXTEND` role.
- A logged local database for UDR registration.
- If `DB_LIBRARY_PATH` is configured, it must include
  `$INFORMIXDIR/extend`.

## First installation

### 1. Configure the environment

```bash
# Project: ifxlib
# Purpose: installation environment
# Version: 1.4.9
# Created: 2026-11-18 09:23:03 -0300
# Created by: ChatGPT - OpenAI

export INFORMIXDIR=/path/to/informix
export INFORMIXSERVER=server_name
export PATH="$INFORMIXDIR/bin:$PATH"
```

### 2. Build and deploy

```bash
./install.sh
```

With no existing installation, the default destination is:

```text
$INFORMIXDIR/extend/ifxlib.1.4.UC1/
```

The installer compiles `ifxlib.bld`, validates its exported symbols, and
copies the module, SQL files, examples, and helper scripts to the extension
directory.

### 3. Register the routines

Register one database:

```bash
$INFORMIXDIR/extend/ifxlib.1.4.UC1/register.sh application_db
```

Register several databases in one invocation:

```bash
$INFORMIXDIR/extend/ifxlib.1.4.UC1/register.sh db_one db_two db_three
```

Register every non-system database returned by `sysmaster:sysdatabases`:

```bash
$INFORMIXDIR/extend/ifxlib.1.4.UC1/register.sh -all
```

`-all` excludes every database whose lower-case name begins with `sys`, which
covers the Informix system databases such as `sysmaster`, `sysadmin`,
`sysutils`, `sysuser`, and `sysha`. It cannot be combined with explicit
database names. Registration stops at the first `dbaccess` error.

### 4. Validate

Run the validation script in every registered database:

```bash
dbaccess application_db \
  "$INFORMIXDIR/extend/ifxlib.1.4.UC1/test.sql"
```

## Updating an existing installation

Never overwrite a loaded `ifxlib.bld` while Informix is online. A loaded
shared object remains mapped into an `oninit` process, and replacing its file
in place can cause a later UDR invocation to fail.

Choose one of these supported update paths:

| Requirement | Update method |
| --- | --- |
| Informix must remain online | Install into a new directory and replace the loaded module. |
| A controlled restart is available | Stop Informix and overwrite the existing directory. |

Do not run `register.sh` again merely because the binary was upgraded. Existing
UDR registrations remain in the database and must either keep their path or be
changed with `ALTER ... MODIFY EXTERNAL NAME`.

### Updating into a new installation directory

Use this method when Informix must remain online.

1. Run `./install.sh` and select **Install into a new directory**.
2. The installer chooses the next available suffix, for example `UC2` after
   `UC1`.
3. Load the new module with `IFX_REPLACE_MODULE`, using absolute paths.
4. Update the persistent `EXTERNAL NAME` in every database that has the UDRs.
5. Run the new `test.sql` in every database.
6. Keep the previous directory until all registrations and active sessions are
   validated.

Non-interactive deployment into a new directory:

```bash
IFXLIB_INSTALL_MODE=new ./install.sh
```

Example module replacement:

```sql
EXECUTE FUNCTION ifx_replace_module(
    '/path/to/informix/extend/ifxlib.1.4.UC1/ifxlib.bld',
    '/path/to/informix/extend/ifxlib.1.4.UC2/ifxlib.bld',
    'C'
);
```

The expected result is zero. Then update each database:

```sql
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

Verify the stored paths:

```sql
SELECT procname, numargs, externalname
  FROM sysprocedures
 WHERE procname IN
       ('sp_cpu', 'sp_cpu_apply_policy', 'sp_yield', 'sp_current2')
 ORDER BY procname, numargs;
```

Do not call `IFX_REPLACE_MODULE` with identical old and new absolute paths.

### Updating in the same installation directory

Use this method only when the Informix instance can be stopped.

1. Stop Informix and confirm that the instance is offline.
2. Extract the new `ifxlib` release.
3. Run `./install.sh` and select **Overwrite an existing directory**.
4. Start Informix.
5. Run `test.sql` in every registered database.

Non-interactive same-directory update:

```bash
export IFXLIB_INSTALL_MODE=overwrite
export IFXLIB_OVERWRITE_VERSION=1.4.UC1
./install.sh
```

The installer requires `INFORMIXSERVER` and runs `onstat -`. If the command
reports a running instance, the overwrite is refused. Because the module path
does not change, no SQL re-registration is required.

### Recovering from an accidental online overwrite

If `ifxlib.bld` was already overwritten while Informix was online:

1. Stop invoking `sp_cpu`, `sp_yield`, and `sp_current2`.
2. Review `online.log` and the instance state.
3. Shut down the instance according to the site's operational procedure.
4. Confirm that shared memory was removed.
5. Start Informix and run `test.sql` before returning the UDRs to service.

For a standalone instance without HDR, RSS, or SDS, the controlled sequence is
typically:

```bash
onstat -
onmode -s
onmode -ky
oninit
onstat -
```

Use the appropriate cluster failover and shutdown procedure in high-
availability environments.

## Usage examples

### Real-time clock inside SPL

```sql
DEFINE v_now DATETIME YEAR TO FRACTION(3);
LET v_now = sp_current2();
```

`sp_current2()` uses `gettimeofday()`, `localtime_r()`, and
`mi_string_to_datetime()`. Its timezone is inherited from the `oninit`
process.

### Cooperative CPU yielding

```sql
-- Disable yielding.
EXECUTE PROCEDURE sp_cpu(-1);

-- Yield on every call.
EXECUTE PROCEDURE sp_cpu(0);

-- Yield after every 1000 no-argument calls.
EXECUTE PROCEDURE sp_cpu(1000);

-- Use the interval already stored in this session.
EXECUTE PROCEDURE sp_cpu();
```

### Administrative policy

```sql
-- Force a yield every 1000 calls; later sp_cpu(N) calls are ignored.
EXECUTE PROCEDURE sp_cpu_apply_policy(1, 1000);

-- Force yielding off.
EXECUTE PROCEDURE sp_cpu_apply_policy(1, -1);

-- Remove the force and set an overridable default of 10000.
EXECUTE PROCEDURE sp_cpu_apply_policy(0, 10000);
```

See [example_sysdbopen.sql](example_sysdbopen.sql) for session initialization.

## Optional benchmark

[example_benchmark.sql](example_benchmark.sql) creates
`sp_ifxlib_benchmark()`, which performs one million catalog queries and calls
`sp_cpu()` during each iteration. It is intentionally expensive and is never
run by `test.sql`.

```bash
dbaccess benchmark_db \
  "$INFORMIXDIR/extend/ifxlib.1.4.UC1/example_benchmark.sql"
```

```sql
SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, -1));
SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, 10000));
SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, 1000));
SELECT * FROM TABLE(FUNCTION sp_ifxlib_benchmark(100000, 0));
```

## Removing an old module directory

Before removing an old directory, query `sysprocedures` in every database and
confirm that no `externalname` still points to it. When the old module is no
longer in use, unload it:

```sql
EXECUTE FUNCTION ifx_unload_module(
    '/path/to/informix/extend/ifxlib.1.4.UC1/ifxlib.bld',
    'C'
);
```

Move the old directory to a quarantine location before permanently deleting
it. `IFX_UNLOAD_MODULE` can unload only a module that is not currently in use.

## Complete removal

1. Run `unregister.sh database` in every database where the UDRs exist.
2. Confirm through `sysprocedures` that no routine references `ifxlib.bld`.
3. Run `IFX_UNLOAD_MODULE` or restart Informix.
4. Remove the extension directory only after the module is no longer loaded.

## Automatic registration

`ifxlib` is a user-defined extension and does not participate in the automatic
registration used by DataBlade modules bundled with Informix. Registration is
explicit and database-specific.

## Official documentation

- [Replacing a loaded shared object](https://help.hcl-software.com/hclinformix/15.0/dbdk/ids_dbdk_274.html)
- [IFX_REPLACE_MODULE](https://help.hcl-software.com/hclinformix/1410/sqs/ids_sqs_1802.html)
- [IFX_UNLOAD_MODULE](https://help.hcl-software.com/hclinformix/1410/sqs/ids_sqs_1803.html)
- [Server modes and onmode](https://help.hcl-software.com/hclinformix/1410/adr/ids_adr_0422.html)
- [C UDR CLASS modifier](https://help.hcl-software.com/hclinformix/1410/sqs/ids_sqs_1722.html)
- [mi_yield()](https://www.ibm.com/docs/en/informix-servers/14.10?topic=descriptions-mi-yield-function)
- [Safe system calls in C UDRs](https://help.hcl-software.com/hclinformix/1410/dapip/ids_dapip_0678.html)
- [DATETIME conversion](https://help.hcl-software.com/hclinformix/1410/dapip/ids_dapip_0150.html)
