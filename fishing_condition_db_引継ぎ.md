# 釣り条件分析データベース 開発引継ぎドキュメント
**最新バージョン：V6.0**
更新日：2026年4月11日

---

## ■ このドキュメントの目的

新しいチャットセッションでこのプロジェクトの開発を継続するための引継ぎ資料。
このファイルと `fishing_condition_db_V60.html` を新チャットに渡せば開発を再開できる。

---

## ■ プロジェクト概要

釣果データベース（V6.0）の日付情報に紐づけて、天気・水温・潮汐・月齢の環境データを収集するシングルファイルHTMLアプリケーション。ブラウザでダブルクリックするだけで動作する。

### アーキテクチャ
- **シングルHTML**：HTML + CSS + JavaScript を1ファイルに収めた構成
- **IndexedDB**：ブラウザ内データベースにデータを保存
- **外部APIキー不要**：Open-Meteo（無料・キー不要）を利用
- **オフライン計算**：月齢・潮汐は天文計算でAPI不要
- **File System Access API**：選択したフォルダに直接ファイルを上書き保存

---

## ■ バージョン履歴

| バージョン | ファイル名 | 更新日 | 主な内容 |
|-----------|-----------|--------|---------|
| V5.0 | `fishing_condition_db_V50.html` | 2026-04-10 | 初版。4つの個別ソフトを1ファイルに統合 |
| V5.1 | `fishing_condition_db_V51.html` | 2026-04-10 | バグ修正3件 + 時間帯対応1件 |
| V5.2 | `fishing_condition_db_V52.html` | 2026-04-11 | HTML↔JS不一致14件修正 + Archive API + 自動保存 |
| V6.0 | `fishing_condition_db_V60.html` | 2026-04-11 | V5.2と同一内容を正式版として命名 |

---

## ■ V5.1 → V6.0 での全変更内容

### バグ修正（V5.2で実施）

| # | 内容 | 詳細 |
|---|------|------|
| 1 | **log() / clearLog()** | `getElementById('log')` → `'log-area'` に修正 |
| 2 | **switchTab()** | `'data'` → `'summary'` に修正 |
| 3 | **fetchAll()** | `'btn-fetch'` → `'btn-all'`、`'progress'` → `'progress-label'` |
| 4 | **fetchPartial()** | 同上 |
| 5 | **loadStationList()** | `'station-list'` → `'stations-tbody'`（テーブル形式に書き換え） |
| 6 | **openStationModal()** | 旧フォームID → `'modal-edit-id'`, `'modal-spot'`, `'modal-station'`, `'modal-lat'`, `'modal-lng'`, `'modal-tide-code'` |
| 7 | **closeStationModal()** | `style.display='none'` → `classList.remove('show')` |
| 8 | **saveStation()** | 旧ID → 新ID。`spot_name`/`station_name` 分離対応 |
| 9 | **loadDataSummary()** | `'data-summary'` → `'summary-grid'` + `'summary-tbody'` |

### 新機能

| # | 機能 | 詳細 |
|---|------|------|
| 1 | **Archive API対応** | 5日前以前のデータは `archive-api.open-meteo.com` を自動使用 |
| 2 | **日付チャンク分割** | 180日単位で分割リクエスト（2022-01-01～今日 = 約9チャンク） |
| 3 | **HTTP 429リトライ** | API制限時に自動待機 + カウントダウン表示（最大5回リトライ） |
| 4 | **差分更新改善** | 全ストア横断で最古日・最新日を判定。欠落期間のみ取得 |
| 5 | **統合CSV出力** | 日付×地点キーで全データ1ファイル（`fishing_condition_db.csv`）|
| 6 | **File System Access API** | 選択フォルダに直接保存（上書き）。フォルダ設定はIndexedDBに記憶 |
| 7 | **自動保存** | データ更新完了後にCSV + JSONを自動保存 |
| 8 | **プログレスバー** | 進捗率をリアルタイム表示 |
| 9 | **地点チップ** | fetch中に各地点が ⏳→✅/❌ と変化 |
| 10 | **実行バッジ** | 「待機中→処理中→完了」表示 |
| 11 | **ステータスバー** | 天気/水温/潮汐/月齢の件数リアルタイム更新 |
| 12 | **有効/無効トグル** | 地点管理で地点ごとにon/off切替 |
| 13 | **トースト通知** | 処理完了時にポップアップ通知 |
| 14 | **ログ色分け** | ok(緑)/warn(黄)/err(赤)/head(金) でログ視認性向上 |

---

## ■ V6.0 の技術仕様

### IndexedDB

| 項目 | 値 |
|------|-----|
| DB名 | `fishing_condition_db` |
| バージョン | `1` |
| 設定DB | `fishing_condition_settings`（保存先フォルダハンドル） |

| ストア名 | キー | 内容 |
|---------|------|------|
| `stations` | `id`（autoIncrement） | 観測地点マスタ |
| `weather` | `[station_id, date]` | 天気データ（6-9時集計） |
| `water_temp` | `[station_id, date]` | 水温・波浪データ |
| `tide` | `[station_id, date]` | 潮汐データ |
| `moon_age` | `[station_id, date]` | 月齢データ |

### デフォルト観測地点（8地点）

| 名前 | 県 | 緯度 | 経度 |
|------|-----|------|------|
| 室戸 | 高知県 | 33.29 | 134.18 |
| 高知 | 高知県 | 33.56 | 133.54 |
| 足摺 | 高知県 | 32.72 | 132.72 |
| 宇和島 | 愛媛県 | 33.22 | 132.56 |
| 松山 | 愛媛県 | 33.84 | 132.77 |
| 来島 | 愛媛県 | 34.12 | 132.99 |
| 高松 | 香川県 | 34.35 | 134.05 |
| 阿南 | 徳島県 | 33.92 | 134.66 |

### APIデータソース

| データ | API | エンドポイント |
|--------|-----|--------------|
| 天気（過去） | Open-Meteo Archive | `archive-api.open-meteo.com/v1/archive` (hourly) |
| 天気（直近） | Open-Meteo Forecast | `api.open-meteo.com/v1/forecast` (hourly) |
| 水温 | Open-Meteo Marine | `marine-api.open-meteo.com/v1/marine` (hourly, daily fallback) |
| 波浪 | Open-Meteo Marine | `marine-api.open-meteo.com/v1/marine` (hourly) |
| 潮汐・月齢 | 天文計算 | API不要（ユリウス日・朔望月から計算） |

### 定数

```javascript
DEFAULT_START_DATE = '2022-01-01'  // データ収集開始日
CHUNK_DAYS = 180                    // 1リクエストの最大日数
MAX_RETRIES = 5                     // 429リトライ回数
API_DELAY = 1200                    // API間隔（ms）
TARGET_HOURS = [6, 7, 8]            // JST 6:00〜8:00
```

### 出力ファイル

| ファイル名 | 形式 | 内容 |
|-----------|------|------|
| `fishing_condition_db.csv` | CSV (UTF-8 BOM) | 統合環境データ（日付×地点で全データ1行） |
| `fishing_condition_db.json` | JSON | IndexedDB全データのバックアップ |

### 統合CSVの列構成

```
日付, 地点名, 観測地点名, 県, 緯度, 経度,
気温_平均, 気温_最高, 気温_最低, 風速_最大, 風向, 降水量, 天気コード, 天気,
水温, 最大波高, 波向, 波周期,
潮汐, 月齢, 月相
```

### 時間帯集計ロジック

```
TARGET_HOURS = [6, 7, 8]  ← JST 6:00, 7:00, 8:00

天気: hourly → 日付ごとに6-8時を集計
  気温_平均 = avg(3h), 気温_最高 = max(3h), 気温_最低 = min(3h)
  風速_最大 = max(3h)の時の風速と風向
  降水量 = sum(3h)
  天気コード = max(3h)  ※数値が大きいほど悪天候

水温: hourly sea_surface_temperature → 6-8時の平均
  失敗時はdaily fallback（日平均値を使用）

波浪: hourly wave_height/direction/period → 6-8時集計
  最大波高 = max(3h), 波向 = avg方位, 波周期 = avg(3h)
```

---

## ■ UIタブ構成

| タブ | 機能 |
|------|------|
| データ更新 | 全一括更新、天気のみ、水温のみ、潮汐・月齢のみ。プログレスバー・ログ付き |
| CSV出力 | 保存先フォルダ設定、統合CSV出力、個別CSV、JSONバックアップ、復元 |
| 地点管理 | 地点の追加・編集・削除・有効/無効切替。stations.json出力 |
| 集計確認 | 地点別データ件数と期間の確認 |

---

## ■ フォルダ構成

```
fishing log 開発　釣り条件分析データベースV50/
├── fishing_condition_db_V50.html      ← V5.0（旧版・保存用）
├── fishing_condition_db_V51.html      ← V5.1（旧版・保存用）
├── fishing_condition_db_V52.html      ← V5.2（旧版・保存用）
├── fishing_condition_db_V60.html      ← V6.0（最新版・これを使う）
├── fishing_condition_db_引継ぎ.md     ← このファイル
├── fishing_condition_db_結合引継ぎ.md ← 釣果DB結合用の引継ぎ書
├── 統合環境データ収集ソフト開発.md     ← V5.0開発時の設計ドキュメント
└── 参考ソース/
    ├── weather_collector_optimized.html
    ├── water_temp_collector_optimized.html
    ├── tide_table_collector_optimized.html
    └── moon_age_collector_optimized.html
```

---

## ■ 現在のステータス

### 動作確認済み
- ブラウザでダブルクリック → 画面表示 OK
- 全データ一括更新（2022-01-01～今日）→ 約12,496件取得 OK
- 差分更新（翌日分のみ追加）→ OK
- Archive API自動切替 → OK
- 統合CSV出力 → OK
- File System Access API フォルダ保存 → OK
- 自動保存（更新完了後CSV+JSON）→ OK
- 地点管理（追加・編集・削除・有効/無効）→ OK
- 集計確認 → OK

---

## ■ 新チャットへの引っ越し手順

1. 新しいCoworkチャットを開く
2. プロジェクトフォルダ「fishing log 開発　釣り条件分析データベースV50」を接続する
3. 以下のメッセージを送る：

```
fishing_condition_db_引継ぎ.md を読んでください。
釣り条件分析データベースの開発を継続します。
現在 V6.0 が完成しています。
fishing_condition_db_V60.html を確認して、現状を把握してください。
[ここにやりたいことを書く]
```

---

*釣り条件分析データベース 引継ぎドキュメント V6.0 — 2026年4月11日*
