CLUSTER_NAME := coil-sart

KIND_VERSION=0.18.0
KUBERNETES_VERSION=1.26.4
KUSTOMIZE_VERSION =5.0.3
GOBGP_VERSION := 3.15.0
CERT_MANAGER_VERSION := 1.12.1
COIL_VERSION ?= 2.3.0
SART_VERSION ?= 0.0.5

SUDO ?= sudo

BINDIR := $(abspath $(PWD)/../bin)
TMPDIR := $(abspath $(PWD)/../tmp)
MANIFESTDIR := $(abspath $(PWD)/manifests)

KIND := $(BINDIR)/kind
KUBECTL := $(BINDIR)/kubectl
KUSTOMIZE := $(BINDIR)/kustomize
export KUBECTL

KIND_CONFIG = kind-config.yaml

NODES ?= 4
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
POD_CIDR ?= 10.100.0.0/16
ESCAPED_POD_CIDR ?= "10.100.0.0\/16"
EGRESS_CIDR ?= 10.68.0.0/24
ESCAPED_EGRESS_CIDR ?= "10.68.0.0\/24"
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

	$(MAKE) configure
	$(MAKE) install-sart
	$(MAKE) install-coil

	$(KUBECTL) -n kube-system wait --for=condition=available --timeout=180s deployment/sart-controller
	$(KUSTOMIZE) build $(MANIFESTDIR)/sart | $(KUBECTL) apply -f -

	$(KUBECTL) -n kube-system wait --for=jsonpath={.status.numberAvailable}=$(NODES) --timeout=180s daemonset/sartd
	
	$(KUSTOMIZE) build $(MANIFESTDIR)/resources | $(KUBECTL) apply -f -


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
	
	sed -e s/POD_CIDR/${ESCAPED_POD_CIDR}/g \
		-e s/EGRESS_CIDR/${ESCAPED_EGRESS_CIDR}/g \
		$(MANIFESTDIR)/coil/addresspool.yaml.tmpl > $(MANIFESTDIR)/coil/addresspool.yaml

	docker exec -d external-bgp gobgpd -f /etc/frr/gobgp.conf

	docker exec $(CLUSTER_NAME)-control-plane ip route add $(POD_CIDR) via $(EXTERNAL_BGP_ADDR) dev eth0
	docker exec $(CLUSTER_NAME)-worker ip route add $(POD_CIDR) via $(EXTERNAL_BGP_ADDR) dev eth0
	docker exec $(CLUSTER_NAME)-worker2 ip route add $(POD_CIDR) via $(EXTERNAL_BGP_ADDR) dev eth0
	docker exec $(CLUSTER_NAME)-worker3 ip route add $(POD_CIDR) via $(EXTERNAL_BGP_ADDR) dev eth0

	docker exec $(CLUSTER_NAME)-control-plane ip route add $(EGRESS_CIDR) via $(EXTERNAL_BGP_ADDR) dev eth0
	docker exec $(CLUSTER_NAME)-worker ip route add $(EGRESS_CIDR) via $(EXTERNAL_BGP_ADDR) dev eth0
	docker exec $(CLUSTER_NAME)-worker2 ip route add $(EGRESS_CIDR) via $(EXTERNAL_BGP_ADDR) dev eth0
	docker exec $(CLUSTER_NAME)-worker3 ip route add $(EGRESS_CIDR) via $(EXTERNAL_BGP_ADDR) dev eth0

	docker exec $(CLUSTER_NAME)-control-plane iptables -t nat -A POSTROUTING -s $(EGRESS_CIDR) -j MASQUERADE 
	docker exec $(CLUSTER_NAME)-worker iptables -t nat -A POSTROUTING -s $(EGRESS_CIDR) -j MASQUERADE 
	docker exec $(CLUSTER_NAME)-worker2 iptables -t nat -A POSTROUTING -s $(EGRESS_CIDR) -j MASQUERADE 
	docker exec $(CLUSTER_NAME)-worker3 iptables -t nat -A POSTROUTING -s $(EGRESS_CIDR) -j MASQUERADE 

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
	$(KUBECTL) apply -f $(MANIFESTDIR)/coil/egress.yaml

.PHONY: clone-coil-repo
clone-coil-repo:
	mkdir -p $(TMPDIR)
	if [ -d "$(TMPDIR)/coil" ]; then \
        cd $(TMPDIR)/coil; git fetch origin; git checkout v$(COIL_VERSION); \
    else \
		cd $(TMPDIR); git clone https://github.com/cybozu-go/coil.git; cd coil; git checkout v$(COIL_VERSION); \
    fi

.PHONY: clean-coil
clean-coil:
	rm $(MANIFESTDIR)/coil/coil.yaml || true
	rm $(MANIFESTDIR)/coil/addresspool.yaml || true

.PHONY: install-sart
install-sart: install-sart-manifests generate-sart-webhook-certificate

	$(eval NODE0_ADDR = $(shell $(KUBECTL) get nodes $(CLUSTER_NAME)-control-plane -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'))
	$(eval NODE1_ADDR = $(shell $(KUBECTL) get nodes $(CLUSTER_NAME)-worker -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'))
	$(eval NODE2_ADDR = $(shell $(KUBECTL) get nodes $(CLUSTER_NAME)-worker2 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'))
	$(eval NODE3_ADDR = $(shell $(KUBECTL) get nodes $(CLUSTER_NAME)-worker3 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'))
	$(eval EXTERNAL_BGP_ADDR = $(shell docker inspect external-bgp | jq '.[0].NetworkSettings.Networks.kind.IPAddress' | tr -d '"'))

	sed -e s/LB_CIDR/'${ESCAPED_LB_CIDR}'/g \
		./manifests/sart/addresspool.yaml.tmpl > ./manifests/sart/addresspool.yaml

	sed -e s/EXTERNAL_BGP_ASN/${EXTERNAL_BGP_ASN}/g -e s/EXTERNAL_BGP_ADDR/${EXTERNAL_BGP_ADDR}/g \
		-e s/CLUSTER_NAME/${CLUSTER_NAME}/g \
		./manifests/sart/bgp.yaml.tmpl > ./manifests/sart/bgp.yaml

	$(KUSTOMIZE) build $(MANIFESTDIR)/sart/controller | $(KUBECTL) apply -f -

.PHONY: install-sart-manifests
install-sart-manifests:
	curl -sfL -o $(MANIFESTDIR)/sart/controller/controller.yaml https://github.com/terassyi/sart/releases/download/v$(SART_VERSION)/sart-controller.yaml

.PHONY: clean-sart
clean-sart:
	rm $(MANIFESTDIR)/sart/bgp.yaml || true
	rm $(MANIFESTDIR)/sart/addresspool.yaml || true
	rm $(MANIFESTDIR)/sart/bgp-config-$(CLUSTER_NAME)-control-plane.yaml || true
	rm $(MANIFESTDIR)/sart/bgp-config-$(CLUSTER_NAME)-worker.yaml || true
	rm $(MANIFESTDIR)/sart/bgp-config-$(CLUSTER_NAME)-worker2.yaml || true
	rm $(MANIFESTDIR)/sart/bgp-config-$(CLUSTER_NAME)-worker3.yaml || true

.PHONY: generate-sart-webhook-certificate
generate-sart-webhook-certificate: install-gencert $(MANIFESTDIR)/sart/controller/key.pem $(MANIFESTDIR)/sart/controller/sart-webhook-certificate-patch.yaml

.PHONY: install-gencert
install-gencert:
	go install github.com/cybozu-go/coil/v2/cmd/gencert@v$(COIL_VERSION)

$(MANIFESTDIR)/sart/controller/key.pem:
	gencert --host webhook-service.kube-system.svc --outdir $(MANIFESTDIR)/sart/controller

$(MANIFESTDIR)/sart/controller/sart-webhook-certificate-patch.yaml: $(MANIFESTDIR)/sart/controller/cert.pem $(MANIFESTDIR)/sart/controller/sart-webhook-certificate-patch.yaml.tmpl
	sed "s/%CACERT%/$$(base64 -w0 < $<)/g" $@.tmpl > $@

.PHONY: clean-sart-webhook-certificate
clean-sart-webhook-certificate:
	rm $(MANIFESTDIR)/sart/controller/cert.pem || true
	rm $(MANIFESTDIR)/sart/controller/key.pem || true
	rm $(MANIFESTDIR)/sart/controller/sart-webhook-certificate-patch.yaml || true

.PHONY: stop
stop: $(KIND) clean
	$(KIND) delete cluster --name $(CLUSTER_NAME)
	docker rm -f external-bgp
	docker rm -f external-client

.PHONY: clean
clean: clean-coil clean-sart clean-sart-webhook-certificate

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
