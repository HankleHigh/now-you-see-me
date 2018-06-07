#!/bin/bash
# Now You See Me
# brownee

NORMAL=`echo "\033[m"`
BRED=`printf "\e[1;31m"`
BGREEN=`printf "\e[1;32m"`
BYELLOW=`printf "\e[1;33m"`
COLUMNS=12

nysm_action() {
  printf "\n${BGREEN}[+]${NORMAL} $1\n"
}

nysm_warning() {
  printf "\n${BYELLOW}[!]${NORMAL} $1\n"
}

nysm_error() {
  printf "\n${BRED}[!] $1${NORMAL}\n"
}

error_exit() {
  echo -e "\n$1\n" 1>&2
  exit 1
}

check_errors() {
  if [ $? -ne 0 ]; then
    nysm_error "An error occurred..."
    error_exit "Exiting..."
  fi
}

nysm_confirm() {
  read -r -p "$1 [y/N] " response
  case "$response" in
      [yY][eE][sS]|[yY])
          return 0
          ;;
      *)
          return 1
          ;;
  esac
}

nysm_install() {
  CONF_DST="/etc/nginx/sites-enabled/default"

  nysm_action "Installing Dependencies..."
  apt-get install -y vim less

  nysm_action "Updating apt-get..."
  apt-get update
  check_errors

  nysm_action "Installing general net tools..."
  apt-get install -y inetutils-ping net-tools screen dnsutils curl
  check_errors

  nysm_action "Installing nginx, certbot..."
  apt-get install -y nginx python-certbot-nginx
  check_errors

  nysm_action "Finished installing dependencies!"
}

nysm_initialize() {
  nysm_action "Modifying nginx configs..."
  cp ./default.conf $CONF_DST
  read -r -p "What is the sites domain name? (ex: google.com) " domain_name
  sed -i.bak "s/<DOMAIN_NAME>/$domain_name/" $CONF_DST
  rm $CONF_DST.bak
  read -r -p "What is the C2 server address? (IP:Port) " c2_server
  sed -i.bak "s/<C2_SERVER>/$c2_server/" $CONF_DST
  rm $CONF_DST.bak
  check_errors

  SSL_SRC="/etc/letsencrypt/live/$domain_name"
  nysm_action "Obtaining Certificates..."
  certbot certonly -a webroot --webroot-path=/var/www/html -d $domain_name
  check_errors

  nysm_action "Installing Certificates..."
  sed -i.bak "s/^#nysm#//g" $CONF_DST
  rm $CONF_DST.bak
  check_errors

  nysm_action "Restarting Nginx..."
  systemctl restart nginx.service
  check_errors

  nysm_action "Done!"
}

nysm_setup() {
  nysm_install
  nysm_initialize
}

nysm_status() {
  printf "\n************************ Processes ************************\n"
  ps aux | grep -E 'nginx' | grep -v grep

  printf "\n************************* Network *************************\n"
  netstat -tulpn | grep -E 'nginx'
}

PS3="
NYSM - Select an Option:  "

finshed=0
while (( !finished )); do
  printf "\n"
  options=("Setup Nginx Redirector" "Check Status" "Quit")
  select opt in "${options[@]}"
  do
    case $opt in
      "Setup Nginx Redirector")
        nysm_setup
        break;
        ;;
      "Check Status")
        nysm_status
        break;
        ;;
      "Quit")
        finished=1
        break;
        ;;
      *) nysm_warning "invalid option" ;;
    esac
  done
done
