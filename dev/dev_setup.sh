#!/usr/bin/env bash

source /root/.bashrc

service mysql stop
service mysql start
sleep 5

gem install tzinfo-data
gem install bundler -v 1.17.1

while :; do echo 'Hit CTRL+C'; sleep 1; done

echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';" | mysql -u root -proot

echo "-------------------------------01------------------------------------"
rbenv rehash

echo "-------------------------------02------------------------------------"
bundle install

echo "-------------------------------03------------------------------------"
bundle exec rake install:hooks

echo "-------------------------------04------------------------------------"
bundle exec rake install

echo "-------------------------------05------------------------------------"
bundle exec rake build
echo "-------------------------------06------------------------------------"
