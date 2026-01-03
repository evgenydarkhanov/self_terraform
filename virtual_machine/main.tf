# network
resource "yandex_vpc_network" "network" {
  name = var.yc_network_name
}

# subnet
resource "yandex_vpc_subnet" "subnet" {
  zone           = var.yc_zone
  name           = var.yc_subnet_name
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.yc_subnet_range]
}

# compute disk
resource "yandex_compute_disk" "disk" {
  name     = var.yc_disk_name
  type     = var.yc_disk_type
  zone     = var.yc_zone
  image_id = var.yc_image_id
}

# compute instance (VM)
resource "yandex_compute_instance" "vm" {
  name        = var.yc_vm_name
  platform_id = var.yc_platform_id
  zone        = var.yc_zone

  resources {
    cores  = var.yc_vm_cores
    memory = var.yc_vm_memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.disk.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.yc_ssh_public_key_path)}" 
  }
}
