#!/bin/bash

# Number of nodes
NUM_NODES=1
# Number of GPUs per node
NUM_GPUS=4
# Size of expert parallel world (should be less than total world size)
EP_SIZE=2
# Number of total experts
EXPERTS=8

/home/scttmars/.local/bin/deepspeed --num_nodes=${NUM_NODES} --num_gpus=${NUM_GPUS} cifar10_deepspeed.py \
	--log-interval 100 \
	--deepspeed \
	--deepspeed_config ds_config.json \
	--moe \
	--ep-world-size ${EP_SIZE} \
	--num-experts ${EXPERTS} \
	--top-k 1 \
	--noisy-gate-policy 'RSample' \
	--moe-param-group
