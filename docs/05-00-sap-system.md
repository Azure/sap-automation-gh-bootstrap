# Create and deploy an SAP system

[Central SDAF hub](https://github.com/Azure/sap-automation) |
[Previous: Workload zone](04-00-workload-zone.md) |
[Troubleshooting](troubleshooting.md)

## Outcome

You have validated infrastructure for one SAP system ID (SID), including the database,
central services, application servers, storage, load balancers, and supporting resources.

## Before you begin

Verify that the workload zone is healthy and its Terraform state is available. Record the
approved workload-zone environment, three-character SID, topology, BoM, sizing, and
configuration commit.

## Inputs

- A three-character SAP SID.
- The existing workload-zone GitHub environment.
- The approved system topology, images, sizes, storage, network, and installation settings.

## Create system configuration

Run workflow `04 - Create SYSTEM environment`. Provide a three-character SAP SID, such as `X00`, and select the workload-zone environment.

Workflow `04` uses `.cfg_template/system.tfvars` to generate and commit
`WORKSPACES/SYSTEM/<workload-zone>-<sid>/<workload-zone>-<sid>.tfvars`. The generated file
is the Terraform deployment input and may be customized after creation. Workflow `05`
binds the selected workload-zone environment and uses its Azure credentials for deployment.

Despite its display name, workflow `04` does not create a GitHub environment. It runs on a
GitHub-hosted runner and commits only the SAP-system `WORKSPACES` configuration to `main`.

## Review system configuration

The generated file describes a sample distributed HANA system. Adapt it to the approved SAP design. Review:

- SAP SID, database SID, platform, and topology.
- Database, central services, and application server counts.
- High availability and scale-out.
- VM images, SAP-certified sizes, zones, and availability sets.
- Disk controller and storage sizing.
- NFS and shared storage.
- Load balancer and secondary IP requirements.
- Network inheritance from the workload zone.
- Authentication, patching, monitoring, and security extensions.
- BoM and installation settings.

Validate image and size availability, SAP support, and quota. Commit approved changes.

The system normally consumes networking, DNS, credentials, and shared services from its
workload zone. Use system-level subnet, DNS, or storage overrides only when the approved
design requires them. Public Azure leaves the Government `dns_zone_names` block commented.
For Azure Government, first implement and validate cloud-specific `azure/login` behavior as
described in the bootstrap guide, then uncomment the Government block in the generated
system file.

## Plan and deploy

1. Select workflow **05 - SAP SID Infrastructure deployment**.
2. Enter the same SAP SID and select the workload-zone environment.
3. Enable **Test deployment without applying changes**.
4. Review the Terraform plan.
5. Confirm that the plan uses the approved `WORKSPACES/SYSTEM` file and configuration
   commit.
6. Run workflow `05` again with test mode disabled.

Confirm expected VMs, disks, NICs, load balancers, and storage; validate deployer connectivity, DNS, Key Vault credentials, and Terraform state. Do not begin installation until infrastructure validation succeeds.

Keep the generated system configuration in version control and preserve its associated
Terraform state for later configuration, installation, and removal stages.

## If deployment fails

Resolve the first actionable configuration, identity, quota, image, storage, network, DNS,
or state error. Preserve the system configuration and state, rerun test mode, and review
the replacement plan before apply. Do not run concurrent workflows against the system
state. See [Troubleshoot GitHub Actions deployments](troubleshooting.md).

## Next step

Continue to [Download software and install SAP](06-00-software-installation.md).
