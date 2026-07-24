# Download software and install SAP

The final deployment stage downloads SAP installation media, configures operating systems, and installs the selected SAP components.

## Prepare SAP credentials

Use an SAP S-user authorized to download the selected software. Confirm the expected GitHub environment contains the S-user name and password. Do not store SAP credentials in tracked files.

## Choose a download workflow

- `06 - Download SAP software` selects a predefined combined Bill of Materials (BoM).
- `06.5 - Download SAP software - new` selects separate application, database, and kernel BoMs and combines them under a selected name.

Use the workflow compatible with the approved BoM model. Do not run both for the same installation unless both media sets are intentional.

## Download SAP software

For workflow `06`, select the combined BoM and control-plane environment. Enable re-download only when existing media must be replaced.

For workflow `06.5`, select mutually compatible application, kernel, database, and platform values and select the control-plane environment. Set either:

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

## Validate installation

Validate OS package state, SAP processes, database connectivity, central services, load balancers, application server registration, shared mounts, DNS, time synchronization, monitoring, backup, security controls, and installation logs.

Record the deployed BoM, SDAF version or container digest, Terraform version, Ansible version, and configuration commit.

## Next step

Continue to [Operations, troubleshooting, and removal](07-00-operations.md).
