# Function for WordPress code sniffer
phpcswp = docker run --rm \
    -v $(CURDIR)/$(CODE_BASE_DIR)/web/themes/custom:/work/themes \
    -v $(CURDIR)/$(CODE_BASE_DIR)/web/plugins/custom:/work/plugins \
    wimg/phpcs \
    --standard=WordPress \
    --extensions=php,inc,js,css \
    --ignore=node_modules/*,vendor/*,dist/* \
    .

## Validate codebase with WordPress Coding Standards
phpcs-wp:
	@echo "WordPress Coding Standards validation..."
	@$(call phpcswp, phpcs)

## Auto-fix codebase according to WordPress standards
phpcbf-wp:
	@$(call phpcswp, phpcbf)

## Add symbolic link from custom script(s) to .git/hooks/
hooksymlink:
ifneq ($(wildcard .git/.*),)
ifneq ("$(wildcard scripts/git_hooks/sniffers.sh)","")
	@echo "Removing previous git hooks and installing fresh ones"
	$(shell find .git/hooks -type l -exec unlink {} \;)
	$(shell ln -sf ../../scripts/git_hooks/sniffers.sh .git/hooks/pre-push)
else
	@echo "scripts/git_hooks/sniffers.sh file does not exist"
	@exit 1
endif
else
	@echo "No git directory found, git hooks won't be installed"
endif

## Validate composer.json file
compval:
	@echo "Composer.json validation..."
	@docker run --rm -v $(CURDIR)/$(CODE_BASE_DIR):/mnt -w /mnt $(IMAGE_PHP) composer validate

## Validate newline at the end of files
newlineeof:
ifneq ("$(wildcard scripts/makefile/newlineeof.sh)","")
	@/bin/sh ./scripts/makefile/newlineeof.sh
else
	@echo "scripts/makefile/newlineeof.sh file does not exist"
	@exit 1
endif

## Run sniffer validations (executed as git hook, by scripts/git_hooks/sniffers.sh)
sniffers: | compval phpcs-wp newlineeof

## Run all tests & validations (including sniffers)
tests: | sniffers

