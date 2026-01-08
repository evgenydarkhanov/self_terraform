# IAM resources
# просто создаём сервисный аккаунт
resource "yandex_iam_service_account" "sa" {
  name        = var.yc_service_account_name
  description = "Service account for Dataproc cluster and related services"
}

# grant permissions
# присваиваем ему роли
resource "yandex_resourcemanager_folder_iam_member" "sa_roles" {
  for_each = toset([
    "storage.admin",
    "dataproc.editor",
    "compute.admin",
    "dataproc.agent",
    "mdb.dataproc.agent",
    "vpc.user",
    "iam.serviceAccounts.user",
    "storage.uploader",
    "storage.viewer",
    "storage.editor"
  ])

  folder_id = var.yc_folder_id
  role      = each.key
  # обращение к сервисному аккаунту
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# create static access keys
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Static access key for object storage"
}

# network resources
resource "yandex_vpc_network" "network" {
  name = var.yc_network_name
}

resource "yandex_vpc_subnet" "subnet" {
  name           = var.yc_subnet_name
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.yc_subnet_range]
  route_table_id = yandex_vpc_route_table.route_table.id
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = var.yc_nat_gateway_name
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route_table" {
  name       = var.yc_route_table_name
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_security_group" "security_group" {
  name        = var.yc_security_group_name
  description = "Security group for Dataproc cluster"
  network_id  = yandex_vpc_network.network.id

  ingress {
    protocol       = "ANY"
    description    = "Allow all incoming traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "UI"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Jupyter"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8888
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol          = "ANY"
    description       = "Internal"
    from_port         = 0
    to_port           = 65535
    predefined_target = "self_security_group"
  }
}

# storage resources
# приватный, подключаемся ключом сервисного аккаунта, который создали выше
resource "yandex_storage_bucket" "data_bucket" {
  bucket                = var.yc_bucket_name
  default_storage_class = var.yc_default_storage_class
  access_key            = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key            = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  force_destroy         = true
}

# Data Proc resources
resource "yandex_dataproc_cluster" "dataproc_cluster" {
  depends_on  = [yandex_resourcemanager_folder_iam_member.sa_roles]
  bucket      = yandex_storage_bucket.data_bucket.bucket
  description = "Dataproc Cluster created by Terraform for OTUS project"
  name        = var.yc_dataproc_cluster_name
  labels      = {
    created_by = "terraform"
  }
  service_account_id = yandex_iam_service_account.sa.id
  zone_id            = var.yc_zone
  security_group_ids = [yandex_vpc_security_group.security_group.id]

  cluster_config {
    version_id = var.yc_dataproc_version

    hadoop {
      services   = ["HDFS", "YARN", "SPARK", "HIVE", "TEZ"]
      properties = {
        "yarn:yarn.resourcemanager.am.max-attempts" = 5
      }
      ssh_public_keys = [file(var.public_key_path)]
    }

    subcluster_spec {
      name = "master"
      role = "MASTERNODE"
      resources {
        resource_preset_id = var.dataproc_master_resources.resource_preset_id
        disk_type_id        = "network-ssd"
        disk_size           = var.dataproc_master_resources.disk_size
      }
      subnet_id        = yandex_vpc_subnet.subnet.id
      hosts_count      = 1
      assign_public_ip = true
    }

    subcluster_spec {
      name = "data"
      role = "DATANODE"

      resources {
        resource_preset_id = var.dataproc_data_resources.resource_preset_id
        disk_type_id        = "network-ssd"
        disk_size           = var.dataproc_data_resources.disk_size
      }
      subnet_id        = yandex_vpc_subnet.subnet.id
      hosts_count      = 1
    }

    subcluster_spec {
      name = "compute"
      role = "COMPUTENODE"

      resources {
        resource_preset_id = var.dataproc_compute_resources.resource_preset_id
        disk_type_id        = "network-ssd"
        disk_size           = var.dataproc_compute_resources.disk_size
      }
      subnet_id        = yandex_vpc_subnet.subnet.id
      hosts_count      = 1
    }
  }
}

# compute instance resources
resource "yandex_compute_disk" "boot_disk" {
  name     = "boot-disk"
  zone     = var.yc_zone
  image_id = var.yc_image_id
  size     = 30
}

resource "yandex_compute_instance" "proxy" {
  name                      = var.yc_instance_name
  allow_stopping_for_update = true
  platform_id               = var.yc_platform_id
  zone                      = var.yc_zone
  service_account_id        = yandex_iam_service_account.sa.id

  # скрипт, запускающийся при старте VM, передаём в него аргументы
  metadata = {
    ssh-keys  = "ubuntu:${file(var.public_key_path)}"
    user-data = templatefile("${path.root}/scripts/user_data.sh", {
      token = var.yc_token
      cloud_id                    = var.yc_cloud_id
      folder_id                   = var.yc_folder_id
      private_key                 = file(var.private_key_path)
      access_key                  = yandex_iam_service_account_static_access_key.sa-static-key.access_key
      secret_key                  = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
      s3_bucket                   = yandex_storage_bucket.data_bucket.bucket
      upload_data_to_hdfs_content = file("${path.root}/scripts/upload_data_to_hdfs.sh")
    })
  }

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores  = var.yc_instance_cores
    memory = var.yc_instance_memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot_disk.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata_options {
    gce_http_endpoint = 1
    gce_http_token    = 1
  }

  # подключение по ssh
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.network_interface[0].nat_ip_address
  }

  # выполнение действий: сохранение логов
  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "echo 'User-data script execution log:' | sudo tee /var/log/user_data_execution.log",
      "sudo cat /var/log/cloud-init-output.log | sudo tee -a /var/log/user_data_execution.log",
    ]
  }
  depends_on = [yandex_dataproc_cluster.dataproc_cluster]
}
