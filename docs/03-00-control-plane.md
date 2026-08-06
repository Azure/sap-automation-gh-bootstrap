# Create and deploy the control plane

[Central SDAF hub](https://github.com/Azure/sap-automation) |
[Previous: Bootstrap GitHub and Azure](02-00-bootstrap.md) |
[Troubleshooting](troubleshooting.md)

## Outcome

You have a validated SDAF control plane containing the deployer virtual machine, SAP
library, shared Terraform state, credentials, and self-hosted GitHub Actions runner.

## Before you begin

Verify that bootstrap completed, workflow `00` committed the deployer and library
configuration, and the configuration commit is approved. Record the control-plane
environment name and the reviewed SDAF container tag or digest.

## Inputs

- The control-plane GitHub environment.
- The generated deployer and library `.tfvars` files under `WORKSPACES`.
- The approved Azure identity, network, DNS, sizing, storage, and optional web application
  decisions.

## Create the environment and configuration

The bootstrap utility triggers workflow `00 - Create Control Plane Environment`. You can also run it manually from the repository's **Actions** tab.

Provide a control-plane name using `ENV-LOCA-VNET`, whether to use a user-assigned managed identity, the identity resource ID when reusing one, and whether to deploy the optional configuration web application.

Workflow `00`:

1. Creates a GitHub environment named after the control plane.
2. Uses `.cfg_template/deployer.tfvars` to generate `WORKSPACES/DEPLOYER/<control-plane>-INFRASTRUCTURE/<control-plane>-INFRASTRUCTURE.tfvars`.
3. Uses `.cfg_template/library.tfvars` to generate `WORKSPACES/LIBRARY/<environment>-<region>-SAP_LIBRARY/<environment>-<region>-SAP_LIBRARY.tfvars`.
4. Commits and pushes both files to the branch selected when workflow `00` was dispatched.

Dispatch workflow `00` from `main`. Although workflow `00` pushes to its selected ref, later workflows `02` and `04` explicitly pull from and push to `main`.

## Review generated configuration

The generated files are the Terraform deployment inputs and may be customized independently
of their source templates. Review subscription and region, management network ranges,
existing resource IDs, Firewall and Bastion choices, DNS, private endpoints, deployer VM
sizing, storage, locks, tags, monitoring, security, and optional web application settings.
Commit approved changes before running workflow `01`.

Non-commented values are required workflow substitutions or deliberate configuration.
Commented values are optional defaults, examples, or values injected by SDAF scripts as
identified in the template comments. Public Azure uses Terraform DNS defaults and leaves the
Government `dns_zone_names` block commented. For Azure Government, first implement and
validate cloud-specific `azure/login` behavior as described in the bootstrap guide, then
uncomment the Government block in both generated files.

Verify private DNS zones and virtual network links cover every network that must resolve
private endpoints. If service endpoints are selected instead, verify the required services
are enabled on the intended subnets and that resource firewall rules match the design.

The SAP library provides persistent storage for Terraform state and SAP installation media.
Protect the state storage account, keep state keys stable, and avoid concurrent deployments
against the same state. See [SDAF control-plane configuration](https://learn.microsoft.com/azure/sap/automation/configure-control-plane).

## Control-plane dry-run limitation

> [!CAUTION]
> Do not rely on workflow `01`'s **Perform a dry-run validation** input. The current workflow declares the input but does not forward it to either control-plane script, so selecting it does not guarantee a plan-only run.

> [!CAUTION]
> Test mode is not a dry run in any workflow that supports it. A run with the test option
> enabled still creates Azure resources. If such a run fails, remove what it provisioned
> with the removal workflow rather than assuming nothing was created.

Before using this workflow in a deployment, update and test the implementation so the input reaches the SDAF scripts and demonstrably prevents apply operations. Until then, obtain and review a control-plane Terraform plan outside this workflow: check out the configuration repository on the setup workstation, then run the SDAF control-plane deployment script in plan-only mode against `WORKSPACES/DEPLOYER/<control-plane>-INFRASTRUCTURE/<control-plane>-INFRASTRUCTURE.tfvars` and `WORKSPACES/LIBRARY/<control-plane>-INFRASTRUCTURE/<control-plane>-INFRASTRUCTURE.tfvars`, as described in [SDAF control-plane configuration](https://learn.microsoft.com/azure/sap/automation/configure-control-plane). There is currently no in-workflow equivalent.

## Deploy the control plane

After the control-plane plan has been reviewed through a validated process:

1. Open **Actions** and select **01 - Deploy Control Plane**.
2. Select the approved control-plane environment.
3. Leave **Perform a dry-run validation** disabled because the current implementation does
   not provide a plan-only safety gate.
4. Review all inputs and the selected configuration commit.
5. Run the workflow and monitor the GitHub-hosted preparation job and self-hosted jobs.

![Run workflow for the control plane](RunWorkflowDeployControlPlane.png)

The first job runs on a GitHub-hosted runner. The deployment creates the deployer VM, installs and registers a self-hosted runner, and uses it for the remaining jobs.

After deployment, review the workflow summary and confirm that the environment contains downstream values such as the deployer Key Vault, Terraform state storage account, and application configuration name.

## Validate the runner

1. Open **Settings** > **Actions** > **Runners** and confirm the runner is **Online** and
   idle.
2. Confirm that the deployer VM is running and the `configure_deployer` extension
   succeeded.
3. Confirm outbound connectivity from the deployer to GitHub, Azure, package sources, and
   required SAP endpoints.
4. Confirm that Terraform state and SAP library storage exist and that the workflow summary
   contains the expected downstream values.
5. Record the workflow run, configuration commit, state key, and deployed version.

## If deployment fails

Review the first failed job before retrying. Preserve the generated configuration and
Terraform state. Resolve authentication, quota, policy, networking, or runner registration
errors, then obtain a new plan through the validated planning process.

If runner installation failed, remove only the failed `configure_deployer` extension and
stale runner registration, then rerun workflow `01` with **Force a re-install** enabled.
Do not run concurrent retries against the same state. See
[Troubleshoot GitHub Actions deployments](troubleshooting.md).

## Next step

Continue to [Create and deploy a workload zone](04-00-workload-zone.md).
