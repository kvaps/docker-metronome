#!/bin/bash

generate_dn()
{
    echo $(hostname -d) | sed 's/^/dc=/g' | sed 's/[\.]/,dc=/g'
}

chk_var () {
   var=$(sh -c "echo $(echo \$$1)")
   [ -z "$var" ] && export "$1"="$2"
}

load_defaults()
{
    chk_var  TZ                    "utc"
    chk_var  FAIL2BAN              true
    chk_var  KOLAB_AUTH            true
    chk_var  KOLAB_GROUPS          true
    chk_var  KOLAB_VCARD           true
    chk_var  KOLAB_DN              `generate_dn`
    chk_var  KOLAB_BIND_USER       'uid=kolab-service,ou=Special Users,dc=example,dc=org'
    chk_var  KOLAB_BIND_PASS       "password"
    chk_var  KOLAB_GROUPS_MODE     "public"
    chk_var  KOLAB_GROUPS_TIMEOUT  "15m"
}

set_timezone()
{
    if [ -f /usr/share/zoneinfo/$TZ ]; then 
        rm -f /etc/localtime && ln -s /usr/share/zoneinfo/$TZ /etc/localtime
    fi
}

dir=(
    /etc/fail2ban
    /etc/my.cnf
    /etc/metronome
    /etc/supervisord.conf
    /var/lib/metronome
    /var/log/metronome
    /etc/ssl
    /etc/pki
    /var/log/messages
    /var/log/supervisor
)

move_dirs()
{
    echo "info:  start moving lib and log folders to /data volume"

    for i in "${dir[@]}"; do mkdir -p /data$(dirname $i) ; done
    for i in "${dir[@]}"; do mv $i /data$i; done

    echo "info:  finished moving lib and log folders to /data volume"
}

link_dirs()
{
    echo "info:  start linking default lib and log folders to /data volume"

    for i in "${dir[@]}"; do rm -rf $i && ln -s /data$i $i ; done
 
    echo "info:  finished linking default lib and log folders to /data volume"
}

configure_metronome()
{
    echo "info:  start configuring Metronome"

    sed -r -i \
        -e "s/example\.org/$(hostname -d)/g" \
        /etc/metronome/metronome.cfg.lua \
        /etc/metronome/ldap.cfg.lua
    
    echo "info:  finished configuring Metronome"
}

configure_kolab()
{
    if   [ ! -z "$KOLAB_HOST" ] ; then
        echo "info:  start configuring Kolab integration"

        sed -r -i \
            -e "/bind_dn /c\        bind_dn = \'$KOLAB_BIND_USER\'," \
            -e "/bind_password /c\        bind_password = \'$KOLAB_BIND_PASS\'," \
            -e "/ hostname *=/c\       hostname       = \'$KOLAB_HOST\'," \
            /etc/metronome/metronome.cfg.lua \
            /etc/metronome/ldap.cfg.lua

        sed -r -i \
            -e "s/dc=[^\']*/$KOLAB_DN/g" \
            /etc/metronome/metronome.cfg.lua \
            /etc/metronome/ldap.cfg.lua
    fi
    [ "KOLAB_AUTH" = false ] && export KOLAB_AUTH=false
    [ "KOLAB_VCARD" = false ] && export KOLAB_VCARD=false
    [ "KOLAB_GROUPS" = true ] && export KOLAB_GROUPS=false

    if   [ "$KOLAB_AUTH" = true  ] ; then
        sed -i -e '/^--.*authentication.*ldap2/s/^--//' /etc/metronome/metronome.cfg.lua
    elif [ "$KOLAB_AUTH" = false  ] ; then
        sed -i -e '/^[^--]*authentication.*ldap2/s/^/--/' /etc/metronome/metronome.cfg.lua
    fi

    if   [ "$KOLAB_VCARD" = true ] ; then
        sed -i -e '/^--.*storage.*vcard = "ldap"/s/^--//' /etc/metronome/metronome.cfg.lua
    elif [ "$KOLAB_VCARD" = false ] ; then
        sed -i -e '/^[^--]*storage.*vcard = "ldap"/s/^/--/' /etc/metronome/metronome.cfg.lua
    fi

    if   [ "$KOLAB_GROUPS" = true ] ; then

        # Uncomment kolabgr
        sed -i --follow-symlinks '/^;.*kolabgr/s/^;//' /etc/supervisord.conf
        if   [ "$KOLAB_GROUPS_MODE" = "public" ] ; then
            sed -i -e '/show_all_groups = /c\        show_all_groups = true,' \
            /etc/metronome/metronome.cfg.lua \
            /etc/metronome/ldap.cfg.lua
        elif [ "$KOLAB_GROUPS_MODE" = "private" ] ; then
            sed -i -e '/show_all_groups = /c\        show_all_groups = false,' \
            /etc/metronome/metronome.cfg.lua \
            /etc/metronome/ldap.cfg.lua
        fi
        if   [ ! -z "$KOLAB_GROUPS_IGNORE" ] ; then
            print_groups_ignore() {
                for i in ${KOLAB_GROUPS_IGNORE//,/ }; do echo -n "'$i', "; done | sed 's/,[^,]*$//'
            }
           sed -i -e "/not_show_groups = /c\        not_show_groups = { `print_groups_ignore` }," \
            /etc/metronome/metronome.cfg.lua \
            /etc/metronome/ldap.cfg.lua
        else
            sed -i -e "/not_show_groups = /c\        not_show_groups = nil," \
            /etc/metronome/metronome.cfg.lua \
            /etc/metronome/ldap.cfg.lua
        fi

    elif [ "$KOLAB_GROUPS" = false ] ; then
        # Comment kolabgr
        sed -i --follow-symlinks '/^[^;]*kolabgr/s/^/;/' /etc/supervisord.conf
    fi

    echo "info:  finished configuring Kolab integration"

}

configure_ssl()
{
    if [ ! -f /etc/pki/tls/certs/$(hostname -f).crt ] ; then
        echo "info:  start configuring SSL"

        # Generate key and certificate
        openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
                    -subj "/CN=$(hostname -f)" \
                    -keyout /etc/pki/tls/private/$(hostname -f).key \
                    -out /etc/pki/tls/certs/$(hostname -f).crt
    
        touch /etc/pki/tls/certs/$(hostname -f)-ca.pem
    
        # Create certificate bundles
        cat /etc/pki/tls/certs/$(hostname -f).crt /etc/pki/tls/private/$(hostname -f).key /etc/pki/tls/certs/$(hostname -f)-ca.pem > /etc/pki/tls/private/$(hostname -f).bundle.pem
        cat /etc/pki/tls/certs/$(hostname -f).crt /etc/pki/tls/certs/$(hostname -f)-ca.pem > /etc/pki/tls/certs/$(hostname -f).bundle.pem
        cat /etc/pki/tls/certs/$(hostname -f)-ca.pem > /etc/pki/tls/certs/$(hostname -f).ca-chain.pem
        # Set access rights
        chown -R root:metronome /etc/pki/tls/private
        chmod 600 /etc/pki/tls/private/$(hostname -f).key
        chmod 750 /etc/pki/tls/private
        chmod 640 /etc/pki/tls/private/*
        # Add CA to system’s CA bundle
        cat /etc/pki/tls/certs/$(hostname -f)-ca.pem >> /etc/pki/tls/certs/ca-bundle.crt

        # Configuration metronome for SSL
        sed -r -i \
            -e '/certificate =/c\    certificate = "/etc/pki/tls/certs/'$(hostname -f)'.bundle.pem";' \
            -e '/key =/c\    key = "/etc/pki/tls/private/'$(hostname -f)'.key";' \
            /etc/metronome/metronome.cfg.lua

        echo "info:  finished configuring SSL"
    else
        echo "warn:  SSL already configured, skipping..."
    fi
}

configure_fail2ban()
{
    if   [ "$FAIL2BAN" = true  ] ; then

        echo "info:  start configuring Fail2ban"
        # Uncoment fail2ban
        sed -i --follow-symlinks '/^;.*fail2ban/s/^;//' /etc/supervisord.conf

    elif [ "$FAIL2BAN" = false  ] ; then

        echo "info:  disabling Fail2Ban"
        # Coment fail2ban
        sed -i --follow-symlinks '/^[^;]*fail2ban/s/^/;/' /etc/supervisord.conf
    fi
    
    echo "info:  finished configuring Fail2ban"
}

start_services()
{
             echo "info:  Starting services"
                      /usr/bin/supervisord
} 

[ ! -f /data/etc/metronome/metronome.cfg.lua ] && export FIRST_SETUP=true #Check for first setup


                                load_defaults
                                set_timezone
[ "$FIRST_SETUP" = true  ]   && move_dirs
                                link_dirs

if [ "$FIRST_SETUP" = true ] ; then
                                configure_metronome
                                configure_ssl
fi
                                configure_fail2ban
                                configure_kolab
                                start_services
