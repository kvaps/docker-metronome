FROM centos:centos6
MAINTAINER kvaps <kvapss@gmail.com>
ENV REFRESHED_AT 2015-09-17

RUN yum -y update
RUN yum -y install epel-release 

# Install additional soft
RUN yum -y install mysql-server supervisor fail2ban dhclient lua-ldap mercurial tar rsyslog dhclient

# Install build-essentials and lua-modules
RUN yum -y install gcc lua-devel openssl-devel libidn-devel lua-expat lua-socket lua-filesystem lua-sec lua-dbi

ENV LUACPATH="/usr/lib64/lua/5.1"
ENV LIBDIR="-L/usr/lib64"

# Install lua-zlib module
RUN curl https://codeload.github.com/brimworks/lua-zlib/tar.gz/v0.4 | tar xzv -C /usr/src/
WORKDIR /usr/src/lua-zlib-0.4/
RUN make linux
RUN make install

# Install lua-bitop module
RUN curl http://bitop.luajit.org/download/LuaBitOp-1.0.2.tar.gz | tar xzv -C /usr/src/
WORKDIR /usr/src/LuaBitOp-1.0.2
RUN make
RUN make install

#Install Prosody 0.10
RUN hg clone http://hg.prosody.im/0.10 /usr/src/prosody
WORKDIR /usr/src/prosody
RUN ./configure --prefix=
RUN make
RUN make install
RUN useradd -r -s /sbin/nologin -d /var/lib/prosody prosody
RUN mkdir /var/log/prosody/
RUN mkdir /var/run/prosody/
RUN chown prosody:prosody /var/lib/prosody/
RUN chown prosody:prosody /var/log/prosody/
RUN chown prosody: /var/run/prosody/

#Install Prosody-modules
RUN hg clone http://hg.prosody.im/prosody-modules/ /usr/src/prosody-modules
RUN ln -s /usr/src/prosody-modules/mod_lib_ldap/ldap.lib.lua /lib/prosody/modules/ldap.lib.lua

# Add config and setup script, run it
ADD wrappers/* /bin/
ADD prosody.cfg.lua /etc/prosody/prosody.cfg.lua
ADD kolabgr.lua /etc/prosody/kolabgr.lua
ADD groups.txt /etc/prosody/groups.txt
ADD settings.ini /etc/settings.ini
ADD setup.sh /bin/setup.sh
ENTRYPOINT ["/bin/setup.sh", "run"]
 
WORKDIR /root


VOLUME ["/data"]

# 5000/tcp: mod_proxy65
# 5222/tcp: client to server
# 5269/tcp: server to server 
# 5280/tcp: BOSH
# 5281/tcp: Secure BOSH
EXPOSE 5000 5222 5269 5280 5281
