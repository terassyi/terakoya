# coil standalone egress compatibility test

## how to run

```
$ make start
$ make install-coil-2.8.0
$ make run-e2e # run coil's e2e test
$ make install-coil-standalone-egress
# to pass compatibility test, we need to delete following resources
$ kubectl delete mutatingwebhookconfiguration coilv2-mutating-webhook-configuration
$ kubectl delete validatingwebhookconfiguration coilv2-validating-webhook-configuration
$ kubectl -n kube-system delete deploy coil-controller
$ make test # run compatibility test
```
