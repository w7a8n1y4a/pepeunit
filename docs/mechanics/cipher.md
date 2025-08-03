# Шифрование

[Pepeunit](/conception/overview) использует шифрование `AES256` с `12 байтовым` инициирующим вектором и `32 байтовым` ключом - схема шифрования `GCM`

```python
def aes_gcm_encode(data: str, key: str = settings.backend_encrypt_key) -> str:
    """
    data: any python str
    key: (base64 str) 16, 24, 32 bytes sync encrypt key
    return: (base64 str - nonce).(base64 str - encrypted data).(base64 str - tag)
    """
    len_content = len(data)
    if len_content > settings.backend_max_cipher_length:
        app_errors.cipher_error.raise_exception(
            f'The encryption content is {len_content} long, although only <= {settings.backend_max_cipher_length} is allowed'
        )

    key = base64.b64decode(key.encode())
    nonce = os.urandom(12)  # 96-bit nonce for AES-GCM
    aesgcm = AESGCM(key)

    cipher = aesgcm.encrypt(nonce, data.encode(), None)  # Encrypt data

    return f"{base64.b64encode(nonce).decode()}.{base64.b64encode(cipher).decode()}"


def aes_gcm_decode(data: str, key: str = settings.backend_encrypt_key) -> str:
    """
    data: (base64 str - nonce).(base64 str - encrypted data)
    key: (base64 str) 16, 24, 32 bytes sync encrypt key
    return: decode python str
    """
    key = base64.b64decode(key.encode())
    nonce, cipher = data.split('.')
    nonce = base64.b64decode(nonce.encode())
    cipher = base64.b64decode(cipher.encode())

    aesgcm = AESGCM(key)

    return aesgcm.decrypt(nonce, cipher, None).decode('utf-8')
```

::: tip Какие данные шифрует [Pepeunit](/conception/overview)?
Все конфиденциальные данные, а именно:
1. Динамическая соль, использующаяся для хэширования пароля [Пользователя](/mechanics/roles.html#user)
1. Авторизационные данные, отвестветвенные за доступ до `Private` [RepositoryRegisty](/definitions#repositoryregistry)
1. Файлы окружений - [env.json](/definitions#env-json) от [Unit](/definitions#unit)
1. [Хранилище внутреннего состояния](/developer/state-storage-unit) [Unit](/definitions#unit)
:::

:::warning Ограничение размера шифруемых объектов
Все шифруемые объекты имеют стандартное ограничение в `1000000` символов. [Администратор](/mechanics/roles#admin) [инстанса](/definitions#instance) может изменить этот объём установив переменную окружения `BACKEND_MAX_CIPHER_LENGTH` в файле [Backend ENV](/deployment/env-variables#backend).
:::

:::danger
[Администратор](/mechanics/roles#admin) имеющий доступ к [Backend ENV](/deployment/env-variables#backend) [инстанса](/definitions#instance) [Pepeunit](/conception/overview), имеет возможность расшифровать данные хранящиеся в шифрованном виде на его [инстансе](/definitions#instance).

Поэтому пользуйтесь только [инстансами](/definitions#instance) [Pepeunit](/conception/overview) [Администраторам](/mechanics/roles#admin) которых вы доверяете.

Шифрованная информация не передаётся между [инстансами](/definitions#instance) и хранится на [инстансе](/definitions#instance) создания сущности, остальные [инстансы](/definitions#instance) получают ограниченное представление о первичной сущности.
:::