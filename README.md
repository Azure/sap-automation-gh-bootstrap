# SAP Deployment Automation Framework with GitHub Actions

This repository is a configuration and workflow template for deploying SAP on Azure with the [SAP Deployment Automation Framework (SDAF)](https://github.com/Azure/sap-automation). SDAF uses Terraform to deploy infrastructure and Ansible to configure operating systems and install SAP software.

## Repository responsibilities

- [`Azure/sap-automation`](https://github.com/Azure/sap-automation) is the central SDAF
  documentation hub. It owns the core Terraform, Ansible, deployment scripts, runner
  implementation, and the
  [`SDAF-GitHub-Actions` setup utility](https://github.com/Azure/sap-automation/tree/main/deploy/scripts/py_scripts/SDAF-GitHub-Actions).
- [`Azure/sap-automation-gh-bootstrap`](https://github.com/Azure/sap-automation-gh-bootstrap)
  (this repository) is the customer configuration template. It owns the `.cfg_template`
  files, generated `WORKSPACES` configuration, and GitHub Actions workflows.
- [`Azure/sap-automation-bootstrap`](https://github.com/Azure/sap-automation-bootstrap)
  owns the Azure DevOps customer configuration and wrapper pipelines.
- [`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples)
  owns shared Terraform samples and SAP Bill of Materials (BoM) definitions consumed by
  the execution models.

Use the [central SDAF hub](https://github.com/Azure/sap-automation) to compare GitHub
Actions, Azure DevOps, and local or scripted execution. This repository documents only
the GitHub Actions-specific procedure.

The deployment consists of:

1. A **control plane** containing the deployer virtual machine, SAP library, Terraform state, credentials, and self-hosted GitHub Actions runner.
2. An **SAP application plane** containing workload zones and SAP systems managed by the control plane.

> [!WARNING]
> The sample configuration creates billable Azure resources. Review architecture, networking, sizing, quota, security, and cost before applying a Terraform plan.

## AI-skills plugin

This repository ships an AI-skills plugin,
`azure-sap-automation-github`, that gives GitHub Copilot CLI, Claude Code,
and Gemini CLI grounded context about the GitHub Actions procedure for
SDAF: the bootstrap flow and setup utility, public Azure authentication
diagnostics (with documented sovereign-cloud limitations), and the
ordered `00`–`12` workflow catalogue. The plugin is documentation and
diagnostics only — it does not modify workflows, `.cfg_template/`, or
`WORKSPACES/`, and installing it is never a prerequisite for using the
workflows.

**All SDAF AI plugins are optional and independently installable.** For
complete coverage:

- Local or scripted execution: install the hub plugin
  `azure-sap-automation` from
  [`Azure/sap-automation`](https://github.com/Azure/sap-automation).
- Azure DevOps control plane: install the hub plus the Azure DevOps
  plugin `azure-sap-automation-devops` from
  [`Azure/sap-automation-bootstrap`](https://github.com/Azure/sap-automation-bootstrap).
- GitHub Actions control plane (this repository): install the hub plus
  `azure-sap-automation-github` shown below.

**The hub plugin is recommended for complete coverage; this plugin does
not install it automatically.** See [`docs/PLUGINS.md`](docs/PLUGINS.md)
for the full operator flow (verify, prompt examples, troubleshooting).

### GitHub Copilot CLI

```bash
copilot plugin marketplace add Azure/sap-automation-gh-bootstrap
copilot plugin install azure-sap-automation-github@sap-automation-gh-bootstrap
```

### Claude Code

```text
/plugin marketplace add Azure/sap-automation-gh-bootstrap
/plugin install azure-sap-automation-github@sap-automation-gh-bootstrap
```

### Gemini CLI

```bash
gemini extensions install https://github.com/Azure/sap-automation-gh-bootstrap
```

For verification, example prompts, and troubleshooting, continue in
[`docs/PLUGINS.md`](docs/PLUGINS.md).

## Getting started

Follow the guides in order:

1. [Prerequisites and planning](docs/01-00-prerequisites.md)
2. [Bootstrap GitHub and Azure](docs/02-00-bootstrap.md)
3. [Create and deploy the control plane](docs/03-00-control-plane.md)
4. [Create and deploy a workload zone](docs/04-00-workload-zone.md)
5. [Create and deploy an SAP system](docs/05-00-sap-system.md)
6. [Download software and install SAP](docs/06-00-software-installation.md)
7. [Operations, troubleshooting, and removal](docs/07-00-operations.md)

Do not start with workflow `01`. The bootstrap process and workflow `00` create the GitHub environment, secrets, variables, and Terraform configuration required by later workflows.

## Workflow sequence

| Order | Workflow | Outcome |
| --- | --- | --- |
| 00 | Create Control Plane Environment | Control-plane GitHub environment and configuration |
| 01 | Deploy Control Plane | Deployer, SAP library, and self-hosted runner |
| 02 | Create workload environment | Workload-zone environment and configuration |
| 03 | Deploy SAP Workload Zone | Shared workload-zone infrastructure |
| 04 | Create SYSTEM environment | SAP system configuration committed to `WORKSPACES`; no GitHub environment is created |
| 05 | SAP SID Infrastructure deployment | SAP virtual machines and infrastructure |
| 06 or 06.5 | Download SAP software | SAP installation media |
| 07 | Operating System Configuration and Installation | Configured and installed SAP system |

Wait for each workflow to succeed and review its output before starting the next one.

Workflows `00`, `02`, and `04` provide GitHub-specific configuration generation. Workflow
`00` creates the control-plane GitHub environment, and workflow `02` creates the
workload-zone GitHub environment. Despite its display name, workflow `04` only generates
and commits SAP-system configuration. Workflow `05` uses the selected workload-zone
environment for credentials and variables.

## Configuration templates and deployment inputs

Files under `.cfg_template` are source templates. Creation workflows substitute their
`@@...@@` placeholders and generate the Terraform deployment inputs under `WORKSPACES`:

| Source template | Creation workflow | Generated configuration |
| --- | --- | --- |
| `deployer.tfvars` | `00 - Create Control Plane Environment` | `WORKSPACES/DEPLOYER/.../*.tfvars` |
| `library.tfvars` | `00 - Create Control Plane Environment` | `WORKSPACES/LIBRARY/.../*.tfvars` |
| `landscape.tfvars` | `02 - Create workload environment` | `WORKSPACES/LANDSCAPE/.../*.tfvars` |
| `system.tfvars` | `04 - Create SYSTEM environment` | `WORKSPACES/SYSTEM/.../*.tfvars` |

The generated `WORKSPACES` files, not `.cfg_template` directly, are the deployment inputs.
Review and customize generated files after creation, then commit approved changes before
running the corresponding deployment workflow. Template changes affect future generation;
they do not update existing `WORKSPACES` files. Apply approved changes to both locations
when a setting must remain consistent for current and future environments.

In each template, non-commented assignments are mandatory workflow values or deliberate
generated configuration. Commented assignments are optional and show the current Terraform
default unless explicitly labeled as an example or cloud-specific override; comments also
identify required values that SDAF scripts inject at deployment time.

Each template contains one commented `dns_zone_names` block with Azure Government values.
For Public Azure, leave it commented because Terraform already supplies the Public Azure DNS
zone names by default. Do not add a redundant Public Azure assignment or enable multiple
blocks.

Set the repository variables `ARM_ENVIRONMENT`, `AZURE_ENVIRONMENT`, and `AZURE_AUDIENCE`
before creating environments. Workflow `00` copies them to the control-plane environment,
and workflow `02` propagates them to workload environments. Public Azure defaults are
`public`, `AzureCloud`, and `api://AzureADTokenExchange`. For Azure Government, use
`usgovernment`, `AzureUSGovernment`, and `api://AzureADTokenExchangeUSGov`, then uncomment
the Government `dns_zone_names` block in each applicable generated configuration.

Deployment is intentionally staged. Later workflows consume the approved `WORKSPACES`
configuration and Terraform state persisted by the SAP library, so complete and validate
each stage before starting a dependent stage.

## Current implementation status

This repository is an evolving template. Review these limitations before using it for deployment:

| Area | Status | Required action |
| --- | --- | --- |
| Workflow `01` dry run | Not operational | The `test` input is not forwarded to the deployment scripts. Do not use workflow `01` to obtain a plan-only run. |
| Workflow `07` installation | Blocked | The workflow currently contains invalid YAML indentation and an inconsistent inventory path. Correct and validate the workflow before running it. |
| Workflow `10` removal | Destructive, no plan mode | The workflow has no `test` input and defaults to removing the SAP system. Review every input before dispatch. |
| Azure Government login | Not implemented | `azure/login` uses Public Azure defaults and the setup utility does not create cloud-selection variables. Add and validate cloud-specific login inputs before using the workflows with Azure Government. |

The detailed guides identify these limitations at the affected steps.

## Repository layout

- `.cfg_template`: Terraform variable templates used by creation workflows.
- `.github/workflows`: GitHub Actions workflows for deployment and removal.
- `WORKSPACES`: generated and customized deployment configuration.
- `docs`: detailed setup, deployment, and operations guides.

For symptom-based diagnostics, see
[Troubleshoot GitHub Actions deployments](docs/troubleshooting.md).

## References

- [SDAF overview](https://learn.microsoft.com/azure/sap/automation/deployment-framework)
- [SDAF deployment planning](https://learn.microsoft.com/azure/sap/automation/plan-deployment)
- [SDAF control-plane configuration](https://learn.microsoft.com/azure/sap/automation/configure-control-plane)
- [Azure Government developer guidance](https://learn.microsoft.com/azure/azure-government/documentation-government-developer-guide)
- [Private endpoint DNS zone values](https://learn.microsoft.com/azure/private-link/private-endpoint-dns)
- [SDAF source](https://github.com/Azure/sap-automation)
- [SDAF samples](https://github.com/Azure/sap-automation-samples)
- [Central SDAF documentation hub](https://github.com/Azure/sap-automation)
