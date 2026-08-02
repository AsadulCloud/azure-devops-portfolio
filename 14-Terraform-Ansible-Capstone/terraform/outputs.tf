# outputs.tf
# These are the two values the pipeline needs to hand off to Ansible:
# 1. Where to connect (the IP)
# 2. What key to connect with (the private key Terraform just generated)
# ##########
output "vm_public_ip" {
  description = "The public IP address of the virtual machine"
  value       = azurerm_public_ip.vm_ip.ip_address
}
output "ssh_private_key" {
  description = "Private SSH key for connecting to the VM (sensitive - handle carefully)"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}