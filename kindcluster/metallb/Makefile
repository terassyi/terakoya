CLUSTER_NAME := metallb

KIND_VERSION := 0.26.0
KUBERNETES_VERSION := 1.32.0
KUSTOMIZE_VERSION := 5.6.0
CONTAINERLAB_VERSION := 0.62.2
HELM_VERSION := 3.17.0
METALLB_VERSION := 0.14.9

SUDO ?= sudo

BINDIR := $(abspath $(PWD)/bin)
MANIFESTDIR := $(abspath $(PWD)/manifests)

KIND := $(BINDIR)/kind
KUBECTL := $(BINDIR)/kubectl
KUSTOMIZE := $(BINDIR)/kustomize
CONTAINERLAB := $(BINDIR)/containerlab
HELM := $(BINDIR)/helm

export KUBECTL

KIND_CONFIG = kind.yaml
CONTAINERLAB_CONFIG = lab.yaml

.PHONY: setup
setup: $(KIND) $(KUBECTL) $(KUSTOMIZE) $(CONTAINERLAB) $(HELM)

.PHONY: start
start: setup
	$(SUDO) sysctl -w fs.inotify.max_user_instances=512
	$(SUDO) sysctl -w fs.inotify.max_user_watches=65536

	@echo "CREATE THE KIND CLUSTER"
	$(KIND) create cluster --image kindest/node:v$(KUBERNETES_VERSION) --config=$(KIND_CONFIG)

	@echo "CREATE TOPOLOGY"
	$(SUDO) $(CONTAINERLAB) -t $(CONTAINERLAB_CONFIG) deploy

	@echo "INSTALL METALLB"
	$(MAKE) install-metallb
	$(KUBECTL) -n metallb-system wait --for=jsonpath='.status.readyReplicas'=1 --timeout=600s deploy/controller

	@echo "APPLY MANIFESTS"
	$(KUBECTL) create ns test
	$(KUSTOMIZE) build $(MANIFESTDIR) | $(KUBECTL) apply -f -

.PHONY: install-metallb
install-metallb:
	$(KUBECTL) apply -f https://raw.githubusercontent.com/metallb/metallb/v$(METALLB_VERSION)/config/manifests/metallb-native.yaml


.PHONY:
stop:
	$(SUDO) $(CONTAINERLAB) -t $(CONTAINERLAB_CONFIG) destroy
	$(KIND) delete cluster

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

$(CONTAINERLAB):
	mkdir -p $(dir $@)
	curl -sfL https://github.com/srl-labs/containerlab/releases/download/v$(CONTAINERLAB_VERSION)/containerlab_$(CONTAINERLAB_VERSION)_Linux_amd64.tar.gz | tar -xz -C $(BINDIR)
	chmod a+x $@

$(HELM):
	mkdir -p $(dir $@)
	curl -sfL https://get.helm.sh/helm-v$(HELM_VERSION)-linux-amd64.tar.gz | tar -zx -C $(BINDIR)
	cp $(BINDIR)/linux-amd64/helm $(BINDIR)
	chmod a+x $@
	rm -rf $(BINDIR)/linux-amd64
