terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "1.49.0"
    }
  }
}
provider "openstack" {
  user_name = "pinakastra"
  tenant_name = "service"
  password = "pinakastra"
  auth_url = "http://10.11.36.7:5000/v3"
  region = "RegionOne"
}
resource "openstack_compute_flavor_v2" "devops_flavor" {
  name      = "devops_flavor"
  ram       = "3096"
  vcpus     = "2"
  disk      = "50"
  flavor_id = "auto"
  is_public = "true"
}
resource "openstack_networking_secgroup_v2" "devops_security" {
  name        = "devops_security"
  description = "Instance Security Group"
  count = 5
  rule {
    direction     = "ingress"
    ethertype     = "IPv4"
    protocol      = "tcp"
    port_range_min = 22
    port_range_max = 22
    remote_ip_prefix = "0.0.0.0/0"
  }
   rule {
    direction      = "ingress"
    ethertype      = "IPv4"
    protocol       = "tcp"
    port_range_min = 80
    port_range_max = 80
  }
  rule {
    direction      = "ingress"
    ethertype      = "IPv4"
    protocol       = "tcp"
    port_range_min = 443
    port_range_max = 443
  }
  rule {
    direction      = "egress"
    ethertype      = "IPv4"
    protocol       = "tcp"
    port_range_min = 0
    port_range_max = 65535
  }
}
resource "openstack_compute_image_v2" "devops_image" {
  name = "devops_image"
  image_location = "http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
  disk_format = "qcow2"
  container_format = "bare"
}
resource "openstack_blockstorage_volume_v3" "devops_volume" {
  name = "devops_volume"
  size = 10
  availability_zone = "nova"
  #image_id          = "<image_id>"
  volume_type       = "RBD"
  bootable          = false
  #source_volid      = "<source_volid>"
}
resource "openstack_compute_instance_v2" "devops-node2" {
  name = "devops-node2"
  flavor_id = openstack_compute_flavor_v2.devops_flavor.id
  image_id = openstack_compute_image_v2.devops_image.id
  key_pair = "devops"
  network {
    name = "dr-nw"
  }
  security_groups = [openstack_networking_secgroup_v2.devops_security.name]
  block_device {
    uuid              = openstack_blockstorage_volume_v3.devops_volume.id
    source_type       = "volume"
    destination_type  = "volume"
    boot_index        = 0
    delete_on_termination = true
  }
   provisioner "remote-exec" {
    inline = [
      "wget -qO- https://get.docker.com/ | sh",  # Install Docker
      "sudo usermod -aG docker $USER",  # Add the current user to the docker group
      "sudo systemctl enable docker",  # Enable Docker service
      "sudo systemctl start docker",  # Start Docker service
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",  # Add Kubernetes apt repository key
      "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list",  # Add Kubernetes apt repository
      "sudo apt-get update",  # Update package lists
      "sudo apt-get install -y kubelet kubeadm kubectl",  # Install Kubernetes components
       "sudo kubeadm init --pod-network-cidr=192.168.0.0/16",  # Initialize the Kubernetes cluster
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",  # Install Flannel networking
    ]
  }
}
resource "openstack_compute_instance_v2" "devops-node3" {
  name = "devops-node3"
  #flavor_name = "openstack_compute_flavor_v2.devops-flavor.name"
  #image_name = "RHEL9"
  flavor_id = openstack_compute_flavor_v2.devops_flavor.id
  image_id = openstack_compute_image_v2.devops_image.id
  key_pair = "devops"
  network {
    name = "dr-nw"
  }
  security_groups = [openstack_networking_secgroup_v2.devops-security.name]
  block_device {
    uuid              = openstack_blockstorage_volume_v3.devops_volume.id
    source_type       = "volume"
    destination_type  = "volume"
    boot_index        = 0
    delete_on_termination = true
  }provisioner "remote-exec" {
    inline = [
      # Previous installation commands...
      "sudo kubeadm join <master-node-ip>:<master-node-port> --token <token> --discovery-token-ca-cert-hash <discovery-token-ca-cert-hash>",  # Join worker node to the cluster
    ]
  }
}
resource "openstack_compute_instance_v2" "devops-node4" {
  name = "devops-node4"
  #flavor_name = "openstack_compute_flavor_v2.devops-flavor.name"
  #image_name = "RHEL9"
  flavor_id = openstack_compute_flavor_v2.devops_flavor.id
  image_id = openstack_compute_image_v2.devops_image.id
  key_pair = "devops"
  network {
    name = "dr-nw"
  }
  security_groups = [openstack_networking_secgroup_v2.devops-security.name]
  block_device {
    uuid              = openstack_blockstorage_volume_v3.devops_volume.id
    source_type       = "volume"
    destination_type  = "volume"
    boot_index        = 0
    delete_on_termination = true
  }
  #provisioner "remote-exec" {
  #  inline = [
      # Previous installation commands...
  #    "sudo kubeadm join <master-node-ip>:<master-node-port> --token <token> --discovery-token-ca-cert-hash <discovery-token-ca-cert-hash>",  # Join worker node to the cluster
  #  ]
  #}
}
resource "openstack_compute_instance_v2" "devops-node5" {
  name = "devops-node5"
  #flavor_name = "openstack_compute_flavor_v2.devops-flavor.name"
  #image_name = "RHEL9"
  flavor_id = openstack_compute_flavor_v2.devops_flavor.id
  image_id = openstack_compute_image_v2.devops_image.id
  key_pair = "devops"
  network {
    name = "dr-nw"
  }
  security_groups = [openstack_networking_secgroup_v2.devops-security.name]
  block_device {
    uuid              = openstack_blockstorage_volume_v3.devops_volume.id
    source_type       = "volume"
    destination_type  = "volume"
    boot_index        = 0
    delete_on_termination = true
  }
  #provisioner "remote-exec" {
   # inline = [
    #  # Previous installation commands...
     # "sudo kubeadm join <master-node-ip>:<master-node-port> --token <token> --discovery-token-ca-cert-hash <discovery-token-ca-cert-hash>",  # Join worker node to the cluster
    #]
  #}
}

