# HTTPBin

Forked repo: https://github.com/tedKozub/httpbin
Used Anthropic Claude assistance, especially for updating python repo to updated packages

Changes made straight in master for simplicity, no PR

For k8s setup check out the README in /k8s/

# Edits made

Repo is ~8 years old and the Python version at that age was python 3.6-3.8 which
is currently outdated and EOL. Many of the packages at the compatible level versions
contain CVEs and didnt pass Trivy check. Thats why I edited som setup.py requires and
updated versions for Werkzeug and Flask. These changes also required minor fixes in tests
to pass properly.

Image chosen was chainguard (https://www.chainguard.dev). I tried python3.12-slim (7 CVEs) and distroless from Google and MS (4+ CVEs) but they didnt pass Trivy checks. chainguard/python:latest passes
all CVE checks and works with new versions of python libs.
The chainguard image also uses nonroot default user (https://edu.chainguard.dev/chainguard/chainguard-images/how-to-use/dev-containers/).

# CI/CD pipeline

The pipeline is setup in .github/workflows/ci.yml.
The basic check like ruff, pytest and bandit run in parallel. When all pass
we can build the artifacts (for linux x86 and also arm64 since I use macos and wanted to test it properly) and continue to trivy check and k8s deploy with basic smoke test that curls the web app
for health check. You can check the passing pipeline at the linked repo page.

## Steps

Quick overview of the pipeline steps:

### Parallel steps

- Lint - static control for code with ruff (subset of checks because the code is very old)-
- Test - pytest run to check endpoints. Some tests needed touchup with updated libs.
- SAST - check for security issues with bandit. (skip B324 (MD5) - httpbin requires)
- pip audit - scan for vulnerable packages
- trufflehog - checks for leaked access tokens and credentials

### Next steps

- build step (multiarch including arm64) - uploads artifacts to github container registry.
- trivy check - check for CVEs and image / package vulnerabilities. (HIGH, CRITICAL severity)
- k8s deploy - build temp cluster, deploy built image and test

# K8s setup

We use `kind` in the example. Check out /k8s/README.md for details.

# Run local docker

```
docker build -t httpbin:dev .
docker run --rm -p 8080:8080 httpbin:dev
```

# Known issues / tradeoffs

Python 3.14 instead of 3.12 The assignment recommends python:3.12-slim
or distroless. I chose distroless (Chainguard) because it ships with 0
HIGH/CRITICAL CVEs out of the box. Chainguard's public free tier only ships
the floating `latest` tag, currently Python 3.14. Pinning to `:3.12`
requires a paid subscription.

Using `latest` without pinning. Ideally we would use a container that has pinned
version or even sha256.

Not ideal: touched python code - bumped to Werkzeug 3 for CVE coverage, some tests
required patching. Ideally we would maintain the codebase and not stay with eol
python versions and libraries from 8 years ago.

Lint scope narrowed in Ruff. Again, the code is very old and contains legacy issues.
Without the skips and without code touchup ruff wont pass with default settings.

## In production

Apart from the tradeoffs we would ideally extend the deployment with other services:

Instead of push-based deploy from CI - ideally we would use gitops (ArgoCD / Flux)
Observability - Prometheus, Loki, Grafana
External secrets management - e.g. HC Vault
