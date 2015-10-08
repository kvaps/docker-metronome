-- kolabgr (Kolab groups) script
-- This script generates a list of groups and members from Kolab's LDAP for Prosody's mod_groups
--
-- author: kvaps

require "lualdap"

-- Load configuration
dofile "ldap.cfg.lua"

ld = assert (lualdap.open_simple (ldap.hostname, ldap.bind_dn, ldap.bind_password))

users = {}
groups = {}

-- Writing LDAP to tables
for dn, attribs in ld:search { base = ldap.user.basedn, scope = 'onelevel', filter = ldap.user.filter } do users[dn]=attribs end
for dn, attribs in ld:search { base = ldap.groups.basedn, scope = 'onelevel', filter = ldap.groups.filter } do groups[dn]=attribs end

-- Search users by groups
for group, val in pairs (groups) do -- Take groups
    if val.cn ~= "All" then    -- If groupname is not "All"
        io.write ("[" .. val.cn .. "]\n")
        if val.uniqueMember then            -- If not empty
             if type(val.uniqueMember) == 'table' then
                 for gr, member in pairs (val.uniqueMember) do -- Take uniqueMember parameter of group
                      for usercn, val in pairs (users) do       -- Take cn paramete of user
                          if member == usercn then
                              print (val.mail .. "=" .. val.displayName)
                          end
                      end
                 end
            else    -- If only one
                 member=val.uniqueMember;
                 for usercn, val in pairs (users) do       -- Take cn paramete of user
                      if member == usercn then
                          print (val.mail .. "=" .. val.displayName)
                      end
                 end
            end
        end
    end
end

-- vim:sts=4 sw=4
