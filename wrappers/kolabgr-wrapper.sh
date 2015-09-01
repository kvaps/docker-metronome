#!/bin/bash

kolabgr ()
{
    lua /etc/prosody/kolabgr.lua > /etc/prosody/groups.txt
    sleep 15m 
    kolabgr
}

kolabgr

