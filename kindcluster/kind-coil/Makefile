CLUSTER_NAME := kind-coil 

KIND_VERSION := 0.24.0
KUBERNETES_VERSION := 1.31.0
KUSTOMIZE_VERSION := 5.4.3

COIL_BRANCH := standalone-egress

SUDO ?= sudo

BINDIR := $(abspath $(PWD)/bin)
MANIFESTDIR := $(abspath $(PWD)/manifests)
TMPDIR := $(abspath $(PWD)/../tmp)

KIND := $(BINDIR)/kind
KUBECTL := $(BINDIR)/kubectl
KUSTOMIZE := $(BINDIR)/kustomize

export KUBECTL

KIND_CONFIG = kind.yaml


.PHONY: setup
setup: $(KIND) $(KUBECTL) $(KUSTOMIZE)

.PHONY: start
start: setup $(KUBEROUTER_MANIFEST)
	$(SUDO) sysctl -w fs.inotify.max_user_instances=512
	$(SUDO) sysctl -w fs.inotify.max_user_watches=65536

	@echo "CREATE THE KIND CLUSTER"
	$(KIND) create cluster --image kindest/node:v$(KUBERNETES_VERSION) --config=$(KIND_CONFIG)


.PHONY:
stop: clean-coil
	$(KIND) delete cluster

.PHONY: install-coil
install-coil: clone-coil-repo
	mkdir -p $(MANIFESTDIR)/coil

	cd $(TMPDIR)/coil/v2; \
	make certs && \
	make image && \
	$(KUSTOMIZE) build . > $(MANIFESTDIR)/coil/coil.yaml
	$(KIND) load docker-image coil:dev
	CM_NAME=$(shell yq 'select(.kind=="ConfigMap") | .metadata.name' $(MANIFESTDIR)/coil/coil.yaml) yq -i '.metadata.name = env(CM_NAME)' $(MANIFESTDIR)/coil/coil_cm_patch.yaml
	$(KUSTOMIZE) build $(MANIFESTDIR)/coil | $(KUBECTL) apply -f -
	$(KUBECTL) -n kube-system wait --for=condition=available --timeout=180s deployment/coil-egress-controller

.PHONY: clone-coil-repo
clone-coil-repo:
	mkdir -p $(TMPDIR)
	if [ -d "$(TMPDIR)/coil" ]; then \
        cd $(TMPDIR)/coil; git fetch origin; git checkout $(COIL_BRANCH); \
    else \
		cd $(TMPDIR); git clone https://github.com/p-strusiewiczsurmacki-mobica/coil.git; cd coil; git checkout $(COIL_BRANCH); \
    fi

.PHONY: clean-coil
clean-coil:
	rm -rf $(TMPDIR)/coil

$(KIND):
	mkdir -p $(dir $@)
	curl -sfL -o $@ https://github.com/kubernetes-sigs/kind/releases/download/v$(KIND_VERSION)/kind-linux-amd64
	chmod a+x $@

$(KUBECTL):
	mkdir -p $(dir $@)
	curl -sfL -o $@ https://dl.k8s.io/release/v$(KUBERNETES_VERSION)/bin/linux/amd64/kubectl
	chmod a+x $@

$(KUSTOMIZE):
	mkdir -p $(dir $@)
	curl -sfL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv$(KUSTOMIZE_VERSION)/kustomize_v$(KUSTOMIZE_VERSION)_linux_amd64.tar.gz | tar -xz -C $(BINDIR)
	chmod a+x $@
