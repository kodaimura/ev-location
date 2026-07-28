# 立地スコア

## 運用メモ

### Google Maps Platform Quota

ポートフォリオ用途のため、Google Maps Platform の無料枠内で運用できるように Google Cloud Console 側で API ごとの Quota を制限する。

設定場所:

```text
Google Cloud Console
→ IAM と管理
→ 割り当てとシステム上限
```

設定値:

| API | Quota | 上限 |
| --- | --- | ---: |
| Maps JavaScript API | Map loads per day | 100 |
| Maps JavaScript API | Map loads per minute | 30 |
| Maps JavaScript API | Map loads per minute per user | 10 |
| Geocoding API | v3 requests per day | 50 |
| Geocoding API | v3 requests per minute | 10 |
| Geocoding API | v3 requests per minute per user | 5 |
| Places API | Requests per day | 50 |
| Places API | Requests per minute | 10 |
| Places API | Requests per minute per user | 5 |
| Directions API | Requests per day | 100 |
| Directions API | Requests per minute | 20 |
| Directions API | Requests per minute per user | 10 |

あわせて、Billing Budget のアラートと API キーの HTTP リファラー制限を設定する。
