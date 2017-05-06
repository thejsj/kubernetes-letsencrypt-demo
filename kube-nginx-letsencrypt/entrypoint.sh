#!/bin/bash

if [[ -z $EMAIL || -z $DOMAINS || -z $SECRET ]]; then
	echo "EMAIL, DOMAINS, and SECRET env vars required"
	env
	exit 1
fi
echo "EMAIL: $EMAIL"
echo "DOMAINS: $DOMAINS"
echo "SECRET: $SECRET"

NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
echo "NAMESPACE: $NAMESPACE"

cd $HOME
echo "HOME: $HOME"
python -m SimpleHTTPServer 80 &
PID=$!
echo "PID: $PID"
certbot certonly --webroot -w $HOME -n --agree-tos --email ${EMAIL} --no-self-upgrade -d ${DOMAINS}
kill $PID

CERTPATH=/etc/letsencrypt/live/$(echo $DOMAINS | cut -f1 -d',')
echo "DOMAINS: $DOMAINS"

ls $CERTPATH || exit 1

echo "** fullchain.pem:"
echo $(cat ${CERTPATH}/fullchain.pem | base64 | tr -d '\n')
echo "** privkey.pem:"
echo $(cat ${CERTPATH}/privkey.pem | base64 | tr -d '\n')
y
cat /secret-patch-template.json | \
	sed "s/NAMESPACE/${NAMESPACE}/" | \
	sed "s/NAME/${SECRET}/" | \
	sed "s/TLSCERT/$(cat ${CERTPATH}/fullchain.pem | base64 | tr -d '\n')/" | \
	sed "s/TLSKEY/$(cat ${CERTPATH}/privkey.pem |  base64 | tr -d '\n')/" \
	> /secret-patch.json

echo "CAT secrete-path.json"
cat /secret-patch.json

ls /secret-patch.json || exit 1

# update secret
curl -v --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -k -v -XPATCH  -H "Accept: application/json, */*" -H "Content-Type: application/strategic-merge-patch+json" -d @/secret-patch.json https://kubernetes/api/v1/namespaces/${NAMESPACE}/secrets/${SECRET}
