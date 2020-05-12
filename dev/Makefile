dev.up:
	docker-compose -f docker-compose.yml -f docker-compose-site.yml -p "codeorg" up

dev.down:
	docker-compose -f docker-compose.yml -p "codeorg" down

dev.build:
	docker-compose -f docker-compose.yml -f docker-compose-setup.yml -p "codeorg" down || true
# 	docker volume rm codeorg_mysqldata || true
# 	docker volume rm codeorg_rbenv || true
# 	docker volume rm codeorg_yarncache || true
# 	docker-compose -f docker-compose.yml -f docker-compose-setup.yml -p "codeorg" build
	docker-compose -f docker-compose.yml -f docker-compose-setup.yml -p "codeorg" up -d
