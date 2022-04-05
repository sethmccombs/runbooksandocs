# Manually Defrag `etcd` Node(s)

* You shouldn't need to do this, hopefully `etcd` can handle this automatically (it runs a compaction every 5 minutes by default) but _just in case_ 


1. `kubectl exec` into the `etcd` pod (if for some reason you cannot `exec` into the container from `kubectl`, the same procedure can be followed by `ssh`-ing onto the `etcd` EC2 instance, and `docker exe`c-ing into the `etcd` container
```
# exec into etcd container
kubectl exec -ti etcd-server-ip-x-x-x-x.us-west-2.compute.internal -n kube-system -c etcd-container -- sh

sh-4.2$
```

2. Obtain the most recent revision number of the `etcd` database (the revision is the "version" of the database, the revision of the database is updated every time keys/values are updated in `etcd`) - the command below with obtain the revision and set it to `$rev` 
```
# obtain latest etcd revision
rev=$(ETCDCTL_API=3 etcdctl endpoint status --command-timeout=15s --write-out="json" --cert="/etc/kubernetes/ssl/etcd-client.pem" --key="/etc/kubernetes/ssl/etcd-client-key.pem" --cacert="/etc/kubernetes/ssl/ca.pem" | egrep -o '"revision":[0-9]*' | egrep -o '[0-9].*')

```

3. Compact the `etcd` revision (this removes the revisions from `etcd`'s memory if they don't hold the latest generation of a key)
```
#compact etcd revision
ETCDCTL_API=3 etcdctl --command-timeout=15s --write-out=table --cert="/etc/kubernetes/ssl/etcd-client.pem" --key="/etc/kubernetes/ssl/etcd-client-key.pem" --cacert="/etc/kubernetes/ssl/ca.pem" compact $rev
 
compacted revision 48887605
```

4. defrag the `etcd` database (once the compaction is complete, a defrag will reclaim memory from keys/values compacted away - this happens automatically in `etcd` but we won't fully regain memory freed by the compaction until this is run)

A defrag is a blocking action unlike a compact, so it's not a command you want to run on all nodes at the same time.
```
# defrag etcd database
ETCDCTL_API=3 etcdctl --command-timeout=15s --write-out=table --cert="/etc/kubernetes/ssl/etcd-client.pem" --key="/etc/kubernetes/ssl/etcd-client-key.pem" --cacert="/etc/kubernetes/ssl/ca.pem" defrag
 
Finished defragmenting etcd member[127.0.0.1:2379]
```

5. Disarm the `etcd` alarm
```
# disarm etcd alarms
ETCDCTL_API=3 etcdctl --command-timeout=15s --cert="/etc/kubernetes/ssl/etcd-client.pem" --key="/etc/kubernetes/ssl/etcd-client-key.pem" --cacert="/etc/kubernetes/ssl/ca.pem" alarm disarm
 
memberID:2399457683142303765 alarm:NOSPACE
```

NOTE: The default value of command-timeout is 5 seconds, the commands in this runbook use 15 seconds as defrag can often take longer than 5 seconds

You can check the size of the `etcd`  database (and the leader status should you need it) with a command such as:
```
# check database size

sh-4.2$ ETCDCTL_API=3 etcdctl endpoint status --write-out="table" --cert="/etc/kubernetes/ssl/etcd-client.pem" --key="/etc/kubernetes/ssl/etcd-client-key.pem" --cacert="/etc/kubernetes/ssl/ca.pem"
 
+----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| 127.0.0.1:2379 | 1f397f44578ab660 |   3.5.0 |   72 MB |      true |      false |         2 |   15186513 |           15186513 |        |
+----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+

```


Check all nodes 
```
date; for i in $(kc get pods -n kube-system | grep '^etcd' | awk '{print $1}'); do echo "$i"; kc exec -ti "$i" -n kube-system -c etcd-container -- sh -c "ETCDCTL_API=3 etcdctl endpoint status --write-out='table' --cert='/etc/kubernetes/ssl/etcd-client.pem' --key='/etc/kubernetes/ssl/etcd-client-key.pem' --cacert='/etc/kubernetes/ssl/ca.pem'"; done
```