# Security Policy

## Supported Versions

We currently provide security updates only for the **latest tagged release** and the **master branch**.

| Version / Branch      | Supported          | Receiving Security Fixes |
|-----------------------|--------------------|---------------------------|
| Latest release tag    | :white_check_mark: | Yes                       |
| master branch         | :white_check_mark: | Yes                       |
| Older tagged releases | :x:                | No                        |

## Reporting a Vulnerability

**Please report security issues responsibly** — we take all security reports seriously.

The preferred and fastest way to report a potential vulnerability is:

→ **[Open a private security advisory](https://github.com/quantbelt/jupyter-quant/security/advisories/new)**  
(GitHub's built-in private vulnerability reporting — only maintainers can see it)

We aim to acknowledge receipt of your report within **48 hours** and provide an estimated timeline for resolution within the following **7 days**.

### What to include in your report

- Description of the vulnerability  
- Steps to reproduce (if possible)  
- Affected versions / Docker tags / dependency combinations  
- Potential impact (what could an attacker achieve?)  
- Any suggested mitigation / fix  
- Your name/handle (for credit in the hall of fame — optional)

## Security Overview of This Project

This repository contains **no application code** — it is a **metapackage / curated environment** providing:

- A Dockerfile  
- Curated set of pinned Python dependencies (quantitative finance, data analysis, scientific computing, Jupyter ecosystem)  
- Pre-configured Jupyter environment

Therefore the **primary security surface** consists of:

1. Base image vulnerabilities (ie `python:3` or `python:3-slim`)  
2. Vulnerabilities in the ~70–100 Python packages we install  
3. Vulnerabilities in OS-level packages inside the container  
4. Supply-chain attacks on PyPI packages (typosquatting, compromised maintainers, etc.)

### Our current security posture & practices (as of 2026)

- We **pin** dependency versions in `pyproject.toml`
- We run automated dependency scanning using **OSV-Scanner** on every push/PR  
  → Results are visible in [Security → Code scanning tab](https://github.com/quantbelt/jupyter-quant/security/code-scanning)  
- We periodically (weekly/monthly) update dependencies and rebuild images  
- We use multi-stage builds where possible to reduce attack surface  
- We avoid installing packages with `sudo pip`, `--user`, or `--break-system-packages` flags  
- We do **not** run the container as root (default Jupyter user)

### Known security limitations

- We cannot guarantee that **all** transitive dependencies are free of vulnerabilities  
- Some quantitative finance / scientific packages have long and complex dependency trees  
- We sometimes need to use relatively recent / pre-release versions for new features  
- Jupyter notebook environments are inherently **dynamic** and allow arbitrary code execution

→ **Users should treat images from this repository as development / research environments, not as hardened production containers.**

## Best Practices for Users

1. Always pull the **latest** image tag you intend to use  
   ```bash
   docker pull ghcr.io/quantbelt/jupyter-quant:latest
   ```
1. Check the Security tab before using a new image version
1. Run containers with minimal privileges:
   ```bash
    docker run --rm -it --user $(id -u):$(id -g) \
    -v "${PWD}":/home/jovyan/work \
    ghcr.io/quantbelt/jupyter-quant:latest
   ```
1. If you discover a critical vulnerability in any of our dependencies, please report it upstream first (to the affected project), then let us know so we can update our pins.

Thank you for helping keep the quantitative finance community safer!

— The jupyter-quant maintainers

Last updated: January 2026
