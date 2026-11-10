# Шифрование

Pepeunit использует шифрование `AES-256-GCM`: `12 байтовый` случайный инициирующий вектор (nonce) и `32 байтовый` ключ `PU_ENCRYPT_KEY` из [Backend ENV](/deployment/env-variables/backend). Каждый раз вектор создаётся заново, поэтому одинаковые данные шифруются в разные строки.

```python
import os
import base64

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from app import runtime, settings


def aes_gcm_encode(data: str, key: str = settings.pu_encrypt_key) -> str:
    """
    data: any python str
    key: (base64 str) 16, 24, 32 bytes sync encrypt key
    return: (base64 str - nonce).(base64 str - encrypted data with the GCM tag)
    """
    len_content = len(data)
    if len_content > runtime.get().pu_instance_cipher_max_length:
        msg = f"The encryption content is {len_content} long, although only <= {runtime.get().pu_instance_cipher_max_length} is allowed"
        raise CipherError(msg, code=ErrorCode.CIPHER_CONTENT_TOO_LONG)

    key = base64.b64decode(key.encode())
    nonce = os.urandom(12)  # 96-bit nonce for AES-GCM
    aesgcm = AESGCM(key)

    cipher = aesgcm.encrypt(nonce, data.encode(), None)  # Encrypt data

    return f"{base64.b64encode(nonce).decode()}.{base64.b64encode(cipher).decode()}"


def aes_gcm_decode(data: str, key: str = settings.pu_encrypt_key) -> str:
    """
    data: (base64 str - nonce).(base64 str - encrypted data with the GCM tag)
    key: (base64 str) 16, 24, 32 bytes sync encrypt key
    return: decode python str
    """
    key = base64.b64decode(key.encode())
    nonce, cipher = data.split(".")
    nonce = base64.b64decode(nonce.encode())
    cipher = base64.b64decode(cipher.encode())

    aesgcm = AESGCM(key)

    return aesgcm.decrypt(nonce, cipher, None).decode("utf-8")
```

Итоговая строка имеет вид `nonce.cipher`, оба значения в base64. Тег аутентификации GCM входит в `cipher`: если данные изменились, расшифровка завершится ошибкой.

::: tip Какие данные шифрует Pepeunit?
Все конфиденциальные данные, которые хранятся на инстансе:
1. Креды доступа к приватному [Repo](/development-pepeunit/mechanics/entities#repo): имя и токен платформы каждого [Пользователя](/development-pepeunit/mechanics/roles#user)
1. Файлы окружений - [env.json](/development-pepeunit/mechanics/alg-env) каждого `Unit`
1. [Хранилище внутреннего состояния](/developer/state-storage-unit) `Unit`
:::

:::info Чего в шифровании больше нет
Паролей и их соли в Pepeunit нет: вход построен на [паре ключей](/development-pepeunit/mechanics/authentication), а в базе лежит только публичный ключ, который секретом не является.
:::

:::warning Ограничение размера шифруемых объектов
Все шифруемые объекты ограничены настройкой `pu_instance_cipher_max_length` в [настройках инстанса](/deployment/instance-settings). Она считается в символах, по умолчанию `1 000 000`, допустимо от `100 000` до `5 000 000`. [Owner](/development-pepeunit/mechanics/roles#owner) меняет её в клиенте. Если данные больше, Pepeunit возвращает ошибку.
:::

:::danger
Тот, у кого есть доступ к [Backend ENV](/deployment/env-variables/backend) инстанса Pepeunit (администратор сервера), может расшифровать данные, хранящиеся в шифрованном виде на его инстансе.

Поэтому пользуйтесь только инстансами Pepeunit, администраторам сервера которых вы доверяете.

Если сменить `PU_ENCRYPT_KEY`, старые шифрованные данные не расшифровать. [Admin](/development-pepeunit/mechanics/roles#admin) и [Owner](/development-pepeunit/mechanics/roles#owner) самого Pepeunit доступа к этим данным через API не получают: они видят их по тем же правилам, что и любой `User`.

Шифрованная информация не передаётся между инстансами и хранится на инстансе создания сущности. Другие инстансы получают через [федерацию](/development-pepeunit/mechanics/federation) только публичные данные.
:::
