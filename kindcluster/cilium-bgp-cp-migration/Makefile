CLUSTER_NAME := cilium-bgp-cp

KIND_VERSION := 0.26.0
KUBERNETES_VERSION := 1.32.0
CILIUM_VERSION := 1.15.12
CILIUM_CLI_VERSION := 0.16.23
KUSTOMIZE_VERSION := 5.6.0
CONTAINERLAB_VERSION := 0.61.0
HELM_VERSION := 3.17.0

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

	$(KUBECTL) label --overwrite nodes kind-control-plane bgp-policy=test-policy
	$(KUBECTL) label --overwrite nodes kind-worker bgp-policy=test-policy
	$(KUBECTL) label --overwrite nodes kind-worker2 bgp-policy=test-policy
	$(KUBECTL) label --overwrite nodes kind-worker3 bgp-policy=test-policy

	@echo "CREATE TOPOLOGY"
	$(SUDO) $(CONTAINERLAB) -t $(CONTAINERLAB_CONFIG) deploy

	@echo "INSTALL CILIUM VIA HELM"
	$(KUSTOMIZE) build $(MANIFESTDIR)/metallb | $(KUBECTL) apply -f -

	$(HELM) repo add cilium https://helm.cilium.io/
	$(HELM) repo update
	$(HELM) install cilium cilium/cilium \
		--version $(CILIUM_VERSION) \
		--namespace kube-system \
		--set debug.enabled=true \
		--set debug.verbose=lbipam \
		--set bgp.enabled=true \
		--set bgp.announce.loadbalancerIP=true \
		--set bgpControlPlane.enabled=false \
		--set ipam.mode=kubernetes \
		--set k8s.requireIPv4PodCIDR=true \
	    --set operator.replicas=1
	sleep 3
	$(KUBECTL) -n kube-system wait --for=jsonpath='.status.readyReplicas'=1 --timeout=600s deploy/cilium-operator

	@echo "APPLY RESOURCES"
	sleep 1
	$(KUSTOMIZE) build $(MANIFESTDIR)/common | $(KUBECTL) apply -f -

.PHONY: migrate
migrate:
	# $(CILIUM_CLI) config set enable-bgp-control-plane true
	$(KUBECTL) apply -f $(MANIFESTDIR)/bgp-cp/cilium_config.yaml
	$(KUBECTL) -n kube-system rollout restart deploy/cilium-operator
	sleep 5
	$(KUBECTL) -n kube-system wait --for=jsonpath='.status.readyReplicas'=2 --timeout=600s deploy/cilium-operator
	sleep 5

	$(KUSTOMIZE) build $(MANIFESTDIR)/bgp-cp | $(KUBECTL) apply -f -
	sleep 5

	$(KUBECTL) -n kube-system patch ds/cilium -p '{"spec":{"updateStrategy":{"rollingUpdate":{"maxUnavailable":1}}}}'
	sleep 1
	$(KUBECTL) -n kube-system rollout restart ds/cilium

	# $(HELM) upgrade cilium cilium/cilium \
	# 	--version $(CILIUM_VERSION) \
	# 	--namespace kube-system \
	# 	--set bgp.enabled=false \
	# 	--set bgp.announce.loadbalancerIP=false \
	# 	--set bgpControlPlane.enabled=true \
	# 	--set ipam.mode=kubernetes \
	# 	--set k8s.requireIPv4PodCIDR=true

	sleep 1
	$(KUSTOMIZE) build $(MANIFESTDIR)/after | $(KUBECTL) apply -f -

.PHONY: apply-bgp-cp
apply-bgp-cp:
	$(KUBECTL) api-resources | tee tmp.txt
	$(KUSTOMIZE) build $(MANIFESTDIR)/bgp-cp | $(KUBECTL) apply -f -

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

	$(KUBECTL) label --overwrite nodes kind-control-plane bgp-policy=test-policy
	$(KUBECTL) label --overwrite nodes kind-worker bgp-policy=test-policy
	$(KUBECTL) label --overwrite nodes kind-worker2 bgp-policy=test-policy
	$(KUBECTL) label --overwrite nodes kind-worker3 bgp-policy=test-policy

	@echo "CREATE TOPOLOGY"
	$(SUDO) $(CONTAINERLAB) -t $(CONTAINERLAB_CONFIG) deploy

	@echo "BUILD CILIUM"
	$(MAKE) -C $(CILIUM_DIR) kind-image

	@echo "INSTALL CILIUM VIA HELM"
	$(KUSTOMIZE) build $(MANIFESTDIR)/metallb | $(KUBECTL) apply -f -

	@echo "INSTALL CILIUM"
	$(HELM) install cilium cilium/cilium \
		--version $(CILIUM_VERSION) \
		--set image.repository=localhost:5000/cilium/cilium-dev \
		--set image.tag=local \
		--set image.useDigest=false \
		--set operator.image.repository=localhost:5000/cilium/operator \
		--set operator.image.tag=local \
		--set operator.image.useDigest=false \
		--set hubble.relay.image.repository=localhost:5000/cilium/hubble-relay \
		--set hubble.relay.image.tag=local \
		--set hubble.relay.image.useDigest=false \
		--namespace kube-system \
		--set debug.enabled=true \
		--set debug.verbose=lbipam \
		--set bgp.enabled=true \
		--set bgp.announce.loadbalancerIP=true \
		--set bgpControlPlane.enabled=false \
		--set ipam.mode=kubernetes \
		--set k8s.requireIPv4PodCIDR=true \
		--set operator.replicas=1

	@echo "CREATE RESOURCES"
	sleep 3
	$(KUBECTL) -n kube-system wait --for=jsonpath='.status.readyReplicas'=1 --timeout=600s deploy/cilium-operator

	@echo "APPLY RESOURCES"
	sleep 1
	$(KUSTOMIZE) build $(MANIFESTDIR)/common | $(KUBECTL) apply -f -

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
