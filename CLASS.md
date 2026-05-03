# Class 23 — Automated Docker Builds and Secure Registry Push in Jenkins

## The Scenario

Jenkins is running lint and tests. The pipeline is green. But deploying the
application is still a manual process owned by one person: the release manager
SSH-es into the server, pulls the latest code, rebuilds the Docker image by hand,
restarts the container, and watches the logs. This takes 25 minutes on a good day.
Last month the release manager was on holiday in a timezone with bad connectivity.
An urgent hotfix sat undeployed for three days while the engineering team had the
fix ready in the main branch. The CTO's exact words: "If the pipeline already runs
the tests, why does a human need to do the rest?"

## The Problem

The pipeline stops at test results. It does not produce a deployable artifact.
That means every deployment is a manual, undocumented, non-reproducible operation.
There is no record of which image version is running in any environment. There is
no way to roll back to a specific build. And the credentials to push to the
container registry currently live in a `.env` file on the release manager's
laptop — which is not version-controlled, not rotated, and known to two other
people "just in case."

## Your Mission

- Extend the `Jenkinsfile` to add a `Build` stage and a `Push` stage after a
  successful `Test` stage.
- The Docker image must be tagged with the Jenkins build number:
  `jcc-app:${BUILD_NUMBER}`. The `latest` tag must never be used.
- Registry credentials (username + password or token) must be stored in the
  Jenkins Credential Store as a `Username with password` credential type and
  accessed in the pipeline with `withCredentials`. They must not appear anywhere
  in the `Jenkinsfile`, in any environment variable set in Jenkins global config,
  or in any file committed to the repository.
- A failed `Test` stage must prevent `Build` and `Push` from running.
- After a successful push, the pipeline must print the full image reference
  (registry, name, and tag) to the build log so it is auditable.

## What You Need to Know First

- The `docker.build()` and `docker.withRegistry()` pipeline steps from the
  Docker Pipeline plugin, or the equivalent `sh "docker build ..."` and
  `sh "docker push ..."` with `withCredentials` wrapping.
- How Jenkins `withCredentials` works: the `usernamePassword` binding, what it
  injects into the environment, and crucially what it redacts from logs.
- The difference between `BUILD_NUMBER` (sequential integer, always unique per
  job) and `GIT_COMMIT` (SHA) as image tags — and why `latest` is dangerous in
  a deployment pipeline.
- How to verify a pushed image exists in the registry without pulling it:
  `docker manifest inspect <image>:<tag>`.

## Constraints

- The image tag must be exactly `jcc-app:${BUILD_NUMBER}` — not `latest`, not
  a git SHA, not a timestamp. The build number format makes the image traceable
  to a specific Jenkins build.
- Credentials must use `withCredentials` with a `usernamePassword` binding.
  To prove this is enforced, you must demonstrate that removing the credential
  from the Jenkins Credential Store causes the `Push` stage to fail with a
  message that clearly identifies a missing credential — not a cryptic Docker
  authentication error.
- The `Jenkinsfile` must be checked for secrets before every commit. Verify with:
  ```bash
  grep -iE "password|secret|token|apikey" Jenkinsfile
  ```
  This must return no matches.
- The `Build` and `Push` stages must be skipped (not just fail gracefully) if
  the branch is not `main`. Feature branches run lint and tests only.

## Verification

```bash
# 1. After a successful pipeline run on main:
docker pull ghcr.io/<your-registry>/jcc-app:42
# (substitute 42 with the actual build number from the Jenkins UI)
# Expected: image layers pulled successfully

# 2. Run the pushed image
docker run -d -p 3000:3000 ghcr.io/<your-registry>/jcc-app:42
curl -s localhost:3000/health
# Expected: ok

# 3. Confirm no secrets in Jenkinsfile
grep -iE "password|secret|token|apikey" Jenkinsfile
# Expected: no output (exit code 1 from grep means no match — that is correct)

# 4. Remove the registry credential from Jenkins, re-trigger the pipeline
# Expected: Push stage fails with a message referencing the missing credential ID
# NOT: "unauthorized: authentication required" or similar opaque Docker error

# 5. Restore the credential, re-trigger — Push stage succeeds
docker manifest inspect ghcr.io/<your-registry>/jcc-app:<new-build-number>
# Expected: JSON manifest with image layers
```

## Stretch Challenge

The pipeline currently runs stages sequentially: `Install → Lint → Test → Build → Push`.
`Lint` and `Test` are independent of each other — neither produces an artifact the
other needs. Refactor the `Jenkinsfile` to run `Lint` and `Test` in parallel using
the `parallel` step. Measure the wall-clock time saved. Then answer these questions
in a comment in the Jenkinsfile:

1. What happens if `Lint` fails but `Test` is still running in the parallel block?
   Does `Test` get cancelled immediately, or does it run to completion?
2. Name one scenario where parallel CI stages can produce a false-green result
   that sequential stages would have caught.

## Instructor Notes

The most common mistake: students store the registry password as a Jenkins global
environment variable (Manage Jenkins → Configure System → Global properties →
Environment variables). This looks like a credential — it is not. It is stored in
plain text in `config.xml` on the Jenkins filesystem and will appear in any build
log that echoes environment variables. The only correct approach is the Credential
Store with `withCredentials`. Jenkins redacts credential values from log output
automatically when `withCredentials` is used.

The `BUILD_NUMBER` vs `latest` debate is worth spending time on. Students
understand "latest is bad" abstractly but have not felt the pain. Walk through
this: two pipelines run simultaneously on two branches. Both tag and push
`latest`. Whichever finishes last wins — the other branch's image is now `latest`
in the registry. A deployment minutes later picks up the wrong code with no error.
This is a real incident pattern.
