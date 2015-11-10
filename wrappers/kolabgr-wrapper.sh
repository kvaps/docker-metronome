#!/bin/bash

kolabgr ()
{
    lua /etc/metronome/kolabgr.lua > /etc/metronome/groups.txt
    sleep $KOLAB_GROUPS_TIMEOUT
    kolabgr
}

kolabgr

