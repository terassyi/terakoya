KIND_VERSION=0.26.0
KUBERNETES_VERSION=1.30.8
KUSTOMIZE_VERSION = 5.5.0
BINDIR := $(abspath $(PWD)/bin)
TMPDIR := $(abspath $(PWD)/tmp)

KIND := $(BINDIR)/kind
KUBECTL := $(BINDIR)/kubectl
KUSTOMIZE := $(BINDIR)/kustomize
export KUBECTL

KIND_CONFIG := kind-config.yaml

.PHONY: start
start: $(KIND) $(KUBECTL) $(KUSTOMIZE)
	$(KIND) create cluster --image kindest/node:v$(KUBERNETES_VERSION) --name coil --config $(KIND_CONFIG)

.PHONY: stop
stop: $(KIND)
	$(KIND) delete cluster --name coil

.PHONY: setup-nodes
setup-nodes:
	$(KUBECTL) taint nodes coil-worker test:NoSchedule
	$(KUBECTL) taint nodes coil-worker2 test:NoSchedule
	$(KUBECTL) label nodes coil-worker test=coil
	$(KUBECTL) label nodes coil-worker2 test=coil

.PHONY: install-coil-2.8.0
install-coil-2.8.0: coil-2.8.0/coil.yaml setup-nodes
	$(KUSTOMIZE) build coil-2.8.0/ | $(KUBECTL) apply -f -
	$(KUBECTL) -n kube-system wait --timeout=3m --for=condition=available deployment/coil-controller

.PHONY: install-coil-standalone-egress
install-coil-standalone-egress: coil-standalone-egress/coil.yaml
	$(MAKE) -C $(TMPDIR)/coil/v2 image
	$(KIND) load docker-image coil:dev --name coil
	$(KUBECTL) apply -f coil-standalone-egress/coil.yaml
	$(KUBECTL) -n kube-system wait --timeout=3m --for=condition=available deployment/coil-egress-controller
	$(KUBECTL) -n kube-system wait --timeout=3m --for=condition=available deployment/coil-egress-controller
	$(KUBECTL) rollout status daemonset coild -n kube-system --timeout=3m

.PHONY: run-e2e
run-e2e: cp-binary
	$(MAKE) -C $(TMPDIR)/coil/v2/e2e test TEST_IPAM=true TEST_EGRESS=true

.PHONY: test
test:
	go test -count 1 -v . -args -ginkgo.progress -ginkgo.v

.PHONY: coil-2.8.0/coil.yaml
coil-2.8.0/coil.yaml: clean-tmp $(TMPDIR)/coil
	mkdir -p coil-2.8.0
	cd $(TMPDIR)/coil/v2; \
	git checkout v2.8.0; \
	$(MAKE) certs; \
	$(KUSTOMIZE) build --load-restrictor=LoadRestrictionsNone e2e/ > $(PWD)/coil-2.8.0/coil.yaml

.PHONY: coil-standalone-egress/coil.yaml
coil-standalone-egress/coil.yaml: clean-tmp $(TMPDIR)/coil
	mkdir -p coil-standalone-egress
	cd $(TMPDIR)/coil/v2; \
	git switch main; \
	$(MAKE) certs; \
	$(KUSTOMIZE) build --load-restrictor=LoadRestrictionsNone e2e/ > $(PWD)/coil-standalone-egress/coil.yaml


.PHONY: $(TMPDIR)/coil
$(TMPDIR)/coil: $(TMPDIR)/coil/README.md

$(TMPDIR)/coil/README.md:
	mkdir -p tmp
	git clone https://github.com/cybozu-go/coil.git tmp/coil

.PHONY: cp-binary
cp-binary:
	mkdir -p tmp/coil/v2/bin
	cp bin/kubectl tmp/coil/v2/bin/kubectl
	cp bin/kustomize tmp/coil/v2/bin/kustomize

.PHONY: clean-tmp
clean-tmp:
	rm -rf $(TMPDIR)

.PHONY: clean
clean: clean-tmp
	$(MAKE) stop || true
	rm coil-2.8.0/coil.yaml || true
	rm coil-standalone-egress/coil.yaml || true


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
