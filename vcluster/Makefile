SUDO ?= sudo
BIN_DIR := $(shell pwd)/bin

VAGRANT_VERSION ?= 2.3.6
KUBERNETES_VERSION ?= 1.27.2
KUSTOMIZE_VERSION ?= 5.0.3
HELM_VERSION ?= 3.12.0
CILIUM_VERSION ?= 1.12.10
CILIUM_OPERATOR_VERSION ?= $(CILIUM_VERSION)
HUBBLE_RELAY_VERSION ?= $(CILIUM_VERSION)
CILIUM_CERTGEN_VERSION ?= 0.1.8
CALICO_VERSION ?= 3.25.1
FLANNEL_VERSION ?= 0.21.5

.PHONY: setup
setup: helm kustomize

.PHONY: install
install: install-ansible
	# wget https://releases.hashicorp.com/vagrant/$(VAGRANT_VERSION)/vagrant_$(VAGRANT_VERSION)-1_amd64.deb
	$(SUDO) dpkg --install vagrant_$(VAGRANT_VERSION)-1_amd64.deb
	$(SUDO) apt update -y
	$(SUDO) apt build-dep vagrant ruby-libvirt
	$(SUDO) apt install -y qemu libvirt-dev libvirt-daemon-system libvirt-clients ebtables dnsmasq libxslt-dev libxml2-dev zlib1g-dev ruby-dev
	vagrant plugin install vagrant-libvirt

install-ansible:
	$(SUDO) apt install software-properties-common
	$(SUDO) add-apt-repository --yes --update ppa:ansible/ansible
	$(SUDO) apt install ansible

.PHONY: start
start: vm cilium
	cd easy; ansible-playbook -i inventory.ini playbooks/playbook.yml

.PHONY: stop
stop:
	vagrant destroy -f
	rm $(CILIUM_MANIFESTS)

.PHONY: vm
vm:
	vagrant up --provider=libvirt
	vagrant ssh-config > ./ssh.config


CILIUM_ORVERLAYS ?= base

CILIUM_MANIFESTS := $(shell pwd)/easy/playbooks/roles/cni/cilium/files/cilium.yaml
.PHONY: cilium
cilium: $(CILIUM_MANIFESTS)

$(CILIUM_MANIFESTS):
	rm -rf /tmp/work-cilium
	mkdir -p /tmp/work-cilium
	curl -sSfL https://github.com/cilium/cilium/archive/$(shell echo $(CILIUM_VERSION) | cut -d \. -f 1,2,3).tar.gz | tar -C /tmp/work-cilium -xzf - --strip-components=1
	$(HELM) template /tmp/work-cilium/install/kubernetes/cilium/ \
		--namespace=kube-system \
		--version $(CILIUM_VERSION) \
		--values cni/cilium/$(CILIUM_ORVERLAYS)/values.yaml \
		--set image.tag=v$(CILIUM_VERSION) \
		--set image.useDigest=false \
		--set operator.image.tag=v$(CILIUM_OPERATOR_VERSION) \
		--set operator.image.useDigest=false \
		--set hubble.relay.image.tag=v$(HUBBLE_RELAY_VERSION) \
		--set hubble.relay.image.useDigest=false \
		--set certgen.image.tag=v$(CILIUM_CERTGEN_VERSION) \
		--set certgen.image.useDigest=false > cni/cilium/$(CILIUM_ORVERLAYS)/upstream.yaml
	bin/kustomize build cni/cilium/$(CILIUM_ORVERLAYS) > $(CILIUM_MANIFESTS)
	rm -rf /tmp/work-cilium

HELM := $(shell pwd)/bin/helm
.PHONY: helm
helm: $(HELM) ## Download helm locally if necessary.

$(HELM):
	mkdir -p $(BIN_DIR)
	curl -sSfL https://get.helm.sh/helm-v$(HELM_VERSION)-linux-amd64.tar.gz \
	  | tar xz -C $(BIN_DIR) --strip-components 1 linux-amd64/helm

KUSTOMIZE := $(shell pwd)/bin/kustomize
.PHONY: kustomize
kustomize:
	mkdir -p bin
	curl -sSfL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv$(KUSTOMIZE_VERSION)/kustomize_v$(KUSTOMIZE_VERSION)_linux_amd64.tar.gz | tar -xz -C bin
	chmod a+x bin/kustomize
