# `sdaf-gh-oidc-and-auth` — cloud matrix

Documented values from [`docs/02-00-bootstrap.md` § Configure cloud and OIDC behavior](../../../docs/02-00-bootstrap.md#configure-cloud-and-oidc-behavior)
and [`README.md` § Configuration templates and deployment inputs](../../../README.md#configuration-templates-and-deployment-inputs).

| Variable | Layer | Public Azure | Azure US Government |
|---|---|---|---|
| `AZURE_ENVIRONMENT` | `azure/login` | `AzureCloud` | `AzureUSGovernment` |
| `AZURE_AUDIENCE` | `azure/login` | `api://AzureADTokenExchange` | `api://AzureADTokenExchangeUSGov` |
| `ARM_ENVIRONMENT` | Terraform / `azurerm` | `public` | `usgovernment` |

Both `AZURE_ENVIRONMENT` and `ARM_ENVIRONMENT` must be exported alongside
ARM credentials in every Terraform step. Omitting either defaults that
layer to Public Azure — the recurring cause of `AADSTS900382` and of
`azure/login` "succeeding" against the wrong cloud.

## Sovereign extras

For Azure US Government, `.cfg_template/` blocks for `dns_zone_names` must
be uncommented. See [`README.md` § Configuration templates and deployment inputs](../../../README.md#configuration-templates-and-deployment-inputs).
The current template also documents sovereign-cloud enablement as
incomplete — see [`README.md` § Current implementation status](../../../README.md#current-implementation-status).

## Federated-credential subject

The OIDC subject format comes from GitHub's OIDC customization endpoint and
may be the standard `repo:<owner>/<repo>:environment:<env>` shape or an
immutable / ID-based form. Read GitHub's actual `sub_claim_prefix` before
registering the federated credential — the docs at
[`docs/02-00-bootstrap.md` § Configure cloud and OIDC behavior](../../../docs/02-00-bootstrap.md#configure-cloud-and-oidc-behavior)
call this out explicitly.