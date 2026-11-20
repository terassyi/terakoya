# 参考文献

mcs-gateway の設計と実装で参照する文献の一覧。

- 各コンポーネントのドキュメントからは、ここの ID（例: `[C-4]`）で参照する。読んで確かめたことは、参照する側のドキュメントの本文に書く。
- URL はすべて 2026-10-27 時点で到達できることを確認済み（C-20、E-8、T-3、T-4、T-8〜T-11、L-10、L-11、K-4 は 2026-11-06 に追加・確認。C-26〜C-31 は 2026-11-18 に追加・確認。C-32〜C-39、E-9〜E-12 は 2026-11-20 に追加・確認）。
- docs.cilium.io などのバージョン付きドキュメントは、`stable` ではなく、[operations.md](operations.md) 2 章で固定したバージョンのものを読む（例: `/en/v1.20/`）。
- 新しく文献を見つけたら、該当するカテゴリに追記する。

列「PR」は、主にどの PR で参照するかを示す（[development.md](development.md) 3.2）。

---

## 1. 社内・リポジトリ内の先行事例

| ID | 文献 | PR | 参照する理由 |
|---|---|---|---|
| I-1 | [Neco 環境における Cilium Multi-Pool IPAM の動作検証（Cybozu Inside Out, 2026-10-09）](https://blog.cybozu.io/entry/cilium-multi-pool-ipam-evaluation) | 03, 04 | Neco を再現した kind 環境での multi-pool IPAM の検証。CiliumPodIPPool の定義、BGP による per-node ブロックの広報、Namespace アノテーションでのプール選択 |
| I-2 | neco-apps-lite `network/cluster.clab.yaml.tmpl` | 02 | `k8s-kind` + `ext-container` + sidecar（`network-mode: container:`）の構成。ToR の bridge と exec |
| I-3 | neco-apps-lite `network/cluster.kind.yaml` | 02 | kubeadm patch による node-ip と advertiseAddress の固定、`disableDefaultCNI`、`kubeProxyMode: none` |
| I-4 | neco-apps-lite `network/nodes.yaml` | 02 | ノードごとの IP、GW、ToR の定義から clab ファイルを生成する方法 |
| I-5 | neco-apps-lite `NetworkTasks.yaml` | 01, 02, 03 | Taskfile の構成。host 側の veth と経路の設定、`restart-node`（`containerlab tools veth create`）、Cilium の helm template と適用 |
| I-6 | neco-apps-lite `network/cilium/values.yaml` | 03, 05 | KPR、native routing、DSR（Geneve）、Maglev、`devices: node+` の実例 |
| I-7 | neco-apps-lite `network/cilium/loadbalancer.yaml` | 04 | CiliumBGPClusterConfig / PeerConfig / Advertisement と LB IP プールの実例 |
| I-8 | neco-apps-lite `network/DESIGN.md`、`network/README.md` | 00, 01 | ネットワーク設計書の粒度。ホストの前提条件（Docker の storage driver など） |
| I-9 | neco-apps-lite `aqua.yaml`、`Taskfile.yaml`、`.github/` の composite actions | 01, 09 | ツールのバージョン固定、CI 上での kind 起動 |
| I-10 | terakoya `kindcluster/cilium-bgp-cp/`（`lab.yaml`、`Makefile`） | 02, 04 | FRR を containerlab で動かす設定例（peer-group、`remote-as external`）、Cilium BGP CP の旧 API での実例 |
| I-11 | terakoya `kindcluster/coil-stand-alone-egress-compatibility/` | 01 | Go による E2E テストの構成と、`kubectl` を呼ぶヘルパー（`suite_test.go`）。ここは Ginkgo を使っているが、本ラボでは使わない |
| I-12 | terakoya `docs/dotfiles-migration.md` | 00 | リポジトリ内の設計書の書き方 |

neco-apps-lite のパスは `~/workspace/github.com/cybozu-private/neco-apps-lite/` からの相対で、terakoya のパスはリポジトリのルートからの相対。

---

## 2. Cilium

| ID | 文献 | PR | 参照する理由 |
|---|---|---|---|
| C-1 | [Kubernetes Without kube-proxy](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/) | 03, 05 | KPR の要件。「Direct Server Return (DSR) with Geneve」「Maglev Consistent Hashing」「Hybrid DSR and SNAT Mode」の各節。dispatch ごとの対応表（`geneve` は native routing でも使える）、`maglev.tableSize` と `maglev.hashSeed` |
| C-2 | [kubeproxy-free.rst（main ブランチのソース）](https://github.com/cilium/cilium/blob/main/Documentation/network/kubernetes/kubeproxy-free.rst) | 05 | 未リリースの記述の確認用 |
| C-3 | [cilium/cilium#26339: The DSR section in kubeproxy-free.rst may need to be updated](https://github.com/cilium/cilium/issues/26339) | 05 | DSR と Geneve の対応についての記述の食い違い。古い資料を読むときの注意点 |
| C-4 | [Multi-Pool IPAM](https://docs.cilium.io/en/stable/network/concepts/ipam/multi-pool/) | 03 | CiliumPodIPPool、プール選択のアノテーション（Pod の作成時にだけ評価される）、`default` プールへのフォールバック、制約事項 |
| C-5 | [IPAM の概要](https://docs.cilium.io/en/stable/network/concepts/ipam/) | 03 | IPAM モードの比較と、各モードでの機能対応 |
| C-6 | [Migrating from Cluster Scope to Multi-Pool](https://docs.cilium.io/en/latest/network/concepts/ipam/cluster-pool-to-multi-pool/) | 03 | multi-pool の前提条件の参考（本ラボでは移行はしない） |
| C-7 | [Routing（native routing / encapsulation）](https://docs.cilium.io/en/stable/network/concepts/routing/) | 03 | `routingMode: native`、`autoDirectNodeRoutes`、`ipv4NativeRoutingCIDR` |
| C-8 | [Masquerading](https://docs.cilium.io/en/stable/network/concepts/masquerading/) | 03, 04 | `ipv4NativeRoutingCIDR` と SNAT の関係（クラスタ間の通信を SNAT しないため） |
| C-9 | [BGP Control Plane（v2）](https://docs.cilium.io/en/stable/network/bgp-control-plane/bgp-control-plane-v2/) | 04 | BGP CP v2 の概要と有効化 |
| C-10 | [BGP Control Plane Resources](https://docs.cilium.io/en/stable/network/bgp-control-plane/bgp-control-plane-configuration/) | 04 | CiliumBGPClusterConfig / PeerConfig / Advertisement / NodeConfigOverride。`advertisementType`（`PodCIDR`、`CiliumPodIPPool`、`Service`）、graceful restart、timers |
| C-11 | [BGP Control Plane Operation](https://docs.cilium.io/en/stable/network/bgp-control-plane/bgp-control-plane-operation/) | 04 | `cilium bgp peers` / `routes` などの運用コマンド |
| C-12 | [BGP Control Plane Troubleshooting](https://docs.cilium.io/en/stable/network/bgp-control-plane/bgp-control-plane-troubleshooting/) | 04 | セッションが張れないときの切り分け |
| C-13 | [LoadBalancer IP Address Management (LB IPAM)](https://docs.cilium.io/en/stable/network/lb-ipam/) | 04 | CiliumLoadBalancerIPPool、Service の選択、既定で有効か |
| C-14 | [Helm Reference](https://docs.cilium.io/en/stable/helm-reference/) | 03, 05 | values のキー名の確認（`loadBalancer.*`、`ipam.*`、`bgpControlPlane.*`、`gatewayAPI.*`、`k8sServiceHost`、`cluster.*`） |
| C-15 | [Installation Using Kind](https://docs.cilium.io/en/stable/installation/kind/) | 03 | kind 上で Cilium を動かすときの注意点 |
| C-16 | [System Requirements](https://docs.cilium.io/en/stable/operations/system_requirements/) | 01 | `task check-host` のカーネル要件 |
| C-17 | [Kubernetes Configuration（Cilium）](https://docs.cilium.io/en/stable/network/kubernetes/configuration/) | 03 | Kubernetes 側の設定項目 |
| C-18 | [Gateway API Support（Cilium）](https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/) | 06 | Cilium 内蔵の Gateway API を無効にする理由（Envoy Gateway と競合させない）の確認 |
| C-19 | [Multi-Cluster Services API（Cilium ClusterMesh）](https://docs.cilium.io/en/stable/network/clustermesh/mcsapi/) | 07 | 本ラボでは採らないが、CoreDNS の要件の参考になる。CoreDNS 1.12.2 以降が必要、Kubernetes 1.35 で既定で入る、`serviceimports` を list と watch する RBAC、Corefile への `clusterset.local` と `multicluster` の追加 |
| C-20 | [Kubernetes Compatibility（v1.20）](https://docs.cilium.io/en/v1.20/network/kubernetes/compatibility/) | 01 | Cilium 1.20 が e2e で確かめている Kubernetes は 1.33〜1.36。Kubernetes のバージョン選定に使った |
| C-21 | [cilium/cilium v1.20.4 `install/kubernetes/cilium/values.yaml`](https://github.com/cilium/cilium/blob/v1.20.4/install/kubernetes/cilium/values.yaml) | 03, 04 | チャートの values のキーと既定値。`nodePort.enabled` と `nodePort.directRoutingDevice` がもうないこと。`values.schema.json` は知らないキーを拒否しない。`enableLBIPAM: true`、`rollOutCiliumPods` と `operator.rollOutPods`（既定 `false`）、`bgpControlPlane.routerIDAllocation` |
| C-22 | [cilium/cilium v1.20.4 `pkg/k8s/apis/cilium.io/client/register.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/k8s/apis/cilium.io/client/register.go) | 03 | Cilium の CRD は operator が起動時に作る。`CiliumPodIPPool` の CRD は IPAM のモードによらず作られる |
| C-23 | [cilium/cilium v1.20.4 `pkg/datapath/tables/direct_routing_device.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/datapath/tables/direct_routing_device.go) | 03 | direct routing device の決め方。指定がなく、選ばれたデバイスが 1 つならそれを使う |
| C-24 | [cilium/cilium v1.20.4 `pkg/k8s/node.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/k8s/node.go) | 03 | `ParseCiliumNode` が multi-pool のブロックを `IPv4SecondaryAllocCIDRs` に入れ、`autoDirectNodeRoutes` の経路の対象になること |
| C-25 | [Multi-Pool IPAM の手順（v1.20.4 `Documentation/network/kubernetes/ipam-multi-pool.rst`）](https://github.com/cilium/cilium/blob/v1.20.4/Documentation/network/kubernetes/ipam-multi-pool.rst) | 03 | Helm の設定例（`ipam.mode`、`kubeProxyReplacement`、`bpf.masquerade`）。agent はノードのブロックが割り当てられるまで待つ |
| C-26 | [cilium/cilium v1.20.4 `pkg/k8s/synced/crd.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/k8s/synced/crd.go) | 04 | operator が作る CRD の一覧。BGP の CRD は `bgpControlPlane.enabled` のときだけ作られ、`CiliumLoadBalancerIPPool` はいつも作られる |
| C-27 | [cilium/cilium v1.20.4 `pkg/bgp/manager/reconciler/pod_ip_pool.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/bgp/manager/reconciler/pod_ip_pool.go) | 04 | `CiliumPodIPPool` の広報。自ノードの `CiliumNode` に割り当てられたブロックのうち、selector に合うプールのものだけを広報する |
| C-28 | [cilium/cilium v1.20.4 `pkg/k8s/apis/cilium.io/v2/bgp_cluster_types.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/k8s/apis/cilium.io/v2/bgp_cluster_types.go) | 04 | `CiliumBGPClusterConfig` の型。`peerAddress`、`peerASN`、`autoDiscovery`（`DefaultGateway`）。BGP の API は `cilium.io/v2` |
| C-29 | [Multi-Pool IPAM の概念（v1.20.4 `Documentation/network/concepts/ipam/multi-pool.rst`）](https://github.com/cilium/cilium/blob/v1.20.4/Documentation/network/concepts/ipam/multi-pool.rst) | 04 | プールの選び方（`ipam.cilium.io/ip-pool` のアノテーション、プールの `namespaceSelector` / `podSelector`、合わなければ `default`）。Masquerade Behaviour（`skip-masquerade`、`--only-masquerade-default-pool`） |
| C-30 | [cilium/cilium v1.20.4 `bpf/lib/nat.h`](https://github.com/cilium/cilium/blob/v1.20.4/bpf/lib/nat.h) | 04 | `snat_v4_needs_masquerade` の判定順（`ipv4NativeRoutingCIDR`、プールの skip-masquerade、ip-masq-agent、リモートノード） |
| C-31 | [cilium/cilium v1.20.4 `pkg/ipam/multipool.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/ipam/multipool.go) | 04 | `shouldSkipMasqForPool`。プールのアノテーション `ipam.cilium.io/skip-masquerade: "true"` で、そのプールの Pod を SNAT しない |
| C-32 | [cilium/cilium v1.20.4 `pkg/loadbalancer/config.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/loadbalancer/config.go) | 05 | DSR の `geneve` dispatch を有効にすると、native routing でもトンネル（`cilium_geneve`）を有効にする（`tunnel.NewEnabler`）。MTU の調整はデータパスに任せる（`WithoutMTUAdaptation`） |
| C-33 | [cilium/cilium v1.20.4 `pkg/kpr/initializer/kube_proxy_replacement.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/kpr/initializer/kube_proxy_replacement.go) | 05 | DSR の `geneve` dispatch には `tunnelProtocol: geneve` が要る（起動時の検査） |
| C-34 | [cilium/cilium v1.20.4 `bpf/lib/overloadable_skb.h`](https://github.com/cilium/cilium/blob/v1.20.4/bpf/lib/overloadable_skb.h) | 05 | `ctx_set_encap_info4`。トンネルのキーのフラグは `BPF_F_ZERO_CSUM_TX` だけで、外側に DF を立てない |
| C-35 | [cilium/cilium v1.20.4 `pkg/datapath/loader/netlink.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/datapath/loader/netlink.go) | 05 | `cilium_geneve` の作成。df を設定しない |
| C-36 | [cilium/cilium v1.20.4 `pkg/mtu/mtu.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/mtu/mtu.go) | 05 | `TunnelOverheadIPv4`（50 byte）と `DsrTunnelOverhead`（12 byte） |
| C-37 | [cilium/cilium v1.20.4 `bpf/lib/nodeport.h`](https://github.com/cilium/cilium/blob/v1.20.4/bpf/lib/nodeport.h) | 05 | `encap_geneve_dsr_opt4`（DSR のオプションは SYN だけ）と `dsr_is_too_big`（`ENABLE_DSR_ICMP_ERRORS` のときだけ ICMP frag-needed を返す） |
| C-38 | [cilium/cilium v1.20.4 `pkg/maglev/maglev.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/maglev/maglev.go) | 05 | `maglev.hashSeed` は base64 で 12 byte でなければならない |
| C-39 | [cilium/cilium v1.20.4 `pkg/datapath/linux/config/config.go`](https://github.com/cilium/cilium/blob/v1.20.4/pkg/datapath/linux/config/config.go) | 05 | `ENABLE_DSR_ICMP_ERRORS` は `pmtuDiscovery.enabled`（`enable-pmtu-discovery`）のときだけ定義される |

---

## 3. Envoy Gateway / Gateway API

| ID | 文献 | PR | 参照する理由 |
|---|---|---|---|
| E-1 | [Envoy Gateway: Install with Helm](https://gateway.envoyproxy.io/docs/install/install-helm/) | 06 | インストール手順と、Gateway API CRD の同梱方法 |
| E-2 | [Envoy Gateway: Quickstart](https://gateway.envoyproxy.io/docs/tasks/quickstart/) | 06 | GatewayClass / Gateway / HTTPRoute の最小構成 |
| E-3 | [Envoy Gateway: Multicluster Service Routing](https://gateway.envoyproxy.io/docs/tasks/traffic/multicluster-service/) | 08 | ServiceImport を backendRef にする公式手順。**Submariner が前提**である点に注意 |
| E-4 | [examples/kubernetes/multicluster-service.yaml](https://raw.githubusercontent.com/envoyproxy/gateway/main/examples/kubernetes/multicluster-service.yaml) | 08 | `group: multicluster.x-k8s.io`、`kind: ServiceImport` の backendRef と、Namespace をまたぐときの ReferenceGrant の実例 |
| E-5 | [Envoy Gateway API Reference（extension types）](https://gateway.envoyproxy.io/docs/api/extension_types/) | 06 | EnvoyProxy（Service type、externalTrafficPolicy など） |
| E-6 | [Envoy Gateway: Compatibility Matrix](https://gateway.envoyproxy.io/news/releases/matrix/) | 01, 06 | Envoy Gateway、Gateway API、Kubernetes のバージョンの対応 |
| E-7 | [envoyproxy/gateway（GitHub）](https://github.com/envoyproxy/gateway) | 06, 08 | ServiceImport の endpoint 解決の実装（EndpointSlice のラベル `multicluster.kubernetes.io/service-name`）を、ソースで確認する |
| E-8 | [Envoy Gateway Compatibility Matrix](https://gateway.envoyproxy.io/news/releases/matrix/) | 01 | v1.9 は Envoy Proxy 1.39、Gateway API v1.6.1、Kubernetes 1.33〜1.36 に対応する。Kubernetes と Gateway API のバージョン選定に使った |
| E-9 | [envoyproxy/gateway v1.9.3 `charts/gateway-helm/charts/crds/crds/gatewayapi-crds.yaml`](https://github.com/envoyproxy/gateway/blob/v1.9.3/charts/gateway-helm/charts/crds/crds/gatewayapi-crds.yaml) | 06 | チャートが同梱する Gateway API の CRD。experimental channel、bundle-version v1.6.1 |
| E-10 | [envoyproxy/gateway v1.9.3 `api/v1alpha1/shared_types.go`](https://github.com/envoyproxy/gateway/blob/v1.9.3/api/v1alpha1/shared_types.go) | 06 | `KubernetesServiceSpec`。Envoy の Service の `type`（既定 `LoadBalancer`）と `externalTrafficPolicy`（既定 `Local`） |
| E-11 | [envoyproxy/gateway v1.9.3 `api/v1alpha1/envoygateway_types.go`](https://github.com/envoyproxy/gateway/blob/v1.9.3/api/v1alpha1/envoygateway_types.go) | 06 | `KubernetesDeployMode`。既定の `ControllerNamespace` では、Envoy のデータプレーンをコントローラの Namespace に作る |
| E-12 | [kubernetes/kubernetes v1.36.4 `test/images/agnhost/porter/porter.go`](https://github.com/kubernetes/kubernetes/blob/v1.36.4/test/images/agnhost/porter/porter.go) | 06 | agnhost の `porter`。環境変数 `SERVE_PORT_<port>` の値を、そのポートで返す |
| G-1 | [Gateway API](https://gateway-api.sigs.k8s.io/) | 06 | 仕様全般 |
| G-2 | [HTTPRoute](https://gateway-api.sigs.k8s.io/reference/api-types/httproute/) | 06, 08 | backendRefs、重み、マッチ条件 |
| G-3 | [GEP-1748: Gateway API Interaction with Multi-Cluster Services](https://gateway-api.sigs.k8s.io/geps/gep-1748/) | 08 | ServiceImport を backendRef にするときの意味論 |
| G-4 | [Cross-Namespace routing](https://gateway-api.sigs.k8s.io/guides/multiple-ns/) | 06, 08 | ReferenceGrant |

---

## 4. Multi-Cluster Services (MCS) / DNS

| ID | 文献 | PR | 参照する理由 |
|---|---|---|---|
| M-1 | [KEP-1645: Multi-Cluster Services API](https://github.com/kubernetes/enhancements/tree/master/keps/sig-multicluster/1645-multi-cluster-services-api) | 07 | ServiceExport / ServiceImport の仕様、EndpointSlice のラベル、`clusterset.local` の DNS 仕様 |
| M-2 | [kubernetes-sigs/mcs-api](https://github.com/kubernetes-sigs/mcs-api) | 07 | CRD（`config/`）、mcs-api-controller（`controllers/`）、kind 2 クラスタでのデモ（`demo/`、`scripts/up.sh`）、conformance テスト |
| M-3 | [SIG Multicluster: Multicluster Services API](https://multicluster.sigs.k8s.io/concepts/multicluster-services-api/) | 07 | 概念の解説（ClusterSet、namespace sameness） |
| M-4 | [SIG Multicluster: MCS Implementations](https://multicluster.sigs.k8s.io/implementations/mcs-implementations/) | 07 | 既存の実装と成熟度。syncer を作るときの参考 |
| M-5 | [SIG Multicluster](https://multicluster.sigs.k8s.io/) | 07 | About API（ClusterProperty / cluster ID）など周辺の仕様 |
| M-6 | [CoreDNS kubernetes plugin（`multicluster` オプション）](https://coredns.io/plugins/kubernetes/) | 07 | `kubernetes cluster.local clusterset.local { multicluster clusterset.local }` の書き方。プラグインは `multicluster` に指定したゾーンに対して authoritative である必要がある |
| M-7 | [coredns/multicluster](https://github.com/coredns/multicluster) | 07 | 外部プラグイン版（参考）。CoreDNS 1.12.2 以降は M-6 の標準オプションを使う |
| M-8 | [Kubernetes: EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/) | 07 | `mcs/sync.sh` で作る EndpointSlice の形式と、`endpointslice.kubernetes.io/managed-by` |
| M-9 | [Kubernetes: DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) | 07 | DNS の名前の規則 |

---

## 5. containerlab / kind

| ID | 文献 | PR | 参照する理由 |
|---|---|---|---|
| L-1 | [containerlab: k8s-kind](https://containerlab.dev/manual/kinds/k8s-kind/) | 02 | `startup-config` に kind の設定を渡す方法、ノード直下のキー `wait` と `kubeconfig`（v0.82.0。旧来の `extras.k8s_kind` は使わない）、ノードの命名規則 |
| L-2 | [containerlab: ext-container](https://containerlab.dev/manual/kinds/ext-container/) | 02 | 外部で作られたコンテナを、リンクの端点として扱う方法 |
| L-3 | [containerlab: linux kind](https://containerlab.dev/manual/kinds/linux/) | 02 | FRR と sidecar のノード定義、`exec`、`binds` |
| L-4 | [containerlab: Nodes](https://containerlab.dev/manual/nodes/) | 02 | `network-mode: container:<name>`、`exec`、`env`、`binds` |
| L-5 | [containerlab: Network wiring](https://containerlab.dev/manual/network/) | 02 | host リンク（`host:<if>`）、管理ネットワーク、MTU |
| L-6 | [containerlab: Topology definition](https://containerlab.dev/manual/topo-def-file/) | 02 | トポロジファイルの全体構造 |
| L-7 | [containerlab: deploy](https://containerlab.dev/cmd/deploy/) | 02 | `--reconfigure` などの冪等性に関わるオプション |
| L-8 | [containerlab: tools veth create](https://containerlab.dev/cmd/tools/veth/create/) | 02 | ノードを再作成したときのリンクの張り直し |
| L-9 | [containerlab 0.50 release notes](https://containerlab.dev/rn/0.50/) | 02 | k8s-kind 統合が入ったときの説明 |
| L-10 | [nicolaka/netshoot](https://github.com/nicolaka/netshoot) | 02, 05 | sidecar と spine の NAT 用のイメージ（iproute2、iptables、ping、curl、tcpdump） |
| L-11 | [srl-labs/containerlab v0.82.0 `nodes/k8s_kind/k8s_kind.go`](https://github.com/srl-labs/containerlab/blob/v0.82.0/nodes/k8s_kind/k8s_kind.go) | 02 | `k8s-kind` の実装。組み込みの kind ライブラリ（v0.33.0）、既定の 15 分の待ち時間、`kubeconfig` の相対パスの解決 |
| K-1 | [kind: Configuration](https://kind.sigs.k8s.io/docs/user/configuration/) | 02 | `networking`（`disableDefaultCNI`、`kubeProxyMode`、`podSubnet`、`serviceSubnet`）、`kubeadmConfigPatches`、ノードごとの patch |
| K-2 | [kind: Known Issues](https://kind.sigs.k8s.io/docs/user/known-issues/) | 01, 02 | inotify の上限、複数クラスタを起動するときのリソース |
| K-3 | [kind: Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/) | 02 | `kind export kubeconfig`、`kind load docker-image` |
| K-4 | [kind v0.33.0 `pkg/internal/patch/kubeadm_merge.go`](https://github.com/kubernetes-sigs/kind/blob/v0.33.0/pkg/internal/patch/kubeadm_merge.go) | 02 | kubeadm `v1beta4` への patch で、`kubeletExtraArgs` を名前でマージする実装。`apiVersion` が一致しない patch は当たらない（`kubeyaml.go`） |

---

## 6. FRR / BGP

| ID | 文献 | PR | 参照する理由 |
|---|---|---|---|
| F-1 | [FRR: BGP](https://docs.frrouting.org/en/latest/bgp.html) | 02, 04 | `bgp listen range`（動的ネイバー）、peer-group、`remote-as external`、`bgp bestpath as-path multipath-relax`、`maximum-paths`、graceful restart、`no bgp ebgp-requires-policy` |
| F-2 | [FRR: VTY shell](https://docs.frrouting.org/en/latest/vtysh.html) | 01, 02 | `vtysh --dryrun`（CI での構文チェック）、`show ... json`（E2E での観測） |
| F-3 | [frrouting/frr（Docker Hub）](https://hub.docker.com/r/frrouting/frr) | 01, 02 | イメージのタグとバージョン固定 |
| R-1 | [RFC 4271: BGP-4](https://www.rfc-editor.org/rfc/rfc4271) | 02 | BGP の基礎 |
| R-2 | [RFC 7938: Use of BGP for Routing in Large-Scale Data Centers](https://www.rfc-editor.org/rfc/rfc7938) | 02, 04 | spine/ToR の eBGP 設計と ASN の割り当て方針 |

---

## 7. データプレーンの背景

| ID | 文献 | PR | 参照する理由 |
|---|---|---|---|
| D-1 | [RFC 8926: Geneve](https://www.rfc-editor.org/rfc/rfc8926) | 05 | Geneve ヘッダの構造。DSR で必要な MTU を見積もるため |
| D-2 | [Maglev: A Fast and Reliable Software Network Load Balancer（Google, NSDI 2016）](https://research.google/pubs/maglev-a-fast-and-reliable-software-network-load-balancer/) | 05 | Maglev ハッシュの性質。一貫性テストの設計に使う |
| D-3 | [Cilium 1.8 release blog（Maglev と XDP LB の導入）](https://cilium.io/blog/2020/06/22/cilium-18/) | 05 | Cilium での Maglev 実装の背景 |

---

## 8. ツール / テスト

| ID | 文献 | PR | 参照する理由 |
|---|---|---|---|
| T-1 | [Task（go-task）](https://taskfile.dev/) | 01 | Taskfile の書き方（vars、deps、`status` による冪等化、`preconditions`） |
| T-2 | [aqua](https://aquaproj.github.io/) | 01 | `aqua.yaml`、checksum の検証、policy |
| T-3 | [Go: testing パッケージ](https://pkg.go.dev/testing) | 01〜08 | `TestMain`、`t.Run` のサブテスト、`-run` のパターン（`Test/Sub` の形）、`-list`、`t.Cleanup` |
| T-4 | [testify](https://github.com/stretchr/testify) | 01〜08 | `assert` / `require`、`assert.EventuallyWithT` による待ち合わせ |
| T-5 | [kubeconform](https://github.com/yannh/kubeconform) | 01 | CI での静的検証。CRD スキーマの取り込み方 |
| T-6 | [hashicorp/http-echo](https://github.com/hashicorp/http-echo) | 06, 07 | サンプル app の候補（`-text` でクラスタ名を返す） |
| T-7 | [D2](https://d2lang.com/) | 00〜 | ドキュメントの図の記述言語（レイアウトエンジン、テーマ、sequence diagram） |
| T-8 | [lychee](https://github.com/lycheeverse/lychee) | 01 | `task lint` のリンクチェック。`--offline` でローカルのリンクだけを見る |
| T-9 | [yamllint](https://yamllint.readthedocs.io/) | 01 | `task lint` の YAML 検査。`extends: default` と規則の無効化 |
| T-10 | [pinact](https://github.com/suzuki-shunsuke/pinact) | 01 | action を commit SHA に固定する。`--fix=false --no-api` によるオフラインの検査 |
| T-11 | [actionlint](https://github.com/rhysd/actionlint) | 01 | `task lint` のワークフロー検査。shellcheck による `run:` の検査 |
| T-12 | [agnhost（kubernetes `test/images/agnhost`）](https://github.com/kubernetes/kubernetes/tree/master/test/images/agnhost) | 03 | テスト用サーバ。`netexec` の `/clientip` で、サーバから見えた送信元を返す |
