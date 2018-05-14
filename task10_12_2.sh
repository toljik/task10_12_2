#!/bin/bash

d=`dirname $0`
cd $d

#дополнительно
. "$d/config"


mkdir $d/certs
mkdir $d/etc



#install docker-ce
curl -fsSl https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
  'deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable'
apt-get update
apt-get install docker-ce -y 


#generate certs
openssl genrsa -out $d/certs/root-ca.key 2048
openssl req -x509 -new \
        -key $d/certs/root-ca.key \ 
        -days 365 \
        -out $d/certs/root-ca.crt \
        -subj '/C=UA/ST=Kharkiv/L=Kharkiv/O=Mirantis/OU=NURE/CN=rootCA'

openssl genrsa -out $d/certs/web.key 2048
openssl req -new \
        -key $d/certs/web.key \
        -nodes \
        -out $d/certs/web.csr \
         -subj "/C=UA/ST=Kharkiv/L=Kharkiv/O=Mirantis/OU=NURE/CN=$(hostname)"


opensll x509 -req -extfile <(printf "subjectAltName=IP:$EXTERNAL_IP,DNS:$HOST_NAME") \
             -days 365 in $d/certs/web.csr \
             -CA $d/certs/root-ca.crt \
             -CAkey $d/certs/root-ca.key \
             -CAcreateserial -out $d/certs/web.crt
