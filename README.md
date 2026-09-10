# openvas-deployment

Deployment utility for the Greenbone OpenVAS Enterprise Container and OpenVAS Security Intelligence.

This script is intended for demonstration purposes until the standard deployment tooling supports this product.
The utility initializes, updates, starts, stops, and manages an enterprise-container or security-intelligence deployment. It also supports feed synchronization, TLS certificate management, administrator password changes, deployment logs and status, and OpenVASD scanner registration.

> [!IMPORTANT]
> Requires compose version 5.3.1 and higher!

## Table of contents

- [Installation](#installation)
- [Download](#download)
- [Quick start](#quick-start)
- [Actions](#actions)
- [Deployment options](#deployment-options)
- [Log options](#log-options)
- [Administrator options](#administrator-options)
- [OCI client certificate options](#oci-client-certificate-options)
- [Ingress certificate options](#ingress-certificate-options)
- [OpenVASD options](#openvasd-options)
- [Development options](#development-options)
- [Examples](#examples)
- [Security considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Support](#support)

## Installation

The utility requires Bash, a reachable Docker daemon, Docker Compose 5.3.1 or newer, ORAS, OpenSSL, `tar`, `curl`, `less`, `awk`, and standard core utilities such as `install`, `grep`, `sed`, `sort`, `base64`, and `chmod`. The release archive also requires `zstd`/`unzstd` for extraction.

The deployment state is stored in `./product` relative to the directory from which `openvas-deployment` is run. Run subsequent `--update`, `--run`, `--logs`, `--ps`, `--down`, and management commands from the same directory used for `--init`.

## Download

**[Releases](https://github.com/greenbone/openvas-deployment/releases)**

```bash
unzstd openvas-deployment.zst
chmod +x openvas-deployment
openvas-deployment --help
```

The help output is displayed in a pager. Use the arrow keys to move through it and press `q` to quit.

To build the executable from a source checkout:

```bash
make
./openvas-deployment --help
```

## Quick start

Initialize an enterprise-container scan deployment:

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

After initialization, the selected product and its settings are read from `./product`, so `--product` does not need to be repeated for later commands when they are run from the same directory.

Download the latest product version:

```bash
openvas-deployment --update
```

Start or redeploy the configured deployment:

```bash
openvas-deployment --run
```

`--run` uses the latest locally downloaded product version. Run `--update` before the first deployment and whenever a newer product version should be downloaded.

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

Use one action per invocation.

| Action                    | Description                                                                                |
| ------------------------- | ------------------------------------------------------------------------------------------ |
| `--init`                  | Initialize the deployment, certificates, secrets, and deployment settings under `./product`. If `./product` already exists, confirmation is requested unless `--skip-init-if-exist` is used. |
| `--init-openvasd-tar`     | Install Docker OCI client credentials for an extracted OpenVASD deployment archive.        |
| `--create-openvasd-cert-tar` | Create an OpenVASD certificate archive in the current directory. Requires `--cn-openvasd`. Only enterprise-container. |
| `--change-admin-password` | Change the `gvmd` administrator password. Requires `--admin-password` and a running enterprise-container scan deployment. Only enterprise-container. |
| `--change-feed-sync-hour` | Change the daily scheduled feed synchronization hour and immediately restart feed synchronization. Requires `--feed-sync-hour`. Only enterprise-container. |
| `--force-feed-sync`       | Restart feed synchronization immediately. Only enterprise-container.                       |
| `--update`                | Download and extract the latest product version from the configured OCI registry. If the latest version is already present locally, no download is performed. |
| `--run`                   | Start or redeploy the configured deployment using the latest locally downloaded product version. |
| `--logs`                  | Show deployment logs. Optionally restrict the output to one service with `--service-name`. |
| `--ps`                    | Show the deployment status, including stopped containers.                                  |
| `--down`                  | Stop the deployment.                                                                       |
| `--down-volumes`          | Stop the deployment and remove its Docker volumes and orphaned containers.                 |
| `--update-ingress-certs`  | Replace the ingress TLS certificate and private key. Requires both ingress certificate options. |
| `--create-openvasd-certs` | Create TLS certificates for an OpenVASD scanner using the enterprise-container scan CA. Requires `--cn-openvasd`. Only enterprise-container. |
| `--create-openvasd-tar`   | Create a portable OpenVASD deployment archive in the current directory. Requires `--cn-openvasd`. Only enterprise-container. |
| `--get-openvasds`         | List OpenVASD scanners registered in `gvmd`. Requires the enterprise-container scan `gvmd` container to be running. Only enterprise-container. |
| `--add-openvasd`          | Register an OpenVASD scanner in `gvmd`. Requires `--cn-openvasd`, `--openvasd-port`, and a reachable ready scanner. Only enterprise-container. |
| `--del-openvasd`          | Remove an OpenVASD scanner from `gvmd`. Requires `--openvasd-uuid`. Only enterprise-container. |
| `-h`, `--help`            | Display the command-line help.                                                             |

## Deployment options

| Option                   | Description                                                                  |
| ------------------------ | ---------------------------------------------------------------------------- |
| `--product PRODUCT`       | Product to deploy: `enterprise-container` or `security-intelligence`. Required for `--init`; stored in `./product/PRODUCT` for later commands. |
| `--domain-name NAME`      | Domain name for the deployment. Required for security-intelligence initialization. |
| `--metafeed-cert FILE`    | Optional metafeed client certificate for security-intelligence. If omitted or missing, initialization continues with a warning. |
| `--metafeed-key FILE`     | Optional metafeed client private key for security-intelligence. If omitted or missing, initialization continues with a warning. |
| `--deployment-mode MODE` | Enterprise-container deployment mode: `scan` or `openvasd`. Default: `scan`. |
| `--openvasd-client-ca FILE` | OpenVASD client CA certificate required for `--init --deployment-mode openvasd`. Only enterprise-container. |
| `--openvasd-server-cert FILE` | OpenVASD server certificate required for `--init --deployment-mode openvasd`. Only enterprise-container. |
| `--openvasd-server-key FILE` | OpenVASD server private key required for `--init --deployment-mode openvasd`. Only enterprise-container. |
| `--feed-mode MODE`       | Feed mode: `volume`, `service`, or `mount`. Default: `volume`. `mount` is currently rejected during initialization. Only enterprise-container. |
| `--feed-key FILE`        | Feed key file. Required for enterprise-container initialization. Base64-encoded keys are decoded before storage; other files are copied as-is. |
| `--feed-path PATH`       | Host feed directory for feed mode `mount`. The `mount` mode is currently not supported. Only enterprise-container. |
| `--feed-sync-hour HOUR`  | Daily scheduled feed synchronization hour from `0` to `23`. Default: `3`. Only enterprise-container. |
| `--ccert-mode MODE`      | Client certificate mode: `ca`, `cert`, or `mount`. Default: `ca`. `mount` is currently rejected during initialization. Only enterprise-container. |
| `--ccert-path PATH`      | Host client-certificate directory for client certificate mode `mount`. The `mount` mode is currently not supported. Only enterprise-container. |
| `--feed-sync-force-no-log` | With `--force-feed-sync` or `--change-feed-sync-hour`, do not prompt to follow the `feed-sync` service logs. Only enterprise-container. |
| `--skip-init-if-exist`   | With `--init`, exit with status 0 without changing the existing `./product` directory if it already exists. |

The active runtime defaults are shown by:

```bash
openvas-deployment --help
```

## Log options

| Option                   | Description                                                   |
| ------------------------ | ------------------------------------------------------------- |
| `--service-name SERVICE` | Restrict `--logs` output to the specified Docker Compose service. |

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
| `--admin-password PASSWORD` | Administrator password used during enterprise-container scan initialization or with `--change-admin-password`. If omitted during initialization, a random 16-character alphanumeric password is generated and printed. |

Avoid exposing passwords in shell history. Where practical, use an interactive shell with history disabled temporarily or another protected invocation mechanism.

## OCI client certificate options

| Option                   | Description                                                                        |
| ------------------------ | ---------------------------------------------------------------------------------- |
| `--license-file FILE`    | License file containing the OCI registry client certificate and private key. With `--init`, this is used instead of separate OCI certificate and key files. |
| `--oci-client-cert FILE` | OCI registry client certificate. Required with `--init` when `--license-file` is not used. |
| `--oci-client-key FILE`  | OCI registry client private key. Required with `--init` when `--license-file` is not used. |
| `--init-docker-oci`      | Install OCI credentials into `/etc/docker/certs.d/packages.greenbone.net` using `sudo`. |
| `--skip-docker-oci`      | Do not install OCI credentials automatically; print the required root commands instead. |

The OCI credentials can be supplied either through a license file or as separate certificate and key files. If neither `--init-docker-oci` nor `--skip-docker-oci` is supplied during initialization, the utility asks whether to install the Docker OCI credentials with `sudo`.

Protect private keys and license files with restrictive permissions:

```bash
chmod 0600 /path/to/product.key
chmod 0600 /path/to/license-file
```

## Ingress certificate options

| Option                       | Description                 |
| ---------------------------- | --------------------------- |
| `--ingress-server-cert FILE` | Ingress server certificate. During `--init`, provide this together with `--ingress-server-key`; otherwise a self-signed certificate pair is generated. |
| `--ingress-server-key FILE`  | Ingress server private key. During `--init`, provide this together with `--ingress-server-cert`; otherwise a self-signed certificate pair is generated. |
| `--update-ingress-cert-redeploy` | With `--update-ingress-certs`, redeploy immediately after replacing the certificates. |
| `--skip-update-ingress-cert-redeploy` | With `--update-ingress-certs`, replace the certificates without redeploying. |

If custom ingress certificates are not supplied during initialization, the utility generates a self-signed RSA certificate and key valid for 365 days. With `--update-ingress-certs`, both certificate files must exist. If neither redeploy option is supplied, the utility asks whether the compose stack should be redeployed.

## OpenVASD options

| Option                            | Description                                                         |
| --------------------------------- | ------------------------------------------------------------------- |
| `--cn-openvasd NAME`              | OpenVASD common name and scanner hostname. Required for OpenVASD initialization, certificate/archive creation, and scanner registration. |
| `--openvasd-port PORT`            | OpenVASD scanner or exposed host port. Default for the OpenVASD deployment is `443`; the port must be supplied explicitly with `--add-openvasd`. |
| `--openvasd-uuid UUID`            | Scanner UUID returned by `--get-openvasds`. Required with `--del-openvasd`. |
| `--openvasd-tar-with-images`      | With `--create-openvasd-tar`, include locally available Docker images in the archive. Disabled by default. |
| `--openvasd-load-images-from-tar` | With `--run`, load packaged Docker images before deploying an OpenVASD archive. Disabled by default; missing packaged images are skipped. |

`--create-openvasd-cert-tar` writes `<cn-with-dots-replaced-by-hyphens>.tar`. `--create-openvasd-tar` writes `<cn-with-dots-replaced-by-hyphens>.tar.gz` and includes the OpenVASD deployment settings, certificates, feed key, downloaded product artifacts, OCI credentials, and the deployment executable. Use `--openvasd-tar-with-images` when the target host should also receive the required Docker images.

## Development options

| Option | Description |
| --- | --- |
| `--dev` | Use development stage URL prefix `-dev/dev` for the current registry operation, typically with `--update`. |
| `--integration` | Use development stage URL prefix `-dev/integration` for the current registry operation, typically with `--update`. |
| `--testing` | Use development stage URL prefix `-dev/testing` for the current registry operation, typically with `--update`. |
| `--staging` | Use development stage URL prefix `-dev/staging` for the current registry operation, typically with `--update`. |

## Examples

### Initialize using a license file

```bash
openvas-deployment --init \
  --product enterprise-container \
  --license-file /path/to/license-file \
  --feed-key /path/to/prod-feed.key
```

For non-interactive initialization, explicitly select how Docker OCI credentials should be handled:

```bash
openvas-deployment --init \
  --product enterprise-container \
  --license-file /path/to/license-file \
  --feed-key /path/to/prod-feed.key \
  --init-docker-oci
```

Use `--skip-docker-oci` instead to print the root commands without executing them.

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

If `--admin-password` is omitted, initialization generates and prints a random password.

### Initialize security-intelligence with metafeed certificates

```bash
openvas-deployment --init \
  --product security-intelligence \
  --domain-name osi.example.com \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --metafeed-cert /path/to/metafeed.crt \
  --metafeed-key /path/to/metafeed.key
```

The metafeed certificate and key are optional; missing files produce warnings and the deployment is configured with empty metafeed certificate values.

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

Changing the feed synchronization hour also restarts the feed synchronization service. To avoid the prompt to follow its logs:

```bash
openvas-deployment --change-feed-sync-hour \
  --feed-sync-hour 4 \
  --feed-sync-force-no-log
```

Trigger feed synchronization immediately:

```bash
openvas-deployment --force-feed-sync
```

Trigger it without the log prompt:

```bash
openvas-deployment --force-feed-sync \
  --feed-sync-force-no-log
```

### Change the administrator password

```bash
openvas-deployment --change-admin-password \
  --admin-password 'new-secure-password'
```

The enterprise-container scan deployment must be running because the command executes `gvmd` inside the `gvmd` container.

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

Both files must be supplied together. If either is missing, initialization creates a self-signed ingress certificate pair instead.

### Replace ingress certificates

Replace the files and choose interactively whether to redeploy:

```bash
openvas-deployment --update-ingress-certs \
  --ingress-server-cert /path/to/ingress.crt \
  --ingress-server-key /path/to/ingress.key
```

Replace the files and redeploy without prompting:

```bash
openvas-deployment --update-ingress-certs \
  --update-ingress-cert-redeploy \
  --ingress-server-cert /path/to/ingress.crt \
  --ingress-server-key /path/to/ingress.key
```

Replace the files without redeploying:

```bash
openvas-deployment --update-ingress-certs \
  --skip-update-ingress-cert-redeploy \
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

Run these certificate creation commands from the directory of an initialized enterprise-container scan deployment so the scan CA is available:

```bash
openvas-deployment --create-openvasd-certs \
  --cn-openvasd sensor.example.com
openvas-deployment --create-openvasd-cert-tar \
  --cn-openvasd sensor.example.com
```

The second command creates `sensor-example-com.tar` in the current directory. Copy the archive, the deployment executable, the feed key, and the OCI client credentials to the target host, then extract the certificate archive.

Initialize the remote OpenVASD deployment:

```bash
openvas-deployment --init \
  --deployment-mode openvasd \
  --product enterprise-container \
  --cn-openvasd sensor.example.com \
  --oci-client-cert oci.crt \
  --oci-client-key oci.key \
  --feed-key key \
  --openvasd-server-cert server.crt \
  --openvasd-server-key server.key \
  --openvasd-client-ca ca.crt
```

Download and run the OpenVASD deployment, optionally exposing a different host port:

```bash
openvas-deployment --update
openvas-deployment --run \
  --openvasd-port 1337
```

### Create an OpenVASD deployment archive

Run the archive creation commands from the directory of an initialized enterprise-container scan deployment.

Create scanner certificates:

```bash
openvas-deployment --create-openvasd-certs \
  --cn-openvasd sensor.example.com
```

Create an archive using the already downloaded deployment artifacts:

```bash
openvas-deployment --create-openvasd-tar \
  --cn-openvasd sensor.example.com
```

Create an archive containing the deployment and locally available Docker images:

```bash
openvas-deployment --create-openvasd-tar \
  --cn-openvasd sensor.example.com \
  --openvasd-tar-with-images
```

The archive is written as `sensor-example-com.tar.gz`. On the target host:

```bash
mkdir sensor-example-com
cd sensor-example-com
tar xzf ../sensor-example-com.tar.gz
```

If the target Docker daemon still needs the registry client certificate contained in the archive, install it with:

```bash
./openvas-deployment --init-openvasd-tar \
  --init-docker-oci
```

Use `--skip-docker-oci` instead of `--init-docker-oci` to print the required root commands.

Run an extracted archive. Because the product artifacts are already included, `--update` is not required before the first run:

```bash
./openvas-deployment --run
```

Run an extracted archive and load packaged images first:

```bash
./openvas-deployment --run \
  --openvasd-load-images-from-tar
```

Run an extracted archive with a different exposed host port:

```bash
./openvas-deployment --run \
  --openvasd-load-images-from-tar \
  --openvasd-port 2337
```

### Manage OpenVASD scanner registrations

The enterprise-container scan deployment must be running. `--add-openvasd` checks `https://HOST:PORT/health/ready` with the configured client certificate and CA and only registers the scanner when the endpoint returns HTTP 200.

Register a scanner:

```bash
openvas-deployment --add-openvasd \
  --cn-openvasd sensor.example.com \
  --openvasd-port 443
```

List registered scanners and obtain their UUIDs:

```bash
openvas-deployment --get-openvasds
```

Remove a scanner:

```bash
openvas-deployment --del-openvasd \
  --openvasd-uuid UUID
```

## Security considerations

* Protect the complete `./product` directory because it contains deployment settings, private keys, OCI credentials, feed keys, and generated secrets.
* Restrict private-key and license files to the deployment administrator.
* Treat deployment archives containing Docker images, certificates, credentials, or configuration as sensitive.
* Review commands printed by `--skip-docker-oci` before running them with elevated privileges.
* Use `--down-volumes` only when persistent deployment data is no longer required.

## Troubleshooting

Display all supported options and current defaults:

```bash
openvas-deployment --help
```

Verify that Docker and Docker Compose are available and that the Docker daemon is reachable:

```bash
docker version
docker compose version
docker ps
```

If a command reports that no product or settings were found under `./product`, run it from the same directory used for `--init`. If no product version is available locally, run:

```bash
openvas-deployment --update
```

Show the deployment status:

```bash
openvas-deployment --ps
```

Inspect deployment logs:

```bash
openvas-deployment --logs
```

Inspect a specific service when its compose service name is known:

```bash
openvas-deployment --logs \
  --service-name SERVICE
```

Inspect the underlying running containers:

```bash
docker ps
```

`feed-mode=mount` and `ccert-mode=mount` are currently not supported and fail during initialization.

For deployment-specific failures, preserve the command output and relevant container logs before restarting the deployment or removing volumes.

## Support

Greenbone support:

https://www.greenbone.net/support/
