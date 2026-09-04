OUTPUT := openvas-deployment

SOURCES := \
	src/global.sh \
	src/args.sh \
	src/artifact.sh \
	src/certs.sh \
	src/certs_ec.sh \
	src/certs_openvasd.sh \
	src/certs_osi.sh \
	src/certs_scan.sh \
	src/deploy.sh \
	src/docker.sh \
	src/gen_passwords.sh \
	src/help.sh \
	src/init.sh \
	src/license.sh \
	src/openvasd.sh \
	src/requirements.sh \
	src/scan.sh \
	src/secrets.sh \
	src/secrets_ec.sh \
	src/secrets_osi.sh \
	src/settings.sh \
	src/settings_ec.sh \
	src/settings_openvasd.sh \
	src/settings_osi.sh \
	src/settings_scan.sh \
	src/main.sh

.PHONY: all clean

all: $(OUTPUT)

$(OUTPUT): $(SOURCES)
	@echo '#!/usr/bin/env bash' > $@
	@echo 'set -euo pipefail' >> $@
	@echo >> $@
	@for src in $(SOURCES); do \
		sed '1{/^#!.*\(ba\)\?sh/d;}' "$$src" >> $@; \
		echo >> $@; \
	done
	@chmod +x $@
	@echo "Created $@"

clean:
	rm -f $(OUTPUT)
