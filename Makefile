# using the chart name and version from chart's metadata
CHART_NAME ?= $(shell awk '/^name:/ { print $$2 }' Chart.yaml)
CHART_VESION ?= $(shell awk '/^version:/ { print $$2 }' Chart.yaml)

# bats entry point and default flags
BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

# path to the bats test files, overwite the variables below to tweak the test scope
E2E_TESTS ?= ./test/e2e/*.bats

E2E_PVC ?= test/e2e/resources/pvc-mvn.yaml
E2E_MAVEN_PARAMS_REVISION ?= master
E2E_MAVEN_PARAMS_URL ?= https://github.com/shashirajraja/shopping-cart 
E2E_TEST_DIR ?= ./test/e2e

# generic arguments employed on most of the targets
ARGS ?=

# external task dependency to run the end-to-end tests pipeline
TASK_GIT ?= https://github.com/openshift-pipelines/task-git/releases/download/0.0.1/task-git-0.0.1.yaml

# installs "git" task directly from the informed location, the task is required to run the test-e2e
# target, it will hold the "source" workspace data
.PHONY: task-git
task-git:
	kubectl apply -f $(TASK_GIT)

# making sure the variables declared in the Makefile are exported to the excutables/scripts invoked
# on all targets
.EXPORT_ALL_VARIABLES:

# uses helm to render the resource templates to the stdout
define render-template
	@helm template $(ARGS) $(CHART_NAME) .
endef

# renders the task resource file printing it out on the standard output
helm-template:
	$(call render-template)

# renders and installs the resources (task)
install:
	$(call render-template) |kubectl $(ARGS) apply -f -

# packages the helm-chart as a single tarball, using it's name and version to compose the file
helm-package: clean
	helm package $(ARGS) .
	tar -ztvpf $(CHART_NAME)-$(CHART_VESION).tgz

# removes the package helm chart, and also the chart-releaser temporary directories
clean:
	rm -rf $(CHART_NAME)-*.tgz > /dev/null 2>&1 || true

# runs bats-core against the pre-determined tests
.PHONY: bats
bats: install
	$(BATS_CORE) $(BATS_FLAGS) $(ARGS) $(E2E_TESTS)

.PHONY: prepare-e2e
prepare-e2e: task-git
	kubectl apply -f ${E2E_PVC}

# run end-to-end tests against the current kuberentes context, it will required a cluster with tekton
# pipelines and other requirements installed, before start testing the target invokes the
# installation of the current project's task (using helm).
.PHONY: test-e2e
test-e2e: prepare-e2e
test-e2e: E2E_TESTS = $(E2E_TEST_DIR)/*.bats
test-e2e: bats

# act runs the github actions workflows, so by default only running the test workflow (integration
# and end-to-end) to avoid running the release workflow accidently
# act: ARGS = --workflows=./.github/workflows/test.yaml
# act:
# 	act $(ARGS)