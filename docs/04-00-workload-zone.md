# Create and deploy a workload zone

A workload zone provides shared networking, storage, credentials, and services for one or more SAP systems.

## Create the workload environment

Run workflow `02 - Create workload environment`. Provide a workload-zone name using `ENV-LOCA-VNET`, such as `DEV-WEEU-SAP01`, and select the managing control-plane environment.

Workflow `02` creates the workload-zone GitHub environment, uses
`.cfg_template/landscape.tfvars` to generate
`WORKSPACES/LANDSCAPE/<workload-zone>-INFRASTRUCTURE/<workload-zone>-INFRASTRUCTURE.tfvars`,
commits it, and copies required control-plane settings into the environment. The generated
file is the Terraform deployment input and may be customized after creation.

## Review workload-zone configuration

Review:

- Subscription, region, and VNet address space.
- Existing VNet resource IDs when applicable.
- Admin, database, application, web, storage, and optional service subnets.
- Control-plane peering, DNS, routes, and network security groups.
- Public access, private endpoints, service endpoints, and firewalls.
- Key Vault authorization and secret retention.
- Installation and transport storage.
- NFS provider and Azure NetApp Files requirements.
- Resource locks, monitoring, and tags.

Ensure no subnet overlaps with the control plane, connected networks, or other workload zones. Commit approved changes.

When `use_separate_storage_subnet` is `true`, provide either
`storage_subnet_address_prefix` for a new subnet or `storage_subnet_arm_id` for an
existing subnet. Otherwise, leave it `false` so storage private endpoints use the
application subnet.

Private endpoints consume private IP addresses and depend on correct DNS resolution. Confirm
the required private DNS zones are linked to the control-plane and workload-zone virtual
networks that need resolution. Service endpoints are subnet-scoped; when private endpoints
are enabled, service endpoints do not remove the private endpoint DNS requirements. For
Public Azure leaves the Government `dns_zone_names` block commented. For Azure Government,
first implement and validate cloud-specific `azure/login` behavior as described in the
bootstrap guide, then uncomment the Government block in the generated workload-zone file.

The SDAF `private_endpoint_network_policies` input controls network security group and
route-table policy support for private endpoints on workload-zone subnets. It defaults to
`Enabled` and supports `Disabled`, `Enabled`, `NetworkSecurityGroupEnabled`, and
`RouteTableEnabled`. Select the value required by the network design; Azure Government
environments may require `Disabled`. See
[Manage network policies for private endpoints](https://learn.microsoft.com/azure/private-link/disable-private-endpoint-network-policy).

Confirm the deployment identity has approved Azure RBAC assignments at the target subscription
or resource scopes, including any separate DNS subscription or resource group.

## Plan and deploy

1. Select workflow **03 - Deploy SAP Workload Zone**.
2. Choose the workload-zone and control-plane environments.
3. Enable the test option and review the Terraform plan.
4. Run workflow `03` again with the test option disabled.

The deployment runs on the self-hosted deployer runner. Confirm the expected resource group, VNet, subnets, storage, and Key Vault exist; verify peering, DNS, routes, private endpoint resolution, and Terraform state.

Do not create SAP systems until the workload-zone deployment and its persisted Terraform
state have been validated.

## Next step

Continue to [Create and deploy an SAP system](05-00-sap-system.md).
