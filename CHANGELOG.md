# ifxlib changelog

Document version: 1.4.9  
Created: 2026-11-18 09:23:03 -0300  
Created by: ChatGPT - OpenAI

## 1.4.9 - 2026-11-18

- `register.sh` now accepts multiple database names.
- Added `register.sh -all` to register every non-system database.
- System databases are excluded through the `sys*` naming convention.
- Translated source comments, scripts, SQL examples, messages, and
  documentation to English.
- Reviewed the repository for environment-specific server, database, user,
  and path references; examples now use generic values.
- Reorganized `README.md` around features, licensing, installation, and both
  supported update procedures.
- Added the MIT License.
- Standardized routine examples on `CREATE OR REPLACE` and cleanup scripts on
  `DROP ... IF EXISTS`.

## 1.4.8 - 2026-11-18

- Made `example_spl.sql` self-contained.
- Added status rows through `RETURN WITH RESUME`.
- Each row reports the stage, loop counter, `sp_current2()` time, and
  `sp_cpu()` interval.
- Added execution and cleanup of the demonstration routine.
- Standardized `CREATE OR REPLACE PROCEDURE` and `DROP PROCEDURE IF EXISTS`.
- Restored the default session interval before the example exits.

## 1.4.7 - 2026-11-13

- Reorganized installation and update documentation.
- Added detection of existing installations to `install.sh`.
- Added choices for a new directory, offline overwrite, or cancellation.
- Blocked overwrite when `onstat` confirms that Informix is running.
- Required `IFXLIB_INSTALL_MODE=new|overwrite` for non-interactive execution.
- Made `make deploy` reject an existing target by default.
- Added automatic selection of the next available `UCn` suffix.
- Added automatic rewriting of `register.sql` for the selected directory.
- Made registration scripts locate SQL files relative to their deployed path.

## 1.4.6 - 2026-11-13

- Removed `dtcurrent()` from `sp_current2()`.
- Read the clock directly through `gettimeofday()`.
- Added thread-safe local-time conversion through `localtime_r()`.
- Added ANSI-to-DATETIME conversion through `mi_string_to_datetime()`.
- Removed the build dependency on `datetime.h`.
- Added a binary validation that rejects a new `dtcurrent` dependency.

## 1.4.5 - 2026-11-12

- Replaced `counter % effective_interval` with a simple comparison.
- Yield now occurs when `counter >= effective_interval`.
- Preserved the effective yield frequency for every supported interval.
- Removed an integer-division operation from each `sp_cpu()` call.

## 1.4.4 - 2026-11-12

- Added the optional `sp_ifxlib_benchmark()` cursor function.
- Added one million `FOREACH SELECT` catalog operations.
- Added progress rows with `sp_current2()` and elapsed seconds.
- Added comparison scenarios for `-1`, `0`, `1000`, and `10000`.
- Kept the expensive benchmark outside `test.sql`.

## 1.4.3 - 2026-11-12

- Removed the invalid `cpu vp` class from UDR registrations.
- Allowed C UDRs to use the default CPU VP by omitting `CLASS`.
- Added `fix_vp_class.sql` for registrations created by 1.4.0 through 1.4.2.
- Added examples for every provided routine.

## 1.4.2 - 2026-11-12

- Reworked the README as operational documentation.
- Documented offline and online update procedures.
- Documented safe retirement and deletion of an old module version.
- Documented complete uninstallation.
- Clarified that automatic registration is limited to DataBlade modules
  bundled with Informix.

## 1.4.1 - 2026-11-12

- Accepted `datetime.h` under `incl/public`, `incl/esql`, or `incl`.
- Removed duplicate `make check` execution from `install.sh`.
- Kept the `ifxlib.1.4.UC1` module directory and existing UDR behavior.

## 1.4.0 - 2026-11-12

- Renamed the project to `ifxlib`.
- Renamed the main source file to `ifxlib.c`.
- Built the library as `ifxlib.bld`.
- Added deployment to `$INFORMIXDIR/extend/ifxlib.1.4.UC1`.
- Replaced the `install.sql.in` template with static registration SQL.
- Added registration, unregistration, and validation SQL files.
- Added installation, registration, and unregistration shell scripts.
- Added Make targets for deployment, registration, testing, and packaging.
- Moved named-memory state to the `ifxlib` namespace.

## 1.3.0 - 2026-10-29

- Reserved interval `-1` for completely disabling yielding.
- Made disabled mode return without incrementing the counter.
- Added disabled-mode behavior to normal and administrative session policies.
- Kept values below `-1` invalid.

## 1.2.0 - 2026-10-29

- Added `sp_cpu_apply_policy(admin_force, admin_interval)`.
- Added per-session administrative priority without a control table.
- Defined overridable and forced policy modes.
- Added a `sysdbopen` integration example.
- Added named-memory locking and zero-initialized allocation.
- Changed the internal state name for compatibility.

## 1.1.0 - 2026-09-09

- Renamed the clock routine to `sp_current2()`.
- Renamed the yield procedure to `sp_cpu()`.
- Added `sp_cpu(INTEGER)` for per-session interval configuration.
- Added `PER_SESSION` named state instead of shared global variables.
- Added `sp_yield()` compatibility aliases.
- Defined zero as yield-always and rejected negative values at that release.

## 1.0.0 - 2026-09-09

- Added `ifx_yield_cpu()` using `mi_yield()`.
- Added `ifx_current_realtime()` using `dtcurrent()`.
- Added the original Makefile, SQL registration, test, example, and removal
  scripts.
