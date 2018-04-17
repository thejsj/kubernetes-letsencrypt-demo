# Kubernetes + Let's Encrypt Automatic Cert Generation

Demo for how to automatically create https certs on Kubernetes using Let's encrypt


docker build -t gcr.io/dht-2718/letsencrypt:testserver .
gcloud docker -- push gcr.io/dht-2718/letsencrypt:testserver

http://frameworthyfilms.com/.well-known/acme-challenge/blank

POD=$(kubectl get pods | grep nginx | awk '{print $1}')
kubectl exec $POD -it bash
apt-get update && apt-get install curl -qq -y # Terrible, I know
curl letsencrypt # Name of the service


docker build -t gcr.io/dht-2718/letsencrypt:getcreds .
gcloud docker -- push gcr.io/dht-2718/letsencrypt:getcreds


