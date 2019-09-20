#!/bin/bash -v

set -e

function finish {
    if [ $rc != 0 ]; then
      echo "cloudformation signal-resource FAILURE" >> $LOG_FILE
      /usr/local/bin/aws cloudformation signal-resource --stack-name ${signal_stack_name} --logical-resource-id ${signal_resource_id} --unique-id $${AWS_UNIQUE_ID} --region $${AWS_REGION} --status FAILURE  2>&1 >> $LOG_FILE

      echo "[halt] 3 min before shutdown" >> $LOG_FILE
      echo "[debug] keep up by creating /var/tmp/keeprunning" >> $LOG_FILE
      sleep 60

      if [ ! -f "/var/tmp/keeprunning" ]; then
        echo "[halt] halt" >> $LOG_FILE
        halt -f
      fi
      echo "[halt] keeprunning" >> $LOG_FILE
    else
      /usr/local/bin/aws cloudformation signal-resource --stack-name ${signal_stack_name} --logical-resource-id ${signal_resource_id} --unique-id $${AWS_UNIQUE_ID} --region $${AWS_REGION} --status SUCCESS  2>&1 >> $LOG_FILE

      # ensure last return code is 0
      echo "End" >> $LOG_FILE
    fi
}

trap 'rc=$?; set +e; finish' EXIT

LOG_FILE="/var/log/user-data.log"

/etc/eks/bootstrap.sh \
    --apiserver-endpoint '${apiserver_endpoint}' \
    --b64-cluster-ca '${b64_cluster_ca}' \
    '${cluster_name}' 2>&1 >> $LOG_FILE
