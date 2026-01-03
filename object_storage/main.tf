# service account
resource "yandex_iam_service_account" "sa" {
  folder_id = var.yc_folder_id
  name      = var.yc_sa_name
}

# grant permissions
resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = var.yc_folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# create static access keys
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

# use keys to create bucket
resource "yandex_storage_bucket" "bucket" {
  access_key            = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key            = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  force_destroy         = true
  bucket                = var.yc_bucket_name
  max_size              = var.yc_bucket_size
  default_storage_class = var.yc_default_storage_class
}
