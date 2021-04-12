sc := php bin/console
user := $(shell id -u)
group := $(shell id -g)
dc := USER_ID=$(user) GROUP_ID=$(group) docker-compose
drtest := $(dc) -f docker-compose.test.yml run --rm 
drprod := $(dc) -f docker-compose.prod.yml exec -T
php := $(drprod) php
de := docker-compose exec
domain := $(DEPLOY_DOMAIN)
server := "$(DEPLOY_USER)@$(domain)" 
dir := $(DEPLOY_DIR) 

.DEFAULT_GOAL := help
help: ### Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


deploy: ### Déploie une nouvelle version du site
	ssh -p $(DEPLOY_PORT) $(server) 'cd $(dir) && git pull origin main && make prod && make install && make prod'

admin: ### Génère le dashboard admin
	$(sc) make:admin:dashboard

crud: ### Crée un Crud
	$(sc) make:admin:crud

entity: ### Crée une entité
	$(sc) make:entity

controller: ### Crée un controller
	$(sc) make:controller

form: ### Crée un controller
	$(sc) make:form

migration: ### Crée une migration
	$(sc) make:migration

migrate: ### Lance la migration
	$(sc) doctrine:migrations:migrate

rollback:
	$(sc) doctrine:migrations:migrate prev

ftest: ### Crée un test fonctionnel
	$(sc)  make:functional-test

utest: ### Crée un test unitaire
	$(sc) make:unit-test

test: vendor/autoload.php ## Execute les tests
	APP_ENV=test $(drtest) phptest symfony console doctrine:schema:validate --skip-sync
	APP_ENV=test $(drtest) phptest bash -c "php -d memory_limit=-1 /var/www/vendor/bin/pest"

dev: ### Lancer le serveur de développement
	$(dc) up -d --remove-orphans
	symfony serve

seed:
	$(sc) hautelook:fixtures:load

cc: ### Clear cache in dev
	$(sc) cache:clear
	$(sc) cache:pool:clear cache.global_clearer

install: ### Installe les différentes dépendances
	APP_ENV=prod APP_DEBUG=0 COMPOSE_HTTP_TIMEOUT=200 $(php) composer install --no-dev --optimize-autoloader --no-scripts
	APP_ENV=prod APP_DEBUG=0 $(php) symfony console doctrine:database:create --if-not-exists --env=prod
	APP_ENV=prod APP_DEBUG=0 $(php) symfony console doctrine:migrations:migrate --no-interaction --env=prod
	APP_ENV=prod APP_DEBUG=0 $(php) symfony console cache:clear --env=prod
	APP_ENV=prod APP_DEBUG=0 $(php) symfony console cache:pool:clear cache.global_clearer --env=prod
	APP_ENV=prod APP_DEBUG=0 $(php) composer dump-autoload

opendb: ### Entre dans le service de base de données
	$(dc) -f docker-compose.prod.yml exec db mysql -uroot -pfredkiss

down: ### éteint le serveur
	$(dc) -f docker-compose.prod.yml down --remove-orphans

format: ### Format the files
	./vendor/bin/php-cs-fixer fix -v ./src

analyze: ### Verify if all the services had been autowired correctly & Make a static analyze
	$(sc) lint:container
	./vendor/bin/phpstan analyse  --level=1 ./src

prod: ### Start Production server
	make down
	APP_ENV=prod APP_DEBUG=0 $(dc) -f docker-compose.prod.yml up -d --remove-orphans

tt:
	./vendor/bin/pest
