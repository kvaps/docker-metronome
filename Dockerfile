FROM centos:centos6
MAINTAINER kvaps <kvapss@gmail.com>

RUN mv /etc/localtime /etc/localtime.old; ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
RUN localedef -v -c -i en_US -f UTF-8 en_US.UTF-8; $(exit 0)
#RUN localedef -v -c -i ru_RU -f UTF-8 ru_RU.UTF-8; $(exit 0)
ENV LANG en_US.UTF-8

RUN yum -y update
RUN yum -y install epel-release 

# Install prosody
RUN yum -y install prosody

# Install additional soft
RUN yum -y install supervisor fail2ban dhclient

# MySQL LDAP IMAP
VOLUME ["/data"]

WORKDIR /root

# Add config and setup script, run it
ADD wrappers/* /bin/
ADD settings.ini /etc/settings.ini
ADD setup.sh /bin/setup.sh
ENTRYPOINT ["/bin/setup.sh", "run"]
 
# Ports: c2s s2s bosh
#EXPOSE  5222, 5269, 5280
