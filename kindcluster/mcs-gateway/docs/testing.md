# テスト

- ステータス: `Reviewed`
- 関連: [development.md](development.md)（テストを書くタイミング）、[operations.md](operations.md)（`task test`、`task lint`、バージョン）

## 1. 方針

- テストの中身（何を確かめるか）は、各コンポーネントのドキュメントの「テスト仕様」の節に書き、実装より先にレビューする。
- テストコードは、実装の後に書く（[development.md](development.md) の Step 3）。
- テスト仕様の表の 1 行が、Go のサブテスト 1 つに対応する。サブテストの名前はテスト ID（例: `fabric-01`）にする。
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

### 3.1 構成

- Go 標準の `testing` パッケージと testify（`assert` / `require`）で書き、`kindcluster/mcs-gateway/e2e/` に置く [T-3][T-4]。
  - BDD 風の DSL（Ginkgo など）は使わない。素の Go のテストにして、読む人と書く AI が覚えることを減らす。
  - 独立した Go モジュールにする。モジュール名は `github.com/terassyi/terakoya/kindcluster/mcs-gateway/e2e`、パッケージ名は `e2e`。
- 依存は testify だけにする。Kubernetes のリソースは `kubectl` の JSON 出力を `encoding/json` で読む。client-go は使わない（3 クラスタ分の client を持つより、`--context` を変えるだけの方が単純なため）。
- ファイルはラベルごとに分ける。PR 01 で作るのは `go.mod`、`go.sum`、`main_test.go`、`helpers_test.go` だけで、ほかは各 PR で足す。

  ```
  e2e/
  ├── go.mod                       # 01
  ├── go.sum                       # 01
  ├── main_test.go                 # 01（TestMain）
  ├── helpers_test.go              # 01
  ├── fabric_test.go               # 02
  ├── cilium_test.go               # 03
  ├── bgp_test.go                  # 04
  ├── dsr_test.go                  # 05
  ├── gateway_test.go              # 06
  ├── mcs_test.go                  # 07
  └── multicluster_gateway_test.go # 08
  ```

### 3.2 ラベルとテスト ID

ラベル 1 つにトップレベルのテスト関数を 1 つ置き、テスト ID ごとに `t.Run` でサブテストを作る。

| ラベル | テスト関数 | ファイル |
|---|---|---|
| `fabric` | `TestFabric` | `fabric_test.go` |
| `cilium` | `TestCilium` | `cilium_test.go` |
| `bgp` | `TestBGP` | `bgp_test.go` |
| `dsr` | `TestDSR` | `dsr_test.go` |
| `gateway` | `TestGateway` | `gateway_test.go` |
| `mcs` | `TestMCS` | `mcs_test.go` |
| `multicluster-gateway` | `TestMulticlusterGateway` | `multicluster_gateway_test.go` |

```go
func TestBGP(t *testing.T) {
	t.Run("bgp-01", func(t *testing.T) {
		// ToR で show bgp summary json を見て、自クラスタの 3 ノードが Established
	})
	t.Run("bgp-02", func(t *testing.T) { /* ... */ })
}
```

- サブテストの名前はテスト ID だけにする。何を確かめるかはドキュメントの表を正とし、コードでは ID の直前のコメントに 1 行で書く。
- サブテストは書いた順に直列で実行する。`t.Parallel` は使わない（同じクラスタとルータを観測するため）。
- 前のサブテストの結果に依存しない。必要な前提（テスト用 Pod など）はサブテストの中か、テスト関数の先頭で作る。

### 3.3 `TestMain`（`main_test.go`）

- 環境変数 `MCSGW_E2E=1` がないときは、何も実行せずに終了コード 0 で終わる。`go test ./...` や `go vet` をクラスタなしで実行しても失敗しないようにするため。`task test` と `task lint`（`go test -list`）は、この変数を付けて実行する。
- クラスタへの接続確認などは `TestMain` でしない（PR 01 の時点ではクラスタがないため）。

### 3.4 待ち合わせとアサーション

- 状態が収束するまで待つ箇所は、testify の `assert.EventuallyWithT` を使う。最後に失敗したときの理由がそのまま出るため（`require.Eventually` は `bool` しか返せず、なぜ失敗したかが残らない）。固定の sleep は使わない。
- 既定値は `helpers_test.go` の定数にする: タイムアウト 5 分（`eventuallyTimeout`）、間隔 1 秒（`eventuallyTick`）。
- その場で失敗させてよい前提の確認には `require`、続けて見たい確認には `assert` を使う。
- テストが作ったリソースは `t.Cleanup` で削除する。サンプル app（`demo/echo`）のように Taskfile が作ったものは削除しない。

### 3.5 ヘルパー（`helpers_test.go`）

PR 01 で次を用意する。各 PR で必要になったものは、そのときに足す。

- エラーを返す版と、失敗したらその場でテストを止める `must` 版を用意する。`assert.EventuallyWithT` の中ではエラーを返す版を使う（中でテストを止めると、待ち合わせにならないため）。
- `must` 版は最初に `t.Helper()` を呼び、失敗した行がテスト側の行として表示されるようにする。

| ヘルパー | 内容 |
|---|---|
| `clusters` | `[]string{"edge", "core1", "core2"}` |
| `kubectl(cluster, input, args...)` / `mustKubectl(t, ...)` | `kubectl --context kind-<cluster> <args>` を実行し、stdout を返す。`input` は stdin |
| `getResource(cluster, ns, resource, name, obj)` | `kubectl get -o json` を `obj` に読み込む |
| `kubectlExec(cluster, ns, pod, cmd...)` | Pod 内でコマンドを実行する |
| `dockerExec(container, cmd...)` | `docker exec <container> <cmd>` を実行する |
| `nodeExec(node, cmd...)` | kind ノード（コンテナ名 `<cluster>-control-plane` など）内でコマンドを実行する |
| `vtyshJSON(router, cmd, obj)` | `docker exec clab-mcsgw-<router> vtysh -c '<cmd> json'` の出力を `obj` に読み込む |
| `hostCurl(args...)` | host で `curl` を実行する（host から VIP への到達性を見るため） |
| `applyManifest(t, cluster, yaml)` | テスト用 Pod と Service を作り、`t.Cleanup` に削除（`--ignore-not-found`）を登録する |

コマンドのパスは `PATH` から探す。aqua の shim が `PATH` にある前提（[operations.md](operations.md) 1 章の 8）。

### 3.6 実行（`task test`）

`e2e/` で `MCSGW_E2E=1 go test -count=1 -v -timeout 60m -run '<pattern>' ./...` を実行する。`-count=1` でテスト結果のキャッシュを使わない。

| 指定 | `-run` | 例 |
|---|---|---|
| なし | なし（すべて） | `task test` |
| `LABEL=<ラベル>` | `^<テスト関数>$`（3.2 の表で変換する） | `task test LABEL=bgp` → `-run '^TestBGP$'` |
| `ID=<テスト ID>` | `^<テスト関数>$/^<ID>$` | `task test ID=bgp-04` → `-run '^TestBGP$/^bgp-04$'` |

- ラベルからテスト関数への変換表は、Taskfile の vars に持つ。知らないラベルを指定したら失敗する。
- PR 01 の時点ではテストが 0 個なので、`task test` は成功する（Go は「no tests to run」と警告するだけで成功する）。テストができる PR 02 からは、出力に `no tests to run` があれば `task test` を失敗させる。`ID` の打ち間違いなどで何も実行されないまま green になるのを防ぐため。

---

## 4. 静的テスト（`task lint` / CI）

### 4.1 検査の一覧

`task lint` は次の検査をすべて実行し、1 つでも失敗したら失敗する。検査は、対象のファイルを作る PR で足す。対象がまだない検査は置かない。

| 検査 | 対象 | コマンド | 追加する PR |
|---|---|---|---|
| yamllint | ラボ内のすべての YAML（`Taskfile.yaml`、`aqua.yaml` を含む） | `uvx yamllint@<ver> -s .`（設定は `.yamllint.yaml`） [T-9] | 01 |
| gofmt | `e2e/` | `gofmt -l e2e` の出力が空 | 01 |
| go vet | `e2e/` | `e2e/` で `go vet ./...` | 01 |
| テストの列挙 | `e2e/` | `e2e/` で `MCSGW_E2E=1 go test -list '.*' ./...`。テストがコンパイルでき、列挙できること | 01 |
| リンクチェック | `docs/**/*.md` | `lychee --offline --no-progress 'docs/**/*.md'`。相対リンクの切れを見る。外部 URL は見ない（CI が外部サイトの状態で落ちないようにするため） [T-8] | 01 |
| 図の生成物 | `docs/images/*.svg` | `task docs` を実行し、`git status --porcelain docs/images` が空であること。`.d2` に対応する `.svg` がない、または `.svg` だけが残っている場合も失敗する | 01 |
| テスト ID の対応 | `e2e/*_test.go` とドキュメントのテスト仕様 | 実装済みのラベル（`<label>_test.go` があるもの）について、ドキュメントの表のテスト ID と、コードの `t.Run("<ID>"` が過不足なく一致すること。テスト ID を `go test -list` で列挙できないので、grep で突き合わせる。再現性確認で確かめる ID（fabric-09、fabric-10）は除く | 02 |
| FRR の設定 | `frr/*.conf` | FRR のコンテナ内で `vtysh --dryrun -f` [F-2] | 02 |
| kubeconform | Kubernetes マニフェスト | CRD スキーマ込みで検証する [T-5] | 03 |
| helm template | Cilium の values | values が展開できること | 03 |
| helm template | Envoy Gateway の values | 同上 | 06 |

`.yamllint.yaml` は `extends: default` にし、次の 2 つだけ変える。

- `line-length`: 無効にする（URL や CRD のフィールドで長くなるため）。
- `document-start`: 無効にする（`---` を必須にしない）。

### 4.2 CI ワークフロー

`.github/workflows/kindcluster-mcs-gateway.yml`

| 項目 | 内容 |
|---|---|
| トリガー | `pull_request` と `push`（`main` のみ） |
| paths | `kindcluster/mcs-gateway/**` と `.github/workflows/kindcluster-mcs-gateway.yml` |
| `pull_request` の branches | 指定しない。stacked PR は `main` 以外のブランチを base にするので、どの base でも動かす |
| runner | `ubuntu-24.04` |
| 作業ディレクトリ | `kindcluster/mcs-gateway` |
| ジョブ | `lint` の 1 つ |

`lint` ジョブのステップ:

1. `actions/checkout`
2. `actions/setup-go`（`go-version-file: kindcluster/mcs-gateway/e2e/go.mod`）
3. `aquaproj/aqua-installer`（aqua v2.66.1）。ラボの `aqua.yaml` のツールを入れる。
4. d2 v0.9.0 を公式リリースから取得する。チェックサムを検証し、`PATH` に置く。
5. `task lint`

action はリポジトリの既存のワークフローと同じく、メジャーバージョンのタグで指定する（例: `actions/checkout@v6`）。

---

## 5. E2E の CI 化

- 最後の PR で、GitHub Actions の標準 runner（ubuntu-24.04）上で 9 ノードが動くかを評価する。
- リソースが足りない場合は、worker 数を変数（例: `WORKERS=1`）で減らせるようにする。それでも無理なら見送り、本書にそう書く。
- それまでの PR では、ローカルの再現性確認（[development.md](development.md) の Step 3）のログを PR 説明に貼って担保する。

---

## 6. 未確定事項

- **kubeconform の CRD スキーマ:** datreeio/CRDs-catalog を commit で固定して使うか、固定した版の CRD からスキーマを生成するかを PR 03 で決める。固定した版の Cilium の CRD が catalog にない可能性があるため。

---

## 7. 参考文献

[I-11] [T-3]〜[T-5] [T-8] [T-9] [F-2]（[references.md](references.md)）
