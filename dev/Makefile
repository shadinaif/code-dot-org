SHELL := /bin/bash

# dev.up:
# 	docker-compose -f docker-compose.yml -f docker-compose-site.yml -p "codeorg" up
# 
# dev.down:
# 	docker-compose -f docker-compose.yml -p "codeorg" down
# 
# dev.build:
# 	docker-compose -f docker-compose.yml -f docker-compose-setup.yml -p "codeorg" down || true
# 	docker volume rm codeorg_mysqldata || true
# # 	docker volume rm codeorg_rbenv || true
# # 	docker volume rm codeorg_yarncache || true
# # 	docker-compose -f docker-compose.yml -f docker-compose-setup.yml -p "codeorg" build
# 	docker-compose -f docker-compose.yml -f docker-compose-setup.yml -p "codeorg" up


pre-requirements:  # install needed programs and clear existing venv
	sudo apt install virtualenv
	sudo rm -R ~/.virtualenvs/code-dot-org || true

requirements:  # install pip requirements inside the venv
	virtualenv --python=/usr/bin/python2.7 ~/.virtualenvs/code-dot-org

	source ~/.virtualenvs/code-dot-org/bin/activate && \
	pip install -r requirements.txt

	source ~/.virtualenvs/code-dot-org/bin/activate && \
	ansible-galaxy install rvm.ruby --force

deploy.dev:  # re-deploy everything
	source ~/.virtualenvs/code-dot-org/bin/activate && \
	cd ./playbooks/ && \
	ansible-playbook deploy.dev.yml -i ../inventory.yml -e@../../../code-dot-org_keys.yml
