CLUSTER_NAME := cilium-sart

KIND_VERSION=0.18.0
KUBERNETES_VERSION=1.26.4
KUSTOMIZE_VERSION =5.0.3
HELM_VERSION := 3.12.1
GOBGP_VERSION := 3.15.0
CERT_MANAGER_VERSION := 1.12.1
CILIUM_VERSION ?= 1.13.4
SART_VERSION ?= 0.0.5

SUDO ?= sudo

BINDIR := $(abspath $(PWD)/../bin)
TMPDIR := $(abspath $(PWD)/../tmp)
MANIFESTDIR := $(abspath $(PWD)/manifests)

KIND := $(BINDIR)/kind
KUBECTL := $(BINDIR)/kubectl
KUSTOMIZE := $(BINDIR)/kustomize
HELM := $(BINDIR)/helm
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
start: $(KIND) $(KUBECTL) $(KUSTOMIZE) $(HELM)
	${SUDO} sysctl -w fs.inotify.max_user_instances=512
	${SUDO} sysctl -w fs.inotify.max_user_watches=65536

	$(KIND) create cluster --image kindest/node:v$(KUBERNETES_VERSION) --name $(CLUSTER_NAME) --config $(KIND_CONFIG)

	docker pull quay.io/cilium/cilium:v$(CILIUM_VERSION)
	docker pull ghcr.io/terassyi/sart:$(SART_VERSION)
	docker pull ghcr.io/terassyi/sart-controller:$(SART_VERSION)

	$(KIND) load docker-image --name $(CLUSTER_NAME) quay.io/cilium/cilium:v$(CILIUM_VERSION)
	$(KIND) load docker-image --name $(CLUSTER_NAME) ghcr.io/terassyi/sart:$(SART_VERSION)
	$(KIND) load docker-image --name $(CLUSTER_NAME) sart:dev
	$(KIND) load docker-image --name $(CLUSTER_NAME) ghcr.io/terassyi/sart-controller:$(SART_VERSION)

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
	$(MAKE) install-cilium
	$(MAKE) install-cert-manager
	$(MAKE) install-sart


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

.PHONY: install-cilium
install-cilium:
	$(HELM) repo add cilium https://helm.cilium.io/
	$(HELM) install cilium cilium/cilium --version $(CILIUM_VERSION) \
   --namespace kube-system \
   --set image.pullPolicy=IfNotPresent \
   --set ipam.mode=kubernetes \
   --values cilium/values.yaml

.PHONY: install-cert-manager
install-cert-manager:
	$(KUBECTL) apply -f https://github.com/jetstack/cert-manager/releases/download/v$(CERT_MANAGER_VERSION)/cert-manager.yaml
	$(KUBECTL) -n cert-manager wait --for=condition=available --timeout=180s --all deployments

.PHONY: install-sart
install-sart: install-sart-manifests

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
	$(KUSTOMIZE) build $(MANIFESTDIR)/sart | $(KUBECTL) apply -f -

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

.PHONY: install-resources
install-resources:
	$(KUSTOMIZE) build $(MANIFESTDIR)/resources | $(KUBECTL) apply -f -

.PHONY: stop
stop: $(KIND) clean
	$(KIND) delete cluster --name $(CLUSTER_NAME)
	docker rm -f external-bgp
	docker rm -f external-client

.PHONY: clean
clean: 


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

$(HELM):
	mkdir -p $(dir $@)
	curl -sfL https://get.helm.sh/helm-v$(HELM_VERSION)-linux-amd64.tar.gz | tar -zx -C $(BINDIR)
	cp $(BINDIR)/linux-amd64/helm $(BINDIR)
	chmod a+x $@
	rm -rf $(BINDIR)/linux-amd64
