#!/bin/bash
d=rsyslog
l=/var/log/messages
trap '{ service $d stop; exit 0; }' EXIT
service $d start
tail -f -n1 $l
