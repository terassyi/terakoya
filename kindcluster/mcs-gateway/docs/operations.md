# 運用（実行環境 / バージョン / タスク / 起動と停止）

- ステータス: `Reviewed`
- 関連: [network.md](network.md)、[testing.md](testing.md)、[development.md](development.md)

## 1. ホストの前提条件

`task check-host` で機械的に検査する。

| # | 項目 | 要件 | 検査方法 | 満たさないとき |
|---|---|---|---|---|
| 1 | OS | Linux（Docker が直接動くもの）。WSL2 と macOS は対象外 | `uname -s` が `Linux`。`/proc/version` に `microsoft` を含まない | 失敗 |
| 2 | CPU | 目安は 8 vCPU 以上。DSR の実装時点の実測値で更新する | `nproc` | 警告のみ |
| 3 | メモリ | 目安は 24 GB 以上。同上 | `/proc/meminfo` の `MemTotal` | 警告のみ |
| 4 | Docker | storage driver が `overlay2`。Docker 29 以降なら `containerd-snapshotter: false`（neco-apps-lite `network/README.md` と同じ [I-8]） | `docker info --format '{{.Driver}}'` が `overlay2`。containerd snapshotter が有効だと `overlayfs` になるので、この 1 つで両方を確かめられる | 失敗 |
| 5 | sysctl | `fs.inotify.max_user_instances >= 512`、`fs.inotify.max_user_watches >= 524288` [K-2] | `sysctl -n` | 失敗 |
| 6 | カーネル | 5.10 以上（Cilium の要件 [C-16]） | `uname -r` | 失敗 |
| 7 | 権限 | `sudo` を使える（containerlab と host の netns 操作に必要） | `command -v sudo`。`check-host` 自身は sudo を実行しない | 失敗 |
| 8 | ツール | aqua で入れたツールに PATH が通っている | `aqua.yaml` の各ツールについて `command -v` | 失敗（`task setup` を案内する） |

- 失敗した項目があれば、その項目と直し方をすべて表示してから失敗する。最初の 1 件で止まらない。
- 警告の項目は表示だけして、成功として扱う。
- host の設定は変えない（読むだけ）。

---

## 2. バージョン

ツールは `aqua.yaml` で固定し、コンテナイメージ、chart、マニフェストのバージョンは `Taskfile.yaml` の vars で固定する。Go のモジュールは `e2e/go.mod` で固定する。

2026-11-05 時点の最新の安定版を調べて決めた。バージョンを変えるときは、この表も更新する。

### 2.1 ラボの構成要素

| コンポーネント | バージョン | 管理場所 | 選んだ理由 |
|---|---|---|---|
| Kubernetes（kindest/node） | v1.36.4（digest 付きで固定） | Taskfile vars | Cilium 1.20 [C-20] と Envoy Gateway 1.9 [E-8] が、どちらも 1.36 までを対応範囲に含めている。1.37 はどちらの範囲にも入っていない |
| Cilium | 1.20.4 | Taskfile vars | 最新の安定版。BGP v2 は `cilium.io/v2` で使える |
| Envoy Gateway | v1.9.3 | Taskfile vars | 最新の安定版 |
| Gateway API CRD | v1.6.1 | Envoy Gateway の chart に同梱されたもの | Envoy Gateway 1.9 が対応している版 [E-8]。単独では入れない |
| FRR | 10.7.1（`quay.io/frrouting/frr:10.7.1`） | Taskfile vars | 最新の安定版 |
| mcs-api | v0.5.2 | Taskfile vars | 最新の安定版 |
| CoreDNS | v1.14.2 | kindest/node v1.36.4 に同梱（kubeadm の既定） | multicluster プラグインに必要な 1.12.2 以上を満たす（[mcs.md](mcs.md)、[C-19]） |

kind v0.33.0 の既定のイメージは v1.37.0 なので、kind の設定でノードのイメージを明示して v1.36.4 にする。

### 2.2 ツール

| ツール | バージョン | 管理場所 | 備考 |
|---|---|---|---|
| aqua | v2.66.1 | host（CI は aqua-installer） | aqua 自体はラボの外で入れる |
| aqua-registry | v4.581.1 | aqua.yaml | |
| kind | v0.33.0 | aqua | |
| containerlab | v0.82.0 | aqua | |
| kubectl | v1.36.6 | aqua | サーバ（1.36）と同じマイナーバージョンにそろえる |
| helm | v3.22.1 | aqua | v4 系が最新だが、v3 系にする。neco-apps と同じ系列にそろえ、Helm 4 の挙動の変更（server-side apply が既定になったことなど）を持ち込まないため |
| kustomize | v5.8.3 | aqua | |
| go-task | v3.54.0 | aqua | |
| yq | v4.54.1 | aqua | |
| jq | 1.8.2 | aqua | |
| cilium-cli | v0.20.2 | aqua | |
| kubeconform | v0.8.0 | aqua | |
| lychee | v0.24.2 | aqua | markdown のリンクチェック |
| uv | 0.13.7 | aqua | yamllint を `uvx` で動かすためだけに使う |
| yamllint | 1.38.0 | Taskfile vars（`uvx yamllint@<ver>`） | aqua-registry にないため |
| Go | 1.26 | `e2e/go.mod`（`go` と `toolchain`） | CI は `actions/setup-go` の `go-version-file` で同じ版を使う |
| testify | v1.12.1 | `e2e/go.mod` | E2E のアサーションと待ち合わせ（[testing.md](testing.md) 3 章） |
| d2 | v0.9.0 | yatate（tomei の `cliTools`）。CI はワークフローで公式リリースを取得 | ドキュメントの図の生成にだけ使う |

aqua の checksum 検証を有効にする（`checksum.enabled: true`、`require_checksum: true`）。checksum は `aqua-checksums.json` としてコミットする [T-2]。

---

## 3. Taskfile

### 3.1 構成

- `Taskfile.yaml` を 1 つだけ置く。include で分けるのは、タスクが増えて読みにくくなってからにする。
- バージョンなど、ほかの PR で変える値は、ファイル先頭の `vars` にまとめる。
- ツールは PATH 上のもの（aqua の shim）を使う。タスクの中で `aqua exec` は使わない。
- 冪等にできるタスクは、Task の `status` や `preconditions` を使って冪等にする [T-1]。

### 3.2 タスク一覧

| タスク | 内容 | 定義するドキュメント | 追加する PR |
|---|---|---|---|
| `setup` | `aqua install`（ラボの aqua.yaml のツールをダウンロードまで済ませる。`-l` だとリンクだけ作り、初回の実行時にダウンロードするため使わない） | 本書 | 01 |
| `check-host` | 1 章の前提条件を検査する | 本書 | 01 |
| `lint` | 静的テスト | [testing.md](testing.md) 4 章 | 01 |
| `test` | E2E テスト（`LABEL=` で絞り込み） | [testing.md](testing.md) 3 章 | 01 |
| `docs` | `docs/diagrams/*.d2` から SVG を生成する | [development.md](development.md) 7 章 | 01 |
| `start` | 4 章の起動手順をすべて実行する | 本書 | 02 |
| `stop` | 5 章の停止手順を実行する | 本書 | 02 |
| `status` | トポロジ、BGP、クラスタの状態を一覧する | 本書 | 02 |
| `deploy-fabric` | containerlab、kind、FRR、host 経路 | [network.md](network.md) | 02 |
| `deploy-cilium` | Cilium と CiliumPodIPPool | [cilium.md](cilium.md) | 03 |
| `deploy-bgp` | BGP と LB IPAM | [cilium.md](cilium.md) | 04 |
| `deploy-dsr` | DSR / Maglev を有効にする | [cilium.md](cilium.md) | 05 |
| `deploy-gateway` | Envoy Gateway と Gateway、HTTPRoute | [envoy-gateway.md](envoy-gateway.md) | 06 |
| `deploy-mcs` | MCS の CRD、コントローラ、CoreDNS | [mcs.md](mcs.md) | 07 |
| `deploy-sample` | echo と ServiceExport | [mcs.md](mcs.md) | 07 |
| `sync-mcs` | edge への同期 | [mcs.md](mcs.md) | 07 |

まだ実装されていないコンポーネントのタスクは、Taskfile に置かない。「追加する PR」の列のとおりに増やしていく。

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
- `task setup`（aqua でラボのツールを入れる）

### 6.2 してはいけない操作

- 6.1 にない host の設定変更（sysctl の永続化、Docker daemon 設定の書き換えなど）
  - 前提条件を満たしていない場合は、自分で直さずに人に報告して止まる。
- `kindcluster/mcs-gateway/` と `.github/workflows/kindcluster-mcs-gateway.yml` 以外の変更。他のラボや dotfiles は触らない。
- `tomei` / `chezmoi` の実行（リポジトリの CLAUDE.md で禁止されている）

---

## 7. 参考文献

[I-5] [I-8] [I-9] [K-2] [C-16] [C-19] [C-20] [E-8] [T-1] [T-2]（[references.md](references.md)）
