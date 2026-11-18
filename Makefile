# Project: ifxlib
# File: Makefile
# Version: 1.4.9
# Created: 2026-11-18 09:23:03 -0300
# Created by: ChatGPT - OpenAI
# Target: HCL Informix 14.10, Linux x86_64, GCC or a compatible compiler.

CC ?= cc
INFORMIXDIR ?= /opt/informix

MODULE_NAME := ifxlib
MODULE_VERSION ?= 1.4.UC1
MODULE_DIR := $(MODULE_NAME).$(MODULE_VERSION)
TARGET := $(MODULE_NAME).bld
OBJECT := $(MODULE_NAME).o
DEPLOY_ROOT := $(INFORMIXDIR)/extend
DEPLOY_DIR := $(DEPLOY_ROOT)/$(MODULE_DIR)
DIST_DIR := dist

CPPFLAGS += -DMI_SERVBUILD \
	-I$(INFORMIXDIR)/incl/public \
	-I$(INFORMIXDIR)/incl \
	-I$(INFORMIXDIR)/incl/esql

CFLAGS += -O2 -fPIC -Wall -Wextra
LDFLAGS += -shared

.PHONY: all clean check-env check deploy install register unregister test fix-vp package help

all: check-env $(TARGET)

check-env:
	@test -n "$(INFORMIXDIR)" || { echo "INFORMIXDIR is not set" >&2; exit 1; }
	@test -r "$(INFORMIXDIR)/incl/public/mi.h" || { echo "mi.h was not found in $(INFORMIXDIR)/incl/public" >&2; exit 1; }

$(OBJECT): ifxlib.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJECT)
	$(CC) $(LDFLAGS) -o $@ $^

check: all
	@file "$(TARGET)"
	@nm -D --defined-only "$(TARGET)" | grep -E ' (sp_cpu_noarg|sp_cpu_set|sp_cpu_apply_policy|sp_current2)$$'
	@echo "Informix symbols expected to remain undefined until the server loads the module:"
	@nm -D --undefined-only "$(TARGET)" | grep -E ' (mi_yield|mi_named_get|mi_named_zalloc|mi_lock_memory|mi_unlock_memory|mi_db_error_raise|mi_string_to_datetime)$$'
	@! nm -D --undefined-only "$(TARGET)" | grep -E ' dtcurrent$$'

deploy: check
	@if [ -e "$(DEPLOY_DIR)/$(TARGET)" ] && [ "$(ALLOW_OVERWRITE)" != "1" ]; then \
		echo "ERROR: $(DEPLOY_DIR)/$(TARGET) already exists." >&2; \
		echo "Use ./install.sh to choose a safe installation mode." >&2; \
		exit 1; \
	fi
	install -d -m 0755 "$(DEPLOY_DIR)"
	install -m 0755 "$(TARGET)" "$(DEPLOY_DIR)/$(TARGET)"
	sed 's|ifxlib\.1\.4\.UC1|$(MODULE_DIR)|g' sql/register.sql > "$(DEPLOY_DIR)/register.sql.tmp"
	install -m 0644 "$(DEPLOY_DIR)/register.sql.tmp" "$(DEPLOY_DIR)/register.sql"
	rm -f "$(DEPLOY_DIR)/register.sql.tmp"
	install -m 0644 sql/unregister.sql "$(DEPLOY_DIR)/unregister.sql"
	install -m 0644 sql/test.sql "$(DEPLOY_DIR)/test.sql"
	install -m 0644 sql/fix_vp_class.sql "$(DEPLOY_DIR)/fix_vp_class.sql"
	install -m 0644 example_spl.sql "$(DEPLOY_DIR)/example_spl.sql"
	install -m 0644 example_benchmark.sql "$(DEPLOY_DIR)/example_benchmark.sql"
	install -m 0644 example_sysdbopen.sql "$(DEPLOY_DIR)/example_sysdbopen.sql"
	install -m 0644 README.md "$(DEPLOY_DIR)/README.md"
	install -m 0644 CHANGELOG.md "$(DEPLOY_DIR)/CHANGELOG.md"
	install -m 0644 LICENSE "$(DEPLOY_DIR)/LICENSE"
	install -m 0755 register.sh "$(DEPLOY_DIR)/register.sh"
	install -m 0755 unregister.sh "$(DEPLOY_DIR)/unregister.sh"
	@echo "ifxlib deployed to $(DEPLOY_DIR)"

install: deploy

register:
	@test -n "$(DB)" || { echo "Usage: make register DB=database" >&2; exit 1; }
	@test -r "$(DEPLOY_DIR)/register.sql" || { echo "Run make deploy first" >&2; exit 1; }
	dbaccess "$(DB)" "$(DEPLOY_DIR)/register.sql"

unregister:
	@test -n "$(DB)" || { echo "Usage: make unregister DB=database" >&2; exit 1; }
	@test -r "$(DEPLOY_DIR)/unregister.sql" || { echo "Module not deployed to $(DEPLOY_DIR)" >&2; exit 1; }
	dbaccess "$(DB)" "$(DEPLOY_DIR)/unregister.sql"

test:
	@test -n "$(DB)" || { echo "Usage: make test DB=database" >&2; exit 1; }
	dbaccess "$(DB)" "$(DEPLOY_DIR)/test.sql"

fix-vp:
	@test -n "$(DB)" || { echo "Usage: make fix-vp DB=database" >&2; exit 1; }
	dbaccess "$(DB)" sql/fix_vp_class.sql

package: check
	rm -rf "$(DIST_DIR)/$(MODULE_DIR)"
	install -d -m 0755 "$(DIST_DIR)/$(MODULE_DIR)"
	install -m 0755 "$(TARGET)" "$(DIST_DIR)/$(MODULE_DIR)/$(TARGET)"
	install -m 0644 sql/register.sql "$(DIST_DIR)/$(MODULE_DIR)/register.sql"
	install -m 0644 sql/unregister.sql "$(DIST_DIR)/$(MODULE_DIR)/unregister.sql"
	install -m 0644 sql/test.sql "$(DIST_DIR)/$(MODULE_DIR)/test.sql"
	install -m 0644 sql/fix_vp_class.sql "$(DIST_DIR)/$(MODULE_DIR)/fix_vp_class.sql"
	install -m 0644 example_spl.sql "$(DIST_DIR)/$(MODULE_DIR)/example_spl.sql"
	install -m 0644 example_benchmark.sql "$(DIST_DIR)/$(MODULE_DIR)/example_benchmark.sql"
	install -m 0644 example_sysdbopen.sql "$(DIST_DIR)/$(MODULE_DIR)/example_sysdbopen.sql"
	install -m 0644 README.md "$(DIST_DIR)/$(MODULE_DIR)/README.md"
	install -m 0644 CHANGELOG.md "$(DIST_DIR)/$(MODULE_DIR)/CHANGELOG.md"
	install -m 0644 LICENSE "$(DIST_DIR)/$(MODULE_DIR)/LICENSE"
	install -m 0644 SHA256SUMS.txt "$(DIST_DIR)/$(MODULE_DIR)/SHA256SUMS.txt"
	install -m 0755 register.sh "$(DIST_DIR)/$(MODULE_DIR)/register.sh"
	install -m 0755 unregister.sh "$(DIST_DIR)/$(MODULE_DIR)/unregister.sh"
	tar -C "$(DIST_DIR)" -czf "$(DIST_DIR)/$(MODULE_DIR).tar.gz" "$(MODULE_DIR)"
	@echo "Package created: $(DIST_DIR)/$(MODULE_DIR).tar.gz"

help:
	@echo "make                  build ifxlib.bld"
	@echo "make check            validate the binary and exported symbols"
	@echo "make deploy           deploy only when the destination does not exist"
	@echo "./install.sh          install interactively with online-overwrite protection"
	@echo "make register DB=db   register the UDRs in one database"
	@echo "make test DB=db       run the SQL tests"
	@echo "make fix-vp DB=db     fix the invalid CLASS used by versions 1.4.0 through 1.4.2"
	@echo "make unregister DB=db unregister the UDRs from one database"
	@echo "make package          create a DataBlade-style package under dist/"

clean:
	rm -f "$(OBJECT)" "$(TARGET)"
	rm -rf "$(DIST_DIR)"
