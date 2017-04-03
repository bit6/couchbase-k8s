set -m

/entrypoint.sh couchbase-server &

sleep 15

USER="Administrator"
PASS="password"
# Full hostname - we will use it instead of the IPs that change
# Could use the short hostname, but that could cause issues for
# eventual XDCR usage
MYHOST=`hostname -f`

# Setup index and memory quota
curl -v -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=$MEM_QUOTA -d indexMemoryQuota=$INDEX_MEM_QUOTA

# Setup services
curl -v -X POST http://127.0.0.1:8091/node/controller/setupServices -d services=kv%2Cn1ql%2Cindex

# Setup credentials
curl -v -X POST http://127.0.0.1:8091/settings/web -d port=8091 -d username=$USER -d password=$PASS

# Setup Memory Optimized Indexes
curl -v -u $USER:$PASS -X POST http://127.0.0.1:8091/settings/indexes -d 'storageMode=memory_optimized'

# Rename the server to use the hostname, not IP
curl -v -u $USER:$PASS -X POST http://127.0.0.1:8091/node/controller/rename -d hostname=$MYHOST

if [[ "$HOSTNAME" == *-0 ]]; then
  TYPE="MASTER"
else
  TYPE="WORKER"
fi

echo "Type: $TYPE"

if [ "$TYPE" = "WORKER" ]; then
  sleep 15

  CMD="server-add"

  echo "Auto Rebalance: $AUTO_REBALANCE"
  if [ "$AUTO_REBALANCE" = "true" ]; then
    CMD="rebalance"
  fi

  couchbase-cli $CMD --cluster=$COUCHBASE_MASTER:8091 --user=$USER --password=$PASS --server-add=$MYHOST --server-add-username=$USER --server-add-password=$PASS
fi

fg 1
