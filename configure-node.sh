set -m

/entrypoint.sh couchbase-server &

sleep 15

USER="Administrator"
PASS="password"

# Setup index and memory quota
curl -v -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=$MEM_QUOTA -d indexMemoryQuota=$INDEX_MEM_QUOTA

# Setup services
curl -v http://127.0.0.1:8091/node/controller/setupServices -d services=kv%2Cn1ql%2Cindex

# Setup credentials
curl -v http://127.0.0.1:8091/settings/web -d port=8091 -d username=$USER -d password=$PASS

# Setup Memory Optimized Indexes
curl -i -u $USER:$PASS -X POST http://127.0.0.1:8091/settings/indexes -d 'storageMode=memory_optimized'

if [[ "$HOSTNAME" == *-0 ]]; then
  TYPE="MASTER"
else
  TYPE="WORKER"
fi

echo "Type: $TYPE"

if [ "$TYPE" = "WORKER" ]; then
  sleep 15

  IP=`hostname -I`

  CMD="server-add"

  echo "Auto Rebalance: $AUTO_REBALANCE"
  if [ "$AUTO_REBALANCE" = "true" ]; then
    CMD="rebalance"
  fi
  couchbase-cli server-add --cluster=$COUCHBASE_MASTER:8091 --user=$USER --password=$PASS --server-add=$IP --server-add-username=$USER --server-add-password=$PASS
fi

fg 1
