#!/bin/bash

set -e

cat <<EOF >> /etc/ecs/ecs.config
ECS_CLUSTER=${tf_ecs_cluster}
ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=30m
ECS_IMAGE_CLEANUP_INTERVAL=10m
ECS_IMAGE_MINIMUM_CLEANUP_AGE=15m
ECS_IMAGE_PULL_BEHAVIOR=always
ECS_IMAGE_PULL_INACTIVITY_TIMEOUT=5m
ECS_CONTAINER_START_TIMEOUT=15m
ECS_NUM_IMAGES_DELETE_PER_CYCLE=15
ECS_INSTANCE_ATTRIBUTES={"ec2":"${tf_ec2_name}"}
EOF

echo "Restart ECS Agent..."
service ecs stop
rm -rf /var/lib/ecs/data/*
systemctl enable --no-block --now ecs
cp /usr/lib/systemd/system/ecs.service /etc/systemd/system/ecs.service
sed -i '/After=cloud-final.service/d' /etc/systemd/system/ecs.service
systemctl daemon-reload
service ecs start

echo "Success!!!"