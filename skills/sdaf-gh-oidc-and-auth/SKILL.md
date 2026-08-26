---
name: sdaf-gh-oidc-and-auth
description: |
  Action-loop skill for authenticating the SDAF GitHub Actions workflows to
  Azure. Two independent layers must both be right: (1) `azure/login` uses an
  OIDC federated credential and reads `AZURE_ENVIRONMENT` +
  `AZURE_AUDIENCE`; (2) Terraform and Ansible authenticate separately via
  either a managed identity (`USE_MSI=true`, `MSI_ID`) or a service principal
  with `ARM_CLIENT_SECRET`, and always read `ARM_ENVIRONMENT`. This skill
  resolves `AADSTS7002381` (enterprise-claim tenant policy),
  `AADSTS7000215` / `AADSTS700016` (missing or expired `ARM_CLIENT_SECRET`),
  `AADSTS900382` (sovereign-cloud `ARM_ENVIRONMENT` not exported alongside
  ARM creds), and "`azure/login` succeeded but hit the wrong cloud". Invoke
  on Azure-login failures, OIDC federated-credential questions, MSI-vs-SPN
  choice, or sovereign-cloud identity configuration. Do NOT invoke for
  bootstrap mechanics or the setup utility (use `sdaf-gh-bootstrap`) or for
  the workflow catalogue (use `sdaf-gh-workflow-sequence`).
allowed-tools: [Read, Grep]
license: MIT
metadata:
  author: Microsoft
  version: 0.1.0
  class: action-loop
---

# sdaf-gh-oidc-and-auth

Diagnoses and configures the two independent authentication layers that every
SDAF GitHub Actions workflow uses to reach Azure: `azure/login` (OIDC) and
Terraform / Ansible (MSI or SPN + `ARM_CLIENT_SECRET`).

## When to invoke

Concrete triggers:

- "`azure/login` failed" / OIDC federated-credential errors.
- `AADSTS7002381`, `AADSTS7000215`, `AADSTS700016`, `AADSTS900382`.
- "Which of MSI or SPN should I use?" / "Do I still need
  `ARM_CLIENT_SECRET` if I'm on OIDC?"
- "How is the OIDC subject built?" / "Immutable / ID-based sub claim."
- "`azure/login` connected to the wrong cloud" / sovereign-cloud identity.

Do NOT invoke for:

- Creating the repo, running the setup utility, provisioning the GitHub
  App, dispatching workflow `00` → `sdaf-gh-bootstrap`.
- Ordered `00`-`12` catalogue → `sdaf-gh-workflow-sequence`.

## The two layers (canonical)

The `docs/troubleshooting.md` § "Azure login fails" note is unambiguous:
`azure/login` and Terraform authenticate **independently**. `azure/login`
reads `AZURE_ENVIRONMENT`; the `azurerm` provider reads `ARM_ENVIRONMENT`.
See [`docs/troubleshooting.md` § Azure login fails](../../docs/troubleshooting.md#azure-login-fails).

| Layer | What it uses | Reads | Fails if |
|---|---|---|---|
| `azure/login` step | OIDC federated credential from GitHub | `AZURE_ENVIRONMENT`, `AZURE_AUDIENCE` | issuer/audience/subject mismatch, or tenant blocks the claim |
| Terraform / Ansible | MSI (`USE_MSI=true` + `MSI_ID`) or SPN (`ARM_CLIENT_ID` + `ARM_CLIENT_SECRET`) | `ARM_ENVIRONMENT`, `ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`, optionally `ARM_CLIENT_SECRET` | secret missing/expired, wrong cloud, wrong subscription |

Terraform does **not** consume the workflow's OIDC token. If `USE_MSI=false`
the SPN's `ARM_CLIENT_SECRET` must be present in the control-plane
Environment and every workload-zone Environment. See
[`docs/troubleshooting.md` § Terraform fails with AADSTS7000215 or AADSTS700016](../../docs/troubleshooting.md#terraform-fails-with-aadsts7000215-or-aadsts700016)
and [`docs/02-00-bootstrap.md` § Choose authentication](../../docs/02-00-bootstrap.md#choose-authentication).

## Recipe — diagnose an authentication failure

1. **Identify which layer failed.** Look at the failing step name.
   `Azure Login`, `azure/login@...` → layer 1. `terraform plan/apply`,
   `azurerm` provider, Ansible calling ARM → layer 2.
2. **For layer-1 failures**, verify `AZURE_ENVIRONMENT`, `AZURE_AUDIENCE`,
   and the OIDC subject registered on the app match the workflow's
   `sub_claim_prefix`. See
   [`docs/02-00-bootstrap.md` § Configure cloud and OIDC behavior](../../docs/02-00-bootstrap.md#configure-cloud-and-oidc-behavior).
3. **If layer 1 returns `AADSTS7002381`**, this is a **tenant policy**
   requiring an enterprise claim, not a misconfiguration. Route to a
   repository owned by a GitHub Enterprise organisation, or a tenant that
   does not enforce the policy. See
   [`docs/troubleshooting.md` § Azure login fails with AADSTS7002381](../../docs/troubleshooting.md#azure-login-fails-with-aadsts7002381).
4. **For layer-2 failures**, decide whether `USE_MSI` is `true` or `false`.
   If `false`, verify `ARM_CLIENT_SECRET` is set in the failing Environment
   and not expired.
   `AADSTS7000215` / `AADSTS700016` == missing/expired secret. See
   [`docs/troubleshooting.md` § Terraform fails with AADSTS7000215 or AADSTS700016](../../docs/troubleshooting.md#terraform-fails-with-aadsts7000215-or-aadsts700016).
5. **If layer 1 succeeded but the deploy hit the wrong cloud**, the
   `azure/login` step is missing `environment` / `audience` and defaulted
   to `AzureCloud`. Set `AZURE_ENVIRONMENT` + `AZURE_AUDIENCE` (plus
   `ARM_ENVIRONMENT`) at the step. See
   [`docs/troubleshooting.md` § azure/login succeeds against the wrong cloud](../../docs/troubleshooting.md#azurelogin-succeeds-against-the-wrong-cloud).
6. **For `AADSTS900382` (sovereign)**, `azurerm` fell back to Public Azure
   while identity lives in the sovereign tenant. Export `ARM_ENVIRONMENT`
   alongside ARM credentials in every Terraform step. See
   [`docs/troubleshooting.md` § Terraform fails with AADSTS900382 in a sovereign cloud](../../docs/troubleshooting.md#terraform-fails-with-aadsts900382-in-a-sovereign-cloud).

## Verify outcomes

- The failing step (or a `test` re-dispatch on workflows `03`, `05`, `12`)
  now completes past the auth boundary.
- Both `AZURE_ENVIRONMENT` and `ARM_ENVIRONMENT` are visible in the
  step-env dump and match the target cloud.
- For sovereign clouds, the cloud matrix table in
  [`references/cloud-matrix.md`](references/cloud-matrix.md) reflects the
  documented values.

## Hard rules

- **Do not conflate the two layers.** Setting `ARM_ENVIRONMENT` alone does
  not fix an `azure/login` cloud mismatch; setting `AZURE_ENVIRONMENT`
  alone does not fix a Terraform cloud mismatch.
  [`docs/troubleshooting.md` § azure/login succeeds against the wrong cloud](../../docs/troubleshooting.md#azurelogin-succeeds-against-the-wrong-cloud).
- **`GITHUB_TOKEN` is not a substitute for `ARM_CLIENT_SECRET`.** Terraform
  does not consume the OIDC token in this template.
  [`docs/troubleshooting.md` § Terraform fails with AADSTS7000215 or AADSTS700016](../../docs/troubleshooting.md#terraform-fails-with-aadsts7000215-or-aadsts700016).
- **Enterprise-claim tenant policy (`AADSTS7002381`) is not fixable inside
  the workflow.** It requires org ownership or a tenant that does not
  enforce the policy.
  [`docs/troubleshooting.md` § Azure login fails with AADSTS7002381](../../docs/troubleshooting.md#azure-login-fails-with-aadsts7002381).

## What this skill does NOT do

- Does not describe repo-creation, template-repo mechanics, or the setup
  utility → `sdaf-gh-bootstrap`.
- Does not enumerate every workflow's inputs → `sdaf-gh-workflow-sequence`.
- Does not describe workflow-`07` behaviour (blocked in current docs).

## See also

- [`sdaf-gh-bootstrap`](../sdaf-gh-bootstrap/SKILL.md)
- [`sdaf-gh-workflow-sequence`](../sdaf-gh-workflow-sequence/SKILL.md)
- [`references/cloud-matrix.md`](references/cloud-matrix.md)