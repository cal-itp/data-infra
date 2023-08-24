# hologit

[hologit](https://github.com/JarvusInnovations/hologit) is a tool that facilitates manipulation of
GitHub branches in a manner that facilitates an "obvious" GitOps workflow for CI/CD. Specifically,
hologit allows:

1. Building branches containing only a subset of repository contents (for example, a branch only including infra-related code)
   - This action is called "projection"
2. Bringing in contents from another repository without relying on published artifacts such as Helm charts
3. Applying transformations to files as part of #1
   - These transformations are called "lenses"

In this repository, we declare one holobranch named [release-candidate](../branches/release-candidate).
By projecting this holobranch in GitHub Actions, individual "candidate" branches end up containing
only the code relevant to infra/Kubernetes as well as Kubernetes code from the upstream [cluster-template](https://github.com/JarvusInnovations/cluster-template)
repository. Then, a PR from a `candidate/<some-branch>` to `releases/<env>` (such as `releases/test`) will only show changes/content
relevant to infra in addition to `releases/*` branches only ever containing infra code. For example:

1. Create a [PR making an infra-related change](https://github.com/cal-itp/data-infra/pull/2828)
2. Create and merge a [PR to deploy a candidate branch to test](https://github.com/cal-itp/data-infra/pull/2829)
3. Merge the PR from #1
4. After merge, [PR to deploy the main candidate branch to prod](https://github.com/cal-itp/data-infra/pull/2832)
