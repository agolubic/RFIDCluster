#!/bin/sh
#CREATE CONFIG FILE

#VARIABLES
GREEN='\033[1;32m'
NC='\033[0m'

MSC_MANAGER_PKG_URL='https://dev.mysql.com/get/Downloads/MySQL-Cluster-7.6/mysql-cluster-community-management-server_7.6.6-1ubuntu18.04_amd64.deb';
MSC_FILE_NAME='mysql_cluster_manager.deb'
MSC_BASE_DIRECTORY=/var/lib/mysql-cluster2
MSC_CONFIGURATION=/var/lib/mysql-cluster2/config.ini
MSC_NUM_REPLICAS=1
MSC_HOST='46.101.248.77'
MSC_DATA_NODE_HOSTS=()
MSC_DATA_DIR=/usr/local/mysql/data
MSC_SQL_HOST='46.101.248.77'
MSC_SYSTEMD='/etc/systemd/system/ndb_mgmd.service'

#FUNCTIONS
checkOption() {
  if [ "" = "${i#*=}" ]; then echo bad option: $i; exit 1; fi
}

createService() {
  echo "" >> $MSC_SYSTEMD
  echo "[Unit]" >> $MSC_SYSTEMD
  echo "Description=MySQL NDB Cluster Management Server" >> $MSC_SYSTEMD
  echo "After=network.target auditd.service" >> $MSC_SYSTEMD
  echo "" >> $MSC_SYSTEMD
  echo "[Service]" >> $MSC_SYSTEMD
  echo "Type=forking" >> $MSC_SYSTEMD
  echo "ExecStart=/usr/sbin/ndb_mgmd -f $MSC_CONFIGURATION" >> $MSC_SYSTEMD
  echo "KillMode=process" >> $MSC_SYSTEMD
  echo "Restart=on-failure" >> $MSC_SYSTEMD
  echo "" >> $MSC_SYSTEMD
  echo "[Install]" >> $MSC_SYSTEMD
  echo "WantedBy=multi-user.target" >> $MSC_SYSTEMD
}

createConfiguration() {
  echo "[ndbd default]" >> $MSC_CONFIGURATION
  echo "NoOfReplicas=$MSC_NUM_REPLICAS"  >> $MSC_CONFIGURATION
  echo "" >> $MSC_CONFIGURATION
  echo "[ndb_mgmd]" >> $MSC_CONFIGURATION
  echo "hostname=$MSC_HOST" >> $MSC_CONFIGURATION
  echo "datadir=$MSC_BASE_DIRECTORY" >> $MSC_CONFIGURATION

  HOSTS=( ${MSC_DATA_NODE_HOSTS//,/ } )
  count=2
  for h in ${HOSTS[@]}
  do
    echo "" >> $MSC_CONFIGURATION
    echo "[ndbd]" >> $MSC_CONFIGURATION
    echo "hostname=$h" >> $MSC_CONFIGURATION
    echo "NodeId=$count" >> $MSC_CONFIGURATION
    echo "datadir=$MSC_DATA_DIR" >> $MSC_CONFIGURATION

    #Allow incomming connection to data nodes
    sudo ufw allow from $h

    count=$(( $count + 1 ))
  done

  echo "" >> $MSC_CONFIGURATION
  echo "[mysqld]" >> $MSC_CONFIGURATION
  echo "hostname=$MSC_SQL_HOST" >> $MSC_CONFIGURATION
}

listVariables() {
  echo -e "${GREEN}MySql Cluster Manager package:${NC}             $MSC_MANAGER_PKG_URL"
  echo -e "${GREEN}MySql Cluster Manager base directory:${NC}      $MSC_BASE_DIRECTORY"
  echo -e "${GREEN}MySql Cluster Manager configuration file:${NC}  $MSC_CONFIGURATION"
  echo -e "${GREEN}MySql Cluster Manager number of replicas:${NC}  $MSC_CONFIGURATION"
  echo -e "${GREEN}MySql Cluster Manager host:${NC}                $MSC_HOST"
  echo -e "${GREEN}MySql Cluster Manager data nodes:${NC}          $MSC_DATA_NODE_HOSTS"
  echo -e "${GREEN}MySql Cluster Manager data node directory:${NC} $MSC_DATA_DIR"
  echo -e "${GREEN}MySql Cluster Manager SQL serve host:${NC}      $MSC_SQL_HOST"
  echo -e "${GREEN}MySql Cluster Manager service:${NC}             $MSC_SYSTEMD"
  exit 0
}

usage()
{
    echo "Usage: test [-p=package URL ] [-c=configuration path] [--node-hosts=192.168.1.1,192.168.1.2]| [-b=base dir path]"
    echo "Options:"
    echo "  -p, --package         sets MySql Cluster Manager package path."
    echo "  -b, --basedir         sets MySql Cluster Manager base directory path."
    echo "  -r, --replicas    sets MySql Cluster Manager number of replicas"
    echo "  -c, --configuration   sets MySql Cluster Manager configuration path. Will create new if does not exist."
    echo "  -l, --list            shows MySql Cluster Manager default settings."
    echo "  --mng-host            sets MySql Cluster Manager host address."
    echo "  --node-hosts          sets MySql Cluster Manager data nodes host address. Comma separated values (eg. 192.168.1.1,192.168.1.2,...)"
    echo "  --node-datadir        sets MySql Cluster Manager data node directory."
}

#CHECK USER INPUT
for i in "$@"
do
case $i in
    -p=*|--package=*)
        checkOption;
        MSC_MANAGER_PKG_URL="${i#*=}"
        shift # past argument=value
        ;;
    -b=*|--basedir=*)
        checkOption;
        MSC_BASE_DIRECTORY="${i#*=}"
        shift # past argument=value
        ;;
    -c=*|--configuration=*)
        checkOption;
        MSC_CONFIGURATION="${i#*=}"
        shift # past argument=value
        ;;
    -r=*|--replicas=*)
        checkOption;
        MSC_NUM_REPLICAS="${i#*=}"
        shift # past argument=value
        ;;
    --mng-host=*)
        checkOption;
        MSC_HOST="${i#*=}"
        shift # past argument=value
        ;;
    --node-hosts=*)
        checkOption;
        MSC_DATA_NODE_HOSTS="${i#*=}"
        shift # past argument=value
        ;;
    --node-datadir=*)
        checkOption;
        MSC_DATA_DIR="${i#*=}"
        shift # past argument=value
        ;;
    -h*|--help)
        usage
        exit 0
        ;;
    -l*|--list)
        listVariables
        ;;
    *)
        usage
        exit 1
        ;;
esac
done

#DOWNLOAD MySQL Cluster Manager Package
echo -e ${GREEN}Downloading MySql Cluster Manager ...${NC}
cd ~
wget $MSC_MANAGER_PKG_URL -O $MSC_FILE_NAME

#INSTALL MySQL Cluster Manager Package
echo -e ${GREEN}Installing MySql Cluster Manager ...${NC}
sudo dpkg -i $MSC_FILE_NAME

#CREATE MySQL Cluster Manager directory
echo -e ${GREEN}Creating MySql Cluster Manager base directory ...${NC}
sudo mkdir $MSC_BASE_DIRECTORY

#CREATE MySQL Cluster Manager Configuration File
echo -e ${GREEN}Creating MySql Cluster Manager config file ...${NC}
if [ ! -f $MSC_CONFIGURATION ]; then
  createConfiguration
fi

#CREATE SYSTEMD FOR MySQL Cluster Manager
echo -e ${GREEN}Creating MySql Cluster Manager service ...${NC}
if [ ! -f $MSC_SYSTEMD ]; then
  createService
fi

#START MySQL Cluster Manager
echo -e ${GREEN}Starting MySql Cluster Manager service ...${NC}
sudo systemctl daemon-reload
sudo systemctl start ndb_mgmd
sudo systemctl status ndb_mgmd
