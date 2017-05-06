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
python -m SimpleHTTPServer 80 &
PID=$!
echo "Starting certbot..."
certbot certonly --webroot -w $HOME -n --agree-tos --email ${EMAIL} --no-self-upgrade -d ${DOMAINS}
kill $PID
echo "Certbot finished. Killing http server..."

echo "Finiding certs. Exiting if certs are not found ..."
CERTPATH=/etc/letsencrypt/live/$(echo $DOMAINS | cut -f1 -d',')
ls $CERTPATH || exit 1

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
