CLUSTER_NAME := cilium-bgp-cp

KIND_VERSION := 0.20.0
KUBERNETES_VERSION := 1.28.0
CILIUM_VERSION := 1.14.1
CILIUM_CLI_VERSION := 0.15.7
KUSTOMIZE_VERSION := 5.1.1
CONTAINERLAB_VERSION := 0.44.3
HELM_VERSION := 3.12.3

SUDO ?= sudo

BINDIR := $(abspath $(PWD)/bin)
MANIFESTDIR := $(abspath $(PWD)/manifests)

KIND := $(BINDIR)/kind
KUBECTL := $(BINDIR)/kubectl
KUSTOMIZE := $(BINDIR)/kustomize
CONTAINERLAB := $(BINDIR)/containerlab
CILIUM_CLI := $(BINDIR)/cilium
HELM := $(BINDIR)/helm

export KUBECTL

KIND_CONFIG = kind-config.yaml
CONTAINERLAB_CONFIG = lab.yaml

CILIUM_DIR ?= /home/terassyi/workspace/cilium

.PHONY: setup
setup: $(KIND) $(KUBECTL) $(KUSTOMIZE) $(CILIUM_CLI) $(CONTAINERLAB) $(HELM)

.PHONY: start
start: setup
	$(SUDO) sysctl -w fs.inotify.max_user_instances=512
	$(SUDO) sysctl -w fs.inotify.max_user_watches=65536

	@echo "CREATE THE KIND CLUSTER"
	$(KIND) create cluster --image kindest/node:v$(KUBERNETES_VERSION) --config=$(KIND_CONFIG)

	@echo "CREATE TOPOLOGY"
	$(SUDO) $(CONTAINERLAB) -t $(CONTAINERLAB_CONFIG) deploy

	@echo "INSTALL CILIUM VIA HELM"
	$(HELM) repo add cilium https://helm.cilium.io/
	$(HELM) repo update
	$(HELM) install cilium cilium/cilium \
		--version $(CILIUM_VERSION) \
		--namespace kube-system \
		--set ipv6.enabled=true \
		--set bgpControlPlane.enabled=true \
		--set ipam.mode=kubernetes \
		--set k8s.requireIPv4PodCIDR=true \
		--set k8s.requireIPv6PodCIDR=true 
	sleep 3
	$(KUBECTL) -n kube-system wait --for=jsonpath='.status.readyReplicas'=2 --timeout=600s deploy/cilium-operator

	@echo "APPLY RESOURCES"
	sleep 3
	$(KUSTOMIZE) build $(MANIFESTDIR) | $(KUBECTL) apply -f -   

.PHONY:
stop:
	$(SUDO) $(CONTAINERLAB) -t $(CONTAINERLAB_CONFIG) destroy
	$(KIND) delete cluster

.PHONY: start-with-build
start-with-build:
	$(SUDO) sysctl -w fs.inotify.max_user_instances=512
	$(SUDO) sysctl -w fs.inotify.max_user_watches=65536

	@echo "CREATE THE KIND CLUSTER"
	$(KIND) create cluster --image kindest/node:v$(KUBERNETES_VERSION) --config=$(KIND_CONFIG)

	@echo "CREATE TOPOLOGY"
	$(SUDO) $(CONTAINERLAB) -t $(CONTAINERLAB_CONFIG) deploy

	@echo "BUILD CILIUM"
	$(MAKE) -C $(CILIUM_DIR) kind-image

	@echo "INSTALL CILIUM"
	$(CILIUM_CLI) install --wait \
    --chart-directory=$(CILIUM_DIR)/install/kubernetes/cilium \
    --helm-set=image.repository=localhost:5000/cilium/cilium-dev \
    --helm-set=image.useDigest=false \
    --helm-set=image.tag=local \
    --helm-set=operator.image.repository=localhost:5000/cilium/operator \
    --helm-set=operator.image.suffix="" \
    --helm-set=operator.image.tag=local \
    --helm-set=operator.image.useDigest=false \
    --helm-set=hubble.relay.image.repository=localhost:5000/cilium/hubble-relay \
    --helm-set=hubble.relay.image.tag=local \
    --helm-set=hubble.relay.image.useDigest=false \
    --helm-set=hubble.eventBufferCapacity=65535 \
    --helm-set=bpf.monitorAggregation=none \
    --helm-set=bgpControlPlane.enabled=true \
    --nodes-without-cilium=kind-worker3 \
    --helm-set-string=kubeProxyReplacement=strict \
    --helm-set-string=routingMode=native \
    --helm-set-string=autoDirectNodeRoutes=true \
    --helm-set-string=ipv4NativeRoutingCIDR=10.244.0.0/16 \
    --helm-set-string=tunnel=disabled \
    --helm-set-string=ipv6NativeRoutingCIDR=fd00:10:244::/56 \
    --helm-set-string=loadBalancer.acceleration=disabled \
    --helm-set-string=loadBalancer.mode=dsr \
    --helm-set-string=loadBalancer.dsrDispatch=geneve \
    --helm-set-string=loadBalancer.dsrL4Translate=backend \
    --helm-set=bpf.masquerade=true \
    --helm-set=enableIPv6Masquerade=false \
    --helm-set=debug.enabled=true \
    --helm-set=ipv6.enabled=true \
    --helm-set-string=devices=eth+

	@echo "CREATE RESOURCES"
	sleep 3
	$(KUSTOMIZE) build $(MANIFESTDIR) | $(KUBECTL) apply -f -   

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
