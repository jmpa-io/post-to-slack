PROJECT = post-to-slack

---: ## ---

# include common targets.
include $(shell while [[ ! -d .git ]]; do cd ..; done; pwd)/Makefile.common.mk
