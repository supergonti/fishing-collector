# 釣果データ収集ツール V5.5 開発経緯まとめ
作成日：2026年4月10日

---

## ■ 開発の背景・目的

釣果データ収集ツール V5.4 をベースに、将来の統合データベース（V6.0）構築に向けた準備として、各釣果レコードに**釣り場の地理情報（緯度・経度）と最近傍観測地点**を紐づける機能を追加した。

最終目標は、釣果データ（V5.5）を中心として天気・水温・潮汐・月齢の各補助データを「日付 × 最近傍観測地点」で自動結合した統合データベース（V6.0 / index.html 1ファイル）を GitHub Pages 上で運用することである。

---

## ■ V5.4 からの変更点一覧

### 1. データ構造の拡張

既存のカラム構成に以下の3フィールドを追加した。

| 追加フィールド | 型 | 内容 |
|---|---|---|
| `spot_lat` | 数値（小数） | 釣り場の緯度（例：33.28） |
| `spot_lng` | 数値（小数） | 釣り場の経度（例：134.15） |
| `nearest_station` | 文字列 | 最近傍観測地点名（例：室戸岬沖） |

既存840件のレコードは互換性を保ったまま読み込まれ、新フィールドは空値として扱われる（localStorage キー `fishing_v2` は継続使用）。

### 2. Claude解析プロンプトの改良

Instagram スクショをClaudeに解析させる際のプロンプトに「手順4」を追加した。

**追加内容：** 釣り場の地名（spot）から日本の緯度・経度を推定し、JSON の `spot_lat`・`spot_lng` フィールドとして返す。

```json
{
  "spot": "室戸岬沖",
  "spot_lat": 33.26,
  "spot_lng": 134.18,
  ...
}
```

地名が不明瞭な場合（「沖」など）は `null` を返すよう指示。

### 3. Haversine 最近傍マッチング

以下の8観測地点マスタ（四国沿岸）との Haversine 距離を計算し、最近傍地点を自動選択する。距離が **300km 超** の場合は `null`（該当なし）とする。

| 観測地点名 | 緯度 | 経度 |
|---|---|---|
| 室戸岬沖 | 33.26 | 134.18 |
| 高知市沖 | 33.56 | 133.53 |
| 足摺岬沖 | 32.78 | 132.97 |
| 宇和島沖 | 33.22 | 132.56 |
| 松山沖 | 33.84 | 132.77 |
| 来島海峡 | 34.07 | 133.00 |
| 高松沖 | 34.34 | 134.05 |
| 阿南市沖 | 34.07 | 134.56 |

この計算は新規レコード取り込み時（Claude JSON取り込み・手動入力・クローン）に自動実行される。

### 4. 既存レコード一括ジオコーディング機能

データ一覧タブに「🌐 緯度経度一括取得（未設定 N件）」ボタンを追加。

- ポイント名ごとにユニーク化して **Nominatim API**（OpenStreetMap / 無料・APIキー不要）を呼び出す
- Nominatim の利用規約に従い **1,000ms 間隔**でリクエストを送信
- 進捗バーとステータスメッセージをリアルタイム表示
- 取得成功後、同名ポイントの全レコードに一括反映し即時保存

```javascript
// Nominatim API 例
fetch('https://nominatim.openstreetmap.org/search?q=室戸岬&format=json&limit=1&countrycodes=jp')
```

### 5. 手動入力フォームの拡張

手動入力タブに「位置情報」セクションを追加。

- `spot_lat`・`spot_lng` の手動入力フィールド
- 「🔍 ポイント名から自動取得」ボタン（Nominatim API を呼び出し緯度経度を自動入力）
- 「📍 最近傍地点を計算」ボタン（入力済みの緯度経度から即時計算・表示）

### 6. データ一覧テーブルの変更

「ポイント」列の右隣に「**最近傍地点**」列（緑色）を追加。テーブルの最小幅を 880px → 1060px に拡張。

### 7. 統計バーの拡張

「地点設定済」件数（`spot_lat` が設定されているレコード数）の統計表示を追加。

### 8. CSV 出力・読み込みの拡張

エクスポート・インポート両方で `spot_lat`・`spot_lng`・`nearest_station` の3カラムを追加対応。

**V5.5 の CSV ヘッダー：**
```
date,time,species,size_cm,weight_kg,count,bait,method,spot,spot_lat,spot_lng,nearest_station,tide,weather,temp,water_temp,wind,memo,source
```

V5.4 の CSV（旧フォーマット）はそのまま読み込み可能。新フィールドが存在しない場合は空値として扱われる。

### 9. CSV_URL の変更

GitHub リポジトリ上のファイル名と一致させるため、以下の1行を変更した。

```javascript
// V5.4
const CSV_URL = 'data.csv';

// V5.5
const CSV_URL = 'fishing_data.csv';
```

### 10. CSV エクスポートファイル名の固定

V5.4 では日付入りのファイル名（例：`釣果DB_20260410.csv`）で出力していたが、GitHub リポジトリのファイル名と一致させるため `fishing_data.csv` に固定した。

### 11. GitHub API 直接アップロード機能

ボタン一つで GitHub リポジトリの `fishing_data.csv` を更新できる機能を追加した。従来の手動アップロード（ドラッグ＆ドロップ → Commit changes）が不要になった。

**実装内容：**
- GitHub Contents API（`PUT /repos/{owner}/{repo}/contents/{file}`）を使用
- Personal Access Token (classic) を localStorage に保存（キー：`fishing_gh_token`）
- ⚙ ボタンからトークン設定モーダルを表示
- 🚀 GitHubに保存 ボタンで即時アップロード
- 成功時は alert ダイアログで Commit SHA を表示して確認可能
- エラー時は HTTP ステータスと詳細メッセージを alert で表示

**トークン設定：**
- GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
- スコープ：`public_repo` にチェック
- 生成されたトークン（`ghp_...`）をアプリの ⚙ ボタンから入力
- トークンはブラウザごと・ドメインごとに個別保存（GitHub Pages版とローカル版は別設定）

**技術的な経緯と修正：**
1. 当初 `Authorization: Bearer` 形式を使用 → GitHub PAT (classic) の正式形式 `Authorization: token` に修正
2. `credentials:'omit'` を fetch に追加 → ブラウザの HTTP Basic Auth ダイアログは防げたが Authorization ヘッダー送信に問題が出る可能性があったため削除
3. トーストだけでは成功/失敗の判別が困難だったため、alert ダイアログで詳細表示に変更
4. Commit SHA を表示して「見かけ上の成功」を防止（同一内容の場合はGitHub側でタイムスタンプが更新されない仕様のため）

### 12. パスワード認証の削除

V5.4 で実装していたパスワード認証画面（パスワード：`7360`）を削除した。アプリ起動時にパスワード入力を求めず、直接データ一覧が表示される。

---

## ■ ファイル構成（V5.5 フォルダ）

```
fishing log 開発　釣果データ収集ソフトｖ55/
├── fishing_collector_V55.html    ← V5.5 本体（ローカル動作確認用）
├── index.html                    ← GitHub Pages 用（同内容）
├── fishing_data.csv              ← V5.4 から引き継いだ釣果データ（840件）
├── data.csv                      ← バックアップ用（fishing_data.csv と同内容）
├── 釣果V5.4の釣り場の地点データ改良.md  ← 開発仕様書（引継ぎドキュメント）
└── fishing_collector_v5.5.md     ← このファイル（開発経緯まとめ）
```

---

## ■ GitHub への反映手順

リポジトリ：`https://github.com/supergonti/fishing-collector`
公開 URL：`https://supergonti.github.io/fishing-collector/`

V5.5 への更新時にアップロードが必要なファイルは以下の1点のみ。

| ファイル | 操作 |
|---|---|
| `index.html` | 差し替え（V5.5版にアップロード） |

`fishing_data.csv` はアプリ内の「🚀 GitHubに保存」ボタンから直接更新可能。手動アップロードは不要。

---

## ■ 変更しなかった項目（V5.4 からの継続）

- localStorage の管理キー：`fishing_v2`（既存データをそのまま引き継ぐ）
- CSV フィンガープリントキー：`fishing_csv_fp`
- 既存機能（重複検出・クローン・ソート・フィルタ・統計バーなど）はすべて継続

---

## ■ 次フェーズ（V6.0 統合）の概要

V5.5 完成後、別チャットで以下を実施予定。

1. 各補助データを GitHub にアップロード
   - `weather_data.csv`（天気データ 約13,000件 / 8地点）
   - `water_temp_data.csv`（水温データ 9,783件 / 8地点）
   - `tide_table_data.csv`（潮汐・月相データ 18,335件 / 8地点）
   - `moon_age_data.csv`（月齢データ 1,560件）

2. 統合 `index.html`（V6.0）を開発
   - 釣果データ表示に天気・水温・潮汐・月齢の列を `nearest_station` × `date` で自動結合
   - GitHub Pages で 1ファイル完結で運用

---

*釣果データ収集ツール V5.5 開発経緯まとめ — 2026年4月10日*
