# openvas-deployment

Deployment utility for the Greenbone OpenVAS Enterprise Container.

This script is intended for demonstration purposes until the standard deployment tooling supports this product.

The repository packages `enterprise-container.sh` as:

* a standalone shell script
* an AppImage for portable execution (not yet available)

The utility initializes, updates, starts, stops, and manages an OpenVAS Enterprise Container deployment. It also supports feed synchronization, TLS certificate management, administrator password changes, deployment logs and status, and OpenVASD scanner registration.

## Installation

### Shell script

Make the script executable and display its command-line help:

```bash
chmod +x AppDir/usr/bin/enterprise-container.sh
./AppDir/usr/bin/enterprise-container.sh --help
```

When installed as `openvas-deployment`, use:

```bash
openvas-deployment --help
```

The help output is displayed in a pager. Use the arrow keys to move through it and press `q` to quit.

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

Check the deployment status:

```bash
openvas-deployment --ps
```

View deployment logs:

```bash
openvas-deployment --logs
```

Stop the deployment:

```bash
openvas-deployment --down
```

> [!WARNING]
> `--down-volumes` stops the deployment and removes its Docker volumes. This can permanently delete persistent deployment data.

## Actions

| Action                    | Description                                                                                |
| ------------------------- | ------------------------------------------------------------------------------------------ |
| `--init`                  | Initialize the deployment, certificates, and deployment settings.                          |
| `--init-openvasd`         | Initialize OCI client certificates for an OpenVASD deployment.                             |
| `--change-admin-password` | Change the `gvmd` administrator password.                                                  |
| `--change-feed-sync-hour` | Change the daily scheduled feed synchronization hour.                                      |
| `--force-feed-sync`       | Restart feed synchronization immediately.                                                  |
| `--update`                | Download the latest product version.                                                       |
| `--run`                   | Start or redeploy the configured deployment.                                               |
| `--logs`                  | Show deployment logs. Optionally restrict the output to one service with `--service-name`. |
| `--ps`                    | Show the deployment status.                                                                |
| `--down`                  | Stop the deployment.                                                                       |
| `--down-volumes`          | Stop the deployment and remove its Docker volumes.                                         |
| `--update-ingress-certs`  | Replace the ingress TLS certificate and private key.                                       |
| `--create-openvasd-certs` | Create TLS certificates for an OpenVASD scanner.                                           |
| `--create-openvasd-tar`   | Create an OpenVASD deployment archive.                                                     |
| `--get-openvasds`         | List OpenVASD scanners registered in `gvmd`.                                               |
| `--add-openvasd`          | Register an OpenVASD scanner in `gvmd`.                                                    |
| `--del-openvasd`          | Remove an OpenVASD scanner from `gvmd`.                                                    |
| `-h`, `--help`            | Display the command-line help.                                                             |

## Deployment options

| Option                   | Description                                                                  |
| ------------------------ | ---------------------------------------------------------------------------- |
| `--deployment-mode MODE` | Deployment mode: `scan` or `openvas`.                                        |
| `--feed-mode MODE`       | Feed mode: `volume`, `service`, or `mount`.                                  |
| `--feed-key FILE`        | Feed key file used with feed mode `volume` or `service`.                     |
| `--feed-path PATH`       | Host feed directory used with feed mode `mount`.                             |
| `--feed-sync-hour HOUR`  | Daily scheduled feed synchronization hour from `1` to `24`.                  |
| `--ccert-mode MODE`      | Client certificate mode: `ca`, `cert`, or `mount`.                           |
| `--ccert-path PATH`      | Host client-certificate directory used with client certificate mode `mount`. |

The active runtime defaults are shown by:

```bash
openvas-deployment --help
```

## Log options

| Option                   | Description                                                   |
| ------------------------ | ------------------------------------------------------------- |
| `--service-name SERVICE` | Restrict `--logs` output to the specified deployment service. |

Show all deployment logs:

```bash
openvas-deployment --logs
```

Show logs for one service:

```bash
openvas-deployment --logs \
  --service-name SERVICE
```

## Administrator options

| Option                      | Description                                                                          |
| --------------------------- | ------------------------------------------------------------------------------------ |
| `--admin-password PASSWORD` | Administrator password used during initialization or with `--change-admin-password`. |

Avoid exposing passwords in shell history. Where practical, use an interactive shell with history disabled temporarily or another protected invocation mechanism.

## OCI client certificate options

| Option                   | Description                                                                        |
| ------------------------ | ---------------------------------------------------------------------------------- |
| `--license-file FILE`    | License file containing the OCI registry client certificate and private key.       |
| `--oci-client-cert FILE` | OCI registry client certificate.                                                   |
| `--oci-client-key FILE`  | OCI registry client private key.                                                   |
| `--init-docker-oci`      | Install OCI credentials into the Docker daemon using `sudo`.                       |
| `--skip-docker-oci`      | Do not install OCI credentials automatically; print the required commands instead. |

The OCI credentials can be supplied either through a license file or as separate certificate and key files.

Protect private keys and license files with restrictive permissions:

```bash
chmod 0600 /path/to/product.key
chmod 0600 /path/to/license-file
```

## Ingress certificate options

| Option                       | Description                 |
| ---------------------------- | --------------------------- |
| `--ingress-server-cert FILE` | Ingress server certificate. |
| `--ingress-server-key FILE`  | Ingress server private key. |

## OpenVASD options

| Option                            | Description                                                         |
| --------------------------------- | ------------------------------------------------------------------- |
| `--cn-openvasd NAME`              | OpenVASD common name and scanner hostname.                          |
| `--openvasd-port PORT`            | OpenVASD scanner or exposed host port. The default is `443`.        |
| `--openvasd-uuid UUID`            | Scanner UUID returned by `--get-openvasds`.                         |
| `--openvasd-tar-with-images`      | Include Docker images in the OpenVASD archive. Disabled by default. |
| `--openvasd-load-images-from-tar` | Load packaged Docker images before deployment. Disabled by default. |

## Examples

### Initialize using a license file

```bash
openvas-deployment --init \
  --license-file /path/to/license-file \
  --feed-key /path/to/prod-feed.key
```

### Initialize with separate OCI credentials

```bash
openvas-deployment --init \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --feed-key /path/to/prod-feed.key
```

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

### Inspect the deployment

Show deployment status:

```bash
openvas-deployment --ps
```

Show all deployment logs:

```bash
openvas-deployment --logs
```

Show logs for a specific service:

```bash
openvas-deployment --logs \
  --service-name SERVICE
```

### Create an OpenVASD deployment archive

Create scanner certificates:

```bash
openvas-deployment --create-openvasd-certs \
  --cn-openvasd sensor.example.com
```

Create an archive containing the deployment and Docker images:

```bash
openvas-deployment --create-openvasd-tar \
  --cn-openvasd sensor.example.com \
  --openvasd-tar-with-images
```

Run an extracted archive and load the packaged images:

```bash
openvas-deployment --run \
  --openvasd-load-images-from-tar
```

Run an extracted archive with a different exposed host port:

```bash
openvas-deployment --run \
  --openvasd-load-images-from-tar \
  --openvasd-port PORT
```

### Manage OpenVASD scanner registrations

Register a scanner using the default port `443`:

```bash
openvas-deployment --add-openvasd \
  --cn-openvasd sensor.example.com \
  --openvasd-port 443
```

List registered scanners:

```bash
openvas-deployment --get-openvasds
```

Remove a scanner:

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

# Check deployment status
openvas-deployment --ps

# Inspect deployment logs
openvas-deployment --logs

# Stop the deployment
openvas-deployment --down
```

After configuration changes, use `--run` to start or redeploy the configured environment.

## Security considerations

* Restrict private-key and license files to the deployment administrator.
* Treat deployment archives containing Docker images, certificates, or configuration as sensitive.
* Review commands printed by `--skip-docker-oci` before running them with elevated privileges.
* Use `--down-volumes` only when persistent deployment data is no longer required.

## Troubleshooting

Display all supported options and current defaults:

```bash
openvas-deployment --help
```

Verify that Docker and Docker Compose are available:

```bash
docker version
docker compose version
```

Show the deployment status:

```bash
openvas-deployment --ps
```

Inspect deployment logs:

```bash
openvas-deployment --logs
```

Inspect the underlying running containers:

```bash
docker ps
```

For deployment-specific failures, preserve the command output and relevant container logs before restarting the deployment or removing volumes.

## Support

Greenbone support:

https://www.greenbone.net/support/
