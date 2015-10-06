#!/bin/bash

kolabgr ()
{
    lua /etc/metronome/kolabgr.lua > /etc/metronome/groups.txt
    sleep 15m 
    kolabgr
}

kolabgr

