minikube mount E:\Project\4thitek\postgres-data:/mnt/data/postgres


minikube start --nodes 4 -p multinode-demo

minikube node add --name=multinode-demo-m04
minikube node add