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
