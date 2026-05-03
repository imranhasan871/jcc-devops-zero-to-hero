# Jenkins — Local Setup Guide

## Quick Start with Docker

Run Jenkins locally with a single Docker command:

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

Port 8080 is the web UI. Port 50000 is for build agents.
Mounting `/var/run/docker.sock` lets Jenkins build Docker images.

## First-time Setup

1. Get the initial admin password:
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```
2. Open http://localhost:8080 and paste the password
3. Choose "Install suggested plugins"
4. Create your admin user

## Required Plugins

Install these from **Manage Jenkins → Plugins → Available**:
- **Pipeline** (usually pre-installed)
- **Git** (usually pre-installed)
- **Docker Pipeline**
- **Credentials Binding**
- **Blue Ocean** (optional — nice UI for pipelines)

## Create a Pipeline Job

1. New Item → Pipeline
2. Under "Pipeline", choose "Pipeline script from SCM"
3. SCM: Git, Repository URL: your repo
4. Script Path: `Jenkinsfile`
5. Save and click "Build Now"

## Key Difference from GitHub Actions

| Feature         | GitHub Actions        | Jenkins               |
|-----------------|-----------------------|-----------------------|
| Hosting         | GitHub cloud          | Self-hosted           |
| Cost            | Free tier (minutes)   | Free (infrastructure) |
| Secrets         | GitHub Secrets        | Jenkins Credentials   |
| Agents          | GitHub-hosted runners | Your own servers      |
| Plugins         | Marketplace actions   | Jenkins plugin center |
| Best for        | Open source / SaaS    | Enterprise / on-prem  |
