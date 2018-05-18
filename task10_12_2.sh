#!/bin/bash

d=`dirname $0`
cd $d

#дополнительно
. "$d/config"

#директории
mkdir $d/certs
mkdir $d/etc

#установка docker-ce
curl -fsSl https://download.docker.com/linux/ubuntu/gpg | apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get -yqq update
apt-get -yqq install docker-ce 
apt-get -yqq  install docker-compose

#загрузка образов
docker pull $NGINX_IMAGE
docker pull $APACHE_IMAGE

#генерация certs
openssl genrsa -out $d/certs/root.key 2048
openssl req -x509 -new \
        -key $d/certs/root.key \
        -days 365\
        -out $d/certs/root.crt \
        -subj '/C=UA/ST=Kharkiv/L=Kharkiv/O=Mirantis/OU=NURE/CN=rootCA'

openssl genrsa -out $d/certs/web.key 2048
openssl req -new \
        -key $d/certs/web.key \
        -nodes \
        -out $d/certs/web.csr \
        -subj "/C=UA/ST=Kharkiv/L=Kharkiv/O=Mirantis/OU=NURE/CN=$(hostname)"


openssl x509 -req -extfile <(printf "subjectAltName=IP:${EXTERNAL_IP},DNS:${HOST_NAME}")\
             -days 365 -in $d/certs/web.csr \
             -CA $d/certs/root.crt \
             -CAkey $d/certs/root.key \
             -CAcreateserial -out $d/certs/web.crt

cat $d/certs/web.crt $d/certs/root.crt > $d/certs/web-full.crt

# конфиг nginx
echo "server {
            listen 443;
            ssl on;
            ssl_certificate /etc/ssl/certs/web-full.crt;
            ssl_certificate_key /etc/ssl/certs/web.key;

           location / {
           proxy_pass http://apache
         }
 } " > $d/etc/nginx.conf

mkdir -p $NGINX_LOG_DIR

echo "version: '2'
services:
    nginx:
      image: $NGINX_IMAGE
      volumes:
        - /home/ubuntu/task10_12_2/etc:/etc/nginx/conf.d
        - /home/ubuntu/task10_12_2/certs:/etc/ssl/certs
        - $NGINX_LOG_DIR:/var/log/nginx
      ports:
          - $NGINX_PORT:443
    apache:
      image: $APACHE_IMAGE" > $d/docker-compose.yml

cd $d
docker-compose up -d
