# Logging

To collect logs from your Codacy installation using fluentd change `fluentdoperator.enabled` to true.

```bash
--set fluentdoperator.enabled=true
```

The fluentd daemonset will send the logs to minio which is also installed by this chart.

In order to send them to our support in case of problems, run the following command locally (replacing the `<namespace>` with the namespace in which Codacy was installed):

```bash
kubectl cp <namespace>/$(kubectl get pods -n <namespace> -l app=minio -o jsonpath='{.items[*].metadata.name}'):/export/fluentd-bucket ./logs
```