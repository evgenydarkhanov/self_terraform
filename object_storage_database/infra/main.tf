### IAM ###
resource "yandex_iam_service_account" "service-account" {
  name        = var.yc_service_account_name
  description = "Service account for S3"
}

# назначаем роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "service-account-roles" {
  for_each = toset([
    "storage.admin",
    "storage.uploader",
    "storage.viewer",
    "storage.editor"
  ])

  folder_id = var.yc_folder_id
  role      = each.key
  member    = "serviceAccount:${yandex_iam_service_account.service-account.id}"
}

# создаём статический ключ доступа для сервисного аккаунта
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.service-account.id
}

# записываем ключи в .env
resource "null_resource" "update_env_and_save_keys" {
  provisioner "local-exec" {
    command = <<EOT
      # определяем переменные для access_key и secret_key
      ACCESS_KEY=${yandex_iam_service_account_static_access_key.sa-static-key.access_key}
      SECRET_KEY=${yandex_iam_service_account_static_access_key.sa-static-key.secret_key}

      # заменяем пустые переменные в .env
      sed -i "s/^S3_ACCESS_KEY=.*/S3_ACCESS_KEY=$ACCESS_KEY/" ../.env
      sed -i "s/^S3_SECRET_KEY=.*/S3_SECRET_KEY=$SECRET_KEY/" ../.env
    EOT
  }
  # добавляем зависимости, чтобы команда выполнялась после создания ключей
  depends_on = [
    yandex_iam_service_account_static_access_key.sa-static-key
  ]
}

### Network ###
resource "yandex_vpc_network" "network" {
  name = var.yc_network_name
}

resource "yandex_vpc_subnet" "subnet" {
  name           = var.yc_subnet_name
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.yc_subnet_range]
}

### S3 ###
resource "random_id" "bucket_id" {
  byte_length = 8
}

resource "yandex_storage_bucket" "bucket" {
  bucket        = "${var.yc_bucket_name}-${random_id.bucket_id.hex}"
  access_key    = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key    = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  force_destroy = true
}

resource "null_resource" "update_env_and_save_bucket_name" {
  provisioner "local-exec" {
    command = <<EOT
      # определяем переменную BUCKET_NAME с именем бакета
      BUCKET_NAME=${yandex_storage_bucket.bucket.bucket}

      # заменяем переменную BUCKET_NAME в .env
      sed -i "s/^S3_BUCKET_NAME=.*/S3_BUCKET_NAME=$BUCKET_NAME/" ../.env
    EOT
  }

  # добавляем зависимости, чтобы команда выполнялась после создания бакета
  depends_on = [
    yandex_storage_bucket.bucket
  ]
}

### DB ###
resource "yandex_mdb_mysql_cluster" "cluster" {
  name        = var.yc_mysql_cluster_name
  environment = var.yc_mysql_environment
  network_id  = yandex_vpc_network.network.id
  version     = var.yc_mysql_version

  resources {
    resource_preset_id = var.yc_mysql_resource_preset_id
    disk_type_id       = var.yc_mysql_disk_type_id
    disk_size          = var.yc_mysql_disk_size
  }

  mysql_config = var.yc_mysql_config

  host {
    zone             = var.yc_zone
    subnet_id        = yandex_vpc_subnet.subnet.id
    assign_public_ip = true
  }
}

# создаём базу данных
resource "yandex_mdb_mysql_database" "db" {
  cluster_id = yandex_mdb_mysql_cluster.cluster.id
  name       = var.yc_mysql_database_name
}

# создаём пользователя
resource "yandex_mdb_mysql_user" "user" {
  cluster_id = yandex_mdb_mysql_cluster.cluster.id
  name       = var.yc_mysql_user_name
  password   = var.yc_mysql_user_password

  permission {
    database_name = yandex_mdb_mysql_database.db.name
    roles         = ["ALL"]
  }
}

resource "null_resource" "update_env_with_db_host" {
  provisioner "local-exec" {
    command = <<EOT
      # определяем переменную DB_HOST с FQDN кластера
      DB_HOST=${yandex_mdb_mysql_cluster.cluster.host[0].fqdn}
      DB_USER=${yandex_mdb_mysql_user.user.name}
      DB_PASS=${yandex_mdb_mysql_user.user.password}
      DB_NAME=${yandex_mdb_mysql_database.db.name}

      # заменяем переменную DB_HOST в .env
      sed -i "s/^DB_HOST=.*/DB_HOST=$DB_HOST/" ../.env
      sed -i "s/^DB_USER=.*/DB_USER=$DB_USER/" ../.env
      sed -i "s/^DB_PASS=.*/DB_PASS=$DB_PASS/" ../.env
      sed -i "s/^DB_NAME=.*/DB_NAME=$DB_NAME/" ../.env
    EOT
  }

  # добавляем зависимости, чтобы команда выполнялась после создания кластера
  depends_on = [
    yandex_mdb_mysql_cluster.cluster
  ]
}
