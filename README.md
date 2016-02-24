Metronome Jabber/XMPP server in a Docker
========================================

This is Metronome Jabber/XMPP server, configured to use with Kolab Groupware in a docker.
Installation is supports automatic configuration **metronome**, **ssl**, and **fail2ban** and communicate with **Kolab** using ldap.

Quick start
-----------

### Run command

```bash
docker run \
    --name metronome \
    -h xmpp.example.org \
    -v /etc/localtime:/etc/localtime:ro \
    -v /lib/modules:/lib/modules:ro \
    -v /opt/metronome:/data:rw \
    -p 5000:5000 \
    -p 5222:5222 \
    -p 5269:5269 \
    -p 5280:5280 \
    -p 5281:5281 \
    -e TZ=Europe/Moscow \
    --cap-add=NET_ADMIN \
    -ti \
    kvaps/metronome
```
It should be noted that the `--cap-add=NET_ADMIN` option is necessary only for **Fail2ban**, if you do not plan to use **Fail2ban**, you can exclude it.

You can also more integrate metronome to your system, simply replace `-v` options like this:
```bash
    -v /etc/metronome:/data/etc:rw \
    -v /var/lib/metronome:/data/var/lib:rw \
    -v /var/log/metronome:/data/var/log:rw \
```

### Kolab integration

To enable Kolab integration, use the following options, for example:

```bash
    --link kolab \
    -e KOLAB_HOST=kolab \
    -e KOLAB_BIND_PASS=<password> \
    -e KOLAB_AUTH=true \
    -e KOLAB_VCARD=true \
    -e KOLAB_GROUPS=true \
```

Docker-compose
--------------
You can use the docker-compose for this image is really simplify your life:

```yaml
metronome:
  image: kvaps/metronome
  restart: always
  hostname: xmpp
  domainname: example.org
  volumes:
    - /etc/localtime:/etc/localtime:ro
    - ./metronome:/data:rw
  links:
    - kolab
  environment:
    - TZ=Europe/Moscow
    - KOLAB_HOST=kolab
    - KOLAB_BIND_PASS=<password>
  cap_add:
    - NET_ADMIN
  ports:
    - 5000:5000
    - 5222:5222
    - 5269:5269
    - 5280:5280
    - 5281:5281
```

Configuration
-------------


### SSL-certificates

```bash

# Go to tls folder of your container
cd /opt/metronome/etc/pki/tls

# Set the variable with your metronome hostname
METRONOME_HOSTNAME='mail.example.org'

# Write your keys
vim private/${METRONOME_HOSTNAME}.key
vim certs/${METRONOME_HOSTNAME}.crt
vim certs/${METRONOME_HOSTNAME}-ca.pem

# Create certificate bundles
cat certs/${METRONOME_HOSTNAME}.crt private/${METRONOME_HOSTNAME}.key certs/${METRONOME_HOSTNAME}-ca.pem > private/${METRONOME_HOSTNAME}.bundle.pem
cat certs/${METRONOME_HOSTNAME}.crt certs/${METRONOME_HOSTNAME}-ca.pem > certs/${METRONOME_HOSTNAME}.bundle.pem
cat certs/${METRONOME_HOSTNAME}-ca.pem > certs/${METRONOME_HOSTNAME}.ca-chain.pem

# Set access rights
chown -R root:metronome private
chmod 750 private
chmod 640 private/*

# Add CA to system’s CA bundle
cat certs/${METRONOME_HOSTNAME}-ca.pem >> certs/ca-bundle.crt
```

### Available Configuration Parameters

*Please refer the docker run command options for the `--env-file` flag where you can specify all required environment variables in a single file. This will save you from writing a potentially long docker run command. Alternatively you can use docker-compose.*

Below is the complete list of available options that can be used to customize your kolab installation.

#### Basic options

  - **TZ**: Sets timezone. Defaults to `utc`.
  - **FAIL2BAN**: Enables Fail2Ban. Defaults to `true`.

#### Kolab Groupware integration

This settings enables Kolab Groupware integration

  - **KOLAB_HOST**: Resolvable name or linked containername of Kolab Groupware server. Deafults to `kolab`.
  - **KOLAB_DN**: Bind DN of your Kolab server. Defaults getting from hostname, like to `dc=example,dc=org`.
  - **KOLAV_BIND_USER**: Bind user path. Defaults to `uid=kolab-service,ou=Special Users,dc=example,dc=org`. *(Domain will be replaced by `KOLAB_DN` parameter)*
  - **KOLAB_BIND_PASS**: Password for bind user. Defaults to `$KOLAB_ENV_LDAP_KOLAB_PASS` if exist, or `password`.
  - **KOLAB_AUTH**: Enables Kolab authentification. Defaults to `true`.
  - **KOLAB_VCARD**: Enables Kolab vcard integration. Defaults to `true`.
  - **KOLAB_GROUPS**: Enables Kolab groups integration. Defaults to `true`.
  - **KOLAB_GROUPS_MODE**: Set all groups as `public` or `private`. Defaults to `public`
  - **KOLAB_GROUPS_TIMEOUT**: Sets how often to run a check for Kolab groups changes. Defaults to `15m`.
  - **KOLAB_GROUPS_IGNORE**: Comma separated groups, which not need be added to the group list.  Example to `All,Everyone`.

Multi-instances
---------------

I use [pipework](https://hub.docker.com/r/dreamcat4/pipework/) image for passthrough external ethernet cards into docker container.

See [examples](https://github.com/dreamcat4/docker-images/blob/master/pipework/3.%20Examples.md), that's realy simple!
