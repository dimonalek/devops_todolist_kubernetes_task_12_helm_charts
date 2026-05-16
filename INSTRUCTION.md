# Validation Instructions

## Prerequisites

- [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/docs/intro/install/) v3+

## 1. Create the Kubernetes cluster

```bash
kind create cluster --config cluster.yml
```

## 2. Inspect nodes and verify labels

```bash
kubectl get nodes --show-labels
```

Expected: two workers with `app=mysql` and three workers with `app=todoapp`.

## 3. Taint mysql nodes and deploy all resources

Run the bootstrap script from the repository root:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

This script:
1. Taints all nodes labelled `app=mysql` with `app=mysql:NoSchedule`
2. Installs the ingress-nginx controller
3. Runs `helm dependency update` to resolve the mysql sub-chart dependency
4. Installs the `todoapp` Helm release (which includes the `mysql` sub-chart)

## 4. Verify taints were applied

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

Expected: mysql-labelled nodes show `[{app mysql NoSchedule}]`.

## 5. Verify the Helm release

```bash
helm list
```

Expected: a release named `todoapp` with STATUS `deployed`.

## 6. Verify all resources

```bash
kubectl get all,cm,secret,ing -A
```

Save to a file for the PR:

```bash
kubectl get all,cm,secret,ing -A > output.log
```

## 7. Verify RBAC and ServiceAccount

```bash
kubectl -n todoapp get sa,role,rolebinding
```

Expected: resources named `secrets-reader`.

Verify the Deployment uses the ServiceAccount:

```bash
kubectl -n todoapp get deploy todoapp -o jsonpath='{.spec.template.spec.serviceAccountName}'
```

Expected output: `secrets-reader`

## 8. Verify affinity and tolerations

Check that todoapp pods land on `app=todoapp` nodes:

```bash
kubectl -n todoapp get pods -o wide
```

Check that mysql pods land on `app=mysql` nodes and that the taint is tolerated:

```bash
kubectl -n mysql get pods -o wide
```

## 9. Cleanup (optional)

```bash
helm uninstall todoapp
kind delete cluster
```
