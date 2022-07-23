#!/bin/bash

set -e

REGION=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | awk '{ print substr($1, 1, length($1)-1) }'`
aws configure set default.region $REGION
aws configure set default.output text

# Wait to mount volume
echo "Sleeping 10s to ensure all EBS volumes are fully attached...."
sleep 10s
echo "Sleep DONE, continuing..."

AWS_DEPLOY_WORKSPACE=/workspace
aws s3 sync --region $REGION s3://${tf_workspace_snapshot_s3}/${tf_asg_name}/ $AWS_DEPLOY_WORKSPACE || true
chown -R ec2-user:ec2-user $AWS_DEPLOY_WORKSPACE

if [ -f $AWS_DEPLOY_WORKSPACE/boot.sh ]; then
    echo "[INFO] found boot script, executing..."
    cd $AWS_DEPLOY_WORKSPACE
    su ec2-user -c 'bash boot.sh'
fi

if [ -n "${tf_efs_id}" ]; then
    echo "Mounting shared EFS volume: ${tf_efs_id}"
    mkdir -p /mnt/efs
    echo "${tf_efs_id} /mnt/efs efs _netdev,tls,accesspoint=${tf_efs_accesspoint} 0 0" >> /etc/fstab
    mount -a
fi