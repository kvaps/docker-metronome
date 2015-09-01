#!/bin/bash
l=/var/log/prosody/prosody.log
trap '{ prosodyctl stop; exit 0; }' EXIT 
prosodyctl start 
tail -f -n1 $l
