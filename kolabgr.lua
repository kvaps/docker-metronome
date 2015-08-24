-- kolabgr (Kolab groups) script
-- This script generates a list of groups and members from Kolab's LDAP for Prosody's mod_groups
--
-- author: kvaps

require "lualdap"

-- Configuration
config = {
    ldapserver = "kolab",
    binddn = "cn=Directory Manager",
    passwd = "password",
    user = {
        basedn = "ou=People,dc=example,dc=org",
        filter = "(objectClass=mailrecipient)",
    },
    groups = {
        basedn = "ou=Groups,dc=example,dc=org",
        filter = "(objectClass=groupofuniquenames)",  -- Simple groups
--        filter = "(objectClass=kolabgroupofuniquenames)",  -- only Kolab groups
    },
}

ld = assert (lualdap.open_simple (config.ldapserver, config.binddn, config.passwd))

users = {}
groups = {}

-- Writing LDAP to tables
for dn, attribs in ld:search { base = config.user.basedn, scope = 'onelevel', filter = config.user.filter } do users[dn]=attribs end
for dn, attribs in ld:search { base = config.groups.basedn, scope = 'onelevel', filter = config.groups.filter } do groups[dn]=attribs end

-- Search users by groups
for groupname, val in pairs (groups) do -- Take groups
    if val.cn ~= "All" then    -- If groupname is not "All"
        io.write ("[" .. val.cn .. "]\n")
        if val.uniqueMember then            -- If not empty
            if type(val.uniqueMember) == 'table' then
                for gr, member in pairs (val.uniqueMember) do -- Take uniqueMember parameter of group
                    for usercn, val in pairs (users) do       -- Take cn paramete of user
                        if member == usercn then
                            io.write (val.mail .. "=" .. val.displayName .. "\n")
                        end
                    end
                end
            else    -- If only one
                member=val.uniqueMember;
                for usercn, val in pairs (users) do       -- Take cn paramete of user
                    if member == usercn then
                        io.write (val.mail .. "=" .. val.displayName .. "\n")
                    end
                end
            end
        end
    end
end

-- vim:sts=4 sw=4

