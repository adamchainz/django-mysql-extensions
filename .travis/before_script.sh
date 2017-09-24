#!/bin/bash

set -e
set -x

# percona-toolkit - have to use non-apt version since Travis' ubuntu 12.04 repo
# is way out of date
sudo apt-get update -qq
sudo apt-get install -y libio-socket-ssl-perl
wget https://www.percona.com/downloads/percona-toolkit/2.2.13/deb/percona-toolkit_2.2.13_all.deb
sudo dpkg -i percona-toolkit_2.2.13_all.deb

# MySQL

if [[ $DB == 'mysql' ]]
then
  if [[ $DB_VERSION == '5.5' ]]
  then
    # Travis default
    sudo service mysql restart
  else
    # Nuke default
    sudo apt-get -y purge mysql-server
    sudo apt-get -y autoremove --purge
    sudo rm -rf /var/lib/mysql
    # Install new
    echo "deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-$DB_VERSION" | sudo tee /etc/apt/sources.list.d/mysql.list >/dev/null
    echo "deb-src http://repo.mysql.com/apt/ubuntu/ trusty mysql-$DB_VERSION" | sudo tee -a /etc/apt/sources.list.d/mysql.list >/dev/null
    sudo apt-get update
    yes Y | sudo DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install mysql-server
  fi

elif [[ $DB == 'mariadb' ]]
then
  # Install
  sudo apt-get install -y software-properties-common
  sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
  sudo add-apt-repository "deb [arch=amd64,i386,ppc64el] http://sfo1.mirrors.digitalocean.com/mariadb/repo/$DB_VERSION/ubuntu trusty main"
  echo 'Package: *
Pin: origin sfo1.mirrors.digitalocean.com
Pin-Priority: 10000' | sudo tee /etc/apt/preferences.d/pin-mariadb.pref
  sudo cat /etc/apt/preferences.d/*
  curl icanhazip.com
  sudo apt-get update
  sudo apt-config dump
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client
fi

sudo mysql -u root -e "create user travis@localhost identified by '';" || true

sudo mysql -u root -e 'grant all privileges on *.* to travis@localhost;'
