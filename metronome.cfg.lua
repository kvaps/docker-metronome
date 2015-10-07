-- Prosody XMPP Server Configuration
--
-- Information on configuring Prosody can be found on our
-- website at http://metronome.im/doc/configure
--
-- Tip: You can check that the syntax of this file is correct
-- when you have finished by running: metronomectl check config
-- If there are any errors, it will let you know what and where
-- they are, otherwise it will keep quiet.
--
-- Good luck, and happy Jabbering!


---------- Server-wide settings ----------
-- Settings in this section apply to the whole server and are the default settings
-- for any virtual hosts

-- This is a (by default, empty) list of accounts that are admins
-- for the server. Note that you must create the accounts separately
-- (see http://metronome.im/doc/creating_accounts for info)
-- Example: admins = { "user1@example.com", "user2@example.net" }
admins = { }

-- Required for init scripts and metronomectl
pidfile = "/var/run/metronome/metronome.pid"

-- ulimit
metronome_max_files_soft = 200000
metronome_max_files_hard = 200000


-- HTTP server
http_ports = { 5280 }
http_interfaces = { "0.0.0.0", "::" }

https_ports = { 5281 }
https_interfaces = { "0.0.0.0", "::" }

-- Enable IPv6
use_ipv6 = true

-- This is the list of modules Prosody will load on startup.
-- It looks for mod_modulename.lua in the plugins folder, so make sure that exists too.
-- Documentation on modules can be found at: http://metronome.im/doc/modules

modules_enabled = {

    -- Generally required
        --"roster"; -- Allow users to have a roster. Recommended ;)
        "saslauth"; -- Authentication for clients and servers. Recommended if you want to log in.
        "tls"; -- Add support for secure TLS on c2s/s2s connections
        "dialback"; -- s2s dialback support
        "disco"; -- Service discovery
        "extdisco"; -- External Service Discovery


    -- Not essential, but recommended
        --"private"; -- Private XML storage (for room bookmarks, etc.)
        --"vcard"; -- Allow users to set vCards
    
    -- These are commented by default as they have a performance impact
        "compression"; -- Stream compression (requires the lua-zlib package installed)

    -- Nice to have
        "version"; -- Replies to server version requests
        "uptime"; -- Report how long server has been running
        "time"; -- Let others know the time here on this server
        "ping"; -- Replies to XMPP pings with pongs
        --"pep"; -- Enables users to publish their mood, activity, playing music and more
        --"register"; -- Allow users to register on this server using a client and change passwords

    -- Admin interfaces
        "admin_adhoc"; -- Allows administration via an XMPP client that supports ad-hoc commands
        --"admin_telnet"; -- Opens telnet console interface on localhost port 5582
    
    -- HTTP modules
        "bosh"; -- Enable BOSH clients, aka "Jabber over HTTP"
        "websocket"; -- Enable WebSocket clients 
        --"http_files"; -- Serve static files from a directory over HTTP

    -- Other specific functionality
        "posix"; -- POSIX functionality, sends server to background, enables syslog, etc.
        "bidi"; -- Bidirectional Streams for S2S connections
        "stream_management"; -- Stream Management support
        --"groups"; -- Shared roster support
        --"announce"; -- Send announcement to all online users
        --"welcome"; -- Welcome users who register accounts
        --"watchregistrations"; -- Alert admins of registrations
        --"motd"; -- Send a message to users when they log in
        --"legacyauth"; -- Legacy authentication. Only used by some old clients and bots. 
        "log_auth";
}

-- These modules are auto-loaded, but should you want
-- to disable them then uncomment them here:
modules_disabled = {
    -- "offline"; -- Store offline messages
    -- "c2s"; -- Handle client connections
    -- "s2s"; -- Handle server-to-server connections
}

-- Discovery items
disco_items = {
    { "muc.example.org" },
    { "proxy.example.org" },
    { "pubsub.example.org" },
    { "vjud.example.org" }
};

-- External Service Discovery (mod_extdisco)
external_services = {
    ["stun.example.org"] = {
        [1] = {
            port = "3478",
            transport = "udp",
            type = "stun"
        },

        [2] = {
            port = "3478",
            transport = "tcp",
            type = "stun"
        }
    }
};

-- Bidirectional Streams configuration (mod_bidi)
bidi_exclusion_list = { "jabber.org" }

-- BOSH configuration (mod_bosh)
bosh_max_inactivity = 30
consider_bosh_secure = true
cross_domain_bosh = true

-- WebSocket configuration (mod_websockets)
consider_websockets_secure = true
cross_domain_websockets = true

-- Disable account creation by default, for security
allow_registration = false

-- Ignore priority settings
ignore_presence_priority = true

-- These are the SSL/TLS-related settings. If you don't want
-- to use SSL/TLS, you may comment or remove this
ssl = {
	key = "/etc/metronome/certs/localhost.key";
  	certificate = "/etc/metronome/certs/localhost.cert";
        protocol = "sslv23";
        ciphers = "ALL"; 
}

-- Force clients to use encrypted connections? This option will
-- prevent clients from authenticating unless they are using encryption.

c2s_require_encryption = true

-- Force servers to use encrypted connections? This option will
-- prevent servers from connecting unless they are using encryption.

s2s_require_encryption = true

-- Allow servers to use an unauthenticated encryption channel

s2s_allow_encryption = true

-- Don't require encryption for listed servers
s2s_encryption_exceptions = {
    "cisco.com",
    "gmail.com"
}

-- Logging configuration
-- For advanced logging see http://metronome.im/doc/logging
log = {
    info = "/var/log/metronome/metronome.log"; -- Change 'info' to 'debug' for verbose logging
    error = "/var/log/metronome/metronome.err";
    -- "*syslog"; -- Uncomment this for logging to syslog
    -- "*console"; -- Log to the console, useful for debugging with daemonize=false
}

activity_log_dir = "/var/log/metronome/activity_log"

-- Storage configuration
storage = "sql";

-- For the "sql" backend, you can uncomment *one* of the below to configure:
sql = { driver = "SQLite3", database = "metronome.sqlite" } -- Default. 'database' is the filename.
--sql = { driver = "MySQL", database = "metronome", username = "metronome", password = "password", host = "localhost" }
--sql = { driver = "PostgreSQL", database = "metronome", username = "metronome", password = "secret", host = "localhost" }

----------- Virtual hosts -----------
-- You need to add a VirtualHost entry for each domain you wish Prosody to serve.
-- Settings under each VirtualHost entry apply *only* to that host.

VirtualHost "example.org"
    enabled = true
    authentication = 'ldap2' -- Indicate that we want to use LDAP for authentication
    default_storage = "sql"
    storage = {
        vcard = "ldap";
    }

    modules_enabled = {
        -- Generally required
            "roster"; -- Allow users to have a roster. Recommended ;)

        -- Not essential, but recommended
            "private"; -- Private XML storage (for room bookmarks, etc.)
            "vcard"; -- Allow users to set vCards

        -- These are commented by default as they have a performance impact
            "mam"; -- Message Archive Management
            "privacy"; -- Support privacy lists

        -- Nice to have
            "lastactivity"; -- Logs the user last activity timestamp
            "pep"; -- Enables users to publish their mood, activity, playing music and more
            "message_carbons"; -- Allow clients to keep in sync with messages send on other resources
            --"register"; -- Allow users to register on this server using a client and change passwords
            --"register_redirect"; -- Redirects users registering to the registration form
            "public_service"; -- Provides some information about the XMPP server
            --"log_activity"; -- Activity log, module from https://github.com/jappix/jappix-xmppd-modules
            "groups"; -- Shared groups

        -- Admin interfaces
            --"admin_adhoc"; -- Allows administration via an XMPP client that supports ad-hoc commands
    }

    groups_file = "/etc/metronome/groups.txt"

    ldap = {
        hostname      = 'kolab',                    -- LDAP server location
        bind_dn       = 'cn=Directory Manager', -- Bind DN for LDAP authentication (optional if anonymous bind is supported)
        bind_password = 'password',                      -- Bind password (optional if anonymous bind is supported)
    
        user = {
          basedn        = 'ou=People,dc=example,dc=org',                  -- The base DN where user records can be found
          filter        = '(objectClass=mailrecipient)', -- Filter expression to find user records under basedn
          usernamefield = 'uid',                                         -- The field that contains the user's ID (this will be the username portion of the JID)
          namefield     = 'cn',                                          -- The field that contains the user's full name (this will be the alias found in the roster)
        },
    
        groups = {
          basedn      = 'ou=Groups,dc=example,dc=org', -- The base DN where group records can be found
          memberfield = 'uniqueMember',                   -- The field that contains user ID records for this group (each member must have a corresponding entry under the user basedn with the same value in usernamefield)
          namefield   = 'cn',                          -- The field that contains the group's name (used for matching groups in LDAP to group definitions below)
    
    --      {
    --        name  = 'Everyone', -- The group name that will be seen in users' rosters
    --        cn    = 'Everyone', -- This field's key *must* match ldap.groups.namefield! It's the name of the LDAP group this definition represents
    --        admin = false,      -- (Optional) A boolean flag that indicates whether members of this group should be considered administrators.
    --      },
          {
            name  = 'IT',
            cn    = 'IT',
            admin = true,
          },
        },
    
        vcard_format = {
          displayname = 'cn', -- Consult the vCard configuration section in the README
          nickname    = 'displayName',
    --      given       = 'givenName',
    --      family      = 'sn',
          fn          = 'displayName',
          email       = {
            internet = { 
              userid = 'mail',
            }
          },
    --      tel         = 'telephoneNumber',
          tel = { 
            work = { 
              number = 'telephoneNumber',
            }
          }, 
    --      org         = 'o',
          title       = 'title',
          bday        = 'birthDay',
          photo       = {
            type   = 'image/jpeg',
            binval = 'jpegPhoto',
          }
        },
    }

    
    mam_stores_cap = 1000
    resources_limit = 10

--[[
    no_registration_whitelist = true
    registration_url = "https://jappix.com/"
    registration_text = "Please register your account on Jappix itself (open Jappix.com in your Web browser). Then you'll be able to use it anywhere you want."

    public_service_vcard = {
        name = "Jappix XMPP service",
        url = "https://jappix.com/",
        foundation_year = "2010",
        country = "FR",
        email = "valerian@jappix.com",
        admin_jid = "valerian@jappix.com",
        geo = "48.87,2.33",
        ca = { name = "StartSSL", url = "https://www.startssl.com/" },
        oob_registration_uri = "https://jappix.com/"
    }
--]]

--[[
VirtualHost "anonymous.jappix.com"
    enabled = true
    authentication = "anonymous"
    allow_anonymous_multiresourcing = true
    allow_anonymous_s2s = true
    anonymous_jid_gentoken = "Jappix Anonymous User"
    anonymous_randomize_for_trusted_addresses = { "127.0.0.1", "::1" }
--]]

------ Components ------
-- You can specify components to add hosts that provide special services,
-- like multi-user conferences, and transports.

---Set up a MUC (multi-user chat) room server on muc.example.org:
Component "muc.example.org" "muc"
    name = "Jappix Chatrooms"

    modules_enabled = {
        "muc_limits";
        "muc_log";
        "muc_log_http";
        "pastebin";
    }

    muc_event_rate = 0.5
    muc_burst_factor = 10

    muc_log_http_config = {
        url_base = "logs";
        theme = "metronome";
    }

    pastebin_url = "https://muc.example.org/paste/"
    pastebin_path = "/paste/"
    pastebin_expire_after = 0
    pastebin_trigger = "!paste"

---Set up a PubSub server
Component "pubsub.example.org" "pubsub"
    name = "Jappix Publish/Subscribe"

    --unrestricted_node_creation = true -- Anyone can create a PubSub node (from any server)

---Set up a VJUD service
Component "vjud.example.org" "vjud"
    ud_disco_name = "Jappix User Directory"
    synchronize_to_host_vcards = "example.org"

---Set up a BOSH service ( https://bind.example.org:5281/http-bind )
Component "bind.example.org" "http"
    modules_enabled = { "bosh" }

---Set up a WebSocket service
Component "websocket.example.org" "http"
    modules_enabled = { "websocket" }

---Set up a BOSH + WebSocket service
Component "me.example.org" "http"
    modules_enabled = { "bosh", "websocket" }

---Set up a statistics service
Component "stats.example.org" "http"
    modules_enabled = { "server_status" }

    server_status_basepath = "/xmppd/"
    server_status_show_hosts = { "example.org", "anonymous.example.org" }
    server_status_show_comps = { "muc.example.org", "proxy.example.org", "pubsub.example.org", "vjud.example.org" }

--[[

---Set up an API service
-- Important: uses modules from https://github.com/jappix/jappix-xmppd-modules
Component "api.example.org" "http"
    modules_enabled = { "api_user", "api_muc" }
--]]

-- Set up a SOCKS5 bytestream proxy for server-proxied file transfers:
Component "proxy.example.org" "proxy65"
    proxy65_acl = { "example.org", "anonymous.example.org" }

