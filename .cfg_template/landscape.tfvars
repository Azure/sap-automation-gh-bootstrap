#########################################################################################
#                                                                                       #
# Workload zone description                                                             #
#                                                                                       #
# Azure Region:       westeurope                                                        #
# Workload Zone:      DEV-WEEU-SAP01                                                    #
#                                                                                       #
# Virtual Network:    New                                                               #
# App Subnet:         Defined                                                           #
# DB Subnet:          Defined
# Web Subnet:         Defined                                                           #
# Admin Subnet:       Defined                                                           #
# ANF Subnet:         Not defined                                                       #
# Storage Subnet:     Not defined                                                       #
# iSCSI Subnet:       Not defined                                                       #
#                                                                                       #
# Key Vault:          New                                                               #
# NAT:                No                                                                #
#                                                                                       #
# iSCSI servers:      Not in use                                                        #
# NFS Implementation: NFS                                                               #
#                                                                                       #
#########################################################################################

# Non-commented assignments are required workflow values or deliberate settings for the
# generated workload-zone configuration. Commented assignments are optional and show the
# current Terraform default unless an example is explicitly identified.


#########################################################################################
#                                                                                       #
# This sample defines a deployment that will create the networks and their subnets      #
#                                                                                       #
#########################################################################################

#########################################################################################
#                                                                                       #
# The automation framework supports both creating resources (greenfield) or using       #
# existing resources (brownfield).                                                      #
#                                                                                       #
# For the greenfield scenario the automation defines default names for resources,       #
# if there is a XXXXname variable then the name is customizable.                        #
#                                                                                       #
# For the brownfield scenario the Azure resource identifiers for the resources must     #
# be specified.                                                                         #
#                                                                                       #
#########################################################################################

#########################################################################################
#                                                                                       #
#  Environment definitions                                                              #
#                                                                                       #
#########################################################################################

# The environment value is a mandatory field, it is used for partitioning the environments, for example (PROD and NP)
environment = "@@ENV@@"

# The location value is a mandatory field, it is used to control where the resources are deployed
location = "@@REGION@@"

# Description of the Workload zone.
Description = "Workload zone for @@ENV@@ systems"

# Optional code name used in resource naming
#codename = ""

# If you want to provide a custom naming json use the following parameter.
#name_override_file = ""

# The subscription ID is required by Terraform and workflow 03 supplies it through
# TF_VAR_subscription_id.
#subscription_id = ""

# Management subscription used by the deployment
#management_subscription_id = ""

# Use the deployer as the deployment engine
#use_deployer = true

# Enable host encryption for workload-zone virtual machines
#encryption_at_host_enabled = false

#########################################################################################
#                                                                                       #
#  Networking                                                                           #
#                                                                                       #
#########################################################################################
# The deployment automation supports two ways of providing subnet information.          #
# 1. Subnets are defined as part of the workload zone deployment                        #
#    In this model multiple SAP System share the subnets                                #
# 2. Subnets are deployed as part of the SAP system                                     #
#    In this model each SAP system has its own sets of subnets                          #
#                                                                                       #
# The automation supports both creating the subnets (greenfield)                        #
# or using existing subnets (brownfield)                                                #
# For the greenfield scenario the subnet address prefix must be specified whereas       #
# for the brownfield scenario the Azure resource identifier for the subnet must         #
# be specified                                                                          #
#                                                                                       #
# If defined these parameters control the subnet name and the subnet prefix             #
#                                                                                       #
#########################################################################################

# The network logical name is mandatory - it is used in the naming convention and should map to the workload virtual network logical name
network_logical_name = "@@VNET@@"

# The name is optional - it can be used to override the default naming
#network_name = ""

# network_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing Virtual Network
#network_arm_id = ""

# network_address_space is a mandatory parameter when an existing Virtual network is not used
network_address_space = ["10.111.0.0/19"]

# use_private_endpoint is a boolean flag controlling if the key vaults and storage accounts have private endpoints
#use_private_endpoint = true

# private_endpoint_network_policies controls NSG and route-table policy support for private endpoints.
# Supported values are Disabled, Enabled, NetworkSecurityGroupEnabled, and RouteTableEnabled.
# Azure Government environments may require Disabled; select the value required by the network design.
#private_endpoint_network_policies = "Enabled"

# use_service_endpoint is a boolean flag controlling if the key vaults and storage accounts have service endpoints
use_service_endpoint = true

# Defines if the SAP VNet will be peered with the control plane VNet
#peer_with_control_plane_vnet = true

# Defines if access to the key vaults and storage accounts is restricted to the SAP and deployer VNets
enable_firewall_for_keyvaults_and_storage = true

# Defines if public access is allowed for the storage accounts and key vaults
#public_network_access_enabled = false

# place_delete_lock_on_resources, If defined, a delete lock will be placed on the key resources
place_delete_lock_on_resources = true

# The flow timeout in minutes of the virtual network
#network_flow_timeout_in_minutes = null

# Enable network route table propagation.
#network_enable_route_propagation = true

#########################################################################################
#                                                                                       #
#  Admin Subnet variables                                                               #
#                                                                                       #
#########################################################################################

# admin_subnet_name is an optional parameter and should only be used if the default naming is not acceptable
#admin_subnet_name = ""

# admin_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
admin_subnet_address_prefix = "10.111.20.0/22"

# admin_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#admin_subnet_arm_id = ""

# admin_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name
#admin_subnet_nsg_name = ""

# admin_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#admin_subnet_nsg_arm_id = ""

#########################################################################################
#                                                                                       #
#  DB Subnet variables                                                                  #
#                                                                                       #
#########################################################################################

# If defined these parameters control the subnet name and the subnet prefix
# db_subnet_name is an optional parameter and should only be used if the default naming is not acceptable
#db_subnet_name = ""

# db_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
db_subnet_address_prefix = "10.111.16.0/22"

# db_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#db_subnet_arm_id = ""

# db_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name
#db_subnet_nsg_name = ""

# db_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#db_subnet_nsg_arm_id = ""

#########################################################################################
#                                                                                       #
#  App Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

# If defined these parameters control the subnet name and the subnet prefix
# app_subnet_name is an optional parameter and should only be used if the default naming is not acceptable
#app_subnet_name = ""

# app_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
app_subnet_address_prefix = "10.111.24.0/22"

# app_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#app_subnet_arm_id = ""

# app_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name
#app_subnet_nsg_name = ""

# app_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#app_subnet_nsg_arm_id = ""

#########################################################################################
#                                                                                       #
#  Web Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

# If defined these parameters control the subnet name and the subnet prefix
# web_subnet_name is an optional parameter and should only be used if the default naming is not acceptable
#web_subnet_name = ""

# web_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
web_subnet_address_prefix = "10.111.28.0/22"

# web_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#web_subnet_arm_id = ""

# web_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name
#web_subnet_nsg_name = ""

# web_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#web_subnet_nsg_arm_id = ""

#########################################################################################
#                                                                                       #
#  ANF Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

# If defined these parameters control the subnet name and the subnet prefix
# anf_subnet_name is an optional parameter and should only be used if the default naming is not acceptable
#anf_subnet_name = ""

# anf_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet
#anf_subnet_arm_id = ""

# ANF requires a dedicated subnet, the address space for the subnet is provided with  anf_subnet_address_prefix
# anf_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
#anf_subnet_address_prefix = ""

# $anf_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name
#anf_subnet_nsg_name = ""

# anf_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#anf_subnet_nsg_arm_id = ""


###########################################################################
#                                                                         #
#                                    ISCSI Networking                     #
#                                                                         #
###########################################################################

# If defined these parameters control the subnet name and the subnet prefix
# iscsi_subnet_name is an optional parameter and should only be used if the default naming is not acceptable
#iscsi_subnet_name = ""

# iscsi_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet
#iscsi_subnet_arm_id = ""

# iscsi_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
#iscsi_subnet_address_prefix = ""

# iscsi_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing nsg
#iscsi_subnet_nsg_arm_id = ""

# iscsi_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name
#iscsi_subnet_nsg_name = ""

###########################################################################
#                                                                         #
#                               AMS Networking                            #
#                                                                         #
###########################################################################

# If defined these parameters control the subnet name and the subnet prefix
# ams_subnet_name is an optional parameter and should only be used if the default naming is not acceptable
#ams_subnet_name = ""

# ams_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet
#ams_subnet_arm_id = ""

# ams_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
#ams_subnet_address_prefix = ""

# ams_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing nsg
#ams_subnet_nsg_arm_id = ""

# ams_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name
#ams_subnet_nsg_name = ""


###########################################################################
#                                                                         #
#                               Storage Subnet                            #
#                                                                         #
###########################################################################

# If defined these parameters control the subnet name and the subnet prefix
# storage_subnet_name is an optional parameter and should only be used if the default naming is not acceptable
#storage_subnet_name = ""

# storage_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet
#storage_subnet_arm_id = ""

# When use_separate_storage_subnet is true, provide storage_subnet_address_prefix for a new subnet
# or storage_subnet_arm_id for an existing subnet.
#storage_subnet_address_prefix = ""

# storage_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing nsg
#storage_subnet_nsg_arm_id = ""

# storage_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name
#storage_subnet_nsg_name = ""

# use_separate_storage_subnet defines if a separate subnet is used (HANA Scale Out scenario).
# Leave this false to use the application subnet for storage private endpoints.
#use_separate_storage_subnet = false

#########################################################################################
#                                                                                       #
#  Common Virtual Machine settings                                                      #
#                                                                                       #
#########################################################################################

# user_assigned_identity_id defines the user assigned identity to be assigned to the Virtual Machines
#user_assigned_identity_id = ""

# If defined, will add the Microsoft.Azure.Monitor.AzureMonitorLinuxAgent extension to the Virtual Machines
#deploy_monitoring_extension = false

# If defined, will add the Microsoft.Azure.Security.Monitoring extension to the Virtual Machines
#deploy_defender_extension = false

# If defined, defines the patching mode for the Virtual Machines
#patch_mode = "ImageDefault"

# If defined, defines the mode of VM Guest Patching for the Virtual Machines
#patch_assessment_mode = "ImageDefault"

#########################################################################################
#                                                                                       #
#  Resource group details                                                               #
#                                                                                       #
#########################################################################################

# The two resource group name and arm_id can be used to control the naming and the creation of the resource group

# The resourcegroup_name value is optional, it can be used to override the name of the resource group that will be provisioned
#resourcegroup_name = ""

# The resourcegroup_name arm_id is optional, it can be used to provide an existing resource group for the deployment
#resourcegroup_arm_id = ""

# Tags applied to the workload-zone resource group
#resourcegroup_tags = {}

# Prevent deletion of resource group if there are Resources left within the Resource Group during deletion
#prevent_deletion_if_contains_resources = true

#########################################################################################
#                                                                                       #
#  DNS Settings                                                                         #
#                                                                                       #
#########################################################################################


# Subscription for the resource group containing the Private DNS zone for the compute resources
#management_dns_subscription_id = ""

# Resource group name for the resource group containing the Private DNS zone for the compute resources
#management_dns_resourcegroup_name = ""

# Subscription for the resource group containing the Private DNS zone for the Privatelink resources
#privatelink_dns_subscription_id = ""

# Resource group name for the resource group containing the Private DNS zone for the Privatelink resources
#privatelink_dns_resourcegroup_name = ""

# AzureUSGovernment: uncomment this entire block to override the Public Azure defaults.
# Public Azure: leave this block commented; Terraform supplies the Public Azure zone names.
#dns_zone_names = {
#  file_dns_zone_name      = "privatelink.file.core.usgovcloudapi.net"
#  blob_dns_zone_name      = "privatelink.blob.core.usgovcloudapi.net"
#  table_dns_zone_name     = "privatelink.table.core.usgovcloudapi.net"
#  vault_dns_zone_name     = "privatelink.vaultcore.usgovcloudapi.net"
#  appconfig_dns_zone_name = "privatelink.azconfig.azure.us"
#}

# Defines if a custom dns solution is used
#use_custom_dns_a_registration = false

# Defines if the Virtual network for the Virtual Machines is registered with DNS
# This also controls the creation of DNS entries for the load balancers
#register_virtual_network_to_dns = true

# register_endpoints_with_dns defines if the endpoints should be registered with the DNS
#register_endpoints_with_dns = true

# Register storage accounts and key vaults with their Private DNS zones
#register_storage_accounts_keyvaults_with_dns = true

# Existing Private Link DNS zone resource IDs
#privatelink_file_id = ""
#privatelink_storage_id = ""
#privatelink_keyvault_id = ""


#########################################################################################
#                                                                                       #
#  Azure Keyvault support                                                               #
#                                                                                       #
#########################################################################################

# The user keyvault is designed to host secrets for the administrative users
# user_keyvault_id is an optional parameter that if provided specifies the Azure resource identifier for an existing keyvault
#user_keyvault_id = ""

# The SPN keyvault is designed to host the SPN credentials used by the automation
# spn_keyvault_id is an optional parameter that if provided specifies the Azure resource identifier for an existing keyvault
#spn_keyvault_id = ""

# Existing private endpoint for the workload-zone key vault
#keyvault_private_endpoint_id = ""

# Optional names for workload-zone credential secrets
#workload_zone_private_key_secret_name = ""
#workload_zone_public_key_secret_name = ""
#workload_zone_username_secret_name = ""
#workload_zone_password_secret_name = ""

# enable_purge_control_for_keyvaults is an optional parameter that can be used to disable the purge protection for Azure key vaults
#enable_purge_control_for_keyvaults = false

# enable_rbac_authorization_for_keyvault Controls the access policy model for the workload zone keyvault.
#enable_rbac_authorization_for_keyvault = true

# Defines a list of Object IDs to be added to the keyvault
#additional_users_to_add_to_keyvault_policies = []

# The number of days that items should be retained in the soft delete period
soft_delete_retention_days = 14

# Set expiry date for secrets
set_secret_expiry = true

#########################################################################################
#                                                                                       #
#  Credentials                                                                          #
#                                                                                       #
#########################################################################################

# The automation_username defines the user account used by the automation
#automation_username = "azureadm"

# The automation_password is an optional parameter that can be used to provide a password for the automation user
# If empty Terraform will create a password and persist it in keyvault
#automation_password = ""

# The automation_path_to_public_key is an optional parameter that can be used to provide a path to an existing ssh public key file
# If empty Terraform will create the ssh key and persist it in keyvault
#automation_path_to_public_key = ""

# The automation_path_to_private_key is an optional parameter that can be used to provide a path to an existing ssh private key file
# If empty Terraform will create the ssh key and persist it in keyvault
#automation_path_to_private_key = ""

# Use service-principal authentication instead of managed identity
#use_spn = false


#########################################################################################
#                                                                                       #
#  Storage account details                                                               #
#                                                                                       #
#########################################################################################


# Defines the size of the install volume
#install_volume_size = 1024

# install_storage_account_id defines the Azure resource id for the install storage account
#install_storage_account_id = ""

# azurerm_private_endpoint_connection_install_id defines the Azure resource id for the install storage account's private endpoint connection
#install_private_endpoint_id = ""

# create_transport_storage defines if the workload zone will host storage for the transport data
#create_transport_storage = true

# Defines the size of the transport volume
#transport_volume_size = 128

# azure_files_transport_storage_account_id defines the Azure resource id for the transport storage account
#transport_storage_account_id = ""

# azurerm_private_endpoint_connection_transport_id defines the Azure resource id for the transport storage accounts private endpoint connection
#transport_private_endpoint_id = ""


# $diagnostics_storage_account_arm_id defines the Azure resource id for the diagnostics storage accounts
#diagnostics_storage_account_arm_id = ""

# witness_storage_account_arm_id defines the Azure resource id for the witness storage accounts
#witness_storage_account_arm_id = ""

# storage_account_replication_type defines the replication type for Azure Files for NFS storage accounts
#storage_account_replication_type = "ZRS"

# shared_access_key_enabled defines Storage account authorization using Shared Access Key.
#shared_access_key_enabled = false

# shared_access_key_enabled_nfs defines Storage account used for NFS shares authorization using Shared Access Key.
#shared_access_key_enabled_nfs = false

# data_plane_available indicates whether storage access is available through the data plane
#data_plane_available = true

# Agent_IP optionally identifies the workflow agent for storage and key vault firewall rules
#Agent_IP = ""

# Add the workflow agent IP to storage and key vault firewall rules
#add_Agent_IP = true


# Value indicating if file shares are created when using existing storage accounts
install_always_create_fileshares = true

# Value indicating if SMB shares should be created
#install_create_smb_shares = true

# Optional utility storage accounts for the workload zone. Terraform defaults to [].
# transform.tf forces FileStorage to Premium, honors the requested NFS/SMB protocol, and
# discards blob_containers. StorageV2 honors account_tier, forces file shares to SMB, and
# retains blob_containers. The complete example below demonstrates both account behaviors.
#utility_storage_accounts = [
#  {
#    name                     = "utilityfiles"
#    account_kind             = "FileStorage"
#    account_tier             = "Premium"
#    account_replication_type = "LRS"
#    file_shares = [
#      {
#        name     = "nfsdata"
#        quota    = 128
#        protocol = "NFS"
#      }
#    ]
#    blob_containers = []
#  },
#  {
#    name                     = "utilitygeneral"
#    account_kind             = "StorageV2"
#    account_tier             = "Standard"
#    account_replication_type = "LRS"
#    file_shares = [
#      {
#        name     = "smbdata"
#        quota    = 128
#        protocol = "SMB"
#      }
#    ]
#    blob_containers = [
#      {
#        name = "artifacts"
#      }
#    ]
#  }
#]


#########################################################################################
#                                                                                       #
#  Private DNS support                                                                  #                                                                                       #
#                                                                                       #
#########################################################################################

# If defined provides the DNS label for the Virtual Network
dns_label = "@@DNS_LABEL@@"

# If defined provides the list of DNS servers to attach to the Virtual NEtwork
#dns_server_list = []

#########################################################################################
#                                                                                       #
#  NFS support                                                                          #
#                                                                                       #
#########################################################################################

# NFS_Provider defines how NFS services are provided to the SAP systems, valid options are "ANF", "AFS", "NFS" or "NONE"
# AFS indicates that Azure Files for NFS is used
# ANF indicates that Azure NetApp Files is used
# NFS indicates that a custom solution is used for NFS
NFS_provider = "AFS"

# use_AFS_for_shared_storage defines if shared media is on AFS even when using ANF for data
use_AFS_for_shared_storage = true

# Defines if encryption in transit is enabled for AFS on NFS shares
#AFS_enable_encryption_in_transit = false

#########################################################################################
#                                                                                       #
#  Azure NetApp files support                                                           #
#                                                                                       #
#########################################################################################

# ANF_account_name is the name for the Netapp Account
#ANF_account_name = ""

# ANF_service_level is the service level for the NetApp pool
#ANF_service_level = "Premium"

# ANF_pool_name is the ANF pool name
#ANF_pool_name = ""

# ANF_pool_size is the pool size in TB for the NetApp pool
#ANF_pool_size = 4

# ANF_qos_type defines the Quality of Service type of the pool (Auto or Manual)
#ANF_qos_type = "Manual"

# ANF_account_arm_id is the Azure resource identifier for an existing Netapp Account
#ANF_account_arm_id = ""

# ANF_use_existing_pool defines if an existing pool is used
#ANF_use_existing_pool = false

# Allowed clients for ANF export policies
#ANF_export_policy_client_access_list = []

#########################################################################################
#                                                                                       #
#  Transport ANF Volume                                                                 #
#                                                                                       #
#########################################################################################

# ANF_transport_volume_use_existing defines if an existing volume is used for transport
#ANF_transport_volume_use_existing = false

# ANF_transport_volume_name is the name of the transport volume
#ANF_transport_volume_name = "transport"

# ANF_transport_volume_throughput is the throughput for the transport volume
#ANF_transport_volume_throughput = 128

# ANF_transport_volume_size is the size for the transport volume
#ANF_transport_volume_size = 128

# ANF_transport_volume_zone is the zone for the transport volume
#ANF_transport_volume_zone = [""]

#########################################################################################
#                                                                                       #
#  Install ANF Volume                                                                   #
#                                                                                       #
#########################################################################################

# ANF_install_volume_use_existing defines if an existing volume is used for install
#ANF_install_volume_use_existing = false

# ANF_install_volume_name is the name of the install volume
#ANF_install_volume_name = ""

# ANF_install_volume_throughput is the throughput for the install volume
#ANF_install_volume_throughput = 128

# ANF_install_volume_size is the size for the install volume
#ANF_install_volume_size = 1024

# ANF_install_volume_zone is the zone for the transport volume
#ANF_install_volume_zone = [""]

###########################################################################
#                                                                         #
#                                ISCSI Devices                            #
#                                                                         #
###########################################################################

# Number of iSCSI devices to be created
#iscsi_count = 0

# Size of iSCSI Virtual Machines to be created
iscsi_size = "Standard_D2s_v3"

# Defines if the iSCSI devices use DHCP
iscsi_useDHCP = true

# Defines the Virtual Machine image for the iSCSI devices
#iscsi_image = {
#  source_image_id = ""
#  publisher       = "SUSE"
#  offer           = "sles-sap-15-sp5"
#  sku             = "gen1"
#  version         = "latest"
#}

# Defines the Virtual Machine authentication type for the iSCSI devices
#iscsi_authentication_type = "key"

# Defines the username for the iSCSI devices
#iscsi_authentication_username = "azureadm"

# Defines the IP Addresses for the iSCSI devices
#iscsi_nic_ips = []

# Defines the Availability zones for the iSCSI devices
#iscsi_vm_zones = []

#########################################################################################
#                                                                                       #
#  Terraform deployment parameters                                                      #
#                                                                                       #
#########################################################################################

# These are required parameters, if using the deployment scripts they will be auto populated otherwise they need to be entered

# tfstate_resource_id is the Azure resource identifier for the Storage account in the SAP Library
# that will contain the Terraform state files. It is required by Terraform but injected by
# the SDAF workload-zone deployment scripts.
#tfstate_resource_id = ""

# deployer_tfstate_key is the state file name for the deployer
#deployer_tfstate_key = ""

# custom_random_id overrides the generated random identifier
#custom_random_id = ""

# additional_network_id and additional_subnet_id identify optional agent networking
#additional_network_id = ""
#additional_subnet_id = ""

# assign_permissions controls permission assignment for deployed resources
#assign_permissions = true

# spn_id identifies the service principal used for deployment
#spn_id = ""

# platform_updates controls VMAgent platform updates
#platform_updates = "true"


#########################################################################################
#                                                                                       #
#  Utility VM definitions                                                              #
#                                                                                       #
#########################################################################################


# Defines the number of workload _vms to create
#utility_vm_count = 0

# Defines the SKU for the workload virtual machine
#utility_vm_size = "Standard_D4ds_v4"

# Defines the size of the OS disk for the Virtual Machine
#utility_vm_os_disk_size = "128"

# Defines the type of the OS disk for the Virtual Machine
#utility_vm_os_disk_type = "Premium_LRS"


# Defines if the utility virtual machine uses DHCP
#utility_vm_useDHCP = true

# Defines if the utility virtual machine image
#utility_vm_image = {
#  os_type         = "WINDOWS"
#  source_image_id = ""
#  publisher       = "MicrosoftWindowsServer"
#  offer           = "WindowsServer"
#  sku             = "2022-Datacenter"
#  version         = "latest"
#}

# Defines if the utility virtual machine IP
#utility_vm_nic_ips = []

############################################################################################
#                                                                                          #
#                                  Tags for all resources                                  #
#                                                                                          #
############################################################################################

# These tags will be applied to all resources
tags = {
  "DeployedBy" = "SDAF",
}

############################################################################################
#                                                                                          #
#                                  AMS Configuration                                       #
#                                                                                          #
############################################################################################

# If true, an AMS instance will be created
#create_ams_instance = false

# ams_instance_name If provided, the name of the AMS instance
#ams_instance_name = ""

# ams_laws_arm_id if provided, Azure resource id for the Log analytics workspace in AMS
#ams_laws_arm_id = ""

#######################################4#######################################8
#                                                                              #
#                             NAT Gateway variables                            #
#                                                                              #
#######################################4#######################################8

# If true, a NAT gateway will be created
#deploy_nat_gateway = false

# If provided, the name of the NAT Gateway
#nat_gateway_name = ""

# If provided, the Azure resource id for the NAT Gateway
#nat_gateway_arm_id = ""

# If provided, the zones for the NAT Gateway public IP
#nat_gateway_public_ip_zones = []

# If provided, Azure resource id for the NAT Gateway public IP
#nat_gateway_public_ip_arm_id = ""

# The idle timeout in minutes for the NAT Gateway
#nat_gateway_idle_timeout_in_minutes = 4

# If provided, the tags for the NAT Gateway public IP
#nat_gateway_public_ip_tags = null

#########################################################################################
#                                                                                       #
#  Export and application configuration                                                 #
#                                                                                       #
#########################################################################################

# Export the install and transport mount paths
#export_install_path = true
#export_transport_path = true

# Existing Azure App Configuration resource and associated control-plane name
#application_configuration_id = ""
#control_plane_name = ""
