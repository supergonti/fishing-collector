# 釣果データベース × 釣り条件分析データベース 結合引継ぎ書
**作成日：2026年4月11日**

---

## ■ このドキュメントの目的

釣果データ収集ソフト（V5.5）と釣り条件分析データベース（V6.0）を結合し、統合釣果データベース（V6.0）を構築するための引継ぎ資料。この作業は別のチャットセッションで行う。

---

## ■ 最終ゴール

1. **統合データベース（index.html）**：釣果データに天気・水温・潮汐・月齢を自動結合して表示
2. **GitHub Pages運用**：1つのリポジトリで全データ・全ソフトを管理
3. **週次自動更新**：GitHub Actionsで環境データを毎週自動収集
4. **分析ソフト**：統合データCSVを解析するツールの開発（将来）

---

## ■ 現在のシステム構成

### 釣果データ収集ソフト V5.5

| 項目 | 値 |
|------|-----|
| ファイル | `fishing_collector_V55.html` / `index.html` |
| データ保存 | localStorage（キー：`fishing_v2`） |
| データ件数 | 840件 |
| データファイル | `fishing_data.csv`（UTF-8 BOM） |
| GitHub | `https://github.com/supergonti/fishing-collector` |
| 公開URL | `https://supergonti.github.io/fishing-collector/` |
| GitHub保存 | GitHub Contents API + PAT (classic) で直接push可能 |

#### 釣果CSVの列構成（V5.5）

```
date, time, species, size_cm, weight_kg, count, bait, method,
spot, tide, weather, temp, water_temp, wind, memo, source,
spot_lat, spot_lng, nearest_station
```

- `spot`：釣り場名（例：高知室戸沖）
- `spot_lat`, `spot_lng`：釣り場の緯度・経度（V5.5で追加）
- `nearest_station`：Haversine距離で自動選択された最近傍観測地点名（V5.5で追加）
- `date`：日付（YYYY-MM-DD形式）

### 釣り条件分析データベース V6.0

| 項目 | 値 |
|------|-----|
| ファイル | `fishing_condition_db_V60.html` |
| データ保存 | IndexedDB（DB名：`fishing_condition_db`） |
| データ件数 | 約12,496件（8地点 × 約1,562日） |
| データ期間 | 2022-01-01 ～ 今日 |
| 出力ファイル | `fishing_condition_db.csv`（統合CSV）、`fishing_condition_db.json`（バックアップ） |
| API | Open-Meteo（天気・水温）、天文計算（潮汐・月齢） |
| 自動保存 | データ更新完了後にCSV + JSONを自動保存 |

#### 条件CSVの列構成（V6.0）

```
日付, 地点名, 観測地点名, 県, 緯度, 経度,
気温_平均, 気温_最高, 気温_最低, 風速_最大, 風向, 降水量, 天気コード, 天気,
水温, 最大波高, 波向, 波周期,
潮汐, 月齢, 月相
```

- `日付`：YYYY-MM-DD形式
- `地点名`：釣りスポット名（例：室戸）
- `観測地点名`：API用の観測地点名（例：室戸）
- データ集計時間帯：JST 6:00～8:00（TARGET_HOURS = [6, 7, 8]）

---

## ■ 結合ロジック

### 結合キー

```
釣果CSV.date = 条件CSV.日付
釣果CSV.nearest_station = 条件CSV.地点名
```

### 結合の流れ

1. 釣果データの各レコードから `date` と `nearest_station` を取得
2. 条件CSVから該当する `日付` × `地点名` の行を検索
3. マッチした場合、天気・水温・潮汐・月齢データを結合
4. マッチしない場合（nearest_stationが空、または条件データ未収集期間）は空値

### 結合後の統合CSVイメージ

```
date, time, species, size_cm, weight_kg, count, bait, method,
spot, tide, weather, temp, water_temp, wind, memo, source,
spot_lat, spot_lng, nearest_station,
気温_平均, 気温_最高, 気温_最低, 風速_最大, 風向_計測, 降水量, 天気コード, 天気_計測,
水温_計測, 最大波高, 波向, 波周期,
潮汐_計測, 月齢, 月相
```

※ 釣果CSVの既存列（weather, temp, water_temp, wind）はInstagramスクショからの手動読み取り値。条件DBからの自動取得値は「_計測」を付加して区別する。

---

## ■ 8観測地点マスタ（共通）

V5.5の`nearest_station`とV6.0の`地点名`は以下の8地点で一致している。

| 地点名 | 県 | 緯度 | 経度 |
|--------|-----|------|------|
| 室戸 | 高知県 | 33.29 | 134.18 |
| 高知 | 高知県 | 33.56 | 133.54 |
| 足摺 | 高知県 | 32.72 | 132.72 |
| 宇和島 | 愛媛県 | 33.22 | 132.56 |
| 松山 | 愛媛県 | 33.84 | 132.77 |
| 来島 | 愛媛県 | 34.12 | 132.99 |
| 高松 | 香川県 | 34.35 | 134.05 |
| 阿南 | 徳島県 | 33.92 | 134.66 |

**重要**：V5.5のHaversine計算で使う地点名と、V6.0の地点名が完全一致していることを確認済み。

---

## ■ 提案するGitHubリポジトリ構成

```
fishing-collector/              ← 既存リポジトリ
├── index.html                  ← 統合釣果データベース V6.0（新規開発）
├── fishing_data.csv            ← 釣果データ（V5.5から引き継ぎ、手動更新）
├── fishing_condition_db.csv    ← 環境条件データ（V6.0から出力、自動更新）
├── fishing_condition_db.json   ← 環境データバックアップ
├── fishing_integrated.csv      ← 結合済み統合データ（自動生成）
├── collector.html              ← 釣果データ収集ソフト V5.5（旧index.htmlをリネーム）
├── condition.html              ← 釣り条件分析データベース V6.0
└── .github/
    └── workflows/
        └── update-conditions.yml  ← 週次自動更新ワークフロー
```

### ファイルの役割

| ファイル | 更新方法 | 頻度 |
|---------|----------|------|
| `index.html` | 手動（開発時のみ） | 不定期 |
| `fishing_data.csv` | 手動（Instagramスクショ読み取り後push） | 不定期 |
| `fishing_condition_db.csv` | **自動**（GitHub Actions） | 週1回 |
| `fishing_integrated.csv` | **自動**（GitHub Actionsの結合ステップ） | 週1回 |
| `collector.html` | 手動 | 不定期 |
| `condition.html` | 手動 | 不定期 |

---

## ■ GitHub Actions ワークフロー設計

### 概要

毎週月曜日の朝（JST 9:00 = UTC 0:00）に以下を自動実行：

1. 条件CSVの最新日付を確認
2. 最新日付+1日～今日のデータをOpen-Meteo APIから取得
3. 既存CSVにデータを追記
4. 釣果CSVと条件CSVを結合して統合CSVを生成
5. 変更があればcommit & push

### ワークフローファイル案（update-conditions.yml）

```yaml
name: Update Fishing Conditions
on:
  schedule:
    - cron: '0 0 * * 1'  # 毎週月曜 UTC 0:00 (JST 9:00)
  workflow_dispatch:       # 手動実行も可能

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Update condition data
        run: node scripts/update-conditions.js

      - name: Merge fishing + condition data
        run: node scripts/merge-data.js

      - name: Commit and push
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add fishing_condition_db.csv fishing_condition_db.json fishing_integrated.csv
          git diff --staged --quiet || git commit -m "Auto-update condition data $(date +%Y-%m-%d)"
          git push
```

### 必要なスクリプト（scripts/フォルダ）

| スクリプト | 機能 |
|-----------|------|
| `update-conditions.js` | Open-Meteo APIから差分データ取得 → CSVに追記 |
| `merge-data.js` | `fishing_data.csv` + `fishing_condition_db.csv` → `fishing_integrated.csv` 生成 |

**update-conditions.js の仕様**：
- 既存CSVの最新日付を読み取り
- 最新日付+1日～今日を取得対象とする
- 8地点分のデータを順次取得（API_DELAY = 1200ms）
- Archive API / Forecast API の自動切替
- 180日チャンク分割
- 429リトライ（最大5回）
- 取得データをCSVに追記、JSONも更新

**merge-data.js の仕様**：
- `fishing_data.csv` を読み込み
- `fishing_condition_db.csv` を読み込み
- `date` × `nearest_station` = `日付` × `地点名` でLEFT JOIN
- 結合結果を `fishing_integrated.csv` として出力

---

## ■ 統合index.html の設計

### 基本方針

- 既存の`fishing_collector_V55.html`をベースに改良
- GitHub Pages上で`fishing_integrated.csv`を`fetch()`で読み込み
- 天気・水温・潮汐・月齢の列を追加表示
- 環境データ列はAPI自動取得値なので編集不可（readonly表示）

### 追加する表示列

| 列名 | 元データ | 表示形式 |
|------|---------|----------|
| 気温（計測） | 気温_平均 | ○○℃ |
| 水温（計測） | 水温_計測 | ○○℃ |
| 天気（計測） | 天気_計測 | テキスト |
| 風速 | 風速_最大 | ○○m/s |
| 波高 | 最大波高 | ○○m |
| 潮汐 | 潮汐_計測 | 大潮/中潮/小潮/長潮/若潮 |
| 月齢 | 月齢 | ○○.○ |
| 月相 | 月相 | 新月/上弦/満月/下弦 |

### データフロー図

```
[Instagram スクショ]
    ↓ （手動：Claude解析）
[fishing_data.csv] ← 釣果データ（手動push）
    ↓
    ├──→ [GitHub リポジトリ]
    │         ↓
    │    [GitHub Actions 週次]
    │         ↓
    │    [Open-Meteo API] → [fishing_condition_db.csv] 更新
    │         ↓
    │    [merge-data.js] → [fishing_integrated.csv] 生成
    │         ↓
    │    [auto commit & push]
    ↓
[index.html (GitHub Pages)]
    ↓ fetch('./fishing_integrated.csv')
[統合釣果データベース 表示]
```

---

## ■ 開発ロードマップ

### Phase 1：GitHub Actions による自動更新

1. `scripts/update-conditions.js` を開発
   - V6.0のHTMLからAPI呼び出しロジックを抽出してNode.jsに移植
   - CSVの読み書きをfs moduleで実装
2. `scripts/merge-data.js` を開発
   - CSV LEFT JOIN処理
3. `.github/workflows/update-conditions.yml` を作成
4. 手動実行（workflow_dispatch）でテスト
5. 週次スケジュールを有効化

### Phase 2：統合index.htmlの開発

1. V5.5のindex.htmlをベースにコピー
2. CSVの読み込み先を`fishing_integrated.csv`に変更
3. 環境データ列の追加（表示のみ、編集不可）
4. フィルタ・ソート機能に環境データ列を追加
5. 統計バーに環境データのサマリを追加

### Phase 3：分析ソフトの開発（将来）

1. `fishing_integrated.csv`を読み込む分析専用HTML
2. 魚種別の好条件パターン分析（気温・水温・潮汐・月齢と釣果の相関）
3. グラフ表示（Chart.jsなど）
4. 釣行計画支援（条件マッチング）

---

## ■ 開発時の注意点

### API制限

- Open-Meteo は無料・キー不要だが、連続リクエストでHTTP 429が返る場合がある
- GitHub Actions環境からのAPI呼び出しでも同様の制限が適用される
- `API_DELAY = 1200ms` を守り、429時はリトライ（最大5回、指数バックオフ推奨）

### データ整合性

- 釣果CSVの`nearest_station`が空の場合（V5.4以前のレコード）は結合できない
- 空の場合は`spot`（釣り場名）からHaversine再計算するロジックを検討
- 条件データの期間（2022-01-01～）より前の釣果データには環境データなし

### 文字コード

- 両CSVともUTF-8 BOM（`\uFEFF`付き）
- CSVの読み書き時にBOM処理が必要

### 地点名の一致

- V5.5の`nearest_station`とV6.0の`地点名`は現在8地点で完全一致
- 将来地点を追加する場合、両方のマスタを同期する必要がある

---

## ■ 関連ファイルの場所

| ファイル | フォルダ |
|---------|--------|
| `fishing_condition_db_V60.html` | `fishing log 開発　釣り条件分析データベースV50/` |
| `fishing_condition_db_引継ぎ.md` | `fishing log 開発　釣り条件分析データベースV50/` |
| `fishing_collector_V55.html` | `fishing log 開発　釣果データ収集ソフトｖ55/` |
| `fishing_collector_v5.5.md` | `fishing log 開発　釣果データ収集ソフトｖ55/` |
| `fishing_data.csv` | `fishing log 開発　釣果データ収集ソフトｖ55/` |

---

## ■ 新チャットで結合開発を始めるプロンプト

以下をコピーして新しいCoworkチャットに貼り付けてください：

```
以下の2つのフォルダを接続してください：
1. fishing log 開発　釣り条件分析データベースV50
2. fishing log 開発　釣果データ収集ソフトｖ55

fishing_condition_db_結合引継ぎ.md を読んでください。

釣果データベース（V5.5）と釣り条件分析データベース（V6.0）の結合開発を開始します。

現状：
- 釣果データ収集ソフト V5.5：840件の釣果データ、GitHubリポジトリ運用中
- 釣り条件分析データベース V6.0：8地点×1,562日の環境データ（天気・水温・潮汐・月齢）

目標：
- GitHub Actionsで環境データの週次自動更新
- 釣果データと環境データの自動結合
- 統合index.htmlで結合データを表示

Phase 1（GitHub Actions自動更新）から開始してください。
```

---

*釣果データベース結合 引継ぎ書 — 2026年4月11日*
