docker build -t lugomes/multi-client:latest -t lugomes/multi-client:$GIT_SHA -f ./client/Dockerfile ./client
docker build -t lugomes/multi-server:latest -t lugomes/multi-server$GIT_SHA -f ./server/Dockerfile ./server
docker build -t lugomes/multi-worker:latest -t lugomes/multi-worker$GIT_SHA -f ./worker/Dockerfile ./worker
docker push lugomes/multi-client:latest
docker push lugomes/multi-client:$GIT_SHA
docker push lugomes/multi-server:latest
docker push lugomes/multi-server:$GIT_SHA
docker push lugomes/multi-worker:latest
docker push lugomes/multi-worker:$GIT_SHA
kubectl apply -f k8s
kubectl set image deployments/server-deployment server=lugomes/multi-server:$GIT_SHA
kubectl set image deployments/client-deployment client=lugomes/multi-client:$GIT_SHA
kubectl set image deployments/worker-deployment worker=lugomes/multi-worker:$GIT_SHA