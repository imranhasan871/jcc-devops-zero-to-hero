# Class 15 — Kubernetes: Concepts + Namespace

## Objective
Understand what Kubernetes is, why it exists, and how it differs from plain
Docker. Create the first Kubernetes resource — a Namespace — and build the
vocabulary needed for the next two classes.

## What You'll Learn
- What container orchestration is and why it matters at scale
- The difference between Docker and Kubernetes
- Core K8s objects: cluster, node, pod, deployment, service, namespace
- How to write and apply a Kubernetes YAML manifest
- What namespaces are used for in production clusters

## What Changed in This Class
- Added `k8s/namespace.yaml` — defines the `jcc-production` namespace
- Added `k8s/README.md` — full glossary of Kubernetes concepts with the directory layout

## Hands-On Exercise
1. Install `kubectl` and a local cluster: [minikube](https://minikube.sigs.k8s.io) or [kind](https://kind.sigs.k8s.io)
2. Start your cluster: `minikube start` or `kind create cluster`
3. Apply the namespace: `kubectl apply -f k8s/namespace.yaml`
4. Verify it exists: `kubectl get namespaces`
5. Describe it: `kubectl describe namespace jcc-production`
6. Explore the default namespaces: `kube-system`, `kube-public`, `default`

## Key Concepts

**Docker Runs ONE Container — Kubernetes Orchestrates MANY**
Docker is a tool for packaging and running a single container. It answers the
question: "How do I run this application on this machine?" Kubernetes answers
a much harder question: "How do I run 50 copies of this application across
20 machines, keep them healthy, update them without downtime, and route traffic
to only the healthy ones?"

At small scale (one server, one app), Docker alone is sufficient. Once you need
high availability (multiple replicas), horizontal scaling (add more pods under
load), zero-downtime deployments (rolling updates), or multi-service
architectures (app + database + cache + background workers), you need an
orchestrator like Kubernetes.

**Namespaces — Logical Isolation**
A namespace is a virtual cluster inside a physical cluster. Resources in
`jcc-production` are invisible to resources in `jcc-staging` unless you
explicitly configure cross-namespace access. This isolation prevents teams
or environments from interfering with each other. Resource quotas and network
policies can also be applied per namespace, giving operators fine-grained
control over what each team can deploy and consume.

**Kubernetes is Declarative**
Like Docker Compose, Kubernetes is declarative: you write YAML that describes
the *desired state*, and Kubernetes continuously works to make the actual state
match it. If a pod crashes, K8s restarts it. If a node fails, K8s reschedules
the pods onto healthy nodes. You declare intent; the control plane acts.

## Next Class Preview
In Class 16 we deploy the JCC backend to our local Kubernetes cluster. We write
a Deployment (which manages pod replicas) and a Service (which provides a stable
network endpoint) and add `kubectl` shortcuts to the Makefile.
