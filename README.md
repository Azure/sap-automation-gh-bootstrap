# SAP Deployment Automation Framework with GitHub Actions

This repository is a configuration and workflow template for deploying SAP on Azure with the [SAP Deployment Automation Framework (SDAF)](https://github.com/Azure/sap-automation). SDAF uses Terraform to deploy infrastructure and Ansible to configure operating systems and install SAP software.

The deployment consists of:

1. A **control plane** containing the deployer virtual machine, SAP library, Terraform state, credentials, and self-hosted GitHub Actions runner.
2. An **SAP application plane** containing workload zones and SAP systems managed by the control plane.

> [!WARNING]
> The sample configuration creates billable Azure resources. Review architecture, networking, sizing, quota, security, and cost before applying a Terraform plan.

## Getting started

Follow the guides in order:

1. [Prerequisites and planning](docs/01-prerequisites.md)
2. [Bootstrap GitHub and Azure](docs/02-bootstrap.md)
3. [Create and deploy the control plane](docs/03-control-plane.md)
4. [Create and deploy a workload zone](docs/04-workload-zone.md)
5. [Create and deploy an SAP system](docs/05-sap-system.md)
6. [Download software and install SAP](docs/06-software-installation.md)
7. [Operations, troubleshooting, and removal](docs/07-operations.md)

Do not start with workflow `01`. The bootstrap process and workflow `00` create the GitHub environment, secrets, variables, and Terraform configuration required by later workflows.

## Workflow sequence

| Order | Workflow | Outcome |
| --- | --- | --- |
| 00 | Create Control Plane Environment | Control-plane GitHub environment and configuration |
| 01 | Deploy Control Plane | Deployer, SAP library, and self-hosted runner |
| 02 | Create workload environment | Workload-zone environment and configuration |
| 03 | Deploy SAP Workload Zone | Shared workload-zone infrastructure |
| 04 | Create SYSTEM environment | SAP system configuration |
| 05 | SAP SID Infrastructure deployment | SAP virtual machines and infrastructure |
| 06 or 06.5 | Download SAP software | SAP installation media |
| 07 | Operating System Configuration and Installation | Configured and installed SAP system |

Wait for each workflow to succeed and review its output before starting the next one.

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
When deploying to `AzureUSGovernment`, explicitly uncomment that entire block. For Public
Azure, leave it commented because Terraform already supplies the Public Azure DNS zone
names by default. Do not add a redundant Public Azure assignment or enable multiple blocks.
The GitHub environment's `AZURE_ENVIRONMENT` selects Azure authentication endpoints; the
`dns_zone_names` override separately selects the Private DNS suffixes used by Terraform.

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

The detailed guides identify these limitations at the affected steps.

## Repository layout

- `.cfg_template`: Terraform variable templates used by creation workflows.
- `.github/workflows`: GitHub Actions workflows for deployment and removal.
- `WORKSPACES`: generated and customized deployment configuration.
- `docs`: detailed setup, deployment, and operations guides.

## References

- [SDAF overview](https://learn.microsoft.com/azure/sap/automation/deployment-framework)
- [SDAF deployment planning](https://learn.microsoft.com/azure/sap/automation/plan-deployment)
- [SDAF control-plane configuration](https://learn.microsoft.com/azure/sap/automation/configure-control-plane)
- [Azure Government developer guidance](https://learn.microsoft.com/azure/azure-government/documentation-government-developer-guide)
- [Private endpoint DNS zone values](https://learn.microsoft.com/azure/private-link/private-endpoint-dns)
- [SDAF source](https://github.com/Azure/sap-automation)
- [SDAF samples](https://github.com/Azure/sap-automation-samples)
