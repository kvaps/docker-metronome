FROM centos:centos6
MAINTAINER kvaps <kvapss@gmail.com>

RUN mv /etc/localtime /etc/localtime.old; ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
RUN localedef -v -c -i en_US -f UTF-8 en_US.UTF-8; $(exit 0)
#RUN localedef -v -c -i ru_RU -f UTF-8 ru_RU.UTF-8; $(exit 0)
ENV LANG en_US.UTF-8

RUN yum -y update
RUN yum -y install epel-release 

# Install prosody
RUN yum -y install mysql-server

# Install additional soft
RUN yum -y install supervisor fail2ban dhclient lua-ldap mercurial

# MySQL LDAP IMAP
VOLUME ["/data"]

# Add config and setup script, run it
ADD wrappers/* /bin/
ADD prosody.cfg.lua /etc/prosody/prosody.cfg.lua
ADD kolabgr.lua /etc/prosody/kolabgr.lua
ADD groups.txt /etc/prosody/groups.txt
ADD settings.ini /etc/settings.ini
ADD setup.sh /bin/setup.sh
ENTRYPOINT ["/bin/setup.sh", "run"]
 
# Ports: c2s s2s bosh
#EXPOSE  5222, 5269, 5280

RUN yum -y install gcc lua-devel openssl-devel libidn-devel
RUN hg clone http://hg.prosody.im/0.10 /usr/src/prosody
RUN hg clone http://hg.prosody.im/prosody-modules/ /usr/src/prosody-modules

WORKDIR /usr/src/prosody

RUN ./configure --prefix=
RUN make
RUN make install

RUN useradd -r -s /sbin/nologin -d /var/lib/prosody prosody
RUN chown prosody:prosody /var/lib/prosody/
RUN mkdir /var/log/prosody
RUN chown prosody:prosody /var/log/prosody/

# lua-zlib

RUN yum -y install tar
RUN curl https://codeload.github.com/brimworks/lua-zlib/tar.gz/v0.4 | tar xzv -C /usr/src/
WORKDIR /usr/src/lua-zlib-0.4/
ENV LUACPATH="/usr/lib64/lua/5.1"
ENV LIBDIR="-L/usr/lib64"
RUN make linux
RUN make install

WORKDIR /root

RUN yum -y install lua-expat lua-socket lua-filesystem lua-sec



#RUN yum -y install git

#RUN git clone https://github.com/bjc/prosody 

