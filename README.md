Prosody 0.10 Jabber/XMPP server in a Docker container
=====================================================

This is Prosody 0.10 Jabber/XMPP server, configured to use with Kolab Groupware in a docker.
Installation is supports automatic configuration **prosody**, **ssl**, and **fail2ban** and communicate with **Kolab** using ldap.

Run
---

```bash
docker run \
    --name prosody \
    -h xmpp.example.org \
    --link=kolab \
    -v /opt/prosody:/data:rw \
    -p 5000:5000 \
    -p 5222:5222 \
    -p 5269:5269 \
    -p 5280:5280 \
    -p 5281:5281 \
    --cap-add=NET_ADMIN \
    -ti \
    kvaps/prosody
```
It should be noted that the `--cap-add=NET_ADMIN` option is necessary only for **Fail2ban**, if you do not plan to use **Fail2ban**, you can exclude it.

You can also more integrate prosody to your system, simply replace `-v` options like this:
```bash
    -v /etc/prosody:/data/etc:rw \
    -v /var/lib/prosody:/data/var/lib:rw \
    -v /var/log/prosody:/data/var/log:rw \
```

If it is the first run, you will see the settings page, make your changes and save it, installation will continue...
*(You need to have the base knowledge of the [vi editor](http://google.com/#q=vi+editor))*

Systemd unit
------------

You can create a unit for systemd, which would run it as a service and use when startup

```bash
vi /etc/systemd/system/prosody.service
```

```ini
[Unit]
Description=Prosody Jabber/XMPP Server
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker start -a prosody
ExecStop=/usr/bin/docker stop prosody

[Install]
WantedBy=multi-user.target
```

Now you can activate and start the container:
```bash
systemctl enable prosody
systemctl start prosody
```

Multi-instances
---------------

I use [pipework](https://github.com/jpetazzo/pipework) script for passthrough external ethernet cards into docker container

I write such systemd-unit:
```bash
vi /etc/systemd/system/prosody@.service
```
```ini
[Unit]
Description=Prosody Jabber/XMPP Server for %I
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=/etc/prosody-docker/%i
Restart=always

ExecStartPre=/bin/bash -c 'docker rm -f ${DOCKER_NAME}'
ExecStart=/bin/bash -c '/usr/bin/docker run --name ${DOCKER_NAME} -h ${DOCKER_HOSTNAME} -v ${DOCKER_VOLUME}:/data:rw ${DOCKER_OPTIONS} kvaps/prosody'
ExecStartPost=/bin/bash -c ' \
        pipework ${EXT_INTERFACE} -i eth1 ${DOCKER_NAME} ${EXT_ADDRESS}@${EXT_GATEWAY}; \
        docker exec ${DOCKER_NAME} bash -c "${INT_ROUTE}"; \
        docker exec ${DOCKER_NAME} bash -c "if ! [ \"${DNS_SERVER}\" = \"\" ] ; then echo nameserver ${DNS_SERVER} > /etc/resolv.conf ; fi" '

ExecStop=/bin/bash -c 'docker stop -t 2 ${DOCKER_NAME}'

[Install]
WantedBy=multi-user.target
```

And this config for each instance:
```bash
vi /etc/prosody-docker/example.org
```
```bash
DOCKER_HOSTNAME=xmpp.example.org
DOCKER_NAME="prosody-$(echo $DOCKER_HOSTNAME | cut -d. -f 2-)"
DOCKER_VOLUME="/opt/prosody-$(echo $DOCKER_HOSTNAME | cut -d. -f 2-)"
DOCKER_OPTIONS='--cap-add=NET_ADMIN --link kolab-$(echo $DOCKER_HOSTNAME | cut -d. -f 2-) -p 5280:5280 -p 5281:5281'
 
EXT_INTERFACE=eth2
#EXT_ADDRESS='dhclient D2:84:9D:CA:F3:BC'
EXT_ADDRESS='10.10.10.123/24'
EXT_GATEWAY='10.10.10.1'
DNS_SERVER='8.8.8.8'
 
INT_ROUTE='ip route add 192.168.1.0/24 via 172.17.42.1 dev eth0'
```
Just simple use:
```bash
systemctl enable prosody@example.org
systemctl start prosody@example.org
```
