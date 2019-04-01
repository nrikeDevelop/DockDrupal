#!/bin/bash

function is_root(){
	if [ "$(id -u)" != "0" ]; then
   		echo "This script must be run as root" 1>&2
   		exit 1
	fi
}

function die(){
	exit 0;
}

##print with color
NC='\033[0m' # No Color
function echo_e(){
	case $1 in 
		red)	echo -e "\033[0;31m$2 ${NC} " ;;
		green) 	echo -e "\033[0;32m$2 ${NC} " ;;
		yellow) echo -e "\033[0;33m$2 ${NC} " ;;
		blue)	echo -e "\033[0;34m$2 ${NC} " ;;
		purple)	echo -e "\033[0;35m$2 ${NC} " ;;
		cyan) 	echo -e "\033[0;36m$2 ${NC} " ;;
		*) echo $1;;
	esac
}

function banner(){
echo_e yellow "*--------------*" 
echo_e green "  DockDrupal"
echo ""
echo "  This configuration use 80 and 3306. Stop local services"
echo_e yellow "*--------------*" 
}

function set_workspace(){
	echo ""
	echo -ne "Select workspace path: "
	read WORKSPACE
	if [ -d $WORKSPACE ]
	then
		echo_e red "[-] Workspace already exist"
		die
	else
		mkdir $WORKSPACE
	fi

	echo -ne "Project name: "
	read PROJECT_NAME
	echo_e green "[+] Workspace created"
	echo ""
}

function set_mysql_configuration(){
	echo -ne "mysql user : "
	read USER
	echo -ne "mysql password : "
	read PASSWORD
	echo -ne "mysql database : "
	read DATABASE
	echo_e green "[+] Mysql data configured"
	echo ""
}

function set_docker_configurations(){
	echo_e yellow "[?] Getting lastest images"
	docker pull mariadb
	docker pull drupal

	#get last html of drupal
	docker run -tid --name remove_container drupal
	docker cp remove_container:/var/www/html $WORKSPACE/html
	docker rm -f remove_container

	#create docker compose
	echo ' 
version: "2.2"
services:
 '$PROJECT_NAME'_web:
  image: drupal
  links:
   - "'$PROJECT_NAME'_db"
  ports:
  - "80:80"
 '$PROJECT_NAME'_db:
  image: mariadb
  environment:
   MYSQL_USER: '$USER'
   MYSQL_PASSWORD: '$PASSWORD'
   MYSQL_DATABASE: '$DATABASE'
   MYSQL_ROOT_PASSWORD: ""
   MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
  ports:
   - "3306:3306"
  #restart: always
'>> $WORKSPACE/docker-compose.yaml
}

function create_control_files(){
echo '
#!/bin/bash
docker-compose up -d
'>> $WORKSPACE/start.sh

chmod +x $WORKSPACE/start.sh

echo '
#!/bin/bash
docker-compose stop
'>> $WORKSPACE/stop.sh
chmod +x $WORKSPACE/stop.sh


}

#MAIN
is_root
banner
set_workspace
set_mysql_configuration
set_docker_configurations

create_control_files

cd $WORKSPACE
docker-compose up -d 

echo ""
echo ""
echo_e yellow "To start project ./start.sh"
echo_e yellow "To stop project ./stop.sh"
echo ""
echo_e yellow "!!IMPORTANT¡¡"
echo_e yellow "To configure database correctly, you must enter ip into web configuration , not localhost or 127.0.0.1"
echo ""



