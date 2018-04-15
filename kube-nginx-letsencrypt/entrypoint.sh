#!/bin/bash

if [[ -z $EMAIL || -z $DOMAINS || -z $SECRET ]]; then
	echo "EMAIL, DOMAINS, and SECRET env vars required"
	env
	exit 1
fi
echo "Inputs:"
echo " EMAIL: $EMAIL"
echo " DOMAINS: $DOMAINS"
echo " SECRET: $SECRET"


NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
echo "Current Kubernetes namespce: $NAMESPACE"

echo "Starting HTTP server..."
mkdir $HOME/.well-known
mkdir $HOME/.well-known/acme-challenge
echo "This is some text" > $HOME/.well-known/acme-challenge/blank
cd $HOME
python -m SimpleHTTPServer 80 &
PID=$!
echo "sleeping 1m"
sleep 1m
echo "Starting certbot..."
certbot certonly --webroot -w $HOME -n --agree-tos --email ${EMAIL} --no-self-upgrade -d ${DOMAINS}
echo "Certbot finished. Killing http server..."

ls $HOME
ls $HOME/.well-known
ls $HOME/.well-known/acme-challenge

echo "Finiding certs. Exiting if certs are not found ..."
CERTPATH=/etc/letsencrypt/live/$(echo $DOMAINS | cut -f1 -d',')
ls $CERTPATH || (echo "sleeping 60m";sleep 60m; exit 1)
kill $PID

echo "Creating update for secret..."
cat /secret-patch-template.json | \
	sed "s/NAMESPACE/${NAMESPACE}/" | \
	sed "s/NAME/${SECRET}/" | \
	sed "s/TLSCERT/$(cat ${CERTPATH}/fullchain.pem | base64 | tr -d '\n')/" | \
	sed "s/TLSKEY/$(cat ${CERTPATH}/privkey.pem |  base64 | tr -d '\n')/" \
	> /secret-patch.json

echo "Checking json file exists. Exiting if not found..."
ls /secret-patch.json || exit 1

# Update Secret
echo "Updating secret..."
curl \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  -XPATCH \
  -H "Accept: application/json, */*" \
  -H "Content-Type: application/strategic-merge-patch+json" \
  -d @/secret-patch.json https://kubernetes/api/v1/namespaces/${NAMESPACE}/secrets/${SECRET} \
  -k -v
echo "Done"
