# =============================================================================
# show_help()
# =============================================================================
# Prints help text. 
show_help() {
    less << EOF
OpenVAS Deployment

Support for enterprise-container and security-intelligence

Requires compose version 5.3.1 and higher!

Info:
  You can move up and down with arrow keys. Press q to quit.


Usage:
  $0 ACTION [OPTIONS]
  $0 -h | --help


Actions:
  --init                         Initialize deployment, certificates, and
                                 deployment settings

  --init-openvasd-tar            Initialize OCI client certificates from an
                                 OpenVASD deployment archive created with
                                 --create-openvasd-tar

  --change-admin-password        Change the gvmd administrator password
                                 Only enterprise-container

  --change-feed-sync-hour        Set the daily hour for scheduled feed
                                 synchronization (0-23)
                                 Only enterprise-container

  --force-feed-sync              Restart feed synchronization immediately
                                 Only enterprise-container

  --update                       Download and install the latest product version

  --run                          Start or redeploy the configured deployment

  --logs                         Show deployment logs
                                 Optional: --service-name

  --ps                           Show deployment status

  --down                         Stop the deployment

  --down-volumes                 Stop the deployment and remove volumes

  --update-ingress-certs         Replace ingress TLS certificate and key

  --create-openvasd-certs        Create TLS certificates for an OpenVASD scanner
                                 Only enterprise-container

  --create-openvasd-cert-tar     Create an OpenVASD certificate archive
                                 Only enterprise-container

  --create-openvasd-tar          Create an OpenVASD deployment archive
                                 Only enterprise-container

  --get-openvasds                List OpenVASD scanners registered in gvmd
                                 Only enterprise-container

  --add-openvasd                 Register an OpenVASD scanner in gvmd
                                 Only enterprise-container

  --del-openvasd                 Remove an OpenVASD scanner from gvmd
                                 Only enterprise-container


Deployment options:
  --product PRODUCT              Product to deploy:
                                   enterprise-container | security-intelligence

  --domain-name NAME             Domain name for the deployment
                                 Only security-intelligence

  --metafeed-cert FILE           Metafeed client certificate
                                 Only security-intelligence

  --metafeed-key FILE            Metafeed client private key
                                 Only security-intelligence

  --deployment-mode MODE         Deployment mode:
                                   scan | openvasd
                                 Default: ${DEPLOYMENT_MODE}
                                 Only enterprise-container

  --openvasd-client-ca FILE      OpenVASD client CA certificate used for
                                 --init --deployment-mode openvasd
                                 Only enterprise-container

  --openvasd-server-cert FILE    OpenVASD server certificate used for
                                 --init --deployment-mode openvasd
                                 Only enterprise-container

  --openvasd-server-key FILE     OpenVASD server private key used for
                                 --init --deployment-mode openvasd
                                 Only enterprise-container

  --feed-mode MODE               Feed mode:
                                   volume | service | mount
                                 Default: ${FEED_MODE}
                                 Only enterprise-container

  --feed-key FILE                Feed key file used with volume or service mode
                                 Only enterprise-container

  --feed-path PATH               Host feed directory used with mount mode
                                 Only enterprise-container

  --feed-sync-hour HOUR          Scheduled feed synchronization hour (0-23)
                                 Default: ${GREENBONE_FEED_SYNC_JOB_HOUR}
                                 Only enterprise-container

  --feed-sync-force-no-log       Force feed synchronization without logging
                                 Only enterprise-container

  --ccert-mode MODE              Client certificate mode:
                                   ca | cert | mount
                                 Default: ${CCERT_MODE}
                                 Only enterprise-container

  --ccert-path PATH              Host client certificate directory used with
                                 mount mode
                                 Only enterprise-container

  --skip-init-if-exist           Exit with status 0 if already initialized


Administrator options:
  --admin-password PASSWORD      Administrator password used during
                                 initialization or password changes
                                 Only enterprise-container


OCI client certificate options:
  --license-file FILE            License file containing OCI registry
                                 client certificate and key

  --oci-client-cert FILE         OCI registry client certificate

  --oci-client-key FILE          OCI registry client private key

  --init-docker-oci              Install OCI credentials into dockerd using sudo

  --skip-docker-oci              Do not install OCI credentials automatically,
                                 print required commands instead


Ingress certificate options:
  --ingress-server-cert FILE     Ingress server certificate

  --ingress-server-key FILE      Ingress server private key

  --update-ingress-cert-redeploy
                                 Redeploy after updating ingress certificates

  --skip--update-ingress-cert-redeploy
                                 Do not redeploy after updating ingress
                                 certificates


OpenVASD options:
  --cn-openvasd NAME             OpenVASD common name and scanner hostname

  --openvasd-port PORT           OpenVASD scanner port
                                 Default port: 443

  --openvasd-uuid UUID           Scanner UUID returned by --get-openvasds

  --openvasd-tar-with-images     Include Docker images in OpenVASD archive
                                 Default: disabled

  --openvasd-load-images-from-tar
                                 Load packaged Docker images before deployment
                                 Default: disabled


Development options:
  --dev                          Use development stage URL prefix:
                                 -dev/dev

  --integration                  Use development stage URL prefix:
                                 -dev/integration

  --testing                      Use development stage URL prefix:
                                 -dev/testing

  --staging                      Use development stage URL prefix:
                                 -dev/staging


Help:
  -h, --help                     Show this help message


Examples:

Initialize a security-intelligence deployment using a Docker volume for feeds:
  $0 --init \\
    --product security-intelligence \\
    --oci-client-cert /path/to/product.crt \\
    --oci-client-key /path/to/product.key \\
    --domain-name osi.example.com

Initialize a enterprise-container scan deployment using a Docker volume for feeds:
  $0 --init \\
    --product enterprise-container \\
    --oci-client-cert /path/to/product.crt \\
    --oci-client-key /path/to/product.key \\
    --feed-key /path/to/prod-feed.key


Initialize a enterprise-container scan deployment with a predefined administrator password:
  $0 --init \\
    --product enterprise-container \\
    --admin-password 'secure-password' \\
    --oci-client-cert /path/to/product.crt \\
    --oci-client-key /path/to/product.key \\
    --feed-key /path/to/prod-feed.key


Initialize a enterprise-container deployment with scheduled feed synchronization:
  $0 --init \\
    --product enterprise-container \\
    --feed-sync-hour 3 \\
    --oci-client-cert /path/to/product.crt \\
    --oci-client-key /path/to/product.key \\
    --feed-key /path/to/prod-feed.key


Initialize a enterprise-container with custom ingress certificates:
  $0 --init \\
    --product enterprise-container \\
    --oci-client-cert /path/to/product.crt \\
    --oci-client-key /path/to/product.key \\
    --feed-key /path/to/prod-feed.key \\
    --ingress-server-cert /path/to/ingress.crt \\
    --ingress-server-key /path/to/ingress.key


Update and start the deployment:
  $0 --update
  $0 --run


Change the gvmd administrator password:
  $0 --change-admin-password --admin-password 'new-secure-password'


Change the scheduled feed synchronization hour:
  $0 --change-feed-sync-hour --feed-sync-hour 4


Restart feed synchronization immediately:
  $0 --force-feed-sync


Show logs and status:
  $0 --logs
  $0 --ps


Stop the deployment:
  $0 --down


Restart the deployment:
  $0 --run


Stop deployment and remove Docker volumes:
  $0 --down-volumes


Update ingress certificates:
  $0 --update-ingress-certs \\
     --ingress-server-cert ./ingress.crt \\
     --ingress-server-key ./ingress.key


External OpenVASD sensor setup:

Option 1:

Create OpenVASD certificates:
  $0 --create-openvasd-certs --cn-openvasd sensor.example.com
  $0 --create-openvasd-cert-tar --cn-openvasd sensor.example.com

Copy the following files to the new host:
  - $0
  - ./sensor-example-com.tar
  - your feed key
  - your oci client certs


Initialize the remote OpenVASD deployment:
  $0 --init --deployment-mode openvasd \\
    --cn-openvasd sensor.example.com \\
    --oci-client-cert oci.crt \\
    --oci-client-key oci.key \\
    --feed-key key \\
    --openvasd-server-cert server.crt \\
    --openvasd-server-key server.key \\
    --openvasd-client-ca ca.crt


Update and start the OpenVASD deployment:
  $0 --update
  $0 --run

Register an OpenVASD scanner:
  $0 --add-openvasd --cn-openvasd sensor.example.com --openvasd-port 443

Option 2:

Create OpenVASD certificates:
  $0 --create-openvasd-certs --cn-openvasd sensor.example.com


Create an OpenVASD deployment archive:
  $0 --create-openvasd-tar \\
     --cn-openvasd sensor.example.com \\
     --openvasd-tar-with-images


Run an extracted OpenVASD archive on your OpenVASD sensor node/host:
  $0 --run --openvasd-load-images-from-tar


Run an extracted OpenVASD archive with a custom host port:
  $0 --run --openvasd-load-images-from-tar --openvasd-port PORT


Register an OpenVASD scanner:
  $0 --add-openvasd --cn-openvasd sensor.example.com --openvasd-port 443


List or remove registered OpenVASD scanners:
  $0 --get-openvasds

  $0 --del-openvasd --openvasd-uuid UUID


For CI workflows:
  Use --skip-init-if-exist with --skip-docker-oci or --init-docker-oci.


Support:
  https://www.greenbone.net/support/
EOF

    exit 0
}
