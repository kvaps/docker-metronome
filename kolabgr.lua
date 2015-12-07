-- kolabgr (Kolab groups) script
-- This script generates a list of groups and members from Kolab's LDAP for Prosody's mod_groups
--
-- author: kvaps

require "lualdap"

-- Load configuration
dofile "/etc/metronome/ldap.cfg.lua"

ld = assert (lualdap.open_simple (ldap.hostname, ldap.bind_dn, ldap.bind_password))

users = {}
groups = {}

-- Writing LDAP to tables
for dn, attribs in ld:search { base = ldap.user.basedn, scope = 'onelevel', filter = ldap.user.filter } do users[dn]=attribs end
for dn, attribs in ld:search { base = ldap.groups.basedn, scope = 'onelevel', filter = ldap.groups.filter } do groups[dn]=attribs end


-- Search users by groups
function print_user(val)
    if ldap.user.usernamefield == "mail" then
        print (val.mail .. "=" .. val.displayName)
    else
        print (val.uid .. "@" .. ldap.kolabgr.domain .. "=" .. val.displayName)
    end
end

function print_group(val)
    if ldap.kolabgr.show_all_groups == true then
        io.write ("[+" .. val.cn .. "]\n")
    else
        io.write ("[" .. val.cn .. "]\n")
    end
        if val.uniqueMember then            -- If not empty
             if type(val.uniqueMember) == 'table' then
                 for gr, member in pairs (val.uniqueMember) do -- Take uniqueMember parameter of group
                      for usercn, val in pairs (users) do       -- Take cn paramete of user
                          if member == usercn then
                              print_user(val)
                          end
                      end
                 end
            else    -- If only one
                 member=val.uniqueMember;
                 for usercn, val in pairs (users) do       -- Take cn paramete of user
                      if member == usercn then
                          print_user()
                      end
                 end
            end
        end
end

if ldap.kolabgr.not_show_groups then
    for group, val in pairs (groups) do -- Take groups
        for id, igngroup in pairs (ldap.kolabgr.not_show_groups) do -- Remove ignoring groups
            if val.cn == igngroup then 
                groups[group] = nil
            end
        end
    end
end

for group, val in pairs (groups) do -- Take groups
    print_group(val)
end
-- vim:sts=4 sw=4
