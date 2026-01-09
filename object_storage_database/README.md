Создание объектного хранилища и базы данных MySQL в Yandex Cloud с помощью Terraform

- `requirements.txt` - зависимости Python для подключения к Yandex Cloud Object Storage и кластера MySQL из Jupyter Notebook

Команды для работы с Terraform в Makefile:
```
make init
make validate
make plan
make apply
make destroy
make clean
```

Команды для получения сертификата для MySQL:
```
# создаём директорию
mkdir -p ~/.mysql

# загружаем сертификат
wget "https://storage.yandexcloud.net/cloud-certs/CA.pem" --output-document "$HOME/.mysql/root.crt"

# права доступа
chmod 0600 "$HOME/.mysql/root.crt"

# определяем переменную для SSL_PATH
SSL_PATH="$HOME/.mysql/root.crt"

# записываем её в .env
sed -i "s/^SSL_PATH=.*/SSL_PATH=$SSL_PATH/" ../.env
```
