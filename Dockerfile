FROM couchbase:community-4.5.0

COPY configure-node.sh /opt/couchbase

ENV MEM_QUOTA 400
ENV MEM_INDEX_QUOTA 400

CMD ["/opt/couchbase/configure-node.sh"]
