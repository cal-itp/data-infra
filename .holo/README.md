# hologit

[hologit](https://github.com/JarvusInnovations/hologit) is a tool that facilitates manipulation of
GitHub branches in a manner that facilitates an "obvious" GitOps workflow for CI/CD. Specifically,
hologit allows:

1. Building branches containing only a subset of repository contents (for example, a branch only including infra-related code)
   - This action is called "projection"
2. Bringing in contents from another repository without relying on published artifacts such as Helm charts
3. Applying transformations to files as part of #1
   - These transformations are called "lenses"

In this repository, we declare one holobranch named [kubernetes-workspace](../branches/kubernetes-workspace).
By projecting this holobranch in GitHub Actions, a tree containing only the code relevant to infra/Kubernetes
as well as Kubernetes code from the upstream [cluster-template](https://github.com/JarvusInnovations/cluster-template)
repository is generated.

See [`kubernetes/README.md`](../kubernetes/README.md#gitops) for details on the pull request workflow for previewing and deploying Kubernetes changes.
