# 総務省 全国地方公共団体コード
ref. http://www.soumu.go.jp/denshijiti/code.html

# これについて

## 前処理（これはやってある）
1. `source_xls/*.xls` を取得（更新）する。
2. `rake data:update_list`

## 使う
1. `require_relative './japan_jyusho'`
