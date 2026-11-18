# Projeto: ifxlib
# Arquivo: Makefile
# Versao: 1.4.6
# Criado em: 2026-11-13 10:28:59 -0300
# Criado por: ChatGPT - OpenAI
# Plataforma-alvo: HCL Informix 14.10, Linux x86_64 com GCC/compativel.

CC ?= cc
INFORMIXDIR ?= /opt/informix

MODULE_NAME := ifxlib
MODULE_VERSION := 1.4.UC1
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
	@test -n "$(INFORMIXDIR)" || { echo "INFORMIXDIR nao definido" >&2; exit 1; }
	@test -r "$(INFORMIXDIR)/incl/public/mi.h" || { echo "mi.h nao encontrado em $(INFORMIXDIR)/incl/public" >&2; exit 1; }

$(OBJECT): ifxlib.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJECT)
	$(CC) $(LDFLAGS) -o $@ $^

check: all
	@file "$(TARGET)"
	@nm -D --defined-only "$(TARGET)" | grep -E ' (sp_cpu_noarg|sp_cpu_set|sp_cpu_apply_policy|sp_current2)$$'
	@echo "Simbolos Informix esperados como indefinidos ate o carregamento pelo servidor:"
	@nm -D --undefined-only "$(TARGET)" | grep -E ' (mi_yield|mi_named_get|mi_named_zalloc|mi_lock_memory|mi_unlock_memory|mi_db_error_raise|mi_string_to_datetime)$$'
	@! nm -D --undefined-only "$(TARGET)" | grep -E ' dtcurrent$$'

deploy: check
	install -d -m 0755 "$(DEPLOY_DIR)"
	install -m 0755 "$(TARGET)" "$(DEPLOY_DIR)/$(TARGET)"
	install -m 0644 sql/register.sql "$(DEPLOY_DIR)/register.sql"
	install -m 0644 sql/unregister.sql "$(DEPLOY_DIR)/unregister.sql"
	install -m 0644 sql/test.sql "$(DEPLOY_DIR)/test.sql"
	install -m 0644 sql/fix_vp_class.sql "$(DEPLOY_DIR)/fix_vp_class.sql"
	install -m 0644 example_spl.sql "$(DEPLOY_DIR)/example_spl.sql"
	install -m 0644 example_benchmark.sql "$(DEPLOY_DIR)/example_benchmark.sql"
	install -m 0644 example_sysdbopen.sql "$(DEPLOY_DIR)/example_sysdbopen.sql"
	install -m 0644 README.md "$(DEPLOY_DIR)/README.md"
	install -m 0755 register.sh "$(DEPLOY_DIR)/register.sh"
	install -m 0755 unregister.sh "$(DEPLOY_DIR)/unregister.sh"
	@echo "ifxlib implantada em $(DEPLOY_DIR)"

install: deploy

register:
	@test -n "$(DB)" || { echo "Use: make register DB=nome_do_banco" >&2; exit 1; }
	@test -r "$(DEPLOY_DIR)/register.sql" || { echo "Execute make deploy primeiro" >&2; exit 1; }
	dbaccess "$(DB)" "$(DEPLOY_DIR)/register.sql"

unregister:
	@test -n "$(DB)" || { echo "Use: make unregister DB=nome_do_banco" >&2; exit 1; }
	@test -r "$(DEPLOY_DIR)/unregister.sql" || { echo "Modulo nao implantado em $(DEPLOY_DIR)" >&2; exit 1; }
	dbaccess "$(DB)" "$(DEPLOY_DIR)/unregister.sql"

test:
	@test -n "$(DB)" || { echo "Use: make test DB=nome_do_banco" >&2; exit 1; }
	dbaccess "$(DB)" "$(DEPLOY_DIR)/test.sql"

fix-vp:
	@test -n "$(DB)" || { echo "Use: make fix-vp DB=nome_do_banco" >&2; exit 1; }
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
	install -m 0755 register.sh "$(DIST_DIR)/$(MODULE_DIR)/register.sh"
	install -m 0755 unregister.sh "$(DIST_DIR)/$(MODULE_DIR)/unregister.sh"
	tar -C "$(DIST_DIR)" -czf "$(DIST_DIR)/$(MODULE_DIR).tar.gz" "$(MODULE_DIR)"
	@echo "Pacote criado: $(DIST_DIR)/$(MODULE_DIR).tar.gz"

help:
	@echo "make                  compila ifxlib.bld"
	@echo "make check            valida o binario e os simbolos exportados"
	@echo "make deploy           instala em \$$INFORMIXDIR/extend/$(MODULE_DIR)"
	@echo "make register DB=db   registra as UDRs no banco"
	@echo "make test DB=db       executa os testes SQL"
	@echo "make fix-vp DB=db     corrige CLASS invalida das versoes 1.4.0 a 1.4.2"
	@echo "make unregister DB=db remove as UDRs do banco"
	@echo "make package          gera o pacote DataBlade-style em dist/"

clean:
	rm -f "$(OBJECT)" "$(TARGET)"
	rm -rf "$(DIST_DIR)"
