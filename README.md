Notes on Udemy Course: [Docker and Kubernetes: The Complete Guide](https://www.udemy.com/course/docker-and-kubernetes-the-complete-guide)


- Why use Docker?
Because it makes it easy to install and run software without worrying about setup and dependencies.

- What is Docker?
Docker is a platform or ecosystem for creating and running containers.

The **Docker CLI** reaches out to **Docker Hub** and downloads an **Image** which contains all configs and dependencies required to run a program. The **Container** is an instance of an image or a running program of sorts with its own set of resources like memory, networking tech and hard drive space.

Docker for Mac contains two tools:
- **Docker Client (CLI)**: where we issue commands to
- **Docker Server (Daemon**): responsible for creating images, running containers, etc

![](images/1.png)
![](images/2.png)

Example: `docker run hello-world`
Output:
```
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
1b930d010525: Pull complete
Digest: sha256:fc6a51919cfeb2e6763f62b6d9e8815acbf7cd2e476ea353743570610737b752
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.
```

The Docker Server tries to find the requested image in the **image cache**. If it does not find it, it reaches out
to Docker Hub to download the file and store it in the cache.

- What is a Container?

Your OS Kernel is the intermediate between running processes and the hard disk. The requests are issued
from the program as **system calls** to the kernel to, for instance, write a file to disk.

We can segment out the HD to house different resources and their versions and hence run specific programs. This is called **namespacing**: isolating resources per process or group of processes. Then when the request is issued, the kernel figures out which segment of the HD to direct that to. **Control groups** are used to limit the amount of resources per process (memory, CPU, HD I/O, network bandwidth). A container encompasses all those aspects.

Note: Namespacing and control groups are specific to the Linux system, not Windows or MacOS. We then use a Linux virtual machine where containers will be created. The Linux kernel now is the one responsible for isolating hardware resources or limit access to them in your computer.

![](images/3.png)
![](images/4.png)
![](images/5.png)

- `docker run <image name>` - `docker run hello-world`
- `docker run <image name> command` - `docker run busybox ls` (overrides the image startup command), ls will list out files in the directory
- `docker ps` to list all containers currently running in your machine
- `docker ps --all` will list all containers ever created in your machine
- `docker run =  docker create + docker start`
- `docker create hello-world` and `docker start -a container_id` (the start will execute the primary startup command, use flag -a to attach to the container and print out its output, docker run does the log of the output automatically)
- `docker start -a container_id` can also be used to restart exited containers, but you cannot replace the command used the first time
- `docker system prune` to delete stopped containers and build cache (images fetched from docker hub)

```WARNING! This will remove:
  - all stopped containers
  - all networks not used by at least one container
  - all dangling images
  - all dangling build cache
```

- `docker logs container_id` to log information emitted from stopped containers, does not run the container!
- `docker stop container_id` allows some time for shutdown and cleanup but 10s later it issues a kill command (preferable)
- `docker kill container_id` shuts down the container immediately
- Example: `docker run redis` to startup a local redis server, then to run the redis-cli and have access to that container running the server (or put in other words run two programs inside the same container), we need to run `docker exec -it container_id redis-cli` (exec to execute a second command inside the same container, `-it` flag to send input text to the running container, -i to attach to STDIN of running program and -t to format output)
- `docker exec -it container_id sh` to drop into a shell inside the container
- `docker run -it busybox sh` to run and be dropped into a container shell

- **Dockerfile**: plain text file with configuration to define how our container should behave (programs it contains, what is does at startup). The Docker Client will hand it over to the Docker Server which will convert it to a usable image.

![](images/6.png)

Example: Create an image to run redis-server.
```
# Use an existing docker image as a base
FROM alpine

# Download and install a dependency
RUN apk add --update redis

# Tell the image what to do when it starts
# as a container
CMD ["redis-server"]
```

- Most important instructions: `FROM` to specify **base image**, `RUN` to execute commands when preparing the image and `CMD` to execute when image is used to startup a new container.

To build the image from the Dockerfile we run `docker build .`. That returns an image id which we use to then run the container with `docker run image_id`. Or we could also run `docker build -t lugomes/redis:latest .` to tag the image and avoid having to paste in the image id in the run command. Then you can run as `docker run lugomes/redis` (latest is used by default).

Specifying the base image is analogous to installing an OS in a computer to sort of create an initial infrastructure to further customize our system.

In detail, the step 2 uses the previously created image (base image) to create a temporary container and execute the run command. The container is then stopped and a temporary image is created with the FS snapshot with redis installed. Then step 3 takes the previous image and creates a new temporary container and sets the the primary command, then creates another image, the final output.

![](images/7.png)

If we run a second time, Docker uses the build cache which adds performance. If a new command is added, a temporary container is created for that step and new image outputted since this was not cached previously. If the order of operations changes, the cache is not used. So the lesson is: make changes as far down as possible to use cache for as much lines as possible :)
```
Sending build context to Docker daemon  2.048kB
Step 1/4 : FROM alpine
 ---> e7d92cdc71fe
Step 2/4 : RUN apk add --update gcc
 ---> Using cache
 ---> de277e133667
Step 3/4 : RUN apk add --update redis
 ---> Using cache
 ---> 168eeaace8c7
Step 4/4 : CMD ["redis-server"]
 ---> Using cache
 ---> fb6ef696a164
Successfully built fb6ef696a164
```

Side-note (not recommended): Manual image creation with docker commit
`docker run -it alpine sh`
`apk add --update redis`

In a second terminal:
`docker ps` to get id of running container
`docker commit -c 'CMD ["redis-server"]' container_id`
Then you can run the aforementioned generated image id.

Example:
Create a simple web application that simply shows number of visits.
Use node.js as web server and redis as in-memory datastore (in the example it stores number of visits).
Note: we could run both node app and redis inside the same container but if more containers are created (app scales), the redis instances will diverge in number of visits.
So to scale up the node server alone, we have to run the redis server in a separate conteiner. But these containers now need to talk to each other...

```
# Specify a base image
FROM node:alpine

WORKDIR /app

# Install some dependencies
COPY ./package.json ./
RUN npm install
COPY . .

# Default command
CMD ["npm", "start"]
```
Notes:
- Alpine image has very few programs pre-installed, not npm for instance. Alpine is a term in the Docker world for an image that is small as possible. The base image used here is `node:alpine` (repo:tag-name) to have npm installed.
- `COPY ./package.json ./` to copy over the file from your local filesystem into the temporary container filesystem.

![](images/8.png)

- Container port mapping: we tried to hit port 8080 but the traffic would not be directed to the available container ports. We need to specify an explicit port mapping! To do that, we pose a runtime constraint as `docker run -p 8080:8080 image-id` meaning forward incoming traffic to local machine port 8080 to container port 8080. The ports do not have to be identical!

- `WORKDIR /usr/app` and `COPY ./ ./` to avoid copying local files into the root directory (and potentially overriding default files created from the base image). It will then copy to the `/usr/app` directory. Any following command will be executed relative to this path in the container.

- `COPY ./ ./` below `RUN npm install` and `COPY ./package.json ./` so that dependencies are not installed again with app changes. Only rebuild if package.json changes.

- Be aware that currently changes in the app are not automatically copied over to the container FS. We would need to rebuild the image. There is extra configuration needed to manage hot reloading.

### Docker-compose

- We run the node app in one container and the redis server in another container (just running `docker run server` will do the trick). If we just run both in separate shells, they are not automatically going to talk to one another. We need to create some networking infrastructure between them! 
- There are two options: Docker CLI network features (complicated to use) or **Docker Compose**. We create a separate file `docker-compose.yml` to house commands we would normally write in the shell to the Docker CLI. Now the docker-compose CLI will parse our file and create the separate containers with the configurations we specified. Now docker-compose sort of takes over Docker CLI but allows us to issue commands much quicker and create infrastructure to run multiple containers in the background.

![](images/9.png)

![](images/10.png)
 
```
version: '3' # version of docker-compose
services: # service is a type of container
  redis-server:
    image: 'redis'
  node-app:
    build: . # look in the current dir and use the Dockerfile to create this image
    ports:
      - "4001:8081" # local machine to container port mapping
```

Note: **Creating the two services in the same docker-compose.yml file automatically creates the containers in the same network**, therefore allowing communication between them. To start up we run `docker-compose up`. We don't need to specify the image because it will auto look for the docker-compose.yml file. To rebuild images inside docker-compose file we run `docker-compose up --build`.

- `docker-compose up -d` to launch containers in the background and `docker-compose down` to stop them. `docker-compose ps` to print out the status of the containers built from the docker-compose.yml file. You need to be inside the directory where the yml file is located to be able to use `docker-compose ps` as opposed to `docker ps`.

- **Restart policies** in case our container crashes:
   - "no": never attempt to restart if container stops or crashes
   - always: always restart if container stops for any reason
   - on-failure: only restart if container stops with an error code
   - unless-stopped: always restart unless we forcibly stop it

For a web app for example we would use always restart policy since we always want it to be available. But for worker process we could use the on-failure policy since the exit would occur naturally after processing has finished.

## Development Workflow

Development > Testing > Deployment > Repeat

We usually push code to a development branch of sorts (e.g. `feature`) and create a pull request to merge that code into the `master` branch. The `master` branch should contain our clean working copy of our codebase whose changes will be automatically deployed to our hosting provider. When the PR is created, we setup a workflow to push our application to the `Travis CI` service (continuous integration provider that runs our app tests). Then, is tests ran successfully, we can merge our branch into master. Then we push again to `Travis CI` and finally have Travis CI push to `AWS Hosting` to deploy our app.

Where does Docker comes in?
It is not needed at all, it makes it easier to execute the tasks in the workflow though. 

We created a `Dockerfile.dev` with this custom name. To run that file we run `docker build -f Dockerfile.dev .`. After building we run `docker run -it -p 3000:3000 <container_id>`. To hot reload (incorporate source code changes without need to manually rebuild the image and re-run), we make use of `volumes`. We will no longer copy the FS over to the docker container but we will place references to the local machine instead, sort of like folder mapping. We run `docker run -it -p 3000:3000 -v /app/node_modules -v $(pwd):/app <image_id>`. To run tests, run `docker run -it <image-id> npm run test`.

For the prod environment we need a server to respond to incoming request. We make use of `nginx`, popular web server with little logic that is used to serve simple static content. So we create a separate `Dockerfile` that creates a production version of our web app using nginx to serve our static files created with the build. 

Caveat is that dependencies are only required to build the app, after we have the static files, we no longer need to dedicate all the space for that. We will need to make use of two base images, one for node and other for nginx, i.e. we say that the Dockerfile will have a `multi-step build process`, with two blocks of configs. The `build phase` uses node:alpine inage to build the app and the `run phase` will use nginx as the base image to copy over the build folder and serve it. The second phase does not copy the dependencies over, so we save space!

```
# Build Phase
FROM node:alpine as builder

WORKDIR /app

COPY ./package.json .
RUN npm install
COPY . .

RUN npm run build

# Run Phase
FROM nginx

COPY --from=builder /app/build /usr/share/nginx/html
```

## Continuous Integration and Deployment with AWS

`Travis CI` watches for anytime we push code to our remote repo. At that time, it pulls the code and does some work, usually testing and/or deployment. 

On web UI `travis-ci.org` we switch on the watch to our repo. We create a `travis.yml` file to tell Travis what to do: tell it we need a copy of Docker running, to build our image using Dockerfile.dev, how to run our test suite and finally how to depliy our code to AWS.

```
language: generic 
sudo: required
services:
  - docker

before_install:
  - docker build -t lugomes/docker-react -f Dockerfile.dev .

script:
  - docker run -e CI=true lugomes/docker-react npm run test
```

**AWS Elastic Beanstalk** is an easy way to run a single container app in production. Easy steps to create an instance of it in AWS, just include Docker config for the environment. Requests to our web app are then handled by a `load balancer` that routes requests to a virtual machine running Docker. It monitors the amount of traffic coming in to our dockerized app. If a threshold is reached it adds in more machines to handle traffic. So the benefit of this AWS service is scalability of our application!

More config in travis.yml to deploy after tests ran in Travis CI. 
Generated API keys using AWS IAM service that Travis CI can use to deploy our application. Those are added using Travis UI since we do not want to commit those. 
```
deploy:
  provider: elasticbeanstalk
  region: "us-east-2"
  app: "docker-react"
  env: "DockerReact-env"
  bucket_name: "elasticbeanstalk-us-east-2-789677611139" # S3 bucket
  bucket_path: "docker-react"
  on:
    branch: master
  access_key_id: $AWS_ACCESS_KEY
  secret_access_key: $AWS_SECRET_KEY
```

We created a PR and Travis CI klicked in to run the tests and allow merge to master. After we merge, Travis CI runs the tests on master another time and attempts to deploy. 

## Building a Multi-Container Application

Our app architecture:
![](./images/11.png)

The nginx server will route requests to either our React server (if a page is being requested) or the Express server (if information is being requested or updated). Pstgres is for permanent storage and Redis for temp one, caching.  

![](./images/12.png)

When we set an environment variable in the `docker-compose.yml` file, this variable is set at *run time*, not inside the image, only once the container is created! If you just setup the variable name, with no value, this means the variable is going to be taken from your computer!

# Kubernetes

- System to deploy dockerized (containerized) applications.

Scalability of applications: In our Fibonacci app we could have benefited from spinning up multiple containers for the worker part of the app since that was the limiting factor. This would be hard to achieve with Elastic Beanstalk since all containers would be replicated, not only the worker container. Kubernetes allows us to setup additional machines to run only more worker containers.

![](./images/13.png)

A Kubernetes cluster is the assembly of a master and one or more nodes. Each node is a computer or a virtual machine that can run different containers. The master controls what each node runs. The load balancer relays the outside requests to each node.
![](./images/14.png)

Kubernetes is a system for running different containers over different machines. We use it when we need to run many different containers with different images (scalability). 

In the development environment we use `Minikube` which is a command line tool (CLI) to setup a mini Kubernetes cluster in our local machines. In production we make use of `managed solutions` such as Amazon Elastic Container Service for Kubernetes (EKS) from Amazon or Google Cloud Kubernetes Engine (GKE) from Google to setup the cluster.

In dev mode we use minikube to setup the VM (or Node) to run our containers. `kubectl` is the CLI to interact with our cluster and manage what nodes are doing what and its used both locally and in production. 

![](./images/15.png)

Config files for Kubernetes create `objects`, not containers to feed into the `kubectl` to interpret and create `objects` in the k8s cluster.

Arguments to the config files explained:
- `kind` entry indicate the kind of object we want to make. Pod, Service, StatefulSet, ReplicaController are types. A `Pod` is used to run container(s), `Service` is used to setup networking.
- `apiVersion` defines the set of objects we can use. For instance `v1` allows access to: `componentStatus`, `configMap`, `Endpoints`, `Event`, `Namespace`, `Pod`. `apps/v1` gives access to: `ControllerRevision` and `StatefulSet`.
- `labels` and `selector` are used to map two objects inside the cluster. He mapped a `Service` to the `Pod` using a `component` key, could have used any other key such as `tier` just as well.
- `Pod` is a grouping of containers with a **similar purporse**, smallest thing we can deploy, if more than 1 container is run, it's because they are very thigtly integrated or in other words, one does not run without the other.
- `Service` types: `ClusterIP`, `NodePort`, `LoadBalancer` and `Ingress`. `NodePort` is the one that exposes the container to the outside world, only used for dev purposes, not prod enviorment. The `kube-proxy` routes the request to the appropriate service.
- To feed a config file to the `kubectl` CLI we run `kubectl apply -f <filename>`
- To print the status of created objects in the cluster we run `kubectl get pods` or `kubectl get services`.
- To access from the browser we need to first get the IP address of our VM with `minikube ip` and then we access `<ip>:31515` to get our app (nodePort was 31515).
- `kube-apiserver` is one process inside master that monitors our nodes' statuses. If new config is fed it checks if the nodes are running the containers as intructed by the deployment file. If we kill one container in one node, the master sees it and restarts the container in one of its nodes. The developer does not interact directly with the nodes, it interacts with the master which watches the nodes constantly against its `list of responsibilities`!
- Two ways of approaching deployment: `imperative` (do exactly these steps to arrive at this container setup) and `declarative` (our container setup should look like this, make it happen). With imperative deployment, there is a lot of effort on the developer side (determine current state, write migration plans...) which can be complicated with a lot of containers running. With declarative deployment, we just write/update the config file (ex. update the tag in an image to update the app) and send the file to k8s whose master does all the rest of the work (check pods that are running old version, update them). k8s allows for both approaches but the declarative is preferred in a production environment.

![](./images/16.png)
![](./images/17.png)

### Maintaining sets of containers with deployments

- Update existing Pod: in declarative approach, we update our config that originally created the Pod and send the file to kubectl. The master knows that it needs to update a given Pod as opposed to creating a new object based on the object' name and kind, those are the unique identifiers. So to update we must leave the name and kind untouched.

- To get detailed info on an object, we run `kubectl describe <object-type> <object-name>`.

- Limitations in config files: in a Pod config file, we cannot just change anything, just some limited amount of properties. To workaround that, we make use of another object called `Deployment` that maintains a set of identical pods, ensuring that they have the correct config and that the right number exists (runnable state), it;s good for dev and production. The Deployment contains `Pod Template` and in the end of the day, creates a Pod from it. With Deployment we can change any piece of the config file we want.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: client-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      component: web
  template:
    metadata:
      labels:
        component: web
    spec:
      containers:
        - name: client
          image: stephengrider/multi-client
          ports:
              - containerPort: 3000
```

- `replicas` specifies number of identical pods to be created using specified template. 
- `selector.matchLabels` + `labels` to give the master a handle of what it is dealing with, which Pod that deployment is trying to update.
- To remove existing object run `kubectl delete -f <filename>` (imperative update) or `kubectl delete <object-type> <object-name>`.
- Why do we need the NodePort Service? `kubectl get pods -o wide` lists Pod and VM's IP, which can change if Pod stops and is restarted. The `Service` is then used to watch every Pod that matches its selector and make sure traffic is routed to that Pod. The developer then can use the same ip in the browser to access the process running in the Pod...
- To get the Deployment to recreate our Pods with the latest version of an image if we updated the image. There was nothing in the config pointing to the image version. If we don't change the config file, kubectl does not apply it again, it gets rejected. 3 possible solutions: 1. delete pods manually (bad idea, we want to have the app available at all times), 2. tag built image with a real version number and specify that version in the config file (adds extra step in production deployment process), 3. use imperative command to update the image version the deployment should use (downside: uses imperative command and therefore bypasses our config file).
- To implement solution 3 mentioned above: we tag our image with the version number with `docker build -t lugomes/multi-client:v1 .`, push it to docker hub`docker push lugomes/multi-client:v1`, `kubectl set image <object-type>/<object-name> <container-name>=<new image to use>` (in the example: `kubectl set image deployment/client-deployment client=lugomes/multi-client:v1`).
- In dev we have two installations of Docker, one in our local computer and another inside the VM. To reconfigure your current terminal window's docker CLI to use another docker server, we run `eval $(minikube docker-env)` to setup new env variables related to the other docker install. Why would we want to access the VM docker server? 1. Use debugging techniques (e.g. `docker exec -it <container-id> sh` to start shell in the container or `kubectl exec -it <container-id> sh`), 2. manually kill containers to test k8s ability to self-heal and 3. delete cached images in the node with `docker system prune -a`.

## Multi-Container App with Kubernetes

Architecture:
![](./images/18.png)

- `ClusterIP Service`: exposes a set of pods to other objects in the cluster. Allows pods to be reached from other pods inside the cluster (e.g. worker to access redis pod).
- `Ingress Service` allows outside traffic to access our pods.

### Persistent Volume Claim needed by Postgres? 
- If we stored the data inside the Postgres container and the Pod crashed, everything would be lost! A new Pod would be created but the data would not be carried over. So we cannot maintain the data inside the Postgres container! So the data should in fact be stored in a `volume` outside of the container, in the host machine. We should avoid two replicas accessing the same volume.
- `Volume in generic container terminology`: some type of mechanism that allow a container to access a filesystem outside of itself.
- `Volume in Kubernetes`: an object that allows a container to store data at the Pod level. If any container in the Pod crashes, a new one has access to the same volume. But the downside is that it is tied to the Pod so it only survives container restarts but not Pod crashes. So it is not appropriate to store data from a database.
- `Persistent Volume Claim` vs `Persistent Volume`: The Persistent Volume is not tied to any Pod or container unlike a `Volume`. A PVC is like an advertisement of different storage options available in the cluster for the different pods in it. So when we are about to create a PV, k8s will have `statically provisioned` PVs (created ahead of time). If it's created on the fly we call them `dynamically provisioned` PVs. If the PVC config is fed to k8s, we created a guarantee that k8s has to find that amount of hard-drive in the future.

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-persistent-volume-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```
- There are three different types of access modes:
  - `ReadWriteOnce`: can be used by a single node, can read and write.
  - `ReadOnlyMany`: multiple nodes can read from this.
  - `ReadWriteMany`: can be read and written to by many nodes.
- If we run in prod and claim a volume, in theory we need to specify where the storage space is to be provisioned, like Google Cloud Persistent Disk or AWS Block Store, etc. We did not add in the spec `storageClassName` because we wanted to use the default provided by our Cloud Provider but we could have used a different one by adding that spec. `kubectl get pv` to list out PVs and `kubectl get pvc` for PVCs.

![](./images/19.png)

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      component: postgres
  template:
    metadata:
      labels:
        component: postgres
    spec:
      volumes:
        - name: postgres-storage
          persistentVolumeClaim: 
              claimName: database-persistent-volumen-claim
      containers:
        - name: postgres
          image: postgres
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data # folder to backup in our PV
              subPath: postgres # folder name inside PV to store data backup
```

- Note: We can specify the directory of config files in the `kubectl apply -f <config-dir>` call to apply all of them.

- We used a `secret` to store our postgres database password. We don't want to commit this value. We run an imperative command as opposed to a config file to create a secret. This is because we need to pass in the value! In the prod environment we create it manually. `kubectl create secret generic <secret-name> --from-literal key=value`. To wire up the secret to the deployments:
```
env:
  - name: POSTGRES_PASSWORD
    valueFrom: 
      secretKeyRef:
        name: pgpassword
        key: POSTGRES_PASSWORD
```
- `LoadBalancer` Service: legacy way of getting network traffic into a cluster.
- `Ingress` Service: exposes a set of services to the outside world. Preferred over LoadBalancer. We use a ngnix ingress implementation (ingress-ngnix project on Github). The setup depends on the environment, we use local and Google Cloud for this. We again have a controller that constantly works to make sure our routing rules are setup. In GC a load balancer is automatically created with the ingress that hands off the traffic to the ingress pod. Read more on ingress-nginx at https://www.joyfulbikeshedding.com/blog/2018-03-26-studying-the-kubernetes-ingress-system.html.
![](./images/20.png)
![](./images/21.png)
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-service
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
    - http:
        paths:
          - path: /?(.*)
            backend:
              serviceName: client-cluster-ip-service
              servicePort: 3000
          - path: /api/?(.*)
            backend:
              serviceName: server-cluster-ip-service
              servicePort: 5000
```
- The minikube dashboard: `minikube dashboard` with info on our cluster with all workloads.

### Kubernetes Production Deployment

On Google Cloud:
- `Kubernetes Engine` tab: Created cluster with 3 nodes with 3.75GB memory each
- Setup `travis.yaml` file 
- Generate service account on GC with Kubernetes Engine Admin role which automatically downloads credentials as a JSON file
- Created a docker container with Ruby pre-installed since that is required to run Travis CLI - `docker run -it -v $(pwd):/app ruby:2.3 sh`. Then `gem install travis` to install Travis CLI in the container, logged in using Github account. Copied the service account json file into the local file and that gets into the container app folder. Then encrypt the service-account.json file with `travis encrypt-file service-account.json -r LuGomes/multi-k8s`. This creates a `service-account.json.enc` file which should be commited, not the original one which we deleted. We added a git SHA to our image tag to make it unique and the deployment can trigger with the new image in our deploy script. Setup secret for postgres password in k8s cluster using GC shell to issue `kubectl create secret generic pgpassword --from-literal POSTGRES_PASSWORD=<value>`.
- Helm is a software to administer third party software inside our k8s cluster. We issue commands to Heml Client which relays them to Tiller Server who ultimately makes changes to configs in the cluster. 
- RBAC (Role Based Access Control) limits who can access and modify objects in our cluster. Enabled by default with GC. Tiller will need to get some permissions set to change our cluster. With Helm v2, we need to create a service account and a ClusterRoleBinding for Tiller. `kubectl create serviceaccount --namespace kube-system tiller` (create a service account named tiller in the kube-system namespace) and `kubectl create clusterrolebinding tiller-cluster-role --clusterrole=cluster-admin --serviceaccount=kube-system:tiller` (create a new clusterrolebinding with the role cluster-admin and assign it to the service account tiller).
  1. `UserAccount`: person administering our cluster
  2. `ServiceAccount`: pod administering a cluster
  3. `ClusterRoleBinding`: authorizes an account do to a certain set of actions across the entire cluster
  4. `RoleBinding`: authorizes an account do to a certain set of actions in a single namespace

### HTTPS Setup with Kubernetes
![](./images/22.png)
![](./images/23.png)
![](./images/24.png)

Idea: If we own the domain, we have that route handler to reply with the appropriate response. Use Helm to automatically go through that flow. Installed `Cert manager` in the cluster that deals with obtaining the certificate. The secret is stored in the cluster.