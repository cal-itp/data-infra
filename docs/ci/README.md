# CI

The `ci` tree contains bash scripts which provide a framework for automation
pipelines. The pipelines framework is delivered as embedded bash scripts to
simplify the process of providing remote/local parity and platform independence
for pipeline runs.

This document covers high level concepts and certain concrete descriptions of
the ci pipeline framework. For a higher level guide on utilizing git flows
powered by this framework, see
[the "Git Flow for Services" documentation](./Git-Flow-Services.md)

## 1.0 Concepts

This section breaks down the conceptual design of pipelines built with the
embedded ci framework.

### 1.1 steps

A step is a discrete, atomic task within a pipeline. Each step can be loosely
thought of as being part of a _phase_ and will consume zero or more _variables_.

### 1.2 phases

Each pipeline can be thought of as being conceptually divided into a series of
phases, though not every pipeline will necessarily need to run steps in every
phase. These phases are loose organizational concepts and are in no way depended
on at any sort of technical implementation level.

- _validate_: steps which check the contents of variables for the existence of
 a value, properly formed values, or any other acceptability criteria.
- _configure_: steps which apply configurations to the execution environment of
 the pipeline based on input variables OR steps which populate variables from
 external sources, e.g., commands that query remote APIs or git commands
- _build_: steps which produce or contribute to the production of an artifact.
- _release_: steps which perform or contribute to the performance of deploying a
 build artifact.

These phases will generally follow the above sequence, but the sequencing is by
no means strict. E.g., there may be plenty of instances where a _validate_ step
is executed after a _configure_ step, and perhaps even additional _configure_
steps are run after that.

### 1.3 variables

Each pipeline is driven by a set of variables which may be provided from the
environment (i.e., values are interpretd without shell features such as array
syntax, interpolation, etc). Variables conceptually exist within a global
pipeline namespace; one variable may be consumed by multiple steps, but the same
variable will always be used to describe the same object or property across all
steps which consume it. By convention, every pipeline variable is named with one
of the following prefixes:

- `CI_`: Control variables for configuring the pipeline run itself.
- `CONFIGURE_`: Variables which describe desired configuration within the
 pipeline execution environment, such as git config parameters, `ssh_config`
 parameters, kubeconfig data, etc.
- `BUILD_`: Variables which describe a build artifact or contain required
 information to produce, package, or publish such an artifact.
- `RELEASE_`: Variables which describe a target environment, deployment
 configuration, or other required information to deploy an artifact or
 application (which is not already described by an existing `BUILD_` variable).

### 1.4 workflows

A workflow is a sequence of steps. There is no reason a workflow could not
include other workflows in place of or addition to individual steps. A complete
pipeline will generally consist of one or more workflows.

## 2.0 Subtree Contents

### 2.1 githooks

This subtree contains hooks which can be symlinked into a `$GIT_DIR/hooks`
directory tp execute local automation workflows. These symlinks may be installed
by hand, or by executing a `make` command from within the subtree. Though these
hooks will generally attempt to replicate the git flow of a canonical remote,
the limitations of git hooks available in local environments typically make
perfect parity unreasonable to achieve.

### 2.2 steps

Each script in the `steps` subtree is an implementation of a single pipeline
step. Each step can be executed directly on a command line or included within a
workflow. It is not recommended to source these steps into a user shell as any
errors will force exit the shell.

### 2.3 workflows

Each script within the `workflows` subtree executes a sequence of one or more
steps. Workflows can be executed directly as commands or can be sourced into
the shell. The latter mode of operation is only recommended within CI systems,
as any errors will cause a force exit of the shell. When executed as a command,
each argument passed to the workflow is processed as an environment file which
provides variables to the workflow. The files are processed in argument order
with the first found definition of a variable taking precedence over any later
definition. Variable values are not evaluated using shell syntax; all values are
interpreted literally.

## 3.0.0 Script Conventions

The following conventions are relevant to writing new workflow or step scripts
or to parsing existing ones.

### 3.1.0 steps

#### 3.1.1 naming and header

The name of each step script should be prefixed with the name of the phase which
it belongs to. E.g., `configure-*` for _configure_ phase steps, `build-*` for
_build_ phase steps, etc.

Every step script should be made executable and MUST use `#!/bin/bash`, NOT
`#!/bin/sh`.

Every step script MUST apply `set -e` in the script header.

#### 3.1.2 variable declaration

Pipeline variables (as described in section 1.3) consumed by a step MUST be
declared at the top of the script using the `test "$VAR_NAME"` convention in
order to test whether the variable is defined. If the variable is optional, the
test statement should be followed by an empty assignment using the `||
VAR_NAME=` convention in order to clearly denote its optional nature. A sensible
default may also be set instead where relevant. If the variable is required, it
should be added to the conventional `required_missing` array. After the variable
declaration block, the step MUST evaluate the `required_missing` array and exit
with code 1 and the conventional error message if the array contains any
elements. See existing steps for examples of this convention.

Variables which are localized to the step itself should be named in all lower
case and should always be initialized to some starting value, as previous steps
within the same workflow may have used localized variables of the same name.

#### 3.1.3 idempotency

Step scripts should be implemented idempotently-- that is, if the desired end
state of any work being performed by the step has already been achieved, that
work should be skipped. Step scripts should not ever, without exceptionally good
reason, cause errors in cases where the desired end state has already been
achieved. Step scripts are encouraged to provide helpful info messages whenever
work is skipped.

### 3.2.0 workflows

#### 3.2.1 naming and header

Workflows names may generally follow the form `{object}-{action}` where
`{object}` is any domain-relevant entity and `{action}` describes the high level
task the workflow performs on that entity. This should be considered a loose
convention-- workflow names should truly take whatever form they need to in
order to plainly and usefully describe their purpose.

Every workflow script should be made executable and MUST use `#!/bin/bash`, NOT
`#!/bin/sh`.

Every workflow script MUST apply `set -e` in the script header.

#### 3.2.3 environment files

The first thing every workflow script MUST do is evaluate all environment files
passed as command line arguments. Refer to existing workflow scripts to see how
to conventionally process and evaluate these environment file arguments.

Values assigned from declarations in these files MUST NOT be evaluated by the
shell, as this violates the tenets of an environment file as well as the user
contract.

#### 3.2.3 variable declaration

Workflows should include a default declaration for every pipeline variable
declared within every included step. This allows operators to easily determine
the variables available to drive a workflow without having to open and read each
individually included step, and further allows them to easily determine which
variables they are required to provide and the default values for variables
which they are not.

Any pipeline variable which is required by the workflow and not provided at
runtime should be prompted for. See existing workflow scripts for how to
conventionally prompt for required variables.

All pipeline variables should be declared with default or prompted values prior
to the execution of the first step.

#### 3.2.4 step execution

Each step should be executed using a `source` statement, and the `source`
statement should be preceded by an info message which prints the name of the
step which will execute next.

Pipeline variables may be changed/redeclared in between steps, but evaluation of
logic between steps is generally discouraged. E.g., conditional execution should
be avoidable in most cases where steps are properly idempotent and explicitly
listing multiple instances of a step should be preferred in cases where a step
will be re-executed a determinitic number of times. Where there is good reason
to do so however, the full power of bash logic and evaluation may be employed to
wrap step execution.
