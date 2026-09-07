COMPOSE := docker compose

include .env
export

.PHONY: up install plugin verify down reset

up:
	$(COMPOSE) up -d --wait db wordpress gateway

install: up
	$(COMPOSE) run --rm cli core install \
		--url="http://localhost:$(WP_PORT)" \
		--title="Bug Bounty Lab" \
		--admin_user="$(WORDPRESS_ADMIN_USER)" \
		--admin_password="$(WORDPRESS_ADMIN_PASSWORD)" \
		--admin_email="$(WORDPRESS_ADMIN_EMAIL)" \
		--skip-email

plugin:
	test -n "$(PLUGIN)"
	test -f "plugins/$(PLUGIN)"
	$(COMPOSE) run --rm cli plugin install "/plugins/$(PLUGIN)" --activate

verify:
	@case "$$($(COMPOSE) port gateway 8080)" in \
		127.0.0.1:$(WP_PORT)) echo "localhost binding verified" ;; \
		*) echo "localhost binding verification failed"; exit 1 ;; \
	esac
	@result="$$($(COMPOSE) exec -T wordpress awk 'NR > 1 && ($$2 == "00000000" || $$3 != "00000000") { found = 1 } END { print found ? "available" : "blocked" }' /proc/net/route)" || { echo "wordpress egress verification failed"; exit 1; }; \
		case "$$result" in blocked) echo "wordpress egress blocked" ;; available) echo "wordpress egress is available"; exit 1 ;; *) echo "wordpress egress verification failed"; exit 1 ;; esac
	@result="$$($(COMPOSE) exec -T gateway awk 'NR > 1 && ($$2 == "00000000" || $$3 != "00000000") { found = 1 } END { print found ? "available" : "blocked" }' /proc/net/route)" || { echo "gateway egress verification failed"; exit 1; }; \
		case "$$result" in blocked) echo "gateway egress blocked" ;; available) echo "gateway egress is available"; exit 1 ;; *) echo "gateway egress verification failed"; exit 1 ;; esac

down:
	$(COMPOSE) down --remove-orphans

reset:
	$(COMPOSE) down --volumes --remove-orphans
