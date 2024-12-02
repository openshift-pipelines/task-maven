SHELL := /usr/bin/env bash
BIN = $(CURDIR)/.bin

OSP_VERSION ?= latest

# using the chart name and version from chart's metadata
CHART_NAME ?= $(shell awk '/^name:/ { print $$2 }' Chart.yaml)
CHART_VERSION ?= $(shell awk '/^version:/ { print $$2 }' Chart.yaml)

RELEASE_VERSION = v$(CHART_VERSION)
# release directory where the Tekton resources are rendered into.
RELEASE_DIR ?= /tmp/$(CHART_NAME)-$(CHART_VERSION)

CATALOGCD_VERSION = v0.1.0

# bats entry point and default flags
BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

# path to the bats test files, overwite the variables below to tweak the test scope
E2E_TESTS ?= ./test/e2e/*.bats

E2E_PVC ?= test/e2e/resources/pvc-maven.yaml
E2E_SECRET ?= test/e2e/resources/secret-maven.yaml
E2E_PROXY_SECRET ?= test/e2e/resources/secret-proxy-maven.yaml                
E2E_CONFIGMAP ?= test/e2e/resources/configmap-proxy-maven.yaml                
E2E_MAVEN_PARAMS_REVISION ?= master
E2E_MAVEN_PARAMS_URL ?= https://github.com/Aneesh-M-Bhat/shopping-cart-test-java
E2E_TEST_DIR ?= ./test/e2e
E2E_MAVEN_PARAMS_SERVER_SECRET ?= secret-maven
E2E_MAVEN_PARAMS_PROXY_SECRET ?= secret-proxy-maven                               
E2E_MAVEN_PARAMS_PROXY_CONFIGMAP ?= config-proxy-maven                              

# container registry URL, usually hostname and port
REGISTRY_URL ?= registry.registry.svc.cluster.local:32222
# container registry namespace, as in the section of the registry allowed to push images
REGISTRY_NAMESPACE ?= task-containers
# base part of a fully qualified container image name
IMAGE_BASE ?= $(REGISTRY_URL)/$(REGISTRY_NAMESPACE)

E2E_JIB_MAVEN_IMAGE_TAG ?= task-jib-maven:latest

E2E_JIB_MAVEN_IMAGE ?= $(IMAGE_BASE)/${E2E_JIB_MAVEN_IMAGE_TAG}
# E2E_JIB_MAVEN_IMAGE ?= docker.io/aneeshmbhat/tekton-maven:latest

# generic arguments employed on most of the targets
ARGS ?=

# making sure the variables declared in the Makefile are exported to the excutables/scripts invoked
# on all targets
.EXPORT_ALL_VARIABLES:

# uses helm to render the resource templates to the stdout
define render-template
	@helm template $(ARGS) $(CHART_NAME) .
endef

$(BIN):
	@mkdir -p $@

CATALOGCD = $(or ${CATALOGCD_BIN},${CATALOGCD_BIN},$(BIN)/catalog-cd)
$(BIN)/catalog-cd: $(BIN)
	curl -fsL https://github.com/openshift-pipelines/catalog-cd/releases/download/v0.1.0/catalog-cd_0.1.0_linux_x86_64.tar.gz | tar xzf - -C $(BIN) catalog-cd


# renders the task resource file printing it out on the standard output
helm-template:
	$(call render-template)

# renders and installs the resources (task)
install:
	$(call render-template) |kubectl $(ARGS) apply -f -

# renders and remove the resources (task)
remove:
	$(call render-template) |kubectl $(ARGS) delete -f -

# pepare a release
.PHONY: prepare-release
prepare-release:
	mkdir -p $(RELEASE_DIR) || true
	hack/release.sh $(RELEASE_DIR)

.PHONY: release
release: ${CATALOGCD} prepare-release
	pushd ${RELEASE_DIR} && \
		$(CATALOGCD) release \
			--output release \
			--version $(CHART_VERSION) \
			tasks/* \
		; \
	popd

# tags the repository with the RELEASE_VERSION and pushes to "origin"
git-tag-release-version:
	if ! git rev-list "${RELEASE_VERSION}".. >/dev/null; then \
		git tag "$(RELEASE_VERSION)" && \
			git push origin --tags; \
	fi

# github-release
.PHONY: github-release
github-release: git-tag-release-version release
	gh release create $(RELEASE_VERSION) --generate-notes && \
	gh release upload $(RELEASE_VERSION) $(RELEASE_DIR)/release/catalog.yaml && \
	gh release upload $(RELEASE_VERSION) $(RELEASE_DIR)/release/resources.tar.gz

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
prepare-e2e:
	kubectl apply -f ${E2E_PVC}
	kubectl apply -f ${E2E_SECRET}
	kubectl apply -f ${E2E_PROXY_SECRET}
	kubectl apply -f ${E2E_CONFIGMAP}

# run end-to-end tests against the current kuberentes context, it will required a cluster with tekton
# pipelines and other requirements installed, before start testing the target invokes the
# installation of the current project's task (using helm).
.PHONY: test-e2e
test-e2e: prepare-e2e
test-e2e: E2E_TESTS = $(E2E_TEST_DIR)/*.bats
test-e2e: bats

.PHONY: test-e2e-jib
test-e2e-jib: REGISTRY_URL = image-registry.openshift-image-registry.svc.cluster.local:5000
test-e2e-jib: REGISTRY_NAMESPACE = $(shell oc project -q)
test-e2e-jib: prepare-e2e
test-e2e-jib: E2E_TESTS = $(E2E_TEST_DIR)/*-jib.bats
test-e2e-jib: bats

.PHONY: test-e2e-maven
test-e2e-maven: prepare-e2e
test-e2e-maven: E2E_TESTS = $(E2E_TEST_DIR)/*-maven.bats
test-e2e-maven: bats

# Run all the end-to-end tests against the current openshift context.
# It is used mainly by the CI and ideally shouldn't differ that much from test-e2e
.PHONY: prepare-e2e-openshift
prepare-e2e-openshift:
	./hack/install-osp.sh $(OSP_VERSION)
.PHONY: test-e2e-openshift
test-e2e-openshift: prepare-e2e-openshift
test-e2e-openshift: test-e2e

# act runs the github actions workflows, so by default only running the test workflow (integration
# and end-to-end) to avoid running the release workflow accidently
act: ARGS = --workflows=./.github/workflows/test.yaml
act:
	act $(ARGS)
