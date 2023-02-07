This folder contains SOPS-managed k8s secrets, just for manual
applies for now. The files contain the necessary metadata identifying the key
with which they are encrypted, but without any additional configuration,
you need to specify the key when creating a new encrypted file.

```bash
sops --encrypt --gcp-kms projects/cal-itp-data-infra/locations/global/keyRings/sops/cryptoKeys/sops-key secret.yaml > sops/encrypted_secret.yaml
```
