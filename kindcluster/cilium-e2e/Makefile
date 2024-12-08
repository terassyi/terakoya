
CILIUM_VERSION := 1.16.4
KIND_VERSION := 0.25.0
KUBERNETES_VERSION := 1.31.2
CILIUM_CLI_VERSION := 0.16.21
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

.PHONY: setup
setup: $(KIND) $(KUBECTL) $(KUSTOMIZE) $(CILIUM_CLI) $(HELM) clone-cilium

.PHONY: clone-cilium
clone-cilium: cilium/VERSION

.PHONY: start
start:
	cd cilium && \
	git fetch origin && \
	git checkout v${CILIUM_VERSION}

	@echo "START KIND CLUSTER"
	cilium/contrib/scripts/kind.sh "1" "3" "" "kindest/node:v$(KUBERNETES_VERSION)" "none" "ipv4"
	$(KUBECTL) label node kind-worker3 --overwrite cilium.io/no-schedule=true
	$(MAKE) -C cilium kind-image
	$(CILIUM_CLI) install --wait \
		--chart-directory=$(PWD)/cilium/install/kubernetes/cilium \
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
		--helm-set=authentication.mutual.spire.enabled=false \
		--helm-set=authentication.mutual.spire.install.enabled=false \
		--helm-set=kubeProxyReplacement=true \
		--helm-set-string=routingMode=native \
		--helm-set-string=tunnelProtocol=geneve \
		--helm-set-string=autoDirectNodeRoutes=true \
		--helm-set-string=ipv4NativeRoutingCIDR=10.244.0.0/16 \
		--helm-set-string=loadBalancer.acceleration=disabled \
		--helm-set-string=loadBalancer.mode=dsr \
		--helm-set-string=loadBalancer.algorithm=maglev \
		--helm-set-string=loadBalancer.dsrDispatch=geneve \
		--helm-set-string=loadBalancer.dsrL4Translate=backend \
		--helm-set-string=conntrackGCInterval=30s \
		--helm-set-string=devices=eth+ \
		--helm-set=bpf.masquerade=true \
		--helm-set=ipv6.disabled=true \
		--helm-set=enableIPv6Masquerade=false \
		--helm-set=debug.enabled=true \
		--helm-set=hostPort.enabled=true \
		--helm-set=nodePort.enabled=true \
		--nodes-without-cilium

.PHONY: connectivity-test
connectivity-test:
	$(CILIUM_CLI) connectivity test --include-unsafe-tests --collect-sysdump-on-failure

.PHONY: apply
apply:
	$(KUSTOMIZE) build $(MANIFESTDIR) | $(KUBECTL) apply -f -

.PHONY: stop
stop:
	cilium/contrib/scripts/kind-down.sh

cilium/VERSION:
	git clone https://github.com/cilium/cilium.git

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
