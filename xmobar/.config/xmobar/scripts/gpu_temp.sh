#!/bin/bash

gpu_str=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader)

IFS=","

read -ra newarr <<< $gpu_str

utilization=$(echo "${newarr[0]}" | sed 's/ //g' | sed 's/MiB/M/')
temp=$(echo "${newarr[1]}" | sed 's/ //g')
echo "GPU: $utilization (${temp}°C)"

