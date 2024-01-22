CLUSTER_NAME := cilium-multi-pool

KIND_VERSION := 0.20.0
KUBERNETES_VERSION := 1.28.0
CILIUM_VERSION := 1.14.4
CILIUM_CLI_VERSION := 0.15.20
KUSTOMIZE_VERSION := 5.3.0
HELM_VERSION := 3.14.0
KUBEROUTER_VERSION := 2.0.1

SUDO ?= sudo

BINDIR := $(abspath $(PWD)/bin)
MANIFESTDIR := $(abspath $(PWD)/manifests)
KUBEROUTERDIR := $(MANIFESTDIR)/kuberouter
KUBEROUTER_MANIFEST := $(KUBEROUTERDIR)/generic-kuberouter-only-advertise-routes.yaml

KIND := $(BINDIR)/kind
KUBECTL := $(BINDIR)/kubectl
KUSTOMIZE := $(BINDIR)/kustomize
CONTAINERLAB := $(BINDIR)/containerlab
CILIUM_CLI := $(BINDIR)/cilium
HELM := $(BINDIR)/helm

export KUBECTL

KIND_CONFIG = kind-config.yaml

CILIUM_DIR ?= /home/terassyi/workspace/cilium

.PHONY: setup
setup: $(KIND) $(KUBECTL) $(KUSTOMIZE) $(CILIUM_CLI) $(CONTAINERLAB) $(HELM)

.PHONY: start
start: setup $(KUBEROUTER_MANIFEST)
	$(SUDO) sysctl -w fs.inotify.max_user_instances=512
	$(SUDO) sysctl -w fs.inotify.max_user_watches=65536

	@echo "CREATE THE KIND CLUSTER"
	$(KIND) create cluster --image kindest/node:v$(KUBERNETES_VERSION) --config=$(KIND_CONFIG)

	#echo "DEPLOY KUBEROUTER"
	$(KUSTOMIZE) build $(KUBEROUTERDIR) | $(KUBECTL) apply -f -

	@echo "INSTALL CILIUM VIA HELM"
	$(HELM) repo add cilium https://helm.cilium.io/
	$(HELM) repo update
	$(HELM) install cilium cilium/cilium \
		--version $(CILIUM_VERSION) \
		--namespace kube-system \
		--set routingMode=native \
		--set ipam.mode=multi-pool \
		--set autoDirectNodeRoutes=true \
		--set ipv4NativeRoutingCIDR="10.0.0.0/8" \
		--set enableIPv4Masquerade=true \
		--set endpointRoutes.enabled=true \
		--set tunnel=disabled \
		--set kubeProxyReplacement=true \
		--set bpf.masquerade=true \
		--set ipam.operator.autoCreateCiliumPodIPPools.default.ipv4.cidrs='{10.10.0.0/16}' \
		--set ipam.operator.autoCreateCiliumPodIPPools.default.ipv4.maskSize=27
	sleep 3
	$(KUBECTL) -n kube-system wait --for=jsonpath='.status.readyReplicas'=2 --timeout=600s deploy/cilium-operator

	@echo "APPLY RESOURCES"
	sleep 3
	$(KUSTOMIZE) build $(MANIFESTDIR) | $(KUBECTL) apply -f -

.PHONY:
stop:
	$(KIND) delete cluster

$(KUBEROUTER_MANIFEST):
	curl  -sfL -o $@ https://raw.githubusercontent.com/cloudnativelabs/kube-router/v$(KUBEROUTER_VERSION)/daemonset/generic-kuberouter-only-advertise-routes.yaml

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

$(CILIUM_CLI):
	mkdir -p $(dir $@)
	curl -sfL https://github.com/cilium/cilium-cli/releases/download/v$(CILIUM_CLI_VERSION)/cilium-linux-amd64.tar.gz | tar -xz -C $(BINDIR)
	chmod a+x $@

$(HELM):
	mkdir -p $(dir $@)
	curl -sfL https://get.helm.sh/helm-v$(HELM_VERSION)-linux-amd64.tar.gz | tar -zx -C $(BINDIR)
	cp $(BINDIR)/linux-amd64/helm $(BINDIR)
	chmod a+x $@
	rm -rf $(BINDIR)/linux-amd64
