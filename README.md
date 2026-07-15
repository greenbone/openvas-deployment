# openvas-deployment

Deployment utility for the Greenbone OpenVAS Enterprise Container.

This script is for demo purposes until our deployment tool supports this product!

The repository packages `enterprise-container.sh` as both:

- a standalone shell script
- an AppImage for portable execution (Not yet!)

The utility initializes, updates, starts, stops, and manages an OpenVAS Enterprise Container deployment. It also supports feed synchronization, TLS certificate management, administrator password changes, and OpenVASD scanner registration.

## Installation

### Shell script

The script can also be executed directly:

```bash
chmod +x AppDir/usr/bin/enterprise-container.sh
./AppDir/usr/bin/enterprise-container.sh --help
```

## Quick start

Initialize a scan deployment using a Docker volume for feeds:

```bash
openvas-deployment --init \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --feed-key /path/to/prod-feed.key
```

Download the latest product version:

```bash
openvas-deployment --update
```

Start or redeploy the configured deployment:

```bash
openvas-deployment --run
```

Stop the deployment:

```bash
openvas-deployment --down
```

> [!WARNING]
> `--down-volumes` removes the deployment volumes in addition to stopping the deployment. This can delete persistent deployment data.

## Actions

| Action | Description |
|---|---|
| `--init` | Initialize the scan deployment, certificates, and deployment settings. |
| `--init-openvasd` | Initialize Docker OCI client certificates for an OpenVASD deployment. |
| `--change-admin-password` | Change the `gvmd` administrator password. |
| `--change-feed-sync-hour` | Change the scheduled feed synchronization hour. |
| `--force-feed-sync` | Restart the feed synchronization service immediately. |
| `--update` | Download the latest product version. |
| `--run` | Start or redeploy the configured deployment. |
| `--down` | Stop the deployment. |
| `--down-volumes` | Stop the deployment and remove its volumes. |
| `--update-ingress-certs` | Replace the ingress TLS certificate and private key. |
| `--create-openvasd-certs` | Create TLS certificates for an OpenVASD scanner. |
| `--create-openvasd-tar` | Create an OpenVASD deployment archive. |
| `--get-openvasds` | List OpenVASD scanners registered in `gvmd`. |
| `--add-openvasd` | Register an OpenVASD scanner in `gvmd`. |
| `--del-openvasd` | Delete an OpenVASD scanner from `gvmd`. |
| `-h`, `--help` | Display the command-line help. |

## Deployment options

| Option | Description |
|---|---|
| `--deployment-mode MODE` | Deployment mode: `scan` or `openvas`. |
| `--feed-mode MODE` | Feed mode: `volume`, `service`, or `mount`. |
| `--feed-key FILE` | Feed key file used by `volume` or `service` mode. |
| `--feed-path PATH` | Host feed directory used with feed mode `mount`. |
| `--feed-sync-hour HOUR` | Scheduled feed synchronization hour from `1` to `24`. |
| `--ccert-mode MODE` | Client certificate mode: `ca`, `cert`, or `mount`. |
| `--ccert-path PATH` | Host client-certificate directory used with client certificate mode `mount`. |

Runtime defaults are shown by:

```bash
openvas-deployment --help
```

## Administrator options

| Option | Description |
|---|---|
| `--admin-password PASSWORD` | Administrator password used during initialization or with `--change-admin-password`. |

Avoid exposing passwords in shell history. Where practical, use an interactive shell with history disabled temporarily or another protected invocation mechanism.

## OCI client certificate options

| Option | Description |
|---|---|
| `--oci-client-cert FILE` | OCI registry client certificate. |
| `--oci-client-key FILE` | OCI registry client private key. |
| `--init-docker-oci` | Install OCI credentials into Docker using `sudo`. |
| `--skip-docker-oci` | Do not install OCI credentials; print the required commands instead. |

Protect private keys with restrictive permissions:

```bash
chmod 0600 /path/to/product.key
```

## Ingress certificate options

| Option | Description |
|---|---|
| `--ingress-server-cert FILE` | Ingress server certificate. |
| `--ingress-server-key FILE` | Ingress server private key. |

## OpenVASD options

| Option | Description |
|---|---|
| `--cn-openvasd NAME` | OpenVASD common name and scanner host. |
| `--openvasd-port PORT` | OpenVASD scanner port, normally `8443` or `443`. |
| `--openvasd-uuid UUID` | Scanner UUID returned by `--get-openvasds`. |
| `--openvasd-tar-with-images` | Include Docker images in the OpenVASD archive. Disabled by default. |
| `--openvasd-load-images-from-tar` | Load packaged Docker images before deployment. Disabled by default. |

## Examples

### Initialize with a predefined administrator password

```bash
openvas-deployment --init \
  --admin-password 'secure-password' \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --feed-key /path/to/prod-feed.key
```

### Configure the feed synchronization hour

During initialization:

```bash
openvas-deployment --init \
  --feed-sync-hour 3 \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --feed-key /path/to/prod-feed.key
```

For an existing deployment:

```bash
openvas-deployment --change-feed-sync-hour \
  --feed-sync-hour 4
```

Trigger feed synchronization immediately:

```bash
openvas-deployment --force-feed-sync
```

### Change the administrator password

```bash
openvas-deployment --change-admin-password \
  --admin-password 'new-secure-password'
```

### Initialize with custom ingress certificates

```bash
openvas-deployment --init \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --feed-key /path/to/prod-feed.key \
  --ingress-server-cert /path/to/ingress.crt \
  --ingress-server-key /path/to/ingress.key
```

### Replace ingress certificates

```bash
openvas-deployment --update-ingress-certs \
  --ingress-server-cert /path/to/ingress.crt \
  --ingress-server-key /path/to/ingress.key
```

### Create an OpenVASD deployment archive

Create scanner certificates:

```bash
openvas-deployment --create-openvasd-certs \
  --cn-openvasd detect.example.com
```

Create an archive containing the deployment and Docker images:

```bash
openvas-deployment --create-openvasd-tar \
  --cn-openvasd detect.example.com \
  --openvasd-tar-with-images
```

Run an extracted archive and load the packaged images:

```bash
openvas-deployment --run \
  --openvasd-load-images-from-tar
```

### Manage OpenVASD scanner registrations

Register a scanner:

```bash
openvas-deployment --add-openvasd \
  --cn-openvasd detect.example.com \
  --openvasd-port 8443
```

List registered scanners:

```bash
openvas-deployment --get-openvasds
```

Delete a scanner:

```bash
openvas-deployment --del-openvasd \
  --openvasd-uuid UUID
```

## Typical lifecycle

```bash
# Initialize the deployment
openvas-deployment --init \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --feed-key /path/to/prod-feed.key

# Download the current product version
openvas-deployment --update

# Start the deployment
openvas-deployment --run

# Stop it later
openvas-deployment --down
```

After configuration changes, use `--run` to start or redeploy the configured environment.

## Security considerations

- Store product certificates, feed keys, and private keys outside the repository.
- Do not commit credentials or generated deployment secrets.
- Restrict private-key files to the deployment administrator.
- Treat deployment archives containing Docker images, certificates, or configuration as sensitive.
- Review commands printed by `--skip-docker-oci` before running them with elevated privileges.
- Use `--down-volumes` only when persistent deployment data is no longer required.

## Troubleshooting

Display all supported options and current defaults:

```bash
openvas-deployment --help
```

Verify that Docker is available:

```bash
docker version
docker compose version
```

Inspect running containers:

```bash
docker ps
```

For deployment-specific failures, preserve the command output and relevant container logs before removing volumes.

## Support

Greenbone support:

https://www.greenbone.net/support/
