# coding: utf-8
require 'yaml'
require 'csv'
require 'pp'
require_relative './japan_jyusho'
require_relative './japan_jyusho/source_xls_file'

L = Logger.new($stdout)
S = JapanJyusho::SourceXlsFile.new('./source_xls')

namespace :test do
  desc "j.txt"
  task :j_txt do
    j = JapanJyusho.new.pretty_inspect
    open('./test/j.txt', 'w:UTF-8') do |o|
      o.print j
    end
  end
  
  desc "test"
  task :sample do
    j = JapanJyusho.new
    h = {}
    CSV.foreach('test/テスト用住所データ（サンプル）.txt', headers: false, encoding: 'UTF-8') do |r|
      a = r[0].chomp
      m = j.match(a)
      c = m[4]
      (h[c] ||= []) << [c, *m[0..3], a]
    end
    h.sort_by{|c, _| c}.each do |c, vs|
      vs.each do |v|
        print v.to_csv
      end
    end
  end
end

namespace :data do
  desc "data update"
  task :update_list do
    a = S.to_a
    open('./data/list.yaml', 'w:UTF-8') do |o|
      o.print a.to_yaml
    end
    open('./data/list.csv', 'w:UTF-8') do |o|
      a.each do |v|
        o.print v.to_csv
      end
    end
  end
end

namespace :チェック do
  desc "チェック 本表1"
  task :本表1 do
    S.read_honhyou1.each do |r|
      i, pref, city = r
      if /\A\d\d000\d\z/ =~ i and /[都道府県]\z/ =~ pref and city.nil?
        # OK
      elsif /\A\d{6}\z/ =~ i and /[都道府県]\z/ =~ pref and /[市区町村]\z/ =~ city
        # OK
      else
        L.warn("[#{i}|#{pref}|#{city}]")
      end
    end
  end

  desc "チェック 本表2"
  task :本表2 do
    S.read_honhyou2.each do |r|
      i, city = r
      if /\A\d{6}\z/ =~ i and /市(?:\S+区)?\z/ =~ city
        # OK
      else
        L.warn("[#{i}|#{city}]")
      end
    end
  end

  desc "チェック 改正一覧"
  task :改正一覧 do
    rs = S.read_kaisei(nil)
    # 先頭の4行を飛ばす
    k = rs.shift(4).size
    # 0 1 2 3 4 5 6 7 8 ...
    # A B C D E F G H I ...
    pref = nil
    kubun = nil
    rs.each do |r|
      k += 1
      i = r[5]
      pref = r[4] if r[4]
      city = r[6]
      kubun = r[8] if r[8] != '〃'
      if kubun.nil?
        # OK
      elsif i.nil? and city.nil?
        # OK
      elsif /\A\d{6}\z/ =~ i and /[都道府県]\z/ =~ pref and /[市区町村]\z/ =~ city
        # OK
      else
        L.warn("#{k} [#{i}|#{pref}|#{city}|#{kubun}]")
      end
    end
  end
end

namespace :ダンプ do
  desc "ダンプ 本表1"
  task :本表1 do
    S.read_honhyou1(nil).each do |r|
      print r.to_csv
    end
  end

  desc "ダンプ 本表2"
  task :本表2 do
    S.read_honhyou2(nil).each do |r|
      print r.to_csv
    end
  end

  desc "ダンプ 改正一覧"
  task :改正一覧 do
    S.read_kaisei(nil).each do |r|
      print r.to_csv
    end
  end

  desc "ダンプ 追加データ"
  task :追加データ do
    pp S.read_tuikadata
  end
end
