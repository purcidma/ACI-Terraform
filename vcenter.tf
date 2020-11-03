 /*
 Code by Pablo Urcid
 */
 
provider "vsphere" {
    user = "YOUT-USER"
    password = "YOUR-PWD"
    vsphere_server = "YOUR-URL-OR-IP"
    allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "YOUR-DATACENTER-ON-VMWARE"
}

data "vsphere_datastore" "datastore" {
  name          = "YOUR-DATASTORE-ON-VMWARE"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "YOUR-CLUSTER-ON-VMWARE"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  #name          = format ("%v|%v|%v", aci_tenant.terra-tenant.name, aci_application_profile.general-network.name, aci_application_epg.epg4.name)
  depends_on = [null_resource.delay]
  name = "terra-tenant|general-network|epg4"
  datacenter_id = data.vsphere_datacenter.dc.id
}
 
data "vsphere_virtual_machine" "template" {
  name          = "YOUR-TEMPLATE-ON-VMWARE"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = "terraform-test"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 2048
  guest_id = data.vsphere_virtual_machine.template.guest_id



  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label = "disk0"
    size  = 100
  }



  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "terraform-test"
        domain    = "test.internal"
      }

      network_interface {
        ipv4_address = "4.4.4.10"
        ipv4_netmask = 24
      }

      ipv4_gateway = "4.4.4.1"
    }

  }
}

##################
# OUTPUT
##################
output "ip" {
    value = "${vsphere_virtual_machine.vm.*.default_ip_address}"
}