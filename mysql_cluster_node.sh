#!/bin/sh

#MYSQL Cluster Data Node Script

#VARIABLES
GREEN='\033[1;32m'
NC='\033[0m'

MSC_DATA_NODE_URL=https://dev.mysql.com/get/Downloads/MySQL-Cluster-7.6/mysql-cluster-community-data-node_7.6.6-1ubuntu18.04_amd64.deb
DEPENDENCY=libclass-methodmaker-perl
CONF_FILE=/etc/my.cnf
NDBM_HOST=46.101.248.77
NODE_DATA_DIR=/usr/local/mysql/data

#DOWNLOAD PACKAGE
echo ${GREEN}Downloading MYSQL Cluster Data Node ...${NC}
cd ~
wget $MSC_DATA_NODE_URL

#INSTALL PREREQUISITES
echo ${GREEN}Installing dependency ...${NC}
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $DEPENDENCY|grep "install ok installed")
echo ${GREEN}Checking for $DEPENDENCY: $PKG_OK${NC}
if [ "" = "$PKG_OK" ]; then
  echo "No $DEPENDENCY. Setting up $DEPENDENCY."
  sudo apt update
  sudo apt install $DEPENDENCIES
fi

#INSTALL PACKAGE
echo ${GREEN}Installing package ...${NC}
sudo dpkg -i mysql-cluster-community-data-node_7.6.6-1ubuntu18.04_amd64.deb


#CREATE CONFIG FILE
echo ${GREEN}Creating my.cnf file ...${NC}
if [ ! -f $CONF_FILE ]; then
  echo "[mysql_cluster]" >> $CONF_FILE
  echo "ndb-connectstring=$NDBM_HOST"  >> $CONF_FILE
fi

#CREATE DATA DIRECTORY
echo ${GREEN}Creating Node data directory ...${NC}
sudo mkdir -p $NODE_DATA_DIR

#START MySQL Cluster Data node
echo ${GREEN}Starting MySql Cluster data node ...${NC}
sudo ndbd
