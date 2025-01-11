# Шифрование

[Pepeunit](/conception/overview) использует шифрование `AES256` с `16 байтовым` инициирующим вектором и `32 байтовым` ключом - схема шифрования `CBC`

```python
def aes_encode(data: str, key: str = settings.encrypt_key) -> str:
    """
    data: any python str
    key: (base64 str) 16, 24, 32 bytes sync encrypt key
    return: (base64 str - iv).(base64 str - encrypted data)
    """
    key = base64.b64decode(key.encode())
    iv = os.urandom(16)

    # set encrypter
    encrypter = pyaes.Encrypter(pyaes.AESModeOfOperationCBC(key, iv))
    # encrypted binary to base64 str
    cipher = base64.b64encode(encrypter.feed(data) + encrypter.feed()).decode('utf-8')

    return f"{base64.b64encode(iv).decode('utf-8')}.{cipher}"


def aes_decode(data: str, key: str = settings.encrypt_key) -> str:
    """
    data: (base64 str - iv).(base64 str - encrypted data)
    key: (base64 str) 16, 24, 32 bytes sync encrypt key
    return: decode python str
    """
    key = base64.b64decode(key.encode())
    iv = base64.b64decode(data.split('.')[0].encode())

    # set decrypter
    decrypter = pyaes.Decrypter(pyaes.AESModeOfOperationCBC(key, iv))
    # data (iv).(encrypted text) to binary encrypted text
    cipher = base64.b64decode(data.split('.')[1].encode())

    return (decrypter.feed(cipher) + decrypter.feed()).decode('utf-8')
```

::: tip Какие данные шифрует [Pepeunit](/conception/overview)?
Все конфиденциальные данные, а именно:
1. Динамическая соль, использующаяся для хэширования пароля пользователя
1. Авторизационные данные, отвестветвенные за доступ до приватных репозиториев
1. Файлы окружений - [env.json](/definitions#env-json) от [Unit](/definitions#unit)
1. Внешнее хранилище внутреннего состояния [Unit](/definitions#unit)
:::

:::danger
Администратор имеющий доступ к `.env` файлу бэкенда инстанса [Pepeunit](/conception/overview), имеет возможность расшифровать данные хранящиеся в шифрованном виде на его инстансе.

Поэтому используйте только инстансы [Pepeunit](/conception/overview) администраторам которых вы доверяете.

Шифрованная информация не передаётся между инстансами и хранится на инстансе, где были созданы ваши сущности, остальные инстансы получают ограниченное представление о первичной сущности.
:::