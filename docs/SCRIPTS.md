# Shell Scripts Guide

This repository includes three main shell scripts to help you manage the Coffee Queue application:

## setup.sh

**Purpose:** Initial environment setup and validation

### What it does:
- Verifies Docker is installed and running
- Checks for Docker Compose
- Creates necessary directories
- Sets up the Postgres database
- Initializes the schema
- Validates Java installation for local development

### Usage:
```bash
./setup.sh
```

### When to use:
- First time setting up the project
- After cloning the repository
- When you need to reset your environment

---

## dev.sh

**Purpose:** Simplified local development management

### Main Commands:

#### Start Development Environment
```bash
./dev.sh start
```
Starts both Postgres database and the Coffee Queue application in local development mode.

#### Stop Development Environment  
```bash
./dev.sh stop
```
Stops the application and database cleanly.

#### View Logs
```bash
./dev.sh logs
```
Displays real-time logs from both Postgres and the application.

#### Database Access
```bash
./dev.sh db
```
Opens an interactive PostgreSQL shell connected to the database.

#### Clean Reset
```bash
./dev.sh clean
```
Stops everything, removes containers, volumes, and target directory. Fresh start.

#### Status Check
```bash
./dev.sh status
```
Shows the status of all running containers and services.

#### Run Tests
```bash
./dev.sh test
```
Runs the application's test suite.

### What runs in dev mode:
- Postgres database (port 5432)
- Spring Boot application (port 8080)
- Automatic code reloading with Maven

### Application endpoints:
- Application: http://localhost:8080
- Database: localhost:5432 (user: coffee, db: coffeequeue)

---

## k8s.sh

**Purpose:** Kubernetes deployment and management

### Main Commands:

#### Deploy to Kubernetes
```bash
./k8s.sh deploy
```
Deploys the complete application stack to your Kubernetes cluster:
- Creates namespace
- Deploys Postgres with persistent storage
- Deploys the Coffee Queue application
- Sets up services and ingress

#### Check Status
```bash
./k8s.sh status
```
Shows detailed status of all Kubernetes resources including:
- Pod status and readiness
- Service endpoints
- PVC status
- Recent events

#### View Logs
```bash
./k8s.sh logs
```
Shows logs from the Coffee Queue application pods.

#### Port Forward
```bash
./k8s.sh port-forward
```
Creates a port forward to access the application locally:
- Application: http://localhost:8080
- Postgres: localhost:5432

#### Cleanup
```bash
./k8s.sh cleanup
```
Removes all Kubernetes resources (namespace and everything in it).

#### Database Shell Access
```bash
./k8s.sh db-shell
```
Opens an interactive shell in the Postgres pod.

### Prerequisites for k8s.sh:
- kubectl installed and configured
- Kubernetes cluster access (minikube, kind, or cloud provider)
- Cluster must be running

---

## Common Workflows

### First Time Setup
```bash
# 1. Initial setup
./setup.sh

# 2. Start development environment
./dev.sh start

# 3. Check it's working
./dev.sh status

# 4. View the application
open http://localhost:8080
```

### Development Workflow
```bash
# Start working
./dev.sh start

# Make code changes...

# Run tests
./dev.sh test

# Check logs
./dev.sh logs

# Done for the day
./dev.sh stop
```

### Kubernetes Testing
```bash
# Make sure your cluster is ready
kubectl cluster-info

# Deploy everything
./k8s.sh deploy

# Check deployment status
./k8s.sh status

# Access the application
./k8s.sh port-forward

# View logs if needed
./k8s.sh logs

# Cleanup when done
./k8s.sh cleanup
```

### Troubleshooting

#### Application won't start
```bash
# Check Docker is running
docker ps

# Clean restart
./dev.sh clean
./dev.sh start
```

#### Database connection issues
```bash
# Check database status
./dev.sh status

# Access database directly
./dev.sh db

# In psql, check connections:
SELECT * FROM pg_stat_activity;
```

#### Kubernetes issues
```bash
# Check cluster
kubectl cluster-info

# Check pod logs
./k8s.sh logs

# Check all resources
./k8s.sh status

# Start fresh
./k8s.sh cleanup
./k8s.sh deploy
```

#### Port already in use
```bash
# Find what's using port 8080
lsof -i :8080

# Or clean everything
./dev.sh clean
```

---

## Script Features

All scripts include:
- Color-coded output (green for success, yellow for warnings, red for errors)
- Built-in help (./script.sh help or ./script.sh --help)
- Detailed error messages
- Status validation at each step
- Safe cleanup operations with confirmations

## Environment Variables

The scripts use these default values (can be customized in .env):
- DB_HOST=localhost
- DB_PORT=5432
- DB_NAME=coffeequeue
- DB_USER=coffee
- DB_PASSWORD=coffee123

## File Locations

- Postgres Data: ./postgres/data/ (persisted locally)
- Application Logs: Check with ./dev.sh logs
- Build Artifacts: ./coffeequeue/target/
- Kubernetes Configs: ./k8s/ directory

---

## Quick Reference

| Task | Command |
|------|---------|
| First setup | ./setup.sh |
| Start dev environment | ./dev.sh start |
| Stop dev environment | ./dev.sh stop |
| View logs | ./dev.sh logs |
| Database shell | ./dev.sh db |
| Run tests | ./dev.sh test |
| Clean reset | ./dev.sh clean |
| Deploy to K8s | ./k8s.sh deploy |
| K8s status | ./k8s.sh status |
| Access K8s app | ./k8s.sh port-forward |
| K8s cleanup | ./k8s.sh cleanup |

For more detailed command information, see COMMANDS.md in this directory.
