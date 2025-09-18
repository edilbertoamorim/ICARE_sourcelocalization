#! /bin/bash

#Go to code folder.
cd distributed_SLSH;

#Start node, wait for a couple of seconds.
python3 sample_main.py node &
sleep 3

#Start orchestrator
python3 sample_main.py orchestrator &
sleep 5
