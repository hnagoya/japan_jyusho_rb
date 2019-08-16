# -*- coding: utf-8 -*-
require 'yaml'
require 'pathname'
require 'nkf'
require 'roo'
require 'roo-xls'

class JapanJyusho
  class SourceXlsFile
    def initialize(dir)
      d = ->(f){(Pathname(dir) + f).to_s}
      r = ->(f){Roo::Excel.new(f, mode: 'r') if f}
      y = YAML.load_file(d['設定.yaml'])
      @追加 = y[:追加データ]
      c = y[:都道府県コード及び市区町村コード]
      @本表 = r[d[c[:本表]]]
      @改正 = r[d[c[:改正一覧表]]]
    end

    # 「現在の団体」シート
    def read_honhyou1(preprocess = ->(rows){rows.shift})
      read_sheet_by_name(@本表, /現在の団体\z/, preprocess)
    end
    
    # 「政令指定都市」シート
    def read_honhyou2(preprocess = nil)
      read_sheet_by_name(@本表, /政令指定都市\z/, preprocess)
    end

    # 「改正一覧表」シート
    def read_kaisei(preprocess = ->(rows){rows.shift(4)})
      read_sheet_by_name(@改正, '改正一覧表', preprocess)
    end

    # 追加データ
    def read_tuikadata
      @追加
    end

    # -> Array
    # [[市区町村コード5桁, 都道府県名, 市区町村名, 分類1, 分類2], ...]
    def to_a
      c = ->(x){[x[0,2], x[2,3], x[0,5]]}
      pref = {}
      vs = []
      read_honhyou1.each do |r|
        i, j, ij = c[r[0]]
        if j == '000'
          pref[i] = r[1]
          vs << [ij, r[1], nil, nil, nil]
        else
          note1 = nil
          note1 = '6.2.6' if /\A13[34]/ =~ ij # 東京都島嶼部これで良いのか？
          vs << [ij, r[1], r[2], note1, nil]
        end
      end
      read_honhyou2.each do |r|
        i, j, ij = c[r[0]]
        vs << [ij, pref[i], r[1], nil, nil]
      end
      kubun = nil
      read_kaisei.each do |r|
        kubun = r[8] if r[8] != '〃'
        next unless kubun == '欠番'
        i, j, ij = c[r[5]]
        vs << [ij, pref[i], r[6], nil, '欠番']
      end
      pref_code = pref.invert
      read_tuikadata.each do |pref_name, cities|
        i = pref_code[pref_name]
        cities.each do |city_name, j|
          ij = i + j.to_s
          vs << [ij, pref_name, city_name, nil, '追加']
        end
      end
      vs.sort_by{|ij, _| ij}
    end
    
    private

    # Array<T> -> Array<String|Nil>
    # セル内の値の揺らぎ（型など）等を吸収する処理をまとめた。
    # そもそも総務省の元データ（ファイル）が変なんだよな。
    def normalize_map(rows)
      rows.map{|row|
        row.map{|v|
          case v
          when Numeric # 所により浮動小数点だったりするので（0-leading有りな）10進表記文字列に揃える、日付時刻も Float 扱いでここに来る様子だがそのまま
            v.to_i.to_s
          when String
            s = NKF.nkf('-Ww -X -Z1', v).strip
            s.empty? ? nil : s # 空文字列は存在しないようにする（nil にする）
          when NilClass
            nil
          else # 他の型の値は現れない様子
            raise "[#{v}<#{v.class}>][#{row.to_a}]"
          end
        }
      }
    end

    # xlsfile: String
    # sheet_name: String|Regexp
    # preprocess: Proc
    # -> Array
    def read_sheet_by_name(xlsfile, sheet_name, preprocess = nil)
      w = xlsfile.worksheets.find{|w| sheet_name === w.name}
      rows = normalize_map(w.to_a)
      preprocess[rows] if preprocess # ヘッダー行を飛ばすとかの処理を想定
      rows
    end
  end
end
