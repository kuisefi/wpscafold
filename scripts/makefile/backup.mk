## Make backup from current state
mysql_dump_name = $(COMPOSE_PROJECT_NAME).sql
files_dir = web
datestamp=$(shell echo `date +'%Y-%m-%d'`)
backup_name = $(COMPOSE_PROJECT_NAME)-$(datestamp).tar.gz

backup:
	$(call php, mkdir -p ./backups)
	$(call php, rm -f ./backups/$(backup_name))
	$(call php, wp db export --skip-ssl './backups/$(mysql_dump_name)')
	$(call php, tar -czf ./backups/$(backup_name) ./web ./backups/$(mysql_dump_name) --exclude=./web/wp-content/cache --exclude=./web/wp-content/backups)
	$(call php, rm ./backups/$(mysql_dump_name))
