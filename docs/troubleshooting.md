# Troubleshoot GitHub Actions deployments

[Central SDAF hub](https://github.com/Azure/sap-automation) |
[GitHub Actions journey](../README.md) |
[Operations and removal](07-00-operations.md)

Use this page for the first diagnostic steps. Preserve configuration, logs, and Terraform
state before retrying.

## A creation workflow does not commit configuration

1. Confirm that the repository default branch is `main`.
2. Confirm that workflow permissions allow the built-in `GITHUB_TOKEN` to
   write repository contents, and review branch-protection requirements. The
   GitHub App token supports GitHub API operations such as environment setup;
   it is not the token used for these configuration commits.
3. Inspect the failed run for workflow `00`, `02`, or `04`.
4. Check whether another commit reached `main` before the workflow push.
5. Resolve the branch conflict, then rerun only the failed creation workflow.
6. Verify the expected file under `WORKSPACES` and review its commit before deployment.

Workflow `04` does not create a GitHub environment. Its expected result is only a committed
`WORKSPACES/SYSTEM/<workload-zone>-<sid>/<workload-zone>-<sid>.tfvars` file. Workflow `05`
uses the existing workload-zone environment.

## Azure login fails

1. Verify the tenant, subscription, client ID, authentication mode, and environment scope.
2. Compare the GitHub OIDC issuer, audience, and subject with the Microsoft Entra federated
   credential.
3. Verify role assignments at every required Azure scope.
4. Replace an unknown or expired secret; GitHub does not display stored secret values.

`azure/login` and Terraform authenticate independently. `azure/login` reads
`AZURE_ENVIRONMENT`, while the `azurerm` provider reads `ARM_ENVIRONMENT`. A sovereign-cloud
deployment must set both, otherwise `azure/login` succeeds and the failure only appears once
Terraform initializes its providers.

### Azure login fails with AADSTS7002381

```text
AADSTS7002381: Federated identity credentials issued by
'https://token.actions.githubusercontent.com/' for applications or managed identities
registered in this tenant must contain the enterprise claim with value 'microsoft',
'github' or 'microsoftopensource' but actual value is ''
```

This is a tenant policy, not a misconfiguration. The issuer, audience, and subject all match
the federated credential; comparing them does not help. GitHub issues the `enterprise` claim
only for repositories owned by an organization that belongs to a GitHub Enterprise account,
and the claim cannot be added through OIDC claim customization.

The policy is tenant-scoped. A repository and subject that fail in an enforcing tenant succeed
unchanged in a tenant that does not enforce the policy, so confirm which tenant you are
targeting before recreating the repository or the credential.

1. Confirm the repository owner type:
   `gh api repos/<owner>/<repository> -q .owner.type`. A `User` owner cannot satisfy an
   enforcing tenant's policy.
2. Recreate the configuration repository under an organization in a GitHub Enterprise
   account, then recreate the federated credential for the new subject, or
3. Target a subscription in a tenant that does not enforce the policy.

See [Tenant federated-credential policy and repository ownership](01-00-prerequisites.md#tenant-federated-credential-policy-and-repository-ownership).

### Workflow 00 reports "Invalid index" and an empty region

```text
Error: Invalid index
...
Region Code: USVI
Region:
```

Workflow `00` resolves the region code against the `sap_namegenerator` module inside the
container image referenced by `DOCKER_IMAGE`. The error means that image's `region_mapping`
does not contain the region code. The generated deployer and library `.tfvars` then receive
`location = ""`, which fails later workflows.

The `main` tag is not rebuilt on every merge and can lag the `sap-automation` repository, so a
region code present in the repository is not necessarily present in the image. Azure
Government codes (`USAR`, `USTE`, `USVI`) require an image containing SDAF 3.22 or later.

1. Check the mapping in the image, using the lowercase four-character code:

   ```powershell
   docker run --rm --entrypoint sh <docker-image> -c `
     "grep -n '\"<region-code>\"' /source/deploy/terraform/terraform-units/modules/sap_namegenerator/variables_global.tf"
   ```

2. Set `DOCKER_IMAGE` to a version-pinned tag or digest that contains the region code.
3. Re-run workflow `00` and confirm it prints a non-empty `Region:`, then confirm both
   generated `.tfvars` files contain the expected `location`.

### Terraform fails with AADSTS900382 in a sovereign cloud

```text
Error: building account: could not acquire access token to parse claims:
AADSTS900382: Confidential Client is not supported in Cross Cloud request.
```

The error is raised once for every `azurerm` provider block in the module. It means the
provider is authenticating against the Public Azure endpoint
(`login.microsoftonline.com`) while the identity exists in a sovereign tenant.

The `azurerm` provider selects its endpoint from `ARM_ENVIRONMENT`. Every workflow step
that invokes Terraform must therefore export `ARM_ENVIRONMENT` alongside `ARM_CLIENT_ID`,
`ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, and `ARM_TENANT_ID`:

```yaml
env:
  ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
  ARM_ENVIRONMENT: ${{ vars.ARM_ENVIRONMENT || 'public' }}
  ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
```

Confirm the fix by re-reading the failure: a correctly targeted request reports its
`error_uri` as `https://login.microsoftonline.us/error?code=...` rather than
`https://login.microsoftonline.com/error?code=...`.

### azure/login succeeds against the wrong cloud

`ARM_ENVIRONMENT` steers Terraform and Ansible. It does **not** steer the `azure/login`
action, which authenticates the Azure CLI. That action reads two separate inputs:

| Input | Variable | Sovereign value |
| --- | --- | --- |
| `environment` | `AZURE_ENVIRONMENT` | `AzureUSGovernment` |
| `audience` | `AZURE_AUDIENCE` | `api://AzureADTokenExchangeUSGov` |

An `azure/login` step that omits `environment` defaults to `AzureCloud`, so it either
fails to exchange the OIDC token or signs in to Public Azure while the rest of the
workflow targets a sovereign cloud. Every `azure/login` step must carry both inputs:

```yaml
- uses: azure/login@v3
  with:
    environment:    ${{ vars.AZURE_ENVIRONMENT || 'AzureCloud' }}
    audience:       ${{ vars.AZURE_AUDIENCE || 'api://AzureADTokenExchange' }}
    client-id:      ${{ vars.ARM_CLIENT_ID }}
    tenant-id:      ${{ vars.ARM_TENANT_ID }}
    subscription-id: ${{ vars.ARM_SUBSCRIPTION_ID }}
```

Set `AZURE_ENVIRONMENT`, `AZURE_AUDIENCE`, and `ARM_ENVIRONMENT` together as repository or
environment variables. Setting only `ARM_ENVIRONMENT` leaves the CLI on Public Azure, and
the resulting failure appears at the first `az` command rather than at the login step.

### Terraform fails with AADSTS7000215 or AADSTS700016

```text
Error: building account: could not acquire access token to parse claims:
AADSTS7000215: Invalid client secret provided.
```

Terraform does not use the workflow's OIDC token. The deployment scripts sign in with
either a service principal and client secret or a managed identity, selected by
`USE_MSI`. When `USE_MSI` is `false`, the `ARM_CLIENT_SECRET` secret must contain a valid,
unexpired client secret for the `ARM_CLIENT_ID` application, in the environment that runs
the workflow.

1. Create a new client secret on the application registration.
2. Store it as the `ARM_CLIENT_SECRET` secret in the control-plane environment, and in every
   workload-zone environment that the deployment creates.
3. Re-run the workflow.

GitHub does not display stored secret values, so an incorrect or truncated secret is only
visible as this error.

## The self-hosted runner is unavailable

1. Open **Settings** > **Actions** > **Runners** and inspect the runner status.
2. Confirm that the deployer VM is running.
3. Inspect the `configure_deployer` VM extension and runner service logs.
4. Verify outbound connectivity to GitHub, Azure, package sources, and required SAP
   endpoints.
5. Remove only a failed extension and stale runner registration before rerunning workflow
   `01` with **Force a re-install** enabled.

The runner installation is implemented by the core
[`Azure/sap-automation`](https://github.com/Azure/sap-automation) repository, not by this
configuration template.

## Terraform plan or apply fails

1. Confirm the selected GitHub environment and configuration commit.
2. Verify the expected `WORKSPACES` file and Terraform state key.
3. Read the first actionable error and correct identity, quota, policy, image, naming,
   network, DNS, storage, or provider issues.
4. Rerun the workflow in validated test mode when that workflow supports it.
5. Review the replacement plan before apply.

Do not run concurrent workflows against the same state. Do not manually delete managed
resources unless the approved recovery procedure requires it.

### Terraform fails with SkuNotAvailable

```text
Error: creating Linux Virtual Machine ...: unexpected status 409 (409 Conflict) with
error: SkuNotAvailable: The requested size for resource ... is currently not available
in location '<region>' ...
```

Virtual machine size availability differs by region and by subscription, and the defaults
in the module are not guaranteed to be offered in every region, particularly in Azure
Government.

1. List the sizes the subscription can actually use in the region:

   ```powershell
   az vm list-skus --location <region> --resource-type virtualMachines `
     --query "[?!(restrictions[0])].name" -o tsv
   ```

2. Set the corresponding size variable in the workspace `.tfvars` file to a size returned
   by that command. The deployer size is set with `deployer_size`.
3. Re-run the workflow.

> [!NOTE]
> Running a workflow in test mode validates the configuration but still creates Azure
> resources. It is not a dry run. Remove a failed deployment with the removal workflow
> rather than assuming that nothing was provisioned.

### Private endpoint creation fails with PrivateEndpointCannotBeCreatedInSubnetThatHasNetworkPoliciesEnabled

```text
creating Private Endpoint (Subscription: "..." Resource Group Name:
"<ZONE>-INFRASTRUCTURE" Private Endpoint Name: "<ZONE>-diag-storage-private-endpoint"):
unexpected status 400 (400 Bad Request) with error:
PrivateEndpointCannotBeCreatedInSubnetThatHasNetworkPoliciesEnabled
```

Observed in workflow `03 - Deploy SAP Workload Zone`. Azure refuses to place a private
endpoint in a subnet whose private endpoint network policies are enabled, so this fails
whenever `use_private_endpoint` is `true` and `private_endpoint_network_policies` is
`Enabled`.

The apply retries the import loop up to ten times before giving up, so the run can take
several minutes and reports `Return code from deployment: 5`.

Set the following in the workload zone `.tfvars` file and re-run:

```terraform
private_endpoint_network_policies = "Disabled"
```

Core SDAF versions that default this variable to `Enabled` reproduce the failure with an
otherwise untouched configuration. Confirm the default in the version you have pinned.

## Workflow 05 fails while reporting a successful deployment

Workflow `05 - SAP SID Infrastructure deployment` can end in a failed step whose own log
reads:

```text
Return code from deployment:         0
```

The deployment succeeded. `deploy/scripts/pipeline_scripts/v2/03-sap-system-deployment.sh`
then stages generated files for commit, and in affected core SDAF versions it overwrites
the deployment return code with `1` when `sap-parameters.yaml` is not present. That file
is produced by the Terraform apply, so it is legitimately absent for plan-only runs and
for runs that create no new infrastructure.

Judge the outcome from the deployment output, not from the step conclusion:

- `Return code from deployment: 0` together with a `Plan:` line and no Terraform `Error:`
  block means the deployment itself succeeded.
- A non-zero return code, or a Terraform `Error:` block, is a genuine failure.

Confirm the resources in the portal before re-running. Re-running an apply that already
succeeded is unnecessary and can force replacements.

## Software download fails

1. Confirm that the SAP S-user can download the selected media.
2. Verify the control-plane environment and SAP library storage.
3. For workflow `06`, verify the predefined combined BoM.
4. For workflow `06.5`, verify the application, database, kernel, platform, and exact
   combined name.
5. Keep re-download disabled unless replacing existing media is intentional.

The shared BoM definitions are owned by
[`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples).

## Workflow 07 cannot run

The currently merged `.github/workflows/07-configuration-installation.yml` remains
blocked. It contains tab indentation, which is invalid YAML. It also passes an absolute
inventory path to `.github/actions/run-ansible`, which prefixes that value with the
parameters folder and produces an inconsistent inventory path.

Do not dispatch workflow `07` until both defects are corrected and the complete workflow
is validated. After correction, retry only installation stages that logs and system checks
prove are safe to repeat.

## Removal cannot be safely previewed

Workflow `10 - SAP Infrastructure removal` has no declared `test` input, even though its
jobs reference `inputs.test`. Treat dispatch as destructive. Review the selected system,
workload zone, state, backups, locks, and cleanup switches before running it.

The file `.github/workflows/12-remove-control-plane.yml` is displayed as
`11 - Remove Control Plane`. It forwards its declared `test` input as `TEST_ONLY`, but
validate that behavior against the pinned core SDAF version before relying on it.

## Collect evidence before opening an issue

Record the workflow file and run URL, failing job and step, sanitized error, configuration
commit, selected environment, pinned SDAF image or digest, Terraform and Ansible versions,
affected state key, and whether the run was a retry. Do not include credentials, tokens,
private keys, SAP passwords, or unredacted Terraform state.
