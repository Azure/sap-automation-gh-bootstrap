# Prerequisites and planning

Complete the following checks before configuring GitHub Actions or deploying Azure resources.

## GitHub requirements

You need a GitHub account with permission to:

- Administer the configuration repository.
- Install a GitHub App.
- Manage Actions secrets and variables.
- Create and manage GitHub environments.
- Run and monitor GitHub Actions workflows.

Ensure that GitHub Issues are enabled, the repository plan supports environments, the default branch has an appropriate protection policy, and environment access is restricted to authorized operators.

> [!IMPORTANT]
> The configuration repository's default branch must currently be named `main`. The setup utility and workflows `02` and `04` hard-code that branch when dispatching, pulling, or pushing changes.

## Local tools

Install Python 3.10 or later, Git, and Azure CLI. Verify them with:

```powershell
python --version
git --version
az version
```

## Azure access

Select the target Azure cloud before signing in. Use `AzureCloud` for Public Azure or
`AzureUSGovernment` for Azure Government:

```powershell
az cloud set --name <AzureCloud-or-AzureUSGovernment>
az login
az account show --output table
```

Change the active subscription when needed:

```powershell
az account set --subscription <subscription-id>
```

Azure Government uses cloud-specific service endpoints and can have different regional
service availability. Review the
[Azure Government developer guide](https://learn.microsoft.com/azure/azure-government/documentation-government-developer-guide)
before bootstrap.

> [!IMPORTANT]
> Selecting `AzureUSGovernment` in Azure CLI does not configure the GitHub Actions workflows.
> The current `azure/login` steps use Public Azure defaults. Add and validate the action's
> cloud-specific `environment` and `audience` inputs throughout the workflow set before using
> this repository for Azure Government.

### Bootstrap operator permissions

The person running bootstrap needs permission to create or manage resource groups, identities or app registrations, federated credentials, and role assignments. In many organizations this requires suitable Microsoft Entra directory permissions plus `Owner`, or `Contributor` together with `User Access Administrator`, at the target Azure scope. Coordinate the exact access with your Azure administrator.

### Deployment identity roles

The setup utility creates or reuses the service principal or managed identity used by the workflows and attempts to configure its access. The exact role set is version-dependent because the utility is maintained in the external `Azure/sap-automation` repository.

Before running bootstrap, review the role-assignment implementation in the same SDAF tag or commit selected for the [setup utility](https://github.com/Azure/sap-automation/tree/main/deploy/scripts/py_scripts/SDAF-GitHub-Actions). Have an Azure administrator approve the effective roles and scopes for that version. Apply least privilege separately to the human operator and the deployment identity.

Azure RBAC grants a security principal a role at a specific scope. Confirm both the role
definition and scope for the bootstrap operator, service principal, or managed identity;
see [Azure RBAC overview](https://learn.microsoft.com/azure/role-based-access-control/overview).

## Capacity and service prerequisites

Before deployment, confirm:

- Regional quota for the deployer and selected SAP VM families.
- Availability of selected VM images and Azure services in the target region.
- Network access from the deployer to GitHub, Azure, package repositories, and SAP download endpoints.
- DNS, routing, firewall, and private endpoint integration requirements.
- An SAP S-user with software download rights before the software download stage.

See [Plan your SAP deployment](https://learn.microsoft.com/azure/sap/automation/plan-deployment) for current endpoint and architecture guidance.

### Network and DNS planning

Reserve nonoverlapping address spaces for the control plane, workload zones, connected
networks, and optional private endpoint subnets. A private endpoint places a network
interface with a private IP address in a virtual network; DNS must resolve the service FQDN
to that address. Link each required private DNS zone to the virtual networks that need
resolution. Service endpoints are configured on subnets and are a different connectivity
model; select the model approved for each service.

See [Private endpoint overview](https://learn.microsoft.com/azure/private-link/private-endpoint-overview),
[private endpoint DNS zone values](https://learn.microsoft.com/azure/private-link/private-endpoint-dns),
[private DNS virtual network links](https://learn.microsoft.com/azure/dns/private-dns-virtual-network-links),
and [virtual network service endpoints](https://learn.microsoft.com/azure/virtual-network/virtual-network-service-endpoints-overview).

## Cost and architecture review

The templates are examples, not an approved production architecture. Defaults can create virtual machines, Azure Firewall, Bastion, storage, Key Vault, App Configuration, and private endpoints.

Agree on subscriptions, regions, network address spaces, connectivity, DNS, VM sizing, high availability, storage, security policy, monitoring, backup, and resource retention before continuing.

## Next step

Continue to [Bootstrap GitHub and Azure](02-00-bootstrap.md).
