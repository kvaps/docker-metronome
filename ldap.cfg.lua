ldap = {
    hostname      = 'localhost',                    -- LDAP server location
    bind_dn       = 'cn=Directory Manager', -- Bind DN for LDAP authentication (optional if anonymous bind is supported)
    bind_password = 'password',                      -- Bind password (optional if anonymous bind is supported)
    
    kolabgr = {
      show_all_groups = true,                   --All users see all groups
      not_show_groups = { 'All', 'Everyone' },  --Exceptions these groups
    },

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
      filter = "(objectClass=groupofuniquenames)",  -- Simple groups
--      filter = "(objectClass=kolabgroupofuniquenames)",  -- only Kolab groups

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
