# moi moi 情報ビューア（iOS / SwiftUI）— 初期プロジェクト

「おかあさんといっしょ」非公式ファンサイト [moi moi](http://moi-moi.jp/) の情報を検索・閲覧するための
SwiftUIアプリの初期構成です。対象OSは **iOS 17+**（SwiftData / `@Observable` / `NavigationStack` を利用）。

Xcodeプロジェクトは [XcodeGen](https://github.com/yonaskolb/XcodeGen) で `project.yml` から生成します
（`.xcodeproj` はコミットしません。衝突を避けるため）。ローカルで開く場合:

```sh
brew install xcodegen   # 初回のみ
xcodegen generate
open MoiMoiViewer.xcodeproj
```

すべてのファイルは iOS 17 Simulator SDK でのタイプチェック・ビルドを通過済みです。

## CI/CD（GitHub Actions → TestFlight）

- `.github/workflows/ci.yml`: `main` へのPRごとにシミュレータ向けビルドを検証。
- `.github/workflows/testflight.yml`: `main` へのpush（または手動実行）で自動アーカイブ・
  署名・TestFlightへアップロード。署名はApp Store Connect API Keyによる自動署名
  （`-allowProvisioningUpdates`）を使用するため、証明書やプロビジョニングプロファイルを
  手動管理する必要はありません。

このワークフローが動くには、以下の **GitHub Actions Secrets**（Settings → Secrets and
variables → Actions → New repository secret）が必要です。いずれもApple側の操作でしか
発行できないため、事前に用意してください。

| Secret名 | 内容 | 取得場所 |
|---|---|---|
| `APPSTORE_CONNECT_KEY_ID` | API Keyの Key ID | App Store Connect → ユーザ管理 (Users and Access) → 統合 (Integrations) → App Store Connect API |
| `APPSTORE_CONNECT_ISSUER_ID` | Issuer ID | 同上ページ上部に表示 |
| `APPSTORE_CONNECT_KEY_CONTENT` | ダウンロードした `AuthKey_XXXXXXXXXX.p8` の中身を **base64化**した文字列（`base64 -i AuthKey_XXXXXXXXXX.p8 \| pbcopy`） | 上記でKey作成時に一度だけダウンロード可 |
| `APPLE_TEAM_ID` | 10桁の英数字チームID | Apple Developer → Membership |

API Keyのロールは自動署名（Bundle ID登録含む）を行うため **Admin** を推奨します。

ワークフローは `macos-15` ランナーのデフォルトXcodeを使用します。iOS 17 SDK が必要なため、
GitHubがランナーイメージの既定Xcodeを更新してビルドが壊れた場合は、
`.github/workflows/*.yml` に `xcode-select -s /Applications/Xcode_XX.X.app/Contents/Developer`
のステップを追加して固定してください（利用可能なバージョンは
[actions/runner-images](https://github.com/actions/runner-images) のmacOSイメージREADMEを参照）。

`project.yml` 内の `PRODUCT_BUNDLE_IDENTIFIER: com.oshiromitsuaki.moimoiviewer` は仮の値です。
実際にApp Store Connectで作成する「App」のBundle IDと一致させてください（変更後は
`xcodegen generate` を再実行）。

## 最初に検討してほしいこと（技術外の注意点）

moi moiは個人が長年運営してきた非公式ファンサイトです。実装を進める前に、サイト運営者へ
連絡してデータの二次利用について許可を得ることを強く推奨します。合わせて以下も設計に織り込んでいます。

- 各詳細画面に「出典: moi moi で見る」リンクを設置し、必ず原典へ導線を残す（`sourceURLString`）。
- スクレイピングは後述のとおりサーバー側で低頻度・集中管理し、サイトへの負荷を最小化する。
- `robots.txt` や利用規約を確認し、許可されない範囲の収集・再配布は行わない。

## 技術的アプローチの選定理由

### 1. データ収集はアプリ内スクレイピングではなく「サーバー側パイプライン + JSON配信」

- 端末上でHTMLを直接パースする実装は、サイト構造の変更に弱く、全ユーザーの端末から
  同時多発的にアクセスが発生してサイトに負荷をかけてしまう。
- 代わりに、定期実行のスクレイパー（Cron/GitHub Actionsなど）を1箇所だけ用意し、
  収集結果を正規化したJSON（`MoiMoiDataPayload`）として静的ホスティング
  （S3 / Cloudflare R2 / GitHub Pagesなど）に配置する構成を推奨。
- アプリは `APIClient` でこのJSONを取得するだけなので、HTML構造の変更はサーバー側の
  修正だけで吸収でき、App Storeへの再申請も不要になる。
- スクレイパー自体の実装は本リポジトリのスコープ外（別リポジトリ/別ジョブとして管理）。

### 2. ローカルDBは SwiftData

- CoreDataやSQLiteを直接扱うより記述量が少なく、`@Query` によるリアクティブなフィルタリングが
  検索画面と相性が良い。
- データ量は数千〜数万件規模と見込まれ、パフォーマンス面でもSwiftDataで十分。
- iOS 17+ を前提にすることで `@Observable` モデルや `#Predicate` マクロなど最新APIを使い、
  ボイラープレートを削減。

### 3. データモデルは「非正規化」寄りに設計

- `Song.singerNames` や `Broadcast.performerNames` は `Performer` への正式なリレーションではなく
  文字列配列として保持。スクレイピング元のHTMLが必ずしも構造化された関係を持たないため、
  多対多リレーションを厳密にモデリングするより、まず文字列一致で検索・絞り込みができる
  シンプルな構造を優先した。将来的に出演者ページとの正式なリンクが必要になれば、
  `Performer.id` を保持する形に拡張できる。

## フォルダ構成

```
MoiMoiViewer/
├── App/
│   ├── MoiMoiViewerApp.swift      # @main, ModelContainerの構築
│   └── RootTabView.swift          # ホーム/検索/お気に入りのタブ構成
├── Models/                        # SwiftData の @Model 群 + 検索用Predicate
│   ├── Performer.swift            # 出演者（歴代含む）
│   ├── PerformerRole.swift
│   ├── Song.swift                 # 今月のうた 等
│   ├── Broadcast.swift            # 放送予定・結果
│   └── SearchFilter.swift         # 検索フィルタの値型
├── Networking/
│   ├── RemoteDTOs.swift           # サーバー配信JSONのCodable定義
│   └── APIClient.swift
├── Persistence/
│   └── DataSyncService.swift      # JSON取得 → SwiftDataへupsert
├── Features/
│   ├── Home/HomeView.swift        # 新着・今月のうた
│   ├── Search/                    # ★ 主要機能：検索画面
│   │   ├── SearchView.swift
│   │   ├── SearchResultsListView.swift
│   │   ├── SearchResultItem.swift
│   │   └── SearchFilterSheet.swift
│   ├── Favorites/FavoritesView.swift
│   └── Detail/                    # 出演者・曲・放送回の詳細
├── Components/
│   ├── SearchResultRow.swift
│   └── FilterChip.swift
└── README.md
```

## 検索画面の設計ポイント

- `SearchView` はキーワード入力欄（`.searchable`）と絞り込みボタンを持ち、
  結果表示は `SearchResultsListView` に委譲。
- `SearchResultsListView` は `SearchFilter` を受け取るたびに3つの `@Query`
  （出演者・曲・放送回）を動的な `#Predicate` で再構築し、結果を1つのリストにマージする
  （SwiftDataの標準的な「動的フィルタリング」パターン）。
- キーワード・出演者名・年の絞り込みはアクティブなフィルタとして画面上部にチップ表示され、
  タップ1つで解除できる。
- お気に入り（`isFavorite`）は各モデルに直接フラグとして持たせ、`FavoritesView` で
  種別ごとにまとめて表示。

## 次のステップ（未実装・要検討）

- スクレイピングパイプライン（別リポジトリ推奨）とJSON配信先の決定。
- サイト運営者への許諾確認、利用規約・クレジット表記の最終文言。
- オフライン時の挙動（初回起動時にデータが空の場合のオンボーディング）。
- 出演者⇔曲⇔放送回の正式なリレーション化（必要になった場合）。
