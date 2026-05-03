# Class 24 — Gated Production Deployments with Audit Trail and Auto-Rollback

## The Scenario

Last Tuesday at 11:43am, a developer deployed directly to production from their
laptop. They ran `kubectl set image` with a locally-built image that had never
gone through CI. A typo in a config value (`"port": "3OO0"` — letter O, not zero)
caused the app to fail on startup. Kubernetes kept restarting the pod every 10
seconds. Nobody was watching. Twenty minutes later a user reported the site was
down. The post-mortem produced three requirements that must be implemented before
the next release: (1) all production deployments must originate from the pipeline,
(2) a human must explicitly approve production deployments — clicking a button is
not enough, they must enter their name, (3) if a deployment fails, it must roll
back automatically without human intervention.

## The Problem

The Jenkins pipeline builds and pushes images. It does not deploy them anywhere.
The deployment step still requires a human to run kubectl manually. There is no
approval gate, no audit trail, and no automatic recovery from a failed deploy.
The separation that should exist between "CI" (build and verify) and "CD" (deploy
to environments with appropriate controls) does not exist at all.

## Your Mission

- Add a `Deploy to Dev` stage to the Jenkinsfile that runs automatically after
  a successful `Push` stage on the `main` branch. It must deploy to the
  `jcc-dev` Kubernetes namespace with no human interaction.
- Add a `Deploy to Production` stage that pauses the pipeline and presents an
  approval prompt. The prompt must display the image reference being deployed
  (registry, name, and build number). The approver must type their name into a
  text field — an empty "Proceed" click must be rejected. The approval must time
  out and abort automatically after 24 hours if nobody responds.
- The production deploy must run `kubectl rollout status` after applying the
  image change. If `rollout status` exits non-zero (rollout failed or timed out),
  the pipeline must automatically execute `kubectl rollout undo` and mark the
  stage as failed with the message: "Deploy failed — automatic rollback triggered."
- The `KUBECONFIG` credentials must be stored in Jenkins as a `Secret file`
  credential type — not as text, not as environment variables.

## What You Need to Know First

- The Jenkins `input` step: the `message`, `parameters`, and `submitter` fields.
  How to make a text parameter required (non-empty validation).
- How to use `withCredentials` with a `Secret file` binding to write the
  kubeconfig to a temp path and pass it to kubectl via `KUBECONFIG` env var.
- `kubectl rollout status --timeout=Xs` — what exit code it returns on success
  vs timeout, and how shell `if/else` or Groovy `try/catch` can branch on it.
- `kubectl rollout undo deployment/<name> -n <namespace>` — what it does and
  what it does NOT do (it does not fix the image — it restores the previous
  revision's spec).
- The difference between `jcc-dev` and `jcc-production` namespaces: both must
  exist before the pipeline runs (`kubectl create namespace` if needed).

## Constraints

- The `input` step must use a `parameters` block with a `string` parameter named
  `APPROVER_NAME`. The pipeline must fail with an explicit error if `APPROVER_NAME`
  is blank. Do not rely on the submitter's login name — the entered name becomes
  part of the audit log in the build parameters.
- `KUBECONFIG` must be injected via `withCredentials` using the `file` binding.
  It must not be set as a global Jenkins environment variable or mounted directly
  into the Jenkins container.
- The automatic rollback must only trigger if `kubectl rollout status` returns
  non-zero. A successful deployment must NOT call `kubectl rollout undo`.
- The `Deploy to Dev` and `Deploy to Production` stages must be skipped entirely
  (not failed) if the branch is not `main`.

## Verification

```bash
# 1. Trigger the pipeline on main. Deploy to Dev must complete without prompting.
kubectl get pods -n jcc-dev
# Expected: pods show the new image tag (jcc-app:<BUILD_NUMBER>)

# 2. Pipeline pauses at Deploy to Production.
# In the Jenkins UI, the stage must show:
# "Approve deployment of jcc-app:<BUILD_NUMBER> to production?
#  Approver name: [text field]  [Proceed] [Abort]"
# Attempt to proceed with empty approver name — must be rejected.

# 3. Enter a name and proceed. After successful rollout:
kubectl get pods -n jcc-production
# Expected: pods running new image tag
kubectl rollout history deployment/backend -n jcc-production
# Expected: new revision entry with the image tag visible

# 4. Simulate a failed production deploy (broken image):
# Manually change the image tag in the pipeline to a non-existent image,
# approve the deployment, watch kubectl rollout status time out.
# Expected: pipeline prints "Deploy failed — automatic rollback triggered."
kubectl get pods -n jcc-production
# Expected: pods are back to the previous working image
```

## Stretch Challenge

Prove the automatic rollback actually restores traffic. Deploy a version of
`jcc-app` that has a `/health` endpoint returning HTTP 500. The liveness probe
will fail. `kubectl rollout status` will time out. The pipeline rolls back. While
this is happening, run:

```bash
while true; do
  STATUS=$(curl -so /dev/null -w "%{http_code}" http://jcc.local/health)
  echo "$(date +%T) $STATUS"
  sleep 2
done
```

Capture the output. Show the window of 500s during the bad rollout, followed by
200s once the rollback completes. Calculate the downtime window in seconds and
explain whether this is acceptable and how you would reduce it.

## Instructor Notes

The `input` step timeout is a common confusion point. `timeout(time: 24, unit: 'HOURS') { input ... }` wraps the input step in a timeout block — if nobody approves within 24 hours, the pipeline stage fails with a `FlowInterruptedException`, which is the correct behaviour. Students often try to set the timeout on the stage, not the input step, which times out the entire stage including the deployment steps.

The "approver name" requirement is not just a compliance theatre exercise. In the Jenkins build parameters log, every approved build permanently records what was entered in the text field. Six months later, when an auditor asks "who approved the deployment of build 287 to production?", the answer is one click away in the build history. This is a real requirement in PCI-DSS and SOC 2 environments.

For the rollback stretch: students are often surprised that there is still a downtime window even with rollback automation. Walk through the math: rollout timeout (e.g. 5 minutes) + rollback time (~30 seconds) = the window. The only way to reduce it is a shorter `--timeout` on `kubectl rollout status` — but too short causes false rollbacks on slow but healthy deployments.
