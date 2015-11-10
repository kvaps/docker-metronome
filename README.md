Metronome Jabber/XMPP server in a Docker container
=====================================================

This is Metronome Jabber/XMPP server, configured to use with Kolab Groupware in a docker.
Installation is supports automatic configuration **metronome**, **ssl**, and **fail2ban** and communicate with **Kolab** using ldap.

Run
---

```bash
docker run \
    --name metronome \
    -h xmpp.example.org \
    --link=kolab \
    -v /opt/metronome:/data:rw \
    -p 5000:5000 \
    -p 5222:5222 \
    -p 5269:5269 \
    -p 5280:5280 \
    -p 5281:5281 \
    --env TZ=Europe/Moscow \
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

If it is the first run, you will see the settings page, make your changes and save it, installation will continue...
*(You need to have the base knowledge of the [vi editor](http://google.com/#q=vi+editor))*

Systemd unit
------------


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

  - **KOLAB_HOST**: Resolvable name or linked containername of Kolab Groupware server. Example to `kolab`.
  - **KOLAB_DN**: Bind DN of your Kolab server. Defaults getting from hostname, like to `dc=example,dc=org`.
  - **KOLAV_BIND_USER**: Bind user path. Defaults to `uid=kolab-service,ou=Special Users,dc=example,dc=org`. *(Domain will be replaced by `KOLAB_DN` parameter)*
  - **KOLAB_BIND_PASS**: Password for bind user. Defaults to `password`.
  - **KOLAB_AUTH**: Enables Kolab authentification. Defaults to `true`.
  - **KOLAB_VCARD**: Enables Kolab vcard integration. Defaults to `true`.
  - **KOLAB_GROUPS**: Enables Kolab groups integration. Defaults to `true`.
  - **KOLAB_GROUPS_MODE**: Set all groups as `public` or `private`. Defaults to `public`


Systemd unit
------------

You can create a unit for systemd, which would run it as a service and use when startup

```bash
vi /etc/systemd/system/metronome.service
```

```ini
[Unit]
Description=Metronome Jabber/XMPP Server
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker start -a metronome
ExecStop=/usr/bin/docker stop metronome

[Install]
WantedBy=multi-user.target
```

Now you can activate and start the container:
```bash
systemctl enable metronome
systemctl start metronome
```

Multi-instances
---------------

I use [pipework](https://github.com/jpetazzo/pipework) script for passthrough external ethernet cards into docker container

I write such systemd-unit:
```bash
vi /etc/systemd/system/metronome@.service
```
```ini
[Unit]
Description=Metronome Jabber/XMPP Server for %I
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=/etc/metronome-docker/%i
Restart=always

ExecStart=/bin/bash -c '/usr/bin/docker run --name ${DOCKER_NAME} -h ${DOCKER_HOSTNAME} -v ${DOCKER_VOLUME}:/data:rw ${DOCKER_OPTIONS} kvaps/metronome'
ExecStartPost=/bin/bash -c ' \
        pipework ${EXT_INTERFACE} -i eth1 ${DOCKER_NAME} ${EXT_ADDRESS}@${EXT_GATEWAY}; \
        docker exec ${DOCKER_NAME} bash -c "${INT_ROUTE}"; \
        docker exec ${DOCKER_NAME} bash -c "if ! [ \"${DNS_SERVER}\" = \"\" ] ; then echo nameserver ${DNS_SERVER} > /etc/resolv.conf ; fi" '

ExecStop=/bin/bash -c 'docker stop -t 2 ${DOCKER_NAME} ; docker rm -f ${DOCKER_NAME}'

[Install]
WantedBy=multi-user.target
```

And this config for each instance:
```bash
vi /etc/metronome-docker/example.org
```
```bash
DOCKER_HOSTNAME=xmpp.example.org
DOCKER_NAME="metronome-$(echo $DOCKER_HOSTNAME | cut -d. -f 2-)"
DOCKER_VOLUME="/opt/metronome-$(echo $DOCKER_HOSTNAME | cut -d. -f 2-)"
DOCKER_OPTIONS='--env TZ=Europe/Moscow --cap-add=NET_ADMIN --link kolab-$(echo $DOCKER_HOSTNAME | cut -d. -f 2-) -p 5280:5280 -p 5281:5281'
 
EXT_INTERFACE=eth2
#EXT_ADDRESS='dhclient D2:84:9D:CA:F3:BC'
EXT_ADDRESS='10.10.10.123/24'
EXT_GATEWAY='10.10.10.1'
DNS_SERVER='8.8.8.8'
 
INT_ROUTE='ip route add 192.168.1.0/24 via 172.17.42.1 dev eth0'
```
Just simple use:
```bash
systemctl enable metronome@example.org
systemctl start metronome@example.org
```
