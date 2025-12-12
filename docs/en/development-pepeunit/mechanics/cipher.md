# Encryption

[Pepeunit](/en/conception/overview) uses `AES256` encryption with a `12-byte` initialization vector and a `32-byte` key — the encryption scheme is `GCM`.

```python
import os
import base64

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from app import settings


def aes_gcm_encode(data: str, key: str = settings.pu_encrypt_key) -> str:
    """
    data: any python str
    key: (base64 str) 16, 24, 32 bytes sync encrypt key
    return: (base64 str - nonce).(base64 str - encrypted data).(base64 str - tag)
    """
    len_content = len(data)
    if len_content > settings.pu_max_cipher_length:
        msg = f"The encryption content is {len_content} long, although only <= {settings.pu_max_cipher_length} is allowed"
        raise CipherError(msg)

    key = base64.b64decode(key.encode())
    nonce = os.urandom(12)  # 96-bit nonce for AES-GCM
    aesgcm = AESGCM(key)

    cipher = aesgcm.encrypt(nonce, data.encode(), None)  # Encrypt data

    return f"{base64.b64encode(nonce).decode()}.{base64.b64encode(cipher).decode()}"


def aes_gcm_decode(data: str, key: str = settings.pu_encrypt_key) -> str:
    """
    data: (base64 str - nonce).(base64 str - encrypted data)
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

::::tip What data does [Pepeunit](/en/conception/overview) encrypt?
All confidential data, namely:
1. Dynamic salt used for hashing a [User](/en/development-pepeunit/mechanics/roles.html#user) password
1. Authorization data responsible for access to `Private` [RepositoryRegisty](/en/definitions#repositoryregistry)
1. Environment files — [env.json](/en/definitions#env-json) of a [Unit](/en/definitions#unit)
1. [Internal state storage](/en/developer/state-storage-unit) of a [Unit](/en/definitions#unit)
::::

::::warning Size limit of encrypted objects
All encrypted objects have a default size limit of `1 000 000` characters. The [Administrator](/en/development-pepeunit/mechanics/roles#admin) of an instance can change this limit by setting the `PU_MAX_CIPHER_LENGTH` environment variable in the [Backend ENV](/en/deployment/env-variables/backend) file.
::::

::::danger
An [Administrator](/en/development-pepeunit/mechanics/roles#admin) who has access to the instance [Backend ENV](/en/deployment/env-variables/backend) of [Pepeunit](/en/conception/overview) can decrypt data stored in encrypted form in that instance.

Therefore, only use [Pepeunit](/en/conception/overview) instances whose [Administrators](/en/development-pepeunit/mechanics/roles#admin) you trust.

Encrypted information is not transferred between instances and is stored on the instance where the entity was created. Other instances receive only a limited representation of the primary entity.
::::


