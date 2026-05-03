# Class 15 — Kubernetes Before the YAML

## The Scenario
The app runs in Docker Compose on a single server. It works. Then the business
team sends three requirements in one email: the app must have zero downtime
during deployments, it must automatically restart if the process crashes, and it
must be able to run three copies simultaneously to handle the expected load
increase next quarter. The fourth item in the email: "Also we need resource
limits so one bug can't kill the whole server." Docker Compose cannot do any of
this. The solution is Kubernetes — but you are not writing a single YAML file
today. Before you touch a manifest, you will answer seven questions from memory.
Students who skip this step spend weeks guessing what their YAML does.

## The Problem
The team knows the words Pod, Deployment, and Service but cannot explain what
any of them actually does without looking it up. They copy YAML from Stack
Overflow and it works until it doesn't, and then they have no mental model to
debug with. The concepts must be understood before the commands are learned.

## Your Mission
1. Answer all seven questions below in writing — in `CLASS.md` itself or in a
   `notes.md` file — before consulting any documentation. Write your first-pass
   answer from memory. Then verify against the docs and add a correction note
   if your first answer was wrong. Both versions must appear in the file.
2. After answering, create the `jcc-production` namespace with a manifest file
   at `k8s/namespace.yaml`. The namespace must have the label
   `managed-by: student`.
3. Apply the manifest and prove it exists with the exact verification commands
   below.

**The seven questions:**
1. What is a Pod? How does it differ from a container?
2. How does a Deployment differ from running `docker run` by hand?
3. What does a Service do and why can you not just use the Pod's IP address
   directly?
4. What is a Namespace and in what situation would you create one for a real
   production system?
5. What does `kubectl apply` do that `kubectl create` does not? When would you
   use `create` over `apply`?
6. What happens to traffic being served by a Pod at the moment you delete that
   Pod? Walk through what Kubernetes does step by step.
7. What is the practical difference between `docker compose up` and
   `kubectl apply -f`? Name one thing each can do that the other cannot.

## What You Need to Know First
- A local Kubernetes cluster: minikube (`minikube start`) or kind
  (`kind create cluster`)
- `kubectl` installed and configured to point at your local cluster
- Basic YAML structure for a Kubernetes manifest: `apiVersion`, `kind`,
  `metadata`, `spec`
- What a Kubernetes `Namespace` manifest looks like — you must write it without
  copying from documentation

## Constraints
- You must write your first-pass answers before checking documentation. This is
  not optional — the point is to discover where your mental model is wrong.
- The `k8s/namespace.yaml` manifest must be written by hand. Do not use
  `kubectl create namespace --dry-run -o yaml` as a shortcut.
- The namespace must have exactly the label `managed-by: student` — no other
  labels unless you add them for the stretch challenge.
- `kubectl apply` must be used to create the namespace — not `kubectl create`.

## Verification
```bash
kubectl get namespace jcc-production
# Expected output:
# NAME              STATUS   AGE
# jcc-production    Active   Xs

kubectl get namespace jcc-production -o jsonpath='{.metadata.labels.managed-by}'
# Must print exactly: student

kubectl get namespace jcc-production -o yaml
# Must show the label in the metadata.labels section
```

## Stretch Challenge
Research and answer in writing: what is the default maximum number of Pods per
node in a standard Kubernetes cluster? What is the mechanism that enforces this
limit — is it a Kubernetes setting, an OS limit, or something else? What happens
to new Pods that are scheduled when a node is already at its limit? Why does
this matter for capacity planning in a production cluster running 200+ services?

## Instructor Notes
Class 15 is deliberately conceptual. The instinct is to skip to the YAML — to
cargo-cult a Deployment manifest from the docs and run `kubectl apply` without
understanding what just happened. That approach works until something goes wrong
and then the developer is completely lost.

The seven questions expose the most common misconceptions. Students almost
always get question 6 wrong on the first try — they think deleting a Pod causes
immediate downtime. Understanding that Kubernetes removes the Pod from the
Service endpoints before sending SIGTERM is the difference between an engineer
who fears `kubectl delete pod` and one who uses it confidently.

Question 5 (apply vs create) matters from day one because teams who use
`kubectl create` end up with unmanageable clusters where nobody knows whether
the running state matches any file in the repo. `apply` is declarative —
infrastructure as truth, not instructions.

The namespace with a label is a small thing that matters enormously at scale.
A label like `managed-by: student` lets you write a single `kubectl get all
-n jcc-production -l managed-by=student` to see everything your manifest
controls. Production clusters have hundreds of namespaces — labels are how
you navigate them.
