# 運用（実行環境 / バージョン / タスク / 起動と停止）

- 関連: [network.md](network.md)、[testing.md](testing.md)、[development.md](development.md)

## 1. ホストの前提条件

`task check-host` で機械的に検査する。

| 項目 | 要件 |
|---|---|
| OS | Linux（Docker が直接動くもの）。WSL2 と macOS は対象外 |
| CPU / メモリ | 目安は 8 vCPU / 24 GB 以上。DSR の実装時点の実測値で更新する |
| Docker | storage driver が `overlay2`。Docker 29 以降なら `containerd-snapshotter: false`（neco-apps-lite `network/README.md` と同じ [I-8]） |
| sysctl | `fs.inotify.max_user_instances >= 512`、`fs.inotify.max_user_watches >= 524288` [K-2] |
| カーネル | Cilium の要件を満たす [C-16] |
| 権限 | `sudo` を使える（containerlab と host の netns 操作に必要） |

前提を満たしていないときは、`check-host` が不足している項目と直し方を表示して失敗する。host の設定を自動で変えることはしない。

---

## 2. バージョン

ツールは `aqua.yaml` で固定し、コンテナイメージと chart は `Taskfile.yaml` の vars で固定する。

最初の実装 PR（骨組み）で、最新の安定版を調べて固定し、この表を更新する。以降バージョンを変えるときも、この表を更新する。

| コンポーネント | バージョン（初期値。neco-apps-lite に合わせたもの） | 管理場所 |
|---|---|---|
| kind | v0.32.0 | aqua |
| kindest/node (Kubernetes) | v1.34.8 | Taskfile vars |
| containerlab | 0.78.2 | aqua |
| helm | v3.20.2 | aqua |
| kubectl | v1.35.3 | aqua |
| kustomize | v5.7.1 | aqua |
| go-task | v3.53.1 | aqua |
| yq / jq | neco-apps-lite に合わせる | aqua |
| cilium-cli | neco-apps-lite に合わせる | aqua |
| Cilium | 1.18 以降（BGP v2 が `cilium.io/v2` で使える版） | Taskfile vars |
| Envoy Gateway | 未定 | Taskfile vars |
| Gateway API CRD | Envoy Gateway が要求するバージョン | Taskfile vars |
| FRR | 未定 | Taskfile vars |
| mcs-api | 未定 | Taskfile vars |
| CoreDNS | kindest/node 同梱のもの。1.12.2 以上が必要（[mcs.md](mcs.md)） | — |
| d2 | v0.9.0 | yatate（tomei の `cliTools`）。ドキュメントの図の生成にだけ使う |

---

## 3. Taskfile のタスク

| タスク | 内容 | 定義するドキュメント |
|---|---|---|
| `setup` | aqua でツールを入れる | 本書 |
| `check-host` | 1 章の前提条件を検査する | 本書 |
| `start` | 4 章の起動手順をすべて実行する | 本書 |
| `stop` | 5 章の停止手順を実行する | 本書 |
| `status` | トポロジ、BGP、クラスタの状態を一覧する | 本書 |
| `lint` | 静的テスト | [testing.md](testing.md) |
| `test` | E2E テスト（`LABEL=` で絞り込み） | [testing.md](testing.md) |
| `docs` | `docs/diagrams/*.d2` から SVG を生成する | [development.md](development.md) |
| `deploy-fabric` | containerlab、kind、FRR、host 経路 | [network.md](network.md) |
| `deploy-cilium` | Cilium と CiliumPodIPPool | [cilium.md](cilium.md) |
| `deploy-bgp` | BGP と LB IPAM | [cilium.md](cilium.md) |
| `deploy-dsr` | DSR / Maglev を有効にする | [cilium.md](cilium.md) |
| `deploy-mcs` | MCS の CRD、コントローラ、CoreDNS | [mcs.md](mcs.md) |
| `deploy-sample` | echo と ServiceExport | [mcs.md](mcs.md) |
| `sync-mcs` | edge への同期 | [mcs.md](mcs.md) |
| `deploy-gateway` | Envoy Gateway と Gateway、HTTPRoute | [envoy-gateway.md](envoy-gateway.md) |

まだ実装されていないコンポーネントのタスクは、Taskfile に存在しない。

---

## 4. 起動手順（`task start`）

各ステップは、何度実行しても同じ状態になる（冪等）。

1. `check-host`
2. `deploy-fabric`
   - `sudo containerlab deploy -t topology.clab.yaml --reconfigure`。kind 3 クラスタ、FRR、sidecar が作られる。
   - `kind export kubeconfig --name <cluster>` を 3 クラスタ分実行する。kube context は `kind-edge`、`kind-core1`、`kind-core2`。
   - host の `to-mcsgw` に IP と経路を設定する（[network.md](network.md) 2.5）。
3. `deploy-cilium`
4. `deploy-bgp`
5. `deploy-dsr`
6. `deploy-mcs`
7. `deploy-sample`
8. `sync-mcs`
9. `deploy-gateway`

---

## 5. 停止手順（`task stop`）

1. `sudo containerlab destroy -t topology.clab.yaml --cleanup`（kind 3 クラスタも消える）
2. `to-mcsgw` を削除する。リンクが消えると経路も消える。
3. 残骸がないことを検査する。
   - `docker ps -a` に `clab-mcsgw-*` と kind ノードがない。
   - `ip link` に `to-mcsgw` がない。
   - `ip route` に 10.69.0.0/16 と 10.80.0.0/14 がない。

残骸があれば `stop` は失敗する。

---

## 6. AI に許可する操作 / してはいけない操作

### 6.1 許可する操作

- `sudo containerlab deploy/destroy`
- `task start/stop/test` と、それらが行う host netns の変更
  - veth `to-mcsgw` の作成と削除
  - 172.30.0.1/30 の付与
  - 経路の追加: 10.69.0.0/16（ノード）と 10.80.0.0/14（LB VIP）を、172.30.0.2（spine）経由にする
- docker / kind / kubectl / helm の操作

### 6.2 してはいけない操作

- 6.1 にない host の設定変更（sysctl の永続化、Docker daemon 設定の書き換えなど）
  - 前提条件を満たしていない場合は、自分で直さずに人に報告して止まる。
- `kindcluster/mcs-gateway/` と `.github/workflows/kindcluster-mcs-gateway.yml` 以外の変更。他のラボや dotfiles は触らない。
- `tomei` / `chezmoi` の実行（リポジトリの CLAUDE.md で禁止されている）

---

## 7. 参考文献

[I-5] [I-8] [I-9] [K-2] [C-16] [T-1] [T-2]（[references.md](references.md)）
