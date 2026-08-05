# Bootstrap GitHub and Azure

[Central SDAF hub](https://github.com/Azure/sap-automation) |
[Previous: Prerequisites and planning](01-00-prerequisites.md) |
[Troubleshooting](troubleshooting.md)

## Outcome

You have a customer configuration repository with the GitHub App, repository settings,
Azure identity, control-plane environment, secrets, variables, and initial `WORKSPACES`
configuration required by the deployment workflows.

## Ownership boundary

The [SDAF GitHub Actions setup utility](https://github.com/Azure/sap-automation/tree/main/deploy/scripts/py_scripts/SDAF-GitHub-Actions)
in the core `Azure/sap-automation` repository creates the GitHub App, repository settings,
Azure identity, and first control-plane environment. This repository owns the customer
configuration templates and workflows that the utility configures. The core repository
also owns the deployer and self-hosted runner implementation.

See the setup utility's
[upstream README](https://github.com/Azure/sap-automation/blob/main/deploy/scripts/py_scripts/SDAF-GitHub-Actions/README.md)
for its source documentation.

## Before you begin

Complete [Prerequisites and planning](01-00-prerequisites.md). Record the reviewed SDAF
tag or commit, target repository, control-plane name, Azure tenant and subscription,
authentication method, and approved role assignments.

## Create the configuration repository

If needed, create a repository from the [`Azure/sap-automation-gh-bootstrap`](https://github.com/Azure/sap-automation-gh-bootstrap) template by selecting [**Use this template**](https://github.com/new?template_name=sap-automation-gh-bootstrap&template_owner=Azure).

Use the generated repository as the long-lived home for SDAF configuration. Do not store credentials in tracked files.

## Configure cloud and OIDC behavior

Configure the repository variables `ARM_ENVIRONMENT`, `AZURE_ENVIRONMENT`, and
`AZURE_AUDIENCE` before running workflow `00`. That workflow copies the values to the new
control-plane environment, and workflow `02` propagates them to workload environments.

For Public Azure, use `public`, `AzureCloud`, and `api://AzureADTokenExchange`. For Azure
Government, use `usgovernment`, `AzureUSGovernment`, and
`api://AzureADTokenExchangeUSGov`.

`AZURE_ENVIRONMENT` and `AZURE_AUDIENCE` configure the `azure/login` step; `ARM_ENVIRONMENT`
configures the `azurerm` Terraform provider. Both are required, because a sovereign-cloud
deployment that sets only the login values fails later with
`AADSTS900382: Confidential Client is not supported in Cross Cloud request`.

Private DNS suffixes: after configuring the login values,
uncomment the Azure Government `dns_zone_names` block in each applicable generated
`WORKSPACES` `.tfvars` file. See
[Azure Government endpoint guidance](https://learn.microsoft.com/azure/azure-government/compare-azure-government-global-azure).

By default the setup utility does not hard-code the OIDC subject. It queries the repository's
GitHub OIDC customization endpoint and builds the subject from the `sub_claim_prefix` GitHub
reports, appending `:environment:<environment>`. Organizations that have enabled the immutable
subject claim therefore get a subject of the form
`repo:<owner>@<owner-id>/<repository>@<repository-id>:environment:<environment>`, not
`repo:<owner>/<repository>:environment:<environment>`. Check the actual subject on the created
`GitHubActions` federated credential before debugging OIDC failures.

Two environment variables override this behaviour:

| Variable | Effect |
| --- | --- |
| `SDAF_GITHUB_OIDC_SUBJECT_FORMAT` | `standard` forces `repo:<owner>/<repository>:environment:<environment>`; `immutable` forces the ID-based form. Any other value is rejected. |
| `SDAF_GITHUB_OIDC_SUBJECT` | Uses the supplied string verbatim as the subject and skips both the query and the format validation. |

The audience is `api://AzureADTokenExchange`. If your GitHub organization emits a subject that
does not match the created credential, set one of the variables above and rerun, or edit the
`GitHubActions` federated credential to match the exact subject reported by GitHub Actions
before deploying.

## Review before execution

1. Verify that the setup utility comes from the reviewed SDAF tag or commit.
2. Review the GitHub App permissions, PAT scopes, Azure role assignments, identity type,
   federated credential subject, and target repository.
3. Confirm that the repository default branch is `main` and that workflow permissions
   allow the utility and creation workflows to commit configuration. Under
   **Settings > Actions > General > Workflow permissions**, select
   **Read and write permissions**. Workflow `00` commits the generated `WORKSPACES`
   configuration back to the repository and fails without it.
4. Confirm that no credentials will be written to tracked files or shell history.

## Download and run the setup utility

The entry script imports files from the adjacent `sdaf` package, so the scripts below download the complete [setup utility directory](https://github.com/Azure/sap-automation/tree/main/deploy/scripts/py_scripts/SDAF-GitHub-Actions) rather than only `New-SDAFGitHubActions.py`.

### Windows

Run in PowerShell from a working directory outside the configuration repository:

```powershell
$source = "https://api.github.com/repos/Azure/sap-automation/contents/deploy/scripts/py_scripts/SDAF-GitHub-Actions?ref=main"
$destination = Join-Path $PWD "SDAF-GitHub-Actions"

function Save-GitHubDirectory {
	param([string] $Uri, [string] $Path)

	New-Item -ItemType Directory -Path $Path -Force | Out-Null
	$headers = @{
		Accept = "application/vnd.github+json"
		"User-Agent" = "SDAF-Setup"
	}
	$items = Invoke-RestMethod -Uri $Uri -Headers $headers

	foreach ($item in $items) {
		$target = Join-Path $Path $item.name
		if ($item.type -eq "dir") {
			Save-GitHubDirectory -Uri $item.url -Path $target
		} elseif ($item.type -eq "file") {
			Invoke-WebRequest -Uri $item.download_url -OutFile $target
		}
	}
}

Save-GitHubDirectory -Uri $source -Path $destination
Set-Location $destination

python -m venv .venv
./.venv/Scripts/Activate.ps1
python -m pip install -r requirements.txt

az login
az account set --subscription <subscription-id>
az account show --output table

python ./New-SDAFGitHubActions.py
```

### Linux

Run in Bash from a working directory outside the configuration repository:

```bash
source_url="https://api.github.com/repos/Azure/sap-automation/contents/deploy/scripts/py_scripts/SDAF-GitHub-Actions?ref=main"
destination="$PWD/SDAF-GitHub-Actions"

python3 - "$source_url" "$destination" <<'PY'
import json
from pathlib import Path
import sys
from urllib.request import Request, urlopen

headers = {
	"Accept": "application/vnd.github+json",
	"User-Agent": "SDAF-Setup",
}

def read_json(url):
	with urlopen(Request(url, headers=headers)) as response:
		return json.load(response)

def save_directory(url, path):
	path.mkdir(parents=True, exist_ok=True)
	for item in read_json(url):
		target = path / item["name"]
		if item["type"] == "dir":
			save_directory(item["url"], target)
		elif item["type"] == "file":
			with urlopen(Request(item["download_url"], headers=headers)) as response:
				target.write_bytes(response.read())

save_directory(sys.argv[1], Path(sys.argv[2]))
PY

cd "$destination"

python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt

az login
az account set --subscription <subscription-id>
az account show --output table

python3 ./New-SDAFGitHubActions.py
```

Both scripts use the `main` branch. For a reproducible production setup, replace `main` in `ref=main` with a reviewed SDAF tag or commit SHA.

The utility guides you through these steps:

1. Create and install a GitHub App. The utility's generated link requests Actions (read),
   Administration (write), Contents (write), Environments (write), Issues (write), Secrets
   (write), Variables (write), and Workflows (write). Metadata (read) is granted implicitly.
2. Provide a classic GitHub PAT with the `repo`, `workflow`, and `admin:repo_hook` scopes. Organization policy can require approval or additional scopes.
3. Select the configuration repository and GitHub server URL.
4. Define the control-plane name.
5. Select the Azure subscription and authentication method.
6. Create or reuse an Azure identity and configure federated authentication.
7. Optionally add SAP S-user credentials and enable the SDAF configuration web application.
8. Add repository values, trigger workflow `00`, and configure the generated control-plane environment.

Treat the PAT, GitHub App private key, client secrets, and SAP password as sensitive. Revoke temporary credentials when they are no longer required.

## Choose authentication

- **Service principal** provides straightforward initial setup, with a client secret that must be protected and rotated.
- **User-assigned managed identity** is preferred for the self-hosted runner because it avoids a long-lived deployment secret. An initial service principal is still required before the self-hosted runner exists.

The workflows sign in twice, by two different mechanisms:

| Layer | Mechanism | Reads |
| --- | --- | --- |
| `azure/login` step | GitHub OIDC federated credential | `AZURE_ENVIRONMENT`, `AZURE_AUDIENCE` |
| Terraform and Ansible | Service principal secret, or managed identity when `USE_MSI` is `true` | `ARM_ENVIRONMENT`, `ARM_CLIENT_SECRET` |

The deployment scripts do not use the workflow's OIDC token. When `USE_MSI` is `false`, the
control-plane environment must therefore also contain an `ARM_CLIENT_SECRET` secret holding
a valid client secret for the `ARM_CLIENT_ID` application. The setup utility does not create
it, and the workflows fail with `AADSTS7000215: Invalid client secret provided` when it is
missing, empty, or expired.

Create the secret before running workflow `01`:

```powershell
az ad app credential reset --id <application-id> --append `
  --display-name sdaf-gh-actions --years 1 -o json | ConvertFrom-Json | `
  Select-Object -ExpandProperty password
```

Store the value as `ARM_CLIENT_SECRET` in the control-plane environment, and in every
workload-zone environment that workflow `02` creates.

## Name the control plane

Control-plane names use `ENV-LOCA-VNET`, for example `MGMT-WEEU-DEP01`.

The setup utility enforces an environment code of no more than five characters, an SDAF region code of exactly four characters, and a virtual network code of no more than seven characters. Confirm the region code exists in SDAF's region mapping before starting workflow `00`.

Workflow `00` resolves the region code against the `sap_namegenerator` module **inside the
container image referenced by `DOCKER_IMAGE`**, not against the `sap-automation` repository.
Verify the mapping in the image you intend to use:

```powershell
docker run --rm --entrypoint sh <docker-image> -c `
  "grep -n '\"<region-code>\"' /source/deploy/terraform/terraform-units/modules/sap_namegenerator/variables_global.tf"
```

Use the lowercase four-character code; `region_mapping` is keyed by full region name with the
lowercase code as its value, while workflow `00` prints the code in uppercase.

If the code is absent, workflow `00` fails with `Error: Invalid index`, prints an empty
`Region:`, and writes `location = ""` into the generated deployer and library `.tfvars`.

## Repository defaults

| Variable | Default |
| --- | --- |
| `DOCKER_IMAGE` | `ghcr.io/azure/sap-automation:main` |
| `TF_VERSION` | `1.14.6` |
| `ANSIBLE_CORE_VERSION` | `2.16` |
| `TF_IN_AUTOMATION` | `true` |
| `TF_LOG` | `ERROR` |

For production, pin the SDAF container to a tested release or digest. The utility also creates repository secrets for the GitHub App. GitHub supplies `GITHUB_TOKEN` automatically; do not duplicate it.

> [!IMPORTANT]
> The `main` tag is not rebuilt on every merge and can lag the `sap-automation` repository by
> weeks. Features present in the repository are therefore not necessarily present in the
> image. Azure Government region codes (`USAR`, `USTE`, `USVI`) in particular require an image
> that includes SDAF 3.22 or later. Check the image before running workflow `00`:
>
> ```powershell
> docker image inspect <docker-image> --format '{{.Created}}'
> ```
>
> Set `DOCKER_IMAGE` to a version-pinned tag or digest that contains the SDAF release you
> reviewed rather than relying on `main`.

## Verify bootstrap

1. Confirm that the expected repository variables and GitHub App secrets exist.
2. Confirm that the control-plane environment exists and contains the expected variables
   and secrets.
3. Confirm that workflow `00` succeeded.
4. Confirm that deployer and library `.tfvars` files were committed under `WORKSPACES`.
5. Record the configuration commit, reviewed SDAF version, identity, and environment name.

Confirm that the Entra federated credential issuer, audience, and subject exactly match the
values emitted by GitHub Actions. For Public Azure, verify that the existing `azure/login`
steps authenticate successfully with their default cloud settings. For Azure Government,
do not proceed until cloud-specific action inputs and environment propagation have been
implemented and validated.

Treat generated files as reviewed configuration snapshots. Customize and commit them before
deployment; later changes to `.cfg_template` do not retroactively update existing snapshots.

Secret values cannot be read back from GitHub. Replace a secret if its source value is unknown.

## If bootstrap fails

Do not rerun the utility without reviewing what it already created. Inspect its terminal
output, the workflow `00` run, repository settings, GitHub App installation, environment
values, federated credential, and Azure role assignments. Reuse or remove partial resources
only after you identify the failed step. See
[Troubleshoot GitHub Actions deployments](troubleshooting.md).

## Next step

Continue to [Create and deploy the control plane](03-00-control-plane.md).
