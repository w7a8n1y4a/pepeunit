# Encryption

Pepeunit uses `AES-256-GCM` encryption: a `12-byte` random initialization vector (nonce) and a `32-byte` key `PU_ENCRYPT_KEY` from the [Backend ENV](/deployment/env-variables/backend). The vector is created anew every time, so identical data is encrypted into different strings.

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

The resulting string has the form `nonce.cipher`, both values in base64. The GCM authentication tag is part of `cipher`: if the data has been changed, decryption fails with an error.

Pepeunit encrypts all confidential data stored on the instance:
1. Access credentials for a private [Repo](/development-pepeunit/mechanics/entities#repo): the platform name and token of each [User](/development-pepeunit/mechanics/roles#user)
1. Environment files: the [env.json](/development-pepeunit/mechanics/alg-env) of each `Unit`
1. The [internal state storage](/developer/state-storage-unit) of a `Unit`

The size of an encrypted object is limited by the `pu_instance_cipher_max_length` setting in the [instance settings](/deployment/instance-settings). It is counted in characters, defaults to `1 000 000`, and may be from `100 000` to `5 000 000`. The [Owner](/development-pepeunit/mechanics/roles#owner) changes it in the client. If the data is larger, Pepeunit returns an error.

Encrypted information is not passed between instances and is stored on the instance where the entity was created: other instances receive only public data through [federation](/development-pepeunit/mechanics/federation). The [Admin](/development-pepeunit/mechanics/roles#admin) and the [Owner](/development-pepeunit/mechanics/roles#owner) of Pepeunit itself get no access to this data through the API: they see it under the same rules as any `User`.

:::danger
Whoever has access to the [Backend ENV](/deployment/env-variables/backend) of an instance (the server administrator) can decrypt the data stored on it in encrypted form. Use only instances whose server administrators you trust.

If you change `PU_ENCRYPT_KEY`, the old encrypted data cannot be decrypted.
:::
