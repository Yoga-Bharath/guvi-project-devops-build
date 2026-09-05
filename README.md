# DevOps Build — Docker, Jenkins CI/CD, AWS & Prometheus Monitoring

## Project Overview

This project demonstrates the complete deployment and CI/CD automation of a static web application using Docker, Docker Hub, Jenkins, GitHub, AWS EC2, and Prometheus monitoring.

The application source is taken from:

**Source Repository:**
https://github.com/sriram-R-krishnan/devops-build

The application files are located inside the `build/` directory of the source repository.

The application is containerized using Nginx and exposed on **HTTP port 80**.

### Project Objectives

* Clone and deploy the provided static web application.
* Dockerize the application using a Dockerfile.
* Create a Docker Compose configuration.
* Create Bash scripts for image building and deployment.
* Maintain the project using Git and GitHub.
* Create separate Docker Hub repositories for development and production.
* Configure Jenkins CI/CD for both `dev` and `master` branches.
* Deploy the application on AWS EC2.
* Configure AWS Security Groups for application and administrative access.
* Monitor application health using Prometheus and Blackbox Exporter.
* Send email notifications when the application becomes unavailable.

---

# 1. Application Source

The application was cloned from:

```text
https://github.com/sriram-R-krishnan/devops-build
```

The deployable static files are located in:

```text
build/
```

The application is served using Nginx on:

```text
HTTP : 80
```

---

# 2. Project Architecture

```text
                         GitHub
                           |
                           |
                 +---------+---------+
                 |                   |
              dev branch         master branch
                 |                   |
                 v                   v
             Jenkins             Jenkins
                 |                   |
                 v                   v
        Docker Build & Push   Docker Build & Push
                 |                   |
                 v                   v
       Docker Hub - DEV      Docker Hub - PROD
       Public Repository     Private Repository
                 |                   |
                 +---------+---------+
                           |
                           v
                    AWS EC2 Instance
                           |
                    Docker Container
                           |
                       Nginx :80
                           |
                           v
                    Deployed Website
                           |
                           v
              Prometheus + Blackbox Exporter
                           |
                           v
                     Alertmanager
                           |
                           v
                    Email Notification
```

---

# 3. Repository Structure

```text
.
├── build/
│   └── Static application files
│
├── Dockerfile
├── docker-compose.yml
├── build.sh
├── deploy.sh
├── Jenkinsfile
├── .dockerignore
├── .gitignore
├── monitoring/
│   ├── prometheus.yml
│   ├── alert.rules.yml
│   ├── alertmanager.yml
│   └── docker-compose-monitoring.yml
│
└── README.md
```

---

# 4. Docker

## 4.1 Dockerfile

The application is dockerized using Nginx.

The Docker image:

* Uses Nginx Alpine as the base image.
* Copies the contents of the `build/` directory into the Nginx web directory.
* Exposes port 80.
* Runs Nginx in the foreground.

Example Dockerfile:

```dockerfile
FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

COPY build/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

---

## 4.2 Build Docker Image

The image can be built manually using:

```bash
docker build -t devops-build:local .
```

Run the container:

```bash
docker run -d \
  --name devops-build-local \
  -p 80:80 \
  devops-build:local
```

Verify:

```bash
docker ps
```

Test:

```bash
curl -I http://localhost/
```

Expected:

```text
HTTP/1.1 200 OK
```

---

# 5. Docker Compose

A Docker Compose file is provided to simplify running the application.

Start the application:

```bash
docker compose up -d
```

Check the container:

```bash
docker compose ps
```

Stop the application:

```bash
docker compose down
```

The application is exposed on:

```text
http://localhost/
```

---

# 6. Bash Scripting

Two Bash scripts are used for automation.

## 6.1 build.sh

`build.sh` is responsible for:

* Selecting the target repository based on the Git branch.
* Building the Docker image.
* Creating a commit-based image tag.
* Tagging the image as `latest`.
* Optionally pushing the image to Docker Hub.

### Development build

```bash
DOCKERHUB_USER=yogabharath \
BRANCH=dev \
PUSH=true \
./build.sh
```

This creates:

```text
yogabharath/devops-build-dev
```

### Production build

```bash
DOCKERHUB_USER=yogabharath \
BRANCH=master \
PUSH=true \
./build.sh
```

This creates:

```text
yogabharath/devops-build-prod
```

---

## 6.2 deploy.sh

`deploy.sh` is responsible for deploying the selected Docker image to the EC2 server.

### Development deployment

```bash
DOCKERHUB_USER=yogabharath \
REPO=dev \
IMAGE_TAG=latest \
./deploy.sh
```

### Production deployment

```bash
DOCKERHUB_USER=yogabharath \
REPO=prod \
IMAGE_TAG=latest \
./deploy.sh
```

The application container is deployed on:

```text
Port 80
```

---

# 7. Git & GitHub

Git CLI is used for version control.

The project is maintained in:

```text
https://github.com/Yoga-Bharath/guvi-project-devops-build
```

## 7.1 Configure Git

```bash
git init
git remote add origin <GITHUB_REPOSITORY_URL>
```

Check the remote:

```bash
git remote -v
```

---

## 7.2 Development Branch

Development changes are pushed to the `dev` branch.

```bash
git checkout dev
git add .
git commit -m "test pipeline"
git push origin dev
```

The `dev` branch automatically triggers the Jenkins development pipeline.

---

## 7.3 Production Branch

After development changes are tested successfully, the `dev` branch is merged into `master`.

```bash
git checkout master
git pull origin master
git merge dev
git push origin master
```

The `master` branch automatically triggers the Jenkins production pipeline.

---

# 8. Git Ignore Files

The project includes:

```text
.gitignore
```

to prevent unnecessary files such as:

```text
.env
*.log
node_modules/
```

from being committed to GitHub.

A `.dockerignore` file is also used to prevent unnecessary files from being included in the Docker build context.

---

# 9. Docker Hub

Two Docker Hub repositories are used.

## Development Repository

```text
yogabharath/devops-build-dev
```

Visibility:

```text
PUBLIC
```

The `dev` branch pushes images to this repository.

---

## Production Repository

```text
yogabharath/devops-build-prod
```

Visibility:

```text
PRIVATE
```

The `master` branch pushes images to this repository.

The production repository requires Docker Hub authentication during deployment.

---

# 10. Jenkins CI/CD

Jenkins is used to automatically build, push, and deploy the application.

The Jenkins server runs on the AWS EC2 instance.

## Pipeline Flow

### Dev Branch

```text
GitHub dev push
       |
       v
Jenkins
       |
       v
Build Docker Image
       |
       v
Push to Docker Hub
       |
       v
yogabharath/devops-build-dev
       |
       v
Deploy locally on EC2
```

### Master Branch

```text
dev merged into master
          |
          v
       Jenkins
          |
          v
  Build Docker Image
          |
          v
   Push to Docker Hub
          |
          v
yogabharath/devops-build-prod
          |
          v
 Deploy locally on EC2
```

---

## 10.1 Jenkins Trigger

Jenkins is connected to the GitHub repository using a webhook.

The Multibranch Pipeline monitors:

```text
dev
master
```

A push to either branch automatically starts the corresponding pipeline.

---

## 10.2 Jenkins Credentials

Docker Hub credentials are configured in Jenkins.

Credential ID:

```text
dockerhub-credentials
```

The credential is used for:

```text
docker login
docker push
docker pull
```

The production repository is private, so Jenkins authenticates with Docker Hub before pulling the production image during deployment.

---

## 10.3 Jenkins Pipeline Stages

The Jenkinsfile contains the following stages:

```text
Checkout
   ↓
Build Image
   ↓
Push to Docker Hub
   ↓
Deploy locally
```

### Development

```text
dev
 ↓
Build
 ↓
yogabharath/devops-build-dev
 ↓
Deploy
```

### Production

```text
master
 ↓
Build
 ↓
yogabharath/devops-build-prod
 ↓
Deploy
```

---

# 11. AWS EC2

The application is deployed on an AWS EC2 instance.

### EC2 Configuration

```text
Instance Name: devops-build-project
Application Port: 80
Operating System: Ubuntu
```

### Instance Type

The project requirement specifies:

```text
t2.micro
```

The implemented environment used:

```text
t3.micro
```

This was used to provide additional resources for Jenkins, Docker builds, and monitoring.

---

# 12. EBS Storage

The EC2 instance uses dedicated storage for Docker data.

### Root Volume

The root volume was increased to provide sufficient space for:

* Jenkins
* Jenkins workspaces
* Jenkins plugins
* System packages
* Build logs

### Docker Volume

A separate EBS volume is mounted at:

```text
/var/lib/docker
```

This keeps Docker images, containers, and build layers away from the root filesystem.

Configured size:

```text
20 GB
```

---

# 13. Swap Configuration

A 4 GB swap file was configured to reduce the possibility of Jenkins being killed because of memory pressure during Docker builds.

Configured:

```text
Swap: 4 GB
vm.swappiness: 10
```

Verify:

```bash
free -h
```

and:

```bash
swapon --show
```

---

# 14. AWS Security Group

The EC2 Security Group is:

```text
devops-build-sg
```

## Inbound Rules

| Protocol | Port | Source                | Purpose              |
| -------- | ---: | --------------------- | -------------------- |
| HTTP     |   80 | `0.0.0.0/0`           | Public application   |
| SSH      |   22 | `<YOUR_PUBLIC_IP>/32` | Administrator access |
| TCP      | 8080 | `0.0.0.0/0`           | Jenkins UI           |
| TCP      | 9090 | `<YOUR_PUBLIC_IP>/32` | Prometheus UI        |

### Application Access

Anyone with an internet connection can access:

```text
http://<EC2_PUBLIC_IP>/
```

### Server Access

SSH access is restricted to the administrator's public IP address.

Example:

```text
<YOUR_PUBLIC_IP>/32
```

---

# 15. Application Deployment Verification

After Jenkins deploys the production image, verify the running container.

```bash
docker ps
```

Expected image:

```text
yogabharath/devops-build-prod:latest
```

Verify the exact image:

```bash
docker inspect devops-build-app \
  --format '{{.Config.Image}}'
```

Expected:

```text
yogabharath/devops-build-prod:latest
```

Test the application:

```bash
curl -I http://localhost/
```

Expected:

```text
HTTP/1.1 200 OK
```

The application can also be accessed from a browser:

```text
http://<EC2_PUBLIC_IP>/
```

---

# 16. Prometheus Monitoring

Prometheus is used to monitor the health of the deployed application.

The monitoring stack consists of:

```text
Prometheus
Blackbox Exporter
Alertmanager
```

## Monitoring Architecture

```text
                 Application
                      |
                      | HTTP request
                      v
             Blackbox Exporter
                      |
                      v
                 Prometheus
                      |
              ApplicationDown
                      |
                      v
                 Alertmanager
                      |
                      v
                    Email
```

---

# 17. Blackbox Exporter

Blackbox Exporter checks whether the live application responds successfully over HTTP.

It monitors the actual deployed application rather than simply checking whether Docker is running.

The monitored endpoint is:

```text
http://<EC2_PUBLIC_IP>/
```

---

# 18. Prometheus Configuration

Prometheus is configured to scrape the Blackbox Exporter.

The monitoring configuration is stored in:

```text
monitoring/prometheus.yml
```

Before starting Prometheus, replace the placeholder:

```text
http://<EC2_PUBLIC_IP>/
```

with the actual EC2 public IP.

Verify:

```bash
cat prometheus.yml | grep targets -A 1
```

---

# 19. Start Monitoring

On the EC2 server:

```bash
cd ~/monitoring
```

Start the monitoring stack:

```bash
docker compose \
  -f docker-compose-monitoring.yml \
  up -d
```

Verify:

```bash
docker ps
```

Expected containers:

```text
prometheus
blackbox-exporter
alertmanager
devops-build-app
```

---

# 20. Prometheus Target Verification

Open:

```text
http://<EC2_PUBLIC_IP>:9090/targets
```

Find:

```text
app-http-health
```

Expected state:

```text
UP
```

This confirms that Prometheus can successfully reach the deployed application.

---

# 21. ApplicationDown Alert

Prometheus contains an alert rule called:

```text
ApplicationDown
```

The alert is triggered when the application becomes unreachable for the configured period.

The alert configuration is stored in:

```text
monitoring/alert.rules.yml
```

When the application is healthy:

```text
ApplicationDown = INACTIVE
```

When the application is unavailable:

```text
ApplicationDown = FIRING
```

---

# 22. Email Notifications

Alertmanager is configured to send email notifications.

Slack notifications are **not used**.

The configuration is stored in:

```text
monitoring/alertmanager.yml
```

Gmail SMTP is used for sending notifications.

The SMTP server is:

```text
smtp.gmail.com:587
```

A Gmail App Password is used instead of the normal Gmail account password.

The configuration sends notifications when:

```text
ApplicationDown = FIRING
```

A resolved notification is also sent when the application becomes healthy again.

Normal healthy operation does not generate repeated notifications.

---

# 23. Monitoring Test

## Step 1 — Confirm healthy application

```bash
curl -I http://localhost/
```

Expected:

```text
HTTP/1.1 200 OK
```

Prometheus:

```text
app-http-health = UP
ApplicationDown = INACTIVE
```

---

## Step 2 — Simulate application failure

Stop the application container:

```bash
docker rm -f devops-build-app
```

Wait approximately 1–2 minutes.

Open:

```text
http://<EC2_PUBLIC_IP>:9090/alerts
```

Expected:

```text
ApplicationDown
FIRING
```

An email notification should be received.

---

## Step 3 — Restore the application

Deploy the application again:

```bash
DOCKERHUB_USER=yogabharath \
REPO=dev \
IMAGE_TAG=latest \
./deploy.sh
```

Verify:

```bash
docker ps
```

Then:

```bash
curl -I http://localhost/
```

Expected:

```text
HTTP/1.1 200 OK
```

After Prometheus detects the recovery:

```text
ApplicationDown = INACTIVE
```

A resolved email notification is sent if `send_resolved` is enabled.

---

# 24. Final Submission Details

| Item               | Details                                                   |
| ------------------ | --------------------------------------------------------- |
| GitHub Repository  | https://github.com/Yoga-Bharath/guvi-project-devops-build |
| Source Application | https://github.com/sriram-R-krishnan/devops-build         |
| Deployed Site      | http://13.232.245.243/                                    |
| Dev Docker Image   | `yogabharath/devops-build-dev:latest`                     |
| Prod Docker Image  | `yogabharath/devops-build-prod:latest`                    |
| Dev Repository     | Public                                                    |
| Prod Repository    | Private                                                   |
| Application Port   | 80                                                        |
| Monitoring         | Prometheus + Blackbox Exporter                            |
| Notifications      | Email                                                     |

---
Final Project Flow

The completed project implements the following workflow:

```text
Developer
    |
    | git push
    v
GitHub
    |
    +----------------------+
    |                      |
    v                      v
  dev branch           master branch
    |                      |
    v                      v
 Jenkins                 Jenkins
    |                      |
    v                      v
Docker Build            Docker Build
    |                      |
    v                      v
Docker Hub DEV         Docker Hub PROD
  (Public)               (Private)
    |                      |
    +----------+-----------+
               |
               v
          Deploy on EC2
               |
               v
          Nginx :80
               |
               v
       Public Web Application
               |
               v
     Blackbox Exporter
               |
               v
          Prometheus
               |
        ApplicationDown
               |
               v
         Alertmanager
               |
               v
        Email Notification
```

## Conclusion

This project demonstrates an end-to-end DevOps workflow covering:

* Git and GitHub version control
* Docker containerization
* Docker Compose
* Bash automation
* Docker Hub image management
* Jenkins CI/CD
* AWS EC2 deployment
* AWS Security Groups
* Persistent Docker storage
* Prometheus application monitoring
* Blackbox HTTP health checks
* Alertmanager
* Email-based outage notifications

The development workflow uses the `dev` branch and public Docker Hub repository, while merging `dev` into `master` promotes the application to the private production Docker Hub repository and production deployment.
