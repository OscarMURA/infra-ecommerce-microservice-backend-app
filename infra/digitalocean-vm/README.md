# DigitalOcean VM for Integration Tests

Scripts and cloud-init configuration to provision a disposable DigitalOcean droplet that Jenkins uses to execute integration and end-to-end tests.

## Requirements

- DigitalOcean Personal Access Token with write permissions (`DO_TOKEN`)
- Jenkins Secret Text credential storing the password for the `jenkins` user (ID sugerido: `integration-vm-password`)
- `curl` y `jq` instalados en el agente de Jenkins

## Files

- `cloud-init.yaml`: cloud-init template executed on first boot. Installs Docker Engine, Compose plugin, Python 3 and other utilities. It creates the `jenkins` user with sudo access and password authentication enabled.
- `create-do-droplet.sh`: helper to create a droplet using the template above.
- `delete-do-droplet.sh`: helper to destroy a droplet either by name or droplet ID.

## Usage

```bash
export DO_TOKEN=...
export VM_PASSWORD='StrongPassword!'
NAME=ecommerce-integration-runner \
  REGION=nyc3 \
  SIZE=s-1vcpu-2gb \
  IMAGE=ubuntu-22-04-x64 \
  ./create-do-droplet.sh
```

To delete the VM by name:

```bash
export DO_TOKEN=...
NAME=ecommerce-integration-runner ./delete-do-droplet.sh
```
