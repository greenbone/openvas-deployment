# openvas-deployment

Deployment utility for the Greenbone OpenVAS Enterprise Container and OpenVAS Security Intelligence.

This script is intended for demonstration purposes until the standard deployment tooling supports this product.
The utility initializes, updates, starts, stops, and manages an enterprise-container or security-intelligence deployment. It also supports feed synchronization, TLS certificate management, administrator password changes, deployment logs and status, and OpenVASD scanner registration.

> [!IMPORTANT]
> - OSI release >= 1.5.5 requires openvas-deployment version >= 0.0.8-alpha.3.
> - Requires Docker Compose version 5.3.1 or higher.
> - Requires Bash version 5.1 or higher.
> - OSI requires an accurate system clock. Verify the current system time with `date` and ensure that NTP synchronization is enabled, for example with `systemd-timesyncd`.
> - Starting with `openvas-deployment` version 0.0.8:
>   - On `--init` with product enterprise-container `--domain-name DOMAIN` and `--domain-ip IP` must be set. These options are not required for versions earlier than 0.0.8.
>   - Support for OpenVAS Enterprise Container Agent component.

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
  --license-file license.toml \
  --feed-key /path/to/prod-feed.key \
  --domain-name oec.example.com \
  --domain-ip IP
```

Or initialize a security-intelligence deployment:

```bash
openvas-deployment --init \
  --product security-intelligence \
  --license-file license.toml \
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

`--run` uses the latest locally downloaded product version by default. Run `--update` before the first deployment and whenever a newer product version should be downloaded.

Use `--version VERSION` to select a specific artifact version for the current invocation:

```sh
openvas-deployment --update --version 1.2.3
openvas-deployment --run --version 1.2.3
openvas-deployment --logs --version 1.2.3
openvas-deployment --ps --version 1.2.3
openvas-deployment --down --version 1.2.3
```

With `--update`, this downloads the exact registry tag. Commands using local artifacts (including `--down-volumes`, container recreation, certificate redeployment, and `--create-openvasd-tar`) use the selected local version and fail if its `compose.yaml` is missing. Download it with `--update --version VERSION` first. An OpenVASD archive created with `--version` includes only that artifact version. The selection is not persisted; repeat `--version` on subsequent commands. Without it, downloads select the latest registry release and local commands select the latest downloaded version.

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
| `--change-setting NAME VALUE` | Replace an existing saved setting for either product. Values must satisfy initialization constraints: supported product/mode values, a feed-sync hour from 0–23, valid domain names and IPv4/IPv6 addresses, and non-empty values. Run `--run` afterward to apply the change. |
| `--list-settings` | List saved settings for the selected product as `NAME=VALUE` pairs. |
| `--change-feed-sync-hour` | Change the daily scheduled feed synchronization hour and immediately restart feed synchronization. Requires `--feed-sync-hour`. Only enterprise-container. |
| `--force-feed-sync`       | Restart feed synchronization immediately. Only enterprise-container.                       |
| `--update`                | Download and extract `--version VERSION` or the latest product version from the configured OCI registry. If the selected version is already present locally, no download is performed. |
| `--run`                   | Start or redeploy the configured deployment using `--version VERSION` or the latest locally downloaded product version. |
| `--logs`                  | Show deployment logs. Optionally restrict the output to one service with `--service-name`. |
| `--ps`                    | Show the deployment status, including stopped containers.                                  |
| `--down`                  | Stop the deployment.                                                                       |
| `--down-volumes`          | Stop the deployment and remove its Docker volumes and orphaned containers.                 |
| `--update-ingress-certs`  | Replace the ingress TLS certificate and private key. Requires both ingress certificate options. |
| `--update-ingress-agent-control-certs`  | Replace the ingress Agent Control TLS certificate and private key. Requires both ingress certificate options. It is strongly advised not to use your own keys! Only enterprise-container. |
| `--create-openvasd-certs` | Create TLS certificates for an OpenVASD scanner using the enterprise-container scan CA. Requires `--cn-openvasd`. Only enterprise-container. |
| `--create-openvasd-tar`   | Create a portable OpenVASD deployment archive in the current directory. Requires `--cn-openvasd`. Only enterprise-container. |
| `--get-openvasds`         | List OpenVASD scanners registered in `gvmd`. Requires the enterprise-container scan `gvmd` container to be running. Only enterprise-container. |
| `--add-openvasd`          | Register an OpenVASD scanner in `gvmd`. Requires `--cn-openvasd`, `--openvasd-port`, and a reachable ready scanner. Only enterprise-container. |
| `--del-openvasd`          | Remove an OpenVASD scanner from `gvmd`. Requires `--openvasd-uuid`. Only enterprise-container. |
| `-h`, `--help`            | Display the command-line help.                                                             |

### Change a saved setting

Run `openvas-deployment --list-settings` to display the selected product's saved
setting names and current values in filename order. This works for both products;
an empty settings directory produces no output, and a missing directory reports
an error requesting initialization.

Use the uppercase file name from `./product/settings/<product>/` as `NAME`.
The setting must already exist. `VALUE` must be non-empty and is stored literally,
without setting-specific validation; quote values containing spaces or shell characters.

```bash
openvas-deployment --change-setting GREENBONE_FEED_SYNC_JOB_HOUR 4
openvas-deployment --run
```

This updates the saved setting with file permissions `0600`. For changing the
feed synchronization hour and restarting synchronization immediately, use
`--change-feed-sync-hour --feed-sync-hour 4` instead.

## Deployment options

| Option                   | Description                                                                  |
| ------------------------ | ---------------------------------------------------------------------------- |
| `--product PRODUCT`       | Product to deploy: `enterprise-container` or `security-intelligence`. Required for `--init`; stored in `./product/PRODUCT` for later commands. |
| `--domain-name NAME`      | DNS host name for the deployment: ASCII letters, digits, and interior hyphens; labels up to 63 characters and a total length up to 253 characters (excluding an optional trailing dot). |
| `--domain-ip IP`          | IPv4 or IPv6 address for the deployment. IPv4 uses four decimal octets (0–255, without leading zeroes); IPv6 supports compressed notation and embedded IPv4, without brackets, a zone ID, or a subnet prefix. |

Domain validation applies both during `--init` and when updating `DOMAIN_NAME` or
`DOMAIN_IP` with `--change-setting`.
| `--metafeed-cert FILE`    | Optional metafeed client certificate for security-intelligence. If omitted or missing, initialization continues with a warning. |
| `--metafeed-key FILE`     | Optional metafeed client private key for security-intelligence. If omitted or missing, initialization continues with a warning. |
| `--deployment-mode MODE` | Enterprise-container deployment mode: `scan` or `openvasd`. Default: `scan`. |
| `--openvasd-client-ca FILE` | OpenVASD client CA certificate required for `--init --deployment-mode openvasd`. Only enterprise-container. |
| `--openvasd-server-cert FILE` | OpenVASD server certificate required for `--init --deployment-mode openvasd`. Only enterprise-container. |
| `--openvasd-server-key FILE` | OpenVASD server private key required for `--init --deployment-mode openvasd`. Only enterprise-container. |
| `--feed-mode MODE`       | Feed mode: `volume` or `service`. Default: `volume`. Only enterprise-container. |
| `--feed-key FILE`        | Feed key file. Required for enterprise-container initialization. Base64-encoded keys are decoded before storage; other files are copied as-is. |
| `--feed-path PATH`       | Host feed directory for feed mode `mount`. The `mount` mode is currently not supported. Only enterprise-container. |
| `--feed-sync-hour HOUR`  | Daily scheduled feed synchronization hour from `0` to `23`. Default: `3`. Only enterprise-container. |
| `--ccert-mode MODE`      | Client certificate mode: `ca` or `cert`. Default: `ca`. Only enterprise-container. |
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
| `--admin-password PASSWORD` | Administrator password used during enterprise-container scan initialization or with `--change-admin-password`. If omitted during initialization, a random 32-character alphanumeric password is generated and printed. |

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
| `--ingress-agent-control-cert FILE` | Agent-control server certificate for `--init`. Supply together with `--ingress-agent-control-key`; otherwise a separate self-signed pair is generated if none exists. |
| `--ingress-agent-control-key FILE` | Agent-control server private key for `--init`. Supply together with `--ingress-agent-control-cert`. An EC private key is required for the Ingress Agent Control Service. The key must be a 256-bit key in SEC1 format, use the prime256v1 (NIST P-256) curve, and begin with -----BEGIN EC PRIVATE KEY-----. |
| `--update-ingress-cert-redeploy` | With `--update-ingress-certs`, redeploy the container immediately after replacing the certificates. |
| `--skip-update-ingress-cert-redeploy` | With `--update-ingress-certs`, replace the certificates without redeploying the container. |

If custom ingress certificates are not supplied during initialization, the utility generates a self-signed EC certificate and key valid for 365 days.

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

### Initialize using a certs

```bash
openvas-deployment --init \
  --product enterprise-container \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --feed-key /path/to/prod-feed.key \
  --domain-name oec.example.com \
  --domain-ip IP
```

For non-interactive initialization, explicitly select how Docker OCI credentials should be handled:

```bash
openvas-deployment --init \
  --product enterprise-container \
  --oci-client-cert /path/to/product.crt \
  --oci-client-key /path/to/product.key \
  --feed-key /path/to/prod-feed.key \
  --init-docker-oci \
  --domain-name oec.example.com \
  --domain-ip IP
```

Use `--skip-docker-oci` instead to print the root commands without executing them.

### Initialize with separate OCI credentials

```bash
openvas-deployment --init \
  --product enterprise-container \
  --license-file license.toml \
  --feed-key /path/to/prod-feed.key \
  --domain-name oec.example.com \
  --domain-ip IP
```

### Initialize with a predefined administrator password

```bash
openvas-deployment --init \
  --product enterprise-container \
  --admin-password 'secure-password' \
  --license-file license.toml \
  --domain-name oec.example.com \
  --domain-ip IP
```

If `--admin-password` is omitted, initialization generates and prints a random password.

### Initialize security-intelligence with metafeed certificates

```bash
openvas-deployment --init \
  --product security-intelligence \
  --domain-name osi.example.com \
  --license-file license.toml \
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
  --license-file license.toml \
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
  --license-file license.toml \
  --feed-key /path/to/prod-feed.key \
  --ingress-server-cert /path/to/ingress.crt \
  --ingress-server-key /path/to/ingress.key
```

Both files must be supplied together. If either is missing, initialization creates a self-signed ingress certificate pair instead.

### Replace ingress certificates

Replace the files and choose interactively whether to redeploy the container:

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
  --license-file license.toml \
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
