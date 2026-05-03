# Class 22 — Self-Hosted CI with Jenkins in an Air-Gapped Environment

## The Scenario

The JCC platform has been acquired by an enterprise client in the financial
sector. Their security team has completed a review of the GitHub Actions
pipeline. Decision: rejected. Their requirements are non-negotiable — all CI/CD
must run on infrastructure they own and can audit, all build artifacts must stay
on-premises, no source code or secrets may leave the internal network, and the
compliance team must be able to inspect every pipeline definition. GitHub Actions
is a managed cloud service. It does not meet these requirements. Jenkins does.

## The Problem

You have a working GitHub Actions pipeline. It means nothing in this client's
environment. You need to rebuild CI from scratch on Jenkins running locally in
Docker — no internet access assumed after initial setup, no managed services,
no marketplace actions. The pipeline must produce the same result as the old one:
install dependencies, run lint, run tests, publish test results. A failure in
lint must prevent tests from running. The compliance team must be able to read
the pipeline definition as a plain file in the repository.

## Your Mission

- Run Jenkins in Docker on port 8080 using the `jenkins/jenkins:lts` image.
- Write a `Jenkinsfile` at the root of the repo using Declarative Pipeline syntax.
- The pipeline must define these stages in order: `Install`, `Lint`, `Test`.
- A failed `Lint` stage must prevent `Test` from executing — the stage must show
  as skipped or not-run, not failed.
- The `Test` stage must publish JUnit XML results using `junit` in a `post { always {} }` block so results appear in the Jenkins UI regardless of pass/fail.
- Document in `CLASS.md` (this file) three architectural differences between
  Jenkins and GitHub Actions, and one concrete reason an enterprise security or
  compliance team would mandate self-hosted CI.

## What You Need to Know First

- Declarative Pipeline syntax: `pipeline`, `agent`, `stages`, `stage`, `steps`,
  `post` blocks.
- The difference between `when { expression }` conditions and natural stage
  sequencing for failure propagation.
- How Jenkins publishes JUnit results: the `junit` step and the XML format it
  expects.
- How to retrieve the Jenkins initial admin password from a running container:
  `docker exec <container> cat /var/jenkins_home/secrets/initialAdminPassword`
- What Blue Ocean and Pipeline Stage View plugins provide and how to install
  them from the Jenkins plugin manager.

## Constraints

- Jenkins must run via `docker run` — not installed on the host system and not
  a managed service.
- The `Jenkinsfile` must live at the repository root and use Declarative (not
  Scripted) Pipeline syntax.
- You may NOT use `try/catch` to suppress lint failures — the pipeline must
  structurally prevent downstream stages from running when lint fails.
- Test results must appear in the Jenkins UI (Pipeline Stage View or Blue Ocean)
  as a dedicated test results tab — not just as console output.
- The three architectural comparisons between Jenkins and GitHub Actions must be
  written in plain English in the section below, not as marketing copy.

## Verification

```bash
# 1. Jenkins is reachable
curl -s http://localhost:8080/login | grep -i "jenkins"
# Expected: HTML containing the word Jenkins

# 2. Introduce a deliberate lint error (e.g. undefined variable usage),
#    commit and trigger the pipeline manually or via SCM poll.
#    In the Stage View or Blue Ocean:
#    Stage: Install  — SUCCESS (green)
#    Stage: Lint     — FAILED  (red)
#    Stage: Test     — NOT RUN (grey, skipped)

# 3. Fix the lint error, re-trigger.
#    Stage: Install  — SUCCESS
#    Stage: Lint     — SUCCESS
#    Stage: Test     — SUCCESS
#    Test results tab in the build shows passing test count > 0.

# 4. Confirm Jenkinsfile is readable as a plain file
cat Jenkinsfile | grep "pipeline {"
# Must return a match — not an encrypted or binary blob
```

## Jenkins vs GitHub Actions — Three Architectural Differences

1. **Execution model**: GitHub Actions runs on Microsoft-managed runners that are
   provisioned on demand and destroyed after each job. Jenkins runs on a
   persistent server (the controller) and optionally on agents you provision and
   manage yourself. This means Jenkins state — build history, credentials,
   plugins — lives on infrastructure you own.

2. **Pipeline definition authority**: GitHub Actions pipelines are YAML and rely
   on Actions marketplace steps maintained by third parties. Every time an action
   updates, your pipeline behaviour can change without any change in your repo.
   A Jenkinsfile is Groovy DSL executed entirely by your Jenkins instance —
   no external dependency resolution at runtime.

3. **Secret handling**: GitHub Actions secrets are stored in GitHub's secret
   store and injected as environment variables at runtime. Jenkins credentials
   are stored in the Jenkins Credential Store on your own server, encrypted with
   a key that never leaves your infrastructure. For compliance-heavy environments
   this is the deciding factor.

**Why enterprises mandate self-hosted CI**: An air-gapped network has no outbound
internet access by design. GitHub Actions requires outbound HTTPS to
`github.com`, `actions.githubusercontent.com`, and the runner pool endpoints.
None of those routes exist. Jenkins with a local agent needs only the internal
network. This is not a preference — it is a hard technical requirement in
regulated industries (finance, defence, healthcare).

## Stretch Challenge

Jenkins stores build history, credentials, installed plugins, and job
configurations inside the container at `/var/jenkins_home`. If the container is
deleted, everything is gone — you would have to reconfigure Jenkins from scratch,
recreate all credentials, and lose all build history. Fix this by mounting the
Jenkins home directory to a named Docker volume. Demonstrate persistence: trigger
a build, stop and delete the container, start a new container with the same
volume mount, and confirm the previous build is visible in the UI without any
reconfiguration.

## Instructor Notes

The most common first failure: students run Jenkins and immediately try to create
a pipeline job pointing at the repo, but forget to install the Pipeline plugin
(and optionally Blue Ocean). The `jenkins/jenkins:lts` base image does not
include Pipeline by default — walk through the setup wizard and install the
suggested plugins, or show the `--volume` + `plugins.txt` pattern for automated
plugin installation.

The "lint failure blocks test" requirement trips up students who use
`catchError(buildResult: 'UNSTABLE')` — that marks the build unstable but still
runs the next stage. The correct pattern is to let the stage fail naturally:
a non-zero exit from the shell command will fail the stage and Jenkins will not
execute subsequent stages in a Declarative pipeline unless `when` or `catchError`
overrides that.
