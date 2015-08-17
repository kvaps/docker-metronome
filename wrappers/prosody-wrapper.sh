#!/bin/bash
d=prosody
l=/var/log/prosody/prosody.log
trap '{ service $d stop; exit 0; }' EXIT 
service $d start 
tail -f -n1 $l
