resource "null_resource" "generate_ign_config_dependsOn" {
  provisioner "local-exec" {
    # Hack to force dependencies to work correctly. Must use the dependsOn var somewhere in the code for dependencies to work. Contain value which comes from previous module.
	  command = "echo The dependsOn output for apache web server module is ${var.dependsOn}"
  }
}

resource "null_resource" "generate_ign_config" {
  depends_on = ["null_resource.generate_ign_config_dependsOn"]
  connection {
    type = "ssh"
    user = "${var.vm_os_user}"
    password =  "${var.vm_os_password}"
    private_key = "${base64decode(var.vm_os_private_key_base64)}"
    host = "${var.vm_ipv4_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${ length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"        
  }

  provisioner "file" {
    source = "${path.module}/scripts/config_infra.sh"
    destination = "/tmp/config_infra.sh"
  }
  
  provisioner "file" {
    source = "${path.module}/scripts/config_firewall.sh"
    destination = "/tmp/config_firewall.sh"
  }  
  
  provisioner "file" {
    source = "${path.module}/scripts/install-config.yaml.tmpl"
    destination = "/tmp/install-config.yaml.tmpl"
  }   

  provisioner "file" {
    source = "${path.module}/scripts/sec_bootstrap.ign"
    destination = "/tmp/sec_bootstrap.ign"
  }  
  
  provisioner "file" {
    source = "${path.module}/scripts/get_interfaces.sh"
    destination = "/tmp/get_interfaces.sh"
  }    
  
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/config_infra.sh /tmp/config_firewall.sh",
      "chmod +x /tmp/config_infra.sh /tmp/get_interfaces.sh",
      "bash -c '/tmp/config_firewall.sh ${var.vm_ipv4_private_address} ${var.vm_ipv4_address}'",
      "bash -c '/tmp/config_infra.sh -h ${var.vm_ipv4_private_address} -oc ${var.ocversion} -d ${var.domain} -n ${var.controlnodes} -m ${var.computenodes} -cn ${var.clustername} -vc ${var.vcenter} -vu ${var.vcenteruser} -vp ${var.vcenterpassword} -vd ${var.vcenterdatacenter} -vs ${var.vmwaredatastore} -s ${var.pullsecret}'"
    ]
  }
}

resource "camc_scriptpackage" "get_bootstrap_ign" {
	depends_on = ["null_resource.generate_ign_config"]
  	program = ["sudo cat /installer/bootstrap.ign | base64 -w0"]
  	on_create = true
    remote_user = "${var.vm_os_user}"
    remote_password =  "${var.vm_os_password}"
    remote_key = "${var.vm_os_private_key_base64}"
    remote_host = "${var.vm_ipv4_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_password    = "${var.bastion_password}"            	
}

resource "camc_scriptpackage" "get_master_ign" {
	depends_on = ["camc_scriptpackage.get_bootstrap_ign"]
  	program = ["sudo cat /installer/allmaster.ign"]
  	on_create = true
    remote_user = "${var.vm_os_user}"
    remote_password =  "${var.vm_os_password}"
    remote_key = "${var.vm_os_private_key_base64}"
    remote_host = "${var.vm_ipv4_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_password    = "${var.bastion_password}"            	
}

resource "camc_scriptpackage" "get_worker_ign" {
	depends_on = ["camc_scriptpackage.get_master_ign"]
  	program = ["sudo cat /installer/allworker.ign"]
  	on_create = true
    remote_user = "${var.vm_os_user}"
    remote_password =  "${var.vm_os_password}"
    remote_key = "${var.vm_os_private_key_base64}"
    remote_host = "${var.vm_ipv4_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_password    = "${var.bastion_password}"            	
}

resource "camc_scriptpackage" "get_bootstrap_sec_ign" {
	depends_on = ["camc_scriptpackage.get_worker_ign"]
  	program = ["sudo cat /installer/sec_bootstrap.ign | base64 -w0"]
  	on_create = true
    remote_user = "${var.vm_os_user}"
    remote_password =  "${var.vm_os_password}"
    remote_key = "${var.vm_os_private_key_base64}"
    remote_host = "${var.vm_ipv4_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_password    = "${var.bastion_password}"            	
}

resource "camc_scriptpackage" "get_cluster_key" {
	depends_on = ["camc_scriptpackage.get_bootstrap_sec_ign"]
  	program = ["sudo cat ~/.ssh/id_rsa_ocp | base64 -w0"]
  	on_create = true
    remote_user = "${var.vm_os_user}"
    remote_password =  "${var.vm_os_password}"
    remote_key = "${var.vm_os_private_key_base64}"
    remote_host = "${var.vm_ipv4_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_password    = "${var.bastion_password}"            	
}

resource "camc_scriptpackage" "get_interfaces" {
	depends_on = ["camc_scriptpackage.get_cluster_key"]
  	program = ["/bin/bash", "/tmp/get_interfaces.sh ${var.vm_ipv4_private_address} ${var.vm_ipv4_address}"]
  	on_create = true
    remote_user = "${var.vm_os_user}"
    remote_password =  "${var.vm_os_password}"
    remote_key = "${var.vm_os_private_key_base64}"
    remote_host = "${var.vm_ipv4_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_password    = "${var.bastion_password}"            	
}

resource "null_resource" "ign_config_generated" {
  depends_on = ["null_resource.generate_ign_config","camc_scriptpackage.get_interfaces","camc_scriptpackage.get_cluster_key","camc_scriptpackage.get_bootstrap_sec_ign","camc_scriptpackage.get_worker_ign","camc_scriptpackage.get_master_ign","null_resource.generate_ign_config_dependsOn"]
  provisioner "local-exec" {
    command = "echo 'Ign config created'" 
  }
}