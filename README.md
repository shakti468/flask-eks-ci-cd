# Flask EKS CI/CD 

# 🚀 Step 1: Flask App + Docker Setup

This is **Step 1** of the project: building and containerizing a minimal Python Flask app that we will later deploy to AWS EKS using CI/CD.

---

## 📂 Project Structure
```bash
flask-eks-ci-cd/
├─ app/
│ ├─ app.py
│ └─ requirements.txt
├─ Dockerfile
├─ .dockerignore
├─ .gitignore
└─ README.md
```


---

## 📝 1. Flask Application

The app is inside the `app/` folder.

- `app.py` → minimal Flask web service with routes:
  - `/` → returns a hello message
  - `/health` → returns health status
- `requirements.txt` → Python dependencies (`flask`, `gunicorn`)

📸 *Screenshot of `app.py` file*
<img width="876" height="431" alt="image" src="https://github.com/user-attachments/assets/cea6e832-3127-492d-8511-2a6715392b02" />

---

## 🐳 2. Dockerfile

We use a **multi-stage Dockerfile** to build and run the app efficiently.

- Stage 1 → installs dependencies
- Stage 2 → copies dependencies & runs Flask app with `gunicorn`
- Non-root user for security
- Exposes port `5000`
### Code 
```bash
# Dockerfile
# Stage 1: build / install dependencies
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build-essential if needed for C extensions (optional)
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files
COPY app/requirements.txt .

# Install into an isolated directory to keep final image small
RUN python -m pip install --upgrade pip
RUN pip install --prefix=/install -r requirements.txt

# Stage 2: final runtime image
FROM python:3.11-slim

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY app/ /app

# Create a non-root user for security
RUN useradd --create-home appuser && chown -R appuser /app
USER appuser

# Expose port
EXPOSE 5000

# Use gunicorn for production; bind to 0.0.0.0 so container accepts external traffic
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app", "--workers", "2"]
```


## 📦 3. Build Docker Image

Build the image locally:

```bash
docker build -t flask-eks-demo:local .

```
### Screenshots:
<img width="1232" height="307" alt="image" src="https://github.com/user-attachments/assets/dc977cc8-0543-4a60-b346-bd097dae770d" />

---
## Run Docker Container
```bash
docker run --rm -d -p 5000:5000 flask-eks-demo:local
```
### Screenshot
<img width="896" height="242" alt="image" src="https://github.com/user-attachments/assets/f4f0bd78-249c-4b44-991c-55c6026a870b" />

----
## Test Endpoints (http://localhost:5000/)
<img width="587" height="376" alt="image" src="https://github.com/user-attachments/assets/d925224c-fbac-4be4-a40d-820510b51f15" />

----

# Step 2 — Terraform AWS Infra (ECR + EKS)

## Folder structure
```bash
infra/
├─ main.tf
├─ variables.tf
├─ outputs.tf
└─ terraform.tfvars
```


## Setup

1. Go into `infra/`:
```bash
cd infra
```

## Initialize Terraform:
```bash
terraform init
```
## Create terraform.tfvars with your values:
```bash
region        = "ap-south-1"
default_vpc_id = "vpc-xxxxxxxx"
subnet_ids    = ["subnet-aaaaaaa", "subnet-bbbbbbb"]
ami_id        = "ami-0abcd1234efgh5678"
key_pair_name = "my-ssh-key"
```
## Preview:
```bash
terraform plan -var-file="terraform.tfvars"
```
## Apply:
```bash
terraform apply -var-file="terraform.tfvars" -auto-approve
```
### Screenshots

<img width="992" height="427" alt="image" src="https://github.com/user-attachments/assets/09e7813a-1e3b-4cdd-8c1d-54e63dbbc7f2" />

-----

### eks_cluster
<img width="1637" height="835" alt="image" src="https://github.com/user-attachments/assets/e9e4d5b7-0b58-4af1-b1e4-106a0df7a24a" />

----
### ecr_repository

<img width="1725" height="687" alt="image" src="https://github.com/user-attachments/assets/fadd9300-98f3-4357-8a3c-fe14f2b148e7" />

----

# Push Local Docker Image to AWS ECR

## Prerequisites

- AWS CLI v2 installed
- Docker installed
- An existing ECR repository (e.g., `flask-eks-demo`) in your AWS account
- Correct AWS credentials configured

---

### Screenshot
<img width="1918" height="706" alt="image" src="https://github.com/user-attachments/assets/fbe90392-cca8-44a7-a337-43dabf354781" />

------

# Step 3 — Kubernetes Setup for Flask App

## Prerequisites
- EKS cluster already created (Step 2)
- Docker image pushed to ECR (will be automated in Jenkins in Step 4)

## Configure kubectl
```bash
aws eks --region ap-south-1 update-kubeconfig --name flask-eks-cluster
kubectl get nodes
```

## Kubernetes Manifests

- Folder: k8s/

- namespace.yaml → defines a namespace flask-app

- deployment.yaml → deploys 2 replicas of Flask container from ECR

- service.yaml → exposes the app using AWS LoadBalancer on port 80


## Apply
```bash
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```
## Verify
```bash
kubectl get pods -n flask-app
kubectl get svc -n flask-app
```
### Open in browser through external ip:
<img width="1731" height="827" alt="image" src="https://github.com/user-attachments/assets/a4d6af2c-67e1-4881-bac7-5c7816704882" />

------

# Step 4 — Jenkins CI/CD Pipeline for Flask on EKS

## Overview
Automate build → push → deploy:
1. Build Docker image from Flask app
2. Push to AWS ECR
3. Deploy to AWS EKS via Kubernetes manifests

## Jenkinsfile
- Located at repo root: `Jenkinsfile`

## Pipeline Stages
1. **Checkout** → clone repo
2. **Build Docker Image** → docker build
3. **Login to ECR** → aws ecr login
4. **Push to ECR** → docker push
5. **Deploy to EKS** → update Deployment image using `kubectl set image`

### Screenshots
<img width="1393" height="990" alt="image" src="https://github.com/user-attachments/assets/ab5b38a0-ccce-47a9-98e4-2caffe1e3a1c" />

### Console output
```bash
Started by user Shakti Ranjan Mohanty
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins in /var/lib/jenkins/workspace/shakti_cicd_pipeline
[Pipeline] {
[Pipeline] withEnv
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Checkout)
[Pipeline] git
Selected Git installation does not exist. Using Default
The recommended git tool is: NONE
No credentials specified
 > git rev-parse --resolve-git-dir /var/lib/jenkins/workspace/shakti_cicd_pipeline/.git # timeout=10
Fetching changes from the remote Git repository
 > git config remote.origin.url https://github.com/shakti468/flask-eks-ci-cd.git # timeout=10
Fetching upstream changes from https://github.com/shakti468/flask-eks-ci-cd.git
 > git --version # timeout=10
 > git --version # 'git version 2.43.0'
 > git fetch --tags --force --progress -- https://github.com/shakti468/flask-eks-ci-cd.git +refs/heads/*:refs/remotes/origin/* # timeout=10
 > git rev-parse refs/remotes/origin/main^{commit} # timeout=10
Checking out Revision e9bdd4a6cf85a3a88cd3c2d904cb16d0cfb0ed7e (refs/remotes/origin/main)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f e9bdd4a6cf85a3a88cd3c2d904cb16d0cfb0ed7e # timeout=10
 > git branch -a -v --no-abbrev # timeout=10
 > git branch -D main # timeout=10
 > git checkout -b main e9bdd4a6cf85a3a88cd3c2d904cb16d0cfb0ed7e # timeout=10
Commit message: "Add files via upload"
 > git rev-list --no-walk 96578d7068df40e1b5c66966a4611fac18911969 # timeout=10
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Build Docker Image)
[Pipeline] sh
+ docker build -t 975050024946.dkr.ecr.ap-south-1.amazonaws.com/flask-eks-demo:latest .
DEPRECATED: The legacy builder is deprecated and will be removed in a future release.
            Install the buildx component to build images with BuildKit:
            https://docs.docker.com/go/buildx/

Sending build context to Docker daemon  43.01kB

Step 1/14 : FROM python:3.11-slim AS builder
 ---> c4640ec0986f
Step 2/14 : WORKDIR /app
 ---> Using cache
 ---> 00ccb75c11f5
Step 3/14 : RUN apt-get update && apt-get install -y --no-install-recommends build-essential     && rm -rf /var/lib/apt/lists/*
 ---> Using cache
 ---> fdb93efab5be
Step 4/14 : COPY app/requirements.txt .
 ---> Using cache
 ---> 0a93bfa3ee75
Step 5/14 : RUN python -m pip install --upgrade pip
 ---> Using cache
 ---> 822c853a3971
Step 6/14 : RUN pip install --prefix=/install -r requirements.txt
 ---> Using cache
 ---> 3250c863548e
Step 7/14 : FROM python:3.11-slim
 ---> c4640ec0986f
Step 8/14 : WORKDIR /app
 ---> Using cache
 ---> 00ccb75c11f5
Step 9/14 : COPY --from=builder /install /usr/local
 ---> Using cache
 ---> 5e152e83aeaf
Step 10/14 : COPY app/ /app
 ---> Using cache
 ---> 0047a39b09f0
Step 11/14 : RUN useradd --create-home appuser && chown -R appuser /app
 ---> Using cache
 ---> 29e72c81f57b
Step 12/14 : USER appuser
 ---> Using cache
 ---> a38dcfd67bd5
Step 13/14 : EXPOSE 5000
 ---> Using cache
 ---> 28c067034cde
Step 14/14 : CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app", "--workers", "2"]
 ---> Using cache
 ---> 0f40b5184d71
Successfully built 0f40b5184d71
Successfully tagged 975050024946.dkr.ecr.ap-south-1.amazonaws.com/flask-eks-demo:latest
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Login to ECR)
[Pipeline] withCredentials
Masking supported pattern matches of $AWS_SECRET_ACCESS_KEY
[Pipeline] {
[Pipeline] sh
+ aws ecr get-login-password --region ap-south-1
+ docker login --username AWS --password-stdin 975050024946.dkr.ecr.ap-south-1.amazonaws.com/flask-eks-demo
WARNING! Your password will be stored unencrypted in /var/lib/jenkins/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credential-stores

Login Succeeded
[Pipeline] }
[Pipeline] // withCredentials
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Push to ECR)
[Pipeline] sh
+ docker push 975050024946.dkr.ecr.ap-south-1.amazonaws.com/flask-eks-demo:latest
The push refers to repository [975050024946.dkr.ecr.ap-south-1.amazonaws.com/flask-eks-demo]
797ea714316d: Preparing
2453dc2009df: Preparing
0d88c04b14a5: Preparing
2ae8edad25c5: Preparing
8d441cbfbc35: Preparing
49dd736005c7: Preparing
135aac4d5c9a: Preparing
daf557c4f08e: Preparing
49dd736005c7: Waiting
135aac4d5c9a: Waiting
daf557c4f08e: Waiting
2ae8edad25c5: Layer already exists
2453dc2009df: Layer already exists
8d441cbfbc35: Layer already exists
797ea714316d: Layer already exists
0d88c04b14a5: Layer already exists
49dd736005c7: Layer already exists
135aac4d5c9a: Layer already exists
daf557c4f08e: Layer already exists
latest: digest: sha256:2f78d8ecf824f9f0b9fa596731555ef6dc5aafa9917ad9e714ba336ab835ef64 size: 1991
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Deploy to EKS)
[Pipeline] withCredentials
Masking supported pattern matches of $AWS_SECRET_ACCESS_KEY
[Pipeline] {
[Pipeline] sh
+ aws eks update-kubeconfig --region ap-south-1 --name flask-eks-cluster
Updated context arn:aws:eks:ap-south-1:975050024946:cluster/flask-eks-cluster in /var/lib/jenkins/.kube/config
+ kubectl apply -f k8s/deployment.yaml
deployment.apps/flask-deployment unchanged
[Pipeline] }
[Pipeline] // withCredentials
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Declarative: Post Actions)
[Pipeline] echo
✅ Deployment Succeeded!
[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // withEnv
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
Finished: SUCCESS
```

## Open EXTERNAL-IP in browser:
```bash
http://a5e03fd4e84b54740b3e6ee311cfb1b6-105602902.ap-south-1.elb.amazonaws.com/
```
### Screenshot
<img width="1348" height="651" alt="image" src="https://github.com/user-attachments/assets/0932ad9a-2fcf-4080-9af3-8dfe09303aa4" />


----------

## Destroy Infrastructure

