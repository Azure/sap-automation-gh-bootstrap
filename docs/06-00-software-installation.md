# Download software and install SAP

[Central SDAF hub](https://github.com/Azure/sap-automation) |
[Previous: SAP system](05-00-sap-system.md) |
[Troubleshooting](troubleshooting.md)

## Outcome

You have approved SAP installation media in the SAP library and, after workflow `07` is
corrected and validated, a configured and installed SAP system.

## Before you begin

Verify that SAP-system infrastructure is healthy, the self-hosted runner is online, and the
system configuration and state are preserved. Obtain an approved BoM from
[`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples), which
owns the shared BoM definitions used by these workflows.

## Inputs

- The control-plane and workload-zone GitHub environments.
- The SAP SID and approved BoM selection.
- SAP S-user credentials with software download rights.
- The installation-stage switches and any approved Ansible extra parameters.

## Prepare SAP credentials

Use an SAP S-user authorized to download the selected software. Confirm the expected GitHub environment contains the S-user name and password. Do not store SAP credentials in tracked files.

## Choose a download workflow

- `06 - Download SAP software` selects a predefined combined Bill of Materials (BoM).
- `06.5 - Download SAP software - new` selects separate application, database, and kernel BoMs and combines them under a selected name.

Use the workflow compatible with the approved BoM model. Do not run both for the same installation unless both media sets are intentional.

## Download SAP software

1. Select workflow `06` for a predefined combined BoM, or select workflow `06.5` to combine
   separate application, database, and kernel BoMs.
2. Select the control-plane environment and the approved BoM inputs.
3. Enable re-download only when approved media must be replaced.
4. Review the selected BoM names, platform, storage impact, credentials, and extra
   parameters.
5. Run the workflow.

For workflow `06.5`, select mutually compatible application, kernel, database, and
platform values. Set either:

- `bom_override_name` to the exact custom BoM name to use; or
- `bom_save_name` to a non-empty suffix. The workflow constructs the name as `<application>-<database>-<kernel>-<save-name>`.

For example, selecting `APP_S4_2025_v0001ms`, `DB_HANA_2_00_SPS08_latest`, `SAP_KERNEL_793_latest`, and save name `S4HANA` produces:

`APP_S4_2025_v0001ms-DB_HANA_2_00_SPS08_latest-SAP_KERNEL_793_latest-S4HANA`

Do not leave `bom_save_name` empty unless the workflow implementation has been corrected and tested. The current expression retains a trailing hyphen instead of reliably defaulting to the application BoM name.

After completion, review the summary and confirm the required media exists in SAP library storage.

## Configure and install SAP

> [!CAUTION]
> Workflow `07` is currently blocked. Its YAML contains tab indentation, which is invalid, and its parameter-validation step passes an absolute inventory path that the composite action prefixes with another folder. Correct both issues and validate the workflow before dispatching it.

After the workflow has been corrected and validated, run `07 - Operating System Configuration and Installation`. Provide the SAP SID, workload-zone environment, BoM name, and any required Ansible parameters.

When media came from workflow `06.5`, enter the exact combined name in workflow `07`'s `bom_override_name` input. Its predefined `bom_name` choices do not include dynamically composed names.

The workflow exposes switches for core and SAP-specific OS configuration, BoM processing, central services, database installation and load, high availability, application servers, and Web Dispatcher.

For the first installation, keep all stages required by the approved topology enabled. On retry, disable only stages known to be complete and safe to skip.

Before dispatching the corrected workflow, review the selected BoM, system configuration,
inventory, stage switches, credentials, backups, and maintenance window. Record approval
for any stage that changes an existing SAP system.

## Validate installation

Validate OS package state, SAP processes, database connectivity, central services, load balancers, application server registration, shared mounts, DNS, time synchronization, monitoring, backup, security controls, and installation logs.

Record the deployed BoM, SDAF version or container digest, Terraform version, Ansible version, and configuration commit.

## If download or installation fails

For a download failure, preserve existing media, correct credentials, storage, or BoM
selection, and rerun with re-download disabled unless replacement is intentional.

Do not dispatch workflow `07` while the blocking YAML and inventory defects remain. After
the workflow is corrected, use its stage switches only when logs and system validation
prove that earlier stages completed successfully. See
[Troubleshoot GitHub Actions deployments](troubleshooting.md).

## Next step

Continue to [Operations, troubleshooting, and removal](07-00-operations.md).
