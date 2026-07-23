# Create and deploy the control plane

The control plane contains the deployer virtual machine, SAP library, shared deployment state, credentials, and self-hosted GitHub Actions runner.

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
identified in the template comments. For Azure Government, explicitly uncomment the
Government `dns_zone_names` block in both generated files; Public Azure uses Terraform
defaults and leaves it commented.

Verify private DNS zones and virtual network links cover every network that must resolve
private endpoints. If service endpoints are selected instead, verify the required services
are enabled on the intended subnets and that resource firewall rules match the design.

The SAP library provides persistent storage for Terraform state and SAP installation media.
Protect the state storage account, keep state keys stable, and avoid concurrent deployments
against the same state. See [SDAF control-plane configuration](https://learn.microsoft.com/azure/sap/automation/configure-control-plane).

## Control-plane dry-run limitation

> [!CAUTION]
> Do not rely on workflow `01`'s **Perform a dry-run validation** input. The current workflow declares the input but does not forward it to either control-plane script, so selecting it does not guarantee a plan-only run.

Before using this workflow in a deployment, update and test the implementation so the input reaches the SDAF scripts and demonstrably prevents apply operations. Until then, obtain and review a control-plane Terraform plan through an independently validated SDAF process.

## Deploy the control plane

After the control-plane plan has been reviewed through a validated process, run workflow `01` to deploy.

![Run workflow for the control plane](RunWorkflowDeployControlPlane.png)

The first job runs on a GitHub-hosted runner. The deployment creates the deployer VM, installs and registers a self-hosted runner, and uses it for the remaining jobs.

After deployment, review the workflow summary and confirm that the environment contains downstream values such as the deployer Key Vault, Terraform state storage account, and application configuration name.

## Validate the runner

Open **Settings** > **Actions** > **Runners** and confirm the runner is **Online** and idle. Also confirm the deployer VM is running, the `configure_deployer` extension succeeded, outbound connectivity works, and state and library storage exist.

## Next step

Continue to [Create and deploy a workload zone](04-workload-zone.md).
