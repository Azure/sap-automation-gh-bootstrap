# Operations, troubleshooting, and removal

[Central SDAF hub](https://github.com/Azure/sap-automation) |
[Previous: Software and installation](06-00-software-installation.md) |
[Detailed troubleshooting](troubleshooting.md)

## Outcome

You can operate, diagnose, recover, and remove an SDAF deployment without bypassing
Terraform state or dependency order.

## Before you begin

Record the configuration commit, pinned SDAF image, Terraform and Ansible versions,
workflow runs, state keys, backups, and current health of every deployed layer. Require
independent approval before a destructive workflow.

## Operating practices

- Review every workflow summary before starting the next stage.
- Do not run concurrent workflows against the same Terraform state.
- Protect environment secrets and require approvals where appropriate.
- Pin and record tested SDAF, Terraform, and Ansible versions.
- Review Terraform plans before apply or destroy operations when the workflow provides a validated plan-only path.
- Back up SAP data and retain deployment evidence according to policy.

## No environments appear

Confirm the bootstrap utility completed, workflow `00` succeeded, the expected environment exists under **Settings** > **Environments**, and your GitHub account can access it.

## Missing variables or secrets

Check repository values under **Settings** > **Secrets and variables** > **Actions** and environment values under **Settings** > **Environments**. Confirm values are in the scope used by the failing job.

Secret values cannot be read back from GitHub. Replace a secret if its source is unknown. Do not manually create `GITHUB_TOKEN`; GitHub supplies it.

## Azure login fails

Check subscription and tenant IDs, client ID, authentication mode, federated credential issuer/audience/subject, environment name, role assignments, and client secret validity when applicable.

For OIDC failures, compare the issuer, audience, and subject emitted by GitHub Actions with
the Entra federated credential; all three must match exactly. Verify that `ARM_ENVIRONMENT`,
`AZURE_ENVIRONMENT`, and `AZURE_AUDIENCE` are set at the repository level and were copied to
the selected GitHub environment. Azure Government uses `usgovernment`,
`AzureUSGovernment`, and `api://AzureADTokenExchangeUSGov`.

By default the setup utility derives the subject from the repository's GitHub OIDC
customization endpoint, so on organizations that use the immutable subject claim it creates
`repo:<owner>@<owner-id>/<repository>@<repository-id>:environment:<environment>` rather than
`repo:<owner>/<repository>:environment:<environment>`. Read the subject from the created
`GitHubActions` federated credential rather than assuming the standard form. To force a
subject, set `SDAF_GITHUB_OIDC_SUBJECT_FORMAT` to `standard` or `immutable`, or set
`SDAF_GITHUB_OIDC_SUBJECT` to an exact value, and rerun the utility. Otherwise, edit the
`GitHubActions` federated credential to match the exact emitted value.

## Self-hosted runner is offline

1. Inspect **Settings** > **Actions** > **Runners**.
2. Confirm the deployer VM is running.
3. Inspect the `configure_deployer` VM extension.
4. Confirm outbound connectivity to GitHub and required SDAF endpoints.
5. Check the runner service and logs.

## Retry runner installation

1. Remove the failed `configure_deployer` extension from the deployer VM.
2. Remove the stale runner registration.
3. Run workflow `01` with **Force a re-install** enabled.
4. Review each retry because recovery can continue from partially created resources.

## Terraform or deployment failures

Read the first actionable error, confirm the expected configuration commit and environment, verify the Terraform state key, resolve quota/policy/naming/provider/image/network/permission errors, and run a plan again before applying.

Avoid manually deleting resources managed by Terraform unless the recovery procedure requires it; manual deletion can create state drift.

Use [Troubleshoot GitHub Actions deployments](troubleshooting.md) for generation,
authentication, runner, BoM, installation, and branch-conflict symptoms.

## Removal order

Remove resources in reverse dependency order:

1. Back up or retain SAP data and deployment evidence.
2. Remove SAP systems.
3. Remove a workload zone after all its systems are removed.
4. Remove the control plane after all dependent workload zones are removed.

### Workflow 10 safeguards

> [!CAUTION]
> Workflow `10 - SAP Infrastructure removal` has no plan-only input. It defaults `cleanup_sap` to `true`, and its undefined `inputs.test` reference does not provide a usable safety gate. Dispatching the workflow can immediately remove infrastructure.

Use these input combinations only after independent review and approval:

| Intent | `cleanup_sap` | `cleanup_workload_zone` |
| --- | --- | --- |
| Remove one SAP system | `true` | `false` |
| Remove an empty workload zone | `false` | `true` |

Do not enable both options unless removing both layers in one run is intentional and the dependency order has been independently validated. Workload-zone removal also currently passes `vars.MSI_ID` as `ARM_CLIENT_ID`, unlike the other jobs; verify or correct that identity configuration before use.

Use `.github/workflows/12-remove-control-plane.yml`, displayed in GitHub Actions as
`11 - Remove Control Plane`, only after all dependent systems and workload zones are gone.
Unlike workflow `10`, this workflow exposes a `test` input and forwards it to the external
SDAF removal scripts as `TEST_ONLY`. Validate that end-to-end behavior against the pinned
SDAF version before relying on it as a safe plan-only path.

For both removal workflows, inspect the inputs, Terraform state, resource locks, retained storage, and recovery requirements before dispatch.

## Validate removal

1. Confirm that the workflow removed only the approved layer.
2. Confirm that retained data, storage, logs, and deployment evidence remain available as
   required.
3. Verify Terraform state and GitHub environments before removing the next dependency
   layer.
4. Record the workflow run, approval, state disposition, and any manually retained
   resources.

## If removal fails

Do not start another removal workflow or manually delete resources. Review the failed core
script, current state, locks, and remaining resources. Correct the cause, confirm the same
input scope, and retry only after independent review. See
[Troubleshoot GitHub Actions deployments](troubleshooting.md).

## Return to overview

Return to the [repository README](../README.md), or use the
[central SDAF hub](https://github.com/Azure/sap-automation) to choose another execution
model.
