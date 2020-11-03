 /*
 Code by Pablo Urcid
 */
 
 provider "aci" {
      # cisco-aci user name
      username = "YOUR-USERNAME"
      # cisco-aci password
      password = "YOUR-PWD"
      # cisco-aci url
      url      = "YOUR-URL-OR-IP"
      insecure = true
    }

resource "aci_tenant" "terra-tenant" {
  name        = "terra-tenant"
  description = "This tenant is created by terraform"
}

resource "aci_vrf" "vrf-terra" {
    tenant_dn = aci_tenant.terra-tenant.id
    name = "vrf-terra"
}

resource "aci_application_profile" "general-network" {
    tenant_dn = aci_tenant.terra-tenant.id
    name = "general-network"
}

resource "aci_bridge_domain" "bd4" {
    tenant_dn = aci_tenant.terra-tenant.id
    relation_fv_rs_ctx = aci_vrf.vrf-terra.id
    name = "bd4"
}

resource "aci_subnet" "bd4_subnet" {
    parent_dn = aci_bridge_domain.bd4.id
    ip = "4.4.4.1/24"
}

data "aci_vmm_domain" "vds" {
    provider_profile_dn = "uni/vmmp-VMware"
    name = "DVS-Site22"
}

resource "aci_application_epg" "epg4" {
    application_profile_dn = aci_application_profile.general-network.id
    name = "epg4"
    relation_fv_rs_bd = aci_bridge_domain.bd4.id
}

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 5"
  }

  triggers = {
    "epg4" = aci_application_epg.epg4.id
  }
}

resource "aci_epg_to_domain" "example" {
    application_epg_dn = aci_application_epg.epg4.id
    tdn = data.aci_vmm_domain.vds.id
}

