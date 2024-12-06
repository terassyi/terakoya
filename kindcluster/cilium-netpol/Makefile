CLUSTER_NAME := cilium-netpol

KIND_VERSION := 0.25.0
KUBERNETES_VERSION := 1.31.2
CILIUM_VERSION := 1.16.3
CILIUM_CLI_VERSION := 0.16.20
KUSTOMIZE_VERSION := 5.5.0
HELM_VERSION := 3.16.3

SUDO ?= sudo

BINDIR := $(abspath $(PWD)/bin)
MANIFESTDIR := $(abspath $(PWD)/manifests)

KIND := $(BINDIR)/kind
KUBECTL := $(BINDIR)/kubectl
KUSTOMIZE := $(BINDIR)/kustomize
CILIUM_CLI := $(BINDIR)/cilium
HELM := $(BINDIR)/helm

export KUBECTL

KIND_CONFIG = kind-config.yaml

.PHONY: setup
setup: $(KIND) $(KUBECTL) $(KUSTOMIZE) $(CILIUM_CLI) $(HELM)

.PHONY: start
start: setup
	$(SUDO) sysctl -w fs.inotify.max_user_instances=512
	$(SUDO) sysctl -w fs.inotify.max_user_watches=65536

	@echo "CREATE THE KIND CLUSTER"
	$(KIND) create cluster --image kindest/node:v$(KUBERNETES_VERSION) --config=$(KIND_CONFIG)

	@echo "INSTALL CILIUM VIA HELM"
	$(HELM) repo add cilium https://helm.cilium.io/
	$(HELM) repo update
	$(HELM) install cilium cilium/cilium \
		--version $(CILIUM_VERSION) \
		--namespace kube-system \
		--set k8sServiceHost=kind-control-plane \
		--set k8sServicePort=6443 \
		--set hostPort.enabled=true \
		--set nodePort.enabled=true \
		--set bgpControlPlane.enabled=true \
		--set ipam.mode=kubernetes \
		--set k8s.requireIPv4PodCIDR=true \
		--set devices=eth+ \
		--set kubeProxyReplacement=true \
		--set routingMode=native \
		--set autoDirectNodeRoutes=true \
		--set ipv4NativeRoutingCIDR=10.244.0.0/16 \
		--set loadBalancer.mode=dsr \
		--set loadBalancer.dsrDispatch=opt \
		--set loadBalancer.dsrL4Translate=backend \
		--set loadBalancer.acceleration=disabled \
		--set loadBalancer.algorithm=maglev
	sleep 3
	$(KUBECTL) -n kube-system wait --for=jsonpath='.status.readyReplicas'=2 --timeout=600s deploy/cilium-operator

	@echo "APPLY MANIFESTS"
	$(KUSTOMIZE) build $(MANIFESTDIR) | $(KUBECTL) apply -f -

.PHONY:
netpol:
	$(KUSTOMIZE) build $(MANIFESTDIR)/netpol | $(KUBECTL) apply -f -

.PHONY:
stop:
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
