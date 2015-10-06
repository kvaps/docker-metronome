#!/bin/bash
l=/var/log/metronome/metronome.log
trap '{ metronomectl stop; exit 0; }' EXIT 
metronomectl start 
tail -f -n1 $l
