#!/bin/bash

gpu_str=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader)

IFS=","

read -ra newarr <<< $gpu_str

used_mem=$(echo "${newarr[0]}" | sed 's/ //g' | sed 's/MiB/M/')
used_mem_str=$(echo "$used_mem" | sed 's/M//')
total_mem=$(echo "${newarr[1]}" | sed 's/MiB//')

utilization=$(($used_mem_str / $total_mem)) 

echo "VRAM: $used_mem (${utilization}%)"

