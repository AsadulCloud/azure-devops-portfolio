# main.tf
# Capstone: creates one Linux VM with a public IP, networking, and firewall rules.
# Terraform also generates the SSH key pair itself, so the pipeline never needs
# a pre-existing key - it gets minted fresh on every run.

# --- Resource Group: the "folder" everything below lives in ---
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

#--- Networking: VM needs a virtual network + subnet to live in ---
resource "azurerm_virtual_network" "vnet" {
  name                = "capstone-vnet"
  address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_subnet" "subnet" {
  name                 = "capstone-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
  depends_on = [azurerm_virtual_network.vnet]
}
# --- Public IP: this is the address Terraform will output, and Ansible will target ---
resource "azurerm_public_ip" "vm_ip" {
  name                = "capstone-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
# --- Network Security Group: firewall rules. Must allow SSH (22) for Ansible
#     and HTTP (80) so we can curl the nginx page to prove it worked. ---
resource "azurerm_network_security_group" "nsg" {
  name                = "capstone-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 111
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# --- Network Interface: connects the VM to the subnet + public IP ---
resource "azurerm_network_interface" "nic" {
  name                = "capstone-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
  }
}
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
# --- SSH key pair: Terraform generates this itself, so no manual key
#     management is needed. The private key gets output (marked sensitive)
#     so the pipeline can save it and hand it to Ansible. ---
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# --- The actual VM ---
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "capstone-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}