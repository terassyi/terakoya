CLUSTER_NAME := coil-sart

KIND_VERSION=0.19.0
KUBERNETES_VERSION=1.27.2
KUSTOMIZE_VERSION =5.0.3
GOBGP_VERSION := 3.15.0
CERT_MANAGER_VERSION := 1.12.1
COIL_VERSION ?= 2.3.0
SART_VERSION ?= 0.0.4

SUDO ?= sudo

BINDIR := $(abspath $(PWD)/../bin)
TMPDIR := $(abspath $(PWD)/../tmp)
MANIFESTDIR := $(abspath $(PWD)/manifests)

KIND := $(BINDIR)/kind
KUBECTL := $(BINDIR)/kubectl
KUSTOMIZE := $(BINDIR)/kustomize
export KUBECTL

KIND_CONFIG = kind-config.yaml

EXTERNAL_BGP_ASN ?= 65000
NODE0_ASN ?= 65000
NODE1_ASN ?= 65000
NODE2_ASN ?= 65000
NODE3_ASN ?= 65000
EXTERNAL_BGP_ADDR ?= ""
NODE0_ADDR ?= ""
NODE1_ADDR ?= ""
NODE2_ADDR ?= ""
NODE3_ADDR ?= ""
CLIENT_ADDR ?= ""
LB_CIDR ?= 10.69.0.0/24
ESCAPED_LB_CIDR ?= "10.69.0.0\/24"
ANOTHER_LB_CIDR ?= 10.69.10.0/24
ANOTHER_ESCAPED_LB_CIDR ?= "10.69.10.0\/24"

.PHONY: start
start: $(KIND) $(KUBECTL) $(KUSTOMIZE)
	${SUDO} sysctl -w fs.inotify.max_user_instances=512
	${SUDO} sysctl -w fs.inotify.max_user_watches=65536

	$(KIND) create cluster --image kindest/node:v$(KUBERNETES_VERSION) --name $(CLUSTER_NAME) --config $(KIND_CONFIG)

	$(KUBECTL) label nodes --overwrite $(CLUSTER_NAME)-control-plane sart.terassyi.net/asn=${NODE0_ASN}
	$(KUBECTL) label nodes --overwrite $(CLUSTER_NAME)-worker sart.terassyi.net/asn=${NODE1_ASN}
	$(KUBECTL) label nodes --overwrite $(CLUSTER_NAME)-worker2 sart.terassyi.net/asn=${NODE2_ASN}
	$(KUBECTL) label nodes --overwrite $(CLUSTER_NAME)-worker3 sart.terassyi.net/asn=${NODE3_ASN}

	$(eval NODE0_ADDR = $(shell $(KUBECTL) get nodes $(CLUSTER_NAME)-control-plane -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'))
	$(eval NODE1_ADDR = $(shell $(KUBECTL) get nodes $(CLUSTER_NAME)-worker -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'))
	$(eval NODE2_ADDR = $(shell $(KUBECTL) get nodes $(CLUSTER_NAME)-worker2 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'))
	$(eval NODE3_ADDR = $(shell $(KUBECTL) get nodes $(CLUSTER_NAME)-worker3 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'))

	docker run -d --privileged --network kind  --rm --ulimit core=-1 --name external-bgp --volume `pwd`/external-bgp/frr:/etc/frr/ ghcr.io/terassyi/terakoya:0.1.2 tail -f /dev/null
	docker run -d --privileged --network kind --rm --name external-client ghcr.io/terassyi/terakoya:0.1.2 tail -f /dev/null

	$(MAKE) install-coil
	$(KUBECTL) apply -f $(MANIFESTDIR)/pod/test-pod.yaml

	# make configure

.PHONY: configure
configure:
	docker exec external-bgp /usr/lib/frr/frrinit.sh start

	$(eval NODE0_ADDR = $(shell $(KUBECTL) get nodes $(CLUSTER_NAME)-control-plane -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'))
	$(eval NODE1_ADDR = $(shell $(KUBECTL) get nodes $(CLUSTER_NAME)-worker -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'))
	$(eval NODE2_ADDR = $(shell $(KUBECTL) get nodes $(CLUSTER_NAME)-worker2 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'))
	$(eval NODE3_ADDR = $(shell $(KUBECTL) get nodes $(CLUSTER_NAME)-worker3 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'))
	$(eval EXTERNAL_BGP_ADDR = $(shell docker inspect external-bgp | jq '.[0].NetworkSettings.Networks.kind.IPAddress' | tr -d '"'))

	sed -e s/NODE0_ASN/${NODE0_ASN}/g -e s/NODE1_ASN/${NODE1_ASN}/g -e s/NODE2_ASN/${NODE2_ASN}/g -e s/NODE3_ASN/${NODE3_ASN}/g \
		-e s/EXTERNAL_BGP_ASN/${EXTERNAL_BGP_ASN}/g \
		-e s/EXTERNAL_BGP_ADDR/${EXTERNAL_BGP_ADDR}/g \
		-e s/NODE0_ADDR/${NODE0_ADDR}/g -e s/NODE1_ADDR/${NODE1_ADDR}/g -e s/NODE2_ADDR/${NODE2_ADDR}/g -e s/NODE3_ADDR/${NODE3_ADDR}/g \
		./external-bgp/frr/gobgp.conf.tmpl > ./external-bgp/frr/gobgp.conf

	sed -e s/LB_CIDR/'${ESCAPED_LB_CIDR}'/g \
		./manifests/templates/addresspool.yaml.tmpl > ./manifests/addresspool.yaml

	sed -e s/ANOTHER_LB_CIDR/'${ANOTHER_ESCAPED_LB_CIDR}'/g \
		./manifests/templates/another_addresspool.yaml.tmpl > ./manifests/another_addresspool.yaml

	sed -e s/EXTERNAL_BGP_ASN/${EXTERNAL_BGP_ASN}/g -e s/EXTERNAL_BGP_ADDR/${EXTERNAL_BGP_ADDR}/g \
		./manifests/templates/peer.yaml.tmpl > ./manifests/peer.yaml

	docker exec -d external-bgp gobgpd -f /etc/frr/gobgp.conf
	docker exec external-client ip route add ${LB_CIDR} via ${EXTERNAL_BGP_ADDR}
	docker exec external-client ip route add ${ANOTHER_LB_CIDR} via ${EXTERNAL_BGP_ADDR}


.PHONY: install
install: install-cert-manager
	$(KIND) load docker-image --name $(CLUSTER_NAME) sart:dev
	$(KIND) load docker-image --name $(CLUSTER_NAME) sart-controller:dev
	$(KIND) load docker-image --name $(CLUSTER_NAME) test-app:dev
	$(KUSTOMIZE) build --load-restrictor=LoadRestrictionsNone . | $(KUBECTL) apply -f -
	$(KUBECTL) -n kube-system wait --timeout=3m --for=condition=available deployment/sart-controller

.PHONY: install-cert-manager
install-cert-manager:
	$(KUBECTL) apply -f https://github.com/jetstack/cert-manager/releases/download/v$(CERT_MANAGER_VERSION)/cert-manager.yaml
	$(KUBECTL) -n cert-manager wait --for=condition=available --timeout=180s --all deployments

.PHONY: install-coil
install-coil: clone-coil-repo
	mkdir -p $(MANIFESTDIR)/coil

	cd $(TMPDIR)/coil/v2; \
	make certs && \
	$(KUSTOMIZE) build . > $(MANIFESTDIR)/coil/coil.yaml
	$(KUBECTL) apply -f $(MANIFESTDIR)/coil/coil.yaml
	$(KUBECTL) -n kube-system wait --for=condition=available --timeout=180s deployment/coil-controller
	$(KUBECTL) apply -f $(MANIFESTDIR)/coil/addresspool.yaml

.PHONY: clone-coil-repo
clone-coil-repo:
	mkdir -p $(TMPDIR)
	if [ -d "$(TMPDIR)/coil" ]; then \
        cd $(TMPDIR)/coil; git fetch origin; git checkout v$(COIL_VERSION); \
    else \
		cd $(TMPDIR); git clone https://github.com/cybozu-go/coil.git; cd coil; git checkout v$(COIL_VERSION); \
    fi

.PHONY: stop
stop: $(KIND)
	$(KIND) delete cluster --name $(CLUSTER_NAME)
	docker rm -f external-bgp
	docker rm -f external-client

.PHONY: logs
logs:
	rm -rf logs.tar.gz logs
	$(KIND) export logs --name=coil ./logs
	tar czf logs.tar.gz logs
	rm -rf logs

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