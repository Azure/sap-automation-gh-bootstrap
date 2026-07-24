# Bootstrap GitHub and Azure

The [SDAF GitHub Actions setup utility](https://github.com/Azure/sap-automation/tree/main/deploy/scripts/py_scripts/SDAF-GitHub-Actions) creates the GitHub App, repository settings, Azure identity, and first control-plane environment. See its [upstream README](https://github.com/Azure/sap-automation/blob/main/deploy/scripts/py_scripts/SDAF-GitHub-Actions/README.md) for the source documentation.

## Create the configuration repository

If needed, create a repository from the [`Azure/sap-automation-gh-bootstrap`](https://github.com/Azure/sap-automation-gh-bootstrap) template by selecting [**Use this template**](https://github.com/new?template_name=sap-automation-gh-bootstrap&template_owner=Azure).

Use the generated repository as the long-lived home for SDAF configuration. Do not store credentials in tracked files.

## Configure cloud and OIDC behavior

The setup utility uses the active Azure CLI subscription and tenant while creating or reusing
the deployment identity. It does not create `AZURE_ENVIRONMENT` or `AZURE_AUDIENCE` GitHub
variables. The current workflows call `azure/login` without cloud-specific `environment` or
`audience` inputs, and workflow `02` copies neither value to workload environments.

Consequently, the current implementation uses the Public Azure defaults. Before using these
workflows with Azure Government, update and validate every `azure/login` step and propagate
any required cloud-selection values to newly created environments. Cloud-specific login
support is separate from Terraform Private DNS suffixes: after the login flow is implemented,
uncomment the Azure Government `dns_zone_names` block in each applicable generated
`WORKSPACES` `.tfvars` file. See
[Azure Government endpoint guidance](https://learn.microsoft.com/azure/azure-government/compare-azure-government-global-azure).

The setup utility creates the standard OIDC subject
`repo:<owner>/<repository>:environment:<environment>` and the audience
`api://AzureADTokenExchange`. It does not currently support environment-variable overrides
for alternate subject formats. If your GitHub organization emits a different subject, update
and validate the setup utility or edit the federated credential to match the exact subject
reported by GitHub Actions before deploying.

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

1. Create and install a GitHub App with access to repository contents, workflows, Actions variables, environments, secrets, and Issues.
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

## Name the control plane

Control-plane names use `ENV-LOCA-VNET`, for example `MGMT-WEEU-DEP01`.

The setup utility enforces an environment code of no more than five characters, an SDAF region code of exactly four characters, and a virtual network code of no more than seven characters. Confirm the region code exists in SDAF's region mapping before starting workflow `00`.

## Repository defaults

| Variable | Default |
| --- | --- |
| `DOCKER_IMAGE` | `ghcr.io/azure/sap-automation:main` |
| `TF_VERSION` | `1.14.6` |
| `ANSIBLE_CORE_VERSION` | `2.16` |
| `TF_IN_AUTOMATION` | `true` |
| `TF_LOG` | `ERROR` |

For production, pin the SDAF container to a tested release or digest. The utility also creates repository secrets for the GitHub App. GitHub supplies `GITHUB_TOKEN` automatically; do not duplicate it.

## Verify bootstrap

Confirm that repository variables and GitHub App secrets exist, the control-plane environment was created, workflow `00` succeeded, and new deployer and library `.tfvars` files were committed under `WORKSPACES`.

Confirm that the Entra federated credential issuer, audience, and subject exactly match the
values emitted by GitHub Actions. For Public Azure, verify that the existing `azure/login`
steps authenticate successfully with their default cloud settings. For Azure Government,
do not proceed until cloud-specific action inputs and environment propagation have been
implemented and validated.

Treat generated files as reviewed configuration snapshots. Customize and commit them before
deployment; later changes to `.cfg_template` do not retroactively update existing snapshots.

Secret values cannot be read back from GitHub. Replace a secret if its source value is unknown.

## Next step

Continue to [Create and deploy the control plane](03-00-control-plane.md).
