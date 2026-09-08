# openvas-deployment

Deployment utility for the Greenbone OpenVAS Enterprise Container and OpenVAS Security Intelligence.

This script is intended for demonstration purposes until the standard deployment tooling supports this product.

The utility initializes, updates, starts, stops, and manages an enterprise-container or security-intelligence deployment. It also supports feed synchronization, TLS certificate management, administrator password changes, deployment logs and status, and OpenVASD scanner registration.

> [!IMPORTANT]
> Requires compose version 5.3.1 and higher!

## Installation

## Download

**[Releases](https://github.com/greenbone/openvas-deployment/releases)** 

```bash
unzstd openvas-deployment.zst
chmod +x openvas-deployment
openvas-deployment --help
```

The help output is displayed in a pager. Use the arrow keys to move through it and press `q` to quit.

## Quick start

Initialize a enterprise-container scan deployment:

```bash
openvas-deployment --init \
  --product enterprise-container \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --feed-key /path/to/prod-feed.key
```

Or initialize a security-intelligence deployment:

```bash
openvas-deployment --init \
  --product security-intelligence \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --domain-name osi.example.com
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
| `--init-openvasd-tar`     | Initialize OCI client certificates from an OpenVASD deployment archive created with `--create-openvasd-tar`. |
| `--create-openvasd-cert-tar` | Create an OpenVASD certificate archive. Only enterprise-container.                      |
| `--change-admin-password` | Change the `gvmd` administrator password. Only enterprise-container.                       |
| `--change-feed-sync-hour` | Change the daily scheduled feed synchronization hour. Only enterprise-container.           |
| `--force-feed-sync`       | Restart feed synchronization immediately. Only enterprise-container.                       |
| `--update`                | Download the latest product version.                                                       |
| `--run`                   | Start or redeploy the configured deployment.                                               |
| `--logs`                  | Show deployment logs. Optionally restrict the output to one service with `--service-name`. |
| `--ps`                    | Show the deployment status.                                                                |
| `--down`                  | Stop the deployment.                                                                       |
| `--down-volumes`          | Stop the deployment and remove its Docker volumes.                                         |
| `--update-ingress-certs`  | Replace the ingress TLS certificate and private key.                                       |
| `--create-openvasd-certs` | Create TLS certificates for an OpenVASD scanner. Only enterprise-container.                |
| `--create-openvasd-tar`   | Create an OpenVASD deployment archive. Only enterprise-container.                          |
| `--get-openvasds`         | List OpenVASD scanners registered in `gvmd`. Only enterprise-container.                    |
| `--add-openvasd`          | Register an OpenVASD scanner in `gvmd`. Only enterprise-container.                         |
| `--del-openvasd`          | Remove an OpenVASD scanner from `gvmd`. Only enterprise-container.                         |
| `-h`, `--help`            | Display the command-line help.                                                             |

## Deployment options

| Option                   | Description                                                                  |
| ------------------------ | ---------------------------------------------------------------------------- |
| `--product PRODUCT`       | Product to deploy: `enterprise-container` or `security-intelligence`.       |
| `--domain-name NAME`      | Domain name for the deployment. Only security-intelligence.                 |
| `--metafeed-cert FILE`    | Metafeed client certificate. Only security-intelligence.                    |
| `--metafeed-key FILE`     | Metafeed client private key. Only security-intelligence.                    |
| `--deployment-mode MODE` | Deployment mode: `scan` or `openvasd`. Only enterprise-container.            |
| `--openvasd-client-ca FILE` | OpenVASD client CA certificate used for `--init --deployment-mode openvasd`. Only enterprise-container. |
| `--openvasd-server-cert FILE` | OpenVASD server certificate used for `--init --deployment-mode openvasd`. Only enterprise-container.  |
| `--openvasd-server-key FILE` | OpenVASD server private key used for `--init --deployment-mode openvasd`. Only enterprise-container.   |
| `--feed-mode MODE`       | Feed mode: `volume`, `service`, or `mount`. Only enterprise-container.                                     |
| `--feed-key FILE`        | Feed key file used with feed mode `volume` or `service`. Only enterprise-container.                        |
| `--feed-path PATH`       | Host feed directory used with feed mode `mount`. Only enterprise-container.                                |
| `--feed-sync-hour HOUR`  | Daily scheduled feed synchronization hour from `0` to `23`. Only enterprise-container.                     |
| `--ccert-mode MODE`      | Client certificate mode: `ca`, `cert`, or `mount`. Only enterprise-container.                              |
| `--ccert-path PATH`      | Host client-certificate directory used with client certificate mode `mount`. Only enterprise-container.    |
| `--feed-sync-force-no-log` | Force feed synchronization without logging. Only enterprise-container. Only enterprise-container.        |
| `--skip-init-if-exist`   | Exit with status 0 if already initialized.                                                                 |

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
| `--update-ingress-cert-redeploy` | Redeploy after updating ingress certificates. |
| `--skip--update-ingress-cert-redeploy` | Do not redeploy after updating ingress certificates. |

## OpenVASD options

| Option                            | Description                                                         |
| --------------------------------- | ------------------------------------------------------------------- |
| `--cn-openvasd NAME`              | OpenVASD common name and scanner hostname.                          |
| `--openvasd-port PORT`            | OpenVASD scanner or exposed host port. The default is `443`.        |
| `--openvasd-uuid UUID`            | Scanner UUID returned by `--get-openvasds`.                         |
| `--openvasd-tar-with-images`      | Include Docker images in the OpenVASD archive. Disabled by default. |
| `--openvasd-load-images-from-tar` | Load packaged Docker images before deployment. Disabled by default. |

## Development options

| Option | Description |
| --- | --- |
| `--dev` | Use development stage URL prefix `-dev/dev`. |
| `--integration` | Use development stage URL prefix `-dev/integration`. |
| `--testing` | Use development stage URL prefix `-dev/testing`. |
| `--staging` | Use development stage URL prefix `-dev/staging`. |

## Examples

### Initialize using a license file

```bash
openvas-deployment --init \
  --product enterprise-container \
  --license-file /path/to/license-file \
  --feed-key /path/to/prod-feed.key
```

### Initialize with separate OCI credentials

```bash
openvas-deployment --init \
  --product enterprise-container \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --feed-key /path/to/prod-feed.key
```

### Initialize with a predefined administrator password

```bash
openvas-deployment --init \
  --product enterprise-container \
  --admin-password 'secure-password' \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --feed-key /path/to/prod-feed.key
```

### Configure the feed synchronization hour

During initialization:

```bash
openvas-deployment --init \
  --product enterprise-container \
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
  --product enterprise-container \
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

### External OpenVASD sensor setup with certificate archive

```bash
openvas-deployment --create-openvasd-certs --cn-openvasd sensor.example.com
openvas-deployment --create-openvasd-cert-tar --cn-openvasd sensor.example.com
```

Initialize the remote OpenVASD deployment:

```bash
openvas-deployment --init --deployment-mode openvasd \
  --product enterprise-container \
  --cn-openvasd sensor.example.com \
  --oci-client-cert oci.crt \
  --oci-client-key oci.key \
  --feed-key key \
  --openvasd-server-cert server.crt \
  --openvasd-server-key server.key \
  --openvasd-client-ca ca.crt
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

### CI workflows

Use `--skip-init-if-exist` with `--skip-docker-oci` or `--init-docker-oci`.

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
