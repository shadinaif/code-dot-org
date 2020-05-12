FROM ubuntu:16.04

# OS Initialization
RUN apt-get -y update && apt-get install -y locales
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV HOME /root

# MySQL
RUN echo "deb http://cn.archive.ubuntu.com/ubuntu/ xenial main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections
RUN apt-get update && \
	apt-get -y install mysql-server-5.7 && \
	mkdir -p /var/lib/mysql && \
	mkdir -p /var/run/mysqld && \
	mkdir -p /var/log/mysql && \
	chown -R mysql:mysql /var/lib/mysql && \
	chown -R mysql:mysql /var/run/mysqld && \
	chown -R mysql:mysql /var/log/mysql
RUN sed -i -e "$ a [client]\n\n[mysql]\n\n[mysqld]"  /etc/mysql/my.cnf && \
	sed -i -e "s/\(\[client\]\)/\1\ndefault-character-set = utf8/g" /etc/mysql/my.cnf && \
	sed -i -e "s/\(\[mysql\]\)/\1\ndefault-character-set = utf8/g" /etc/mysql/my.cnf && \
	sed -i -e "s/\(\[mysqld\]\)/\1\ninit_connect='SET NAMES utf8'\ncharacter-set-server = utf8\ncollation-server=utf8_unicode_ci\nbind-address = 0.0.0.0/g" /etc/mysql/my.cnf
RUN apt-get install -y mysql-client-5.7 libmysqlclient-dev

# Pre-requisites
RUN apt-get install -y sudo git curl libreadline-dev apt-transport-https ca-certificates \
	libxslt1-dev libssl-dev zlib1g-dev imagemagick \
	libmagickcore-dev libmagickwand-dev \
	openjdk-9-jre-headless libcairo2-dev libjpeg8-dev libpango1.0-dev libgif-dev curl \
	pdftk enscript libsqlite3-dev build-essential redis-server rbenv chromium-browser

# NodeJs
ENV NVM_DIR $HOME/.nvm
ENV NODE_VERSION v8.15.0
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Ruby
ENV PATH $HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH
RUN curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash
RUN curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
RUN rbenv install 2.5.0
RUN rbenv global 2.5.0
RUN rbenv rehash

# Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get -y update && apt-get -y install yarn=1.16.0-1
ENV CHROME_BIN $(which chromium-browser)
RUN echo "export CHROME_BIN=$(which chromium-browser)" >> $HOME/.bashrc
RUN echo 'PATH="$(yarn global bin):$PATH"' >> $HOME/.bashrc

# Finalizing
RUN mkdir /code-dot-org
WORKDIR /code-dot-org
EXPOSE 3000 3306 33060
