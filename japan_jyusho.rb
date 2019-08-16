# -*- coding: utf-8 -*-
require 'yaml'
require 'pathname'

class JapanJyusho
  attr_reader :list
  
  def initialize
    y = ->(f){YAML.load_file(Pathname(__dir__) + 'data' + f)}
    @char = y['normalize_char.yaml']
    @list = y['list.yaml']
    setup_regexp
  end

  # マッチすれば Array を、しなければ nil を返す。
  # これ仕様再検討した方がよさげ？
  def match(addr)
    a1 = normalize_string(addr)
    m1 = @都道府県名照合.match(a1)
    if m1.nil?
      return nil
    end
    pref, a2 = m1[1], m1[2]
    code = @コード[pref]
    m2 = @郡島部町村名照合[pref].match(a2)
    if m2
      county, city, street = m2[1], m2[2], m2[3]
      code = code[:市区町村コード][city] || code[:都道府県コード]
      return [pref, county, city, street, code]
    end
    m3 = @市区町村名照合[pref].match(a2)
    if m3
      city, ward, street = m3[1], nil, m3[2]
      code = code[:市区町村コード][city] || code[:都道府県コード]
      # このあたり data 側前処理に入れるべき
      if pref == '東京都'
      else
        if /\A(.+市)([^区]+区)\z/ =~ city
          city, ward = $1, $2
        end
      end
      return [pref, city, ward, street, code]
    end
    return nil
  end

  # 文字種正規化処理: String -> String
  # String のメソッドにした方がカッコよいかも。
  def normalize_string(x)
    x.to_s.strip.tr(*@char)
  end

  private

  # 全国地方公共団体コード仕様より
  #
  # マッチングする住所データ（文字列）に
  # ・北海道の支庁は含まれない想定
  # ・郡島は含まれる想定
  # でパターンマッチングを準備している。
  def setup_regexp
    c1, c2 = {}, {}
    @list.each do |ij, pref, city, note1, note2|
      i = ij[0,2]
      j = ij[2,3]
      pref = normalize_string(pref)
      city = normalize_string(city)
      case j
      when '000'
        (@都道府県名 ||= {})[i] = pref
        c1[pref] = []
        c2[pref] = []
      when /^[12]/
        c1[pref] << city
      when /^[3-7]/
        c2[pref] << city
      end
      case note1
      when '6.2.6'
        c1[pref] << city
      end
      if j == '000'
        (@コード ||= {})[pref] = {都道府県コード: i + '000', 市区町村コード: {}}
      else
        @コード[pref][:市区町村コード][city] = ij
      end
    end
    m = ->(x){x.sort_by{|n| -n.size}.join('|')}
    @都道府県名照合 = /\A(#{m[@都道府県名]})\s*(.*)\z/
    @市区町村名照合 = {}
    @郡島部町村名照合 = {}
    @都道府県名.each do |_, pref|
      @市区町村名照合[pref] = /\A(#{m[c1[pref]]})\s*(.*)\z/
      @郡島部町村名照合[pref] = /\A([^郡]+郡|[^島]+島)\s*(#{m[c2[pref]]})(.*)\z/
    end
  end
end
