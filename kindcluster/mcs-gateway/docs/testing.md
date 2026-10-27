# テスト

- 関連: [development.md](development.md)（テストを書くタイミング）、[operations.md](operations.md)（`task test`）

## 1. 方針

- テストの中身（何を確かめるか）は、各コンポーネントのドキュメントの「テスト仕様」の節に書き、実装より先にレビューする。
- テストコードは、実装の後に書く（[development.md](development.md) の Step 3）。
- テスト仕様の表の 1 行が、Ginkgo の 1 spec に対応する。spec の名前にはテスト ID（例: `fabric-01`）を含める。
- 既存のテストは回帰テストとして残し、テストは累積していく。
- テストを消したり skip したりして green にしてはいけない。仕様を変えるときは、先にドキュメントのテスト仕様を変えてレビューを受ける。

## 2. テスト仕様の場所

| ラベル | ドキュメント |
|---|---|
| `fabric` | [network.md](network.md) 6 章 |
| `cilium`, `bgp`, `dsr` | [cilium.md](cilium.md) 7 章 |
| `gateway`, `multicluster-gateway` | [envoy-gateway.md](envoy-gateway.md) 4 章 |
| `mcs` | [mcs.md](mcs.md) 4 章 |

---

## 3. E2E テスト

- Go + Ginkgo で書き、`kindcluster/mcs-gateway/e2e/` に置く [T-3]。
  - terakoya の `kindcluster/coil-stand-alone-egress-compatibility/`（`suite_test.go`、`coil_test.go`）の構成を流用する [I-11]。
- ファイルはラベルごとに分ける。

  ```
  e2e/
  ├── go.mod
  ├── suite_test.go
  ├── helpers_test.go
  ├── fabric_test.go
  ├── cilium_test.go
  ├── bgp_test.go
  ├── dsr_test.go
  ├── gateway_test.go
  ├── mcs_test.go
  └── multicluster_gateway_test.go
  ```

- 各 spec に Ginkgo の `Label(...)` を付ける [T-4]。
- `task test` は、実装済みのラベルをすべて実行する。`task test LABEL=bgp` のように、`--label-filter` で絞り込める。
- `helpers_test.go` に用意するヘルパー:
  - kubectl のコンテキスト指定（`kind-edge`、`kind-core1`、`kind-core2`）
  - `docker exec clab-mcsgw-<router> vtysh -c '<cmd> json'` を実行し、JSON をパースする
  - ノード（kind コンテナ）内でのコマンド実行（`docker exec`）
  - Pod 内でのコマンド実行（`kubectl exec`）
  - host からの curl / ping
  - テスト用 Pod と Service の作成と削除
- 状態が収束するまで待つ必要がある箇所は `Eventually` を使い、固定の sleep は使わない。
- テストが作ったリソースは、テストの終わりに削除する。サンプル app（`demo/echo`）のように Taskfile が作ったものは削除しない。

---

## 4. 静的テスト（`task lint` / CI）

`.github/workflows/kindcluster-mcs-gateway.yml` を作り、`paths: kindcluster/mcs-gateway/**` のときだけ動かす。CI は `task lint` を実行する。

| 検査 | 対象 |
|---|---|
| yamllint | すべての YAML |
| kubeconform（CRD スキーマ込み） | Kubernetes マニフェスト [T-5] |
| `helm template` | Cilium と Envoy Gateway の values が展開できること |
| `vtysh --dryrun -f`（frr コンテナ内で実行） | `frr/*.conf` [F-2] |
| `go vet` | `e2e/` |
| `ginkgo --dry-run` | spec がコンパイルでき、列挙できること |
| markdown のリンクチェック | `docs/`（相対リンク切れがないこと） |
| `task docs` の再実行 | `docs/images/*.svg` に差分が出ないこと（図のソースと生成物が一致している） |

---

## 5. E2E の CI 化

- 最後の PR で、GitHub Actions の標準 runner（ubuntu-24.04）上で 9 ノードが動くかを評価する。
- リソースが足りない場合は、worker 数を変数（例: `WORKERS=1`）で減らせるようにする。それでも無理なら見送り、本書にそう書く。
- それまでの PR では、ローカルの再現性確認（[development.md](development.md) の Step 3）のログを PR 説明に貼って担保する。

---

## 6. 参考文献

[I-11] [T-3]〜[T-5] [F-2]（[references.md](references.md)）
