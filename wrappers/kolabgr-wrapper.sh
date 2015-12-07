#!/bin/bash

kolabgr ()
{
    lua /bin/kolabgr.lua > /etc/metronome/groups.txt
    sleep $KOLAB_GROUPS_TIMEOUT
    kolabgr
}

kolabgr

