# 参考文献

mcs-gateway の設計と実装で参照する文献の一覧。

- 各コンポーネントのドキュメントからは、ここの ID（例: `[C-4]`）で参照する。読んで確かめたことは、参照する側のドキュメントの本文に書く。
- URL はすべて 2026-10-27 時点で到達できることを確認済み。
- docs.cilium.io などのバージョン付きドキュメントは、`stable` ではなく、[operations.md](operations.md) 2 章で固定したバージョンのものを読む（例: `/en/v1.18/`）。
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
| I-11 | terakoya `kindcluster/coil-stand-alone-egress-compatibility/` | 01 | Go + Ginkgo による E2E テストの構成（`suite_test.go`） |
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
| L-1 | [containerlab: k8s-kind](https://containerlab.dev/manual/kinds/k8s-kind/) | 02 | `startup-config` に kind の設定を渡す方法、`extras.k8s_kind`、ノードの命名規則 |
| L-2 | [containerlab: ext-container](https://containerlab.dev/manual/kinds/ext-container/) | 02 | 外部で作られたコンテナを、リンクの端点として扱う方法 |
| L-3 | [containerlab: linux kind](https://containerlab.dev/manual/kinds/linux/) | 02 | FRR と sidecar のノード定義、`exec`、`binds` |
| L-4 | [containerlab: Nodes](https://containerlab.dev/manual/nodes/) | 02 | `network-mode: container:<name>`、`exec`、`env`、`binds` |
| L-5 | [containerlab: Network wiring](https://containerlab.dev/manual/network/) | 02 | host リンク（`host:<if>`）、管理ネットワーク、MTU |
| L-6 | [containerlab: Topology definition](https://containerlab.dev/manual/topo-def-file/) | 02 | トポロジファイルの全体構造 |
| L-7 | [containerlab: deploy](https://containerlab.dev/cmd/deploy/) | 02 | `--reconfigure` などの冪等性に関わるオプション |
| L-8 | [containerlab: tools veth create](https://containerlab.dev/cmd/tools/veth/create/) | 02 | ノードを再作成したときのリンクの張り直し |
| L-9 | [containerlab 0.50 release notes](https://containerlab.dev/rn/0.50/) | 02 | k8s-kind 統合が入ったときの説明 |
| K-1 | [kind: Configuration](https://kind.sigs.k8s.io/docs/user/configuration/) | 02 | `networking`（`disableDefaultCNI`、`kubeProxyMode`、`podSubnet`、`serviceSubnet`）、`kubeadmConfigPatches`、ノードごとの patch |
| K-2 | [kind: Known Issues](https://kind.sigs.k8s.io/docs/user/known-issues/) | 01, 02 | inotify の上限、複数クラスタを起動するときのリソース |
| K-3 | [kind: Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/) | 02 | `kind export kubeconfig`、`kind load docker-image` |

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
| T-3 | [Ginkgo](https://onsi.github.io/ginkgo/) | 01〜08 | suite の構成、`Eventually`、`Ordered` |
| T-4 | [Ginkgo: Spec Labels](https://onsi.github.io/ginkgo/#spec-labels) | 01 | `Label(...)` と `--label-filter`（`task test LABEL=`） |
| T-5 | [kubeconform](https://github.com/yannh/kubeconform) | 01 | CI での静的検証。CRD スキーマの取り込み方 |
| T-6 | [hashicorp/http-echo](https://github.com/hashicorp/http-echo) | 06, 07 | サンプル app の候補（`-text` でクラスタ名を返す） |
| T-7 | [D2](https://d2lang.com/) | 00〜 | ドキュメントの図の記述言語（レイアウトエンジン、テーマ、sequence diagram） |
