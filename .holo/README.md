# .holo
This folder contains configurations for [hologit](https://github.com/JarvusInnovations/hologit), a tool used to
"project" (i.e. create and push) git branches with specific contents (from this repo, or other repos) during CI/CD
operations. There are two main features we utilize.

1. hologit can bring in source code from other repositories directly via git, so we can use Helm charts and other pieces of source code without relying on published artifacts.
2. hologit can "project" a subset of content from a branch to another branch; this allows git-driven CI/CD workflows to operate on specific folders (e.g. infra-related candidate branches that only contain infra-specific code)

In this repo, the most important definition is [the release-candidate branch](./branches/release-candidate) which is referenced by the [GitHub Action](../.github/workflows/service-release-candidate.yml) that pushes infra-specific candidates branches.
