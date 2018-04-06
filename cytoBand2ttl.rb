#!/usr/bin/env ruby
#
# $ curl http://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/cytoBand.txt.gz | gzip -dc - > cytoBand-GRCh37.txt
# $ curl http://hgdownload.cse.ucsc.edu/goldenPath/hg38/database/cytoBand.txt.gz | gzip -dc - > cytoBand-GRCh38.txt
# $ ruby cytoBand2ttl.rb > cytoBand.ttl
#

hash = {}

[ "GRCh37", "GRCh38" ].each do |ver|
  File.open("cytoBand-#{ver}.txt") do |file|
    file.each do |line|
      chr, from, to, band, col = line.strip.split
      if pat = /^chr(\d{1,2}|[XY])$/.match(chr)
        num = pat[1]
        cyto = "#{num}#{band}"
        hash[cyto] ||= {}
        hash[cyto][ver] = {
          :from => from.to_i,
          :to   => to.to_i,
          :cyto => cyto,
          :col  => col,
          :ref  => "hco:#{num}##{ver}"
        }
      end
    end
  end
end

puts "
@prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#> .
@prefix faldo: <http://biohackathon.org/resource/faldo#> .
@prefix hco:   <http://identifiers.org/hco/> .

"

hash.each do |cyto, data|
  puts "hco:#{cyto}"
  puts "\trdf:type\thco:Cytoband ;"
  puts "\trdfs:label\t\"#{cyto}\" ;"
  [ data["GRCh37"], data["GRCh38"] ].each do |h|
    puts "\tfaldo:location\t["
    puts "\t\trdf:type\tfaldo:Region ;"
    puts "\t\tfaldo:begin\t["
    puts "\t\t\trdf:type\tfaldo:Position ;"
    puts "\t\t\tfaldo:position\t#{h[:from]} ;"
    puts "\t\t\tfaldo:reference\t#{h[:ref]}"
    puts "\t\t] ;"
    puts "\t\tfaldo:end\t["
    puts "\t\t\trdf:type\tfaldo:Position ;"
    puts "\t\t\tfaldo:position\t#{h[:to]} ;"
    puts "\t\t\tfaldo:reference\t#{h[:ref]}"
    puts "\t\t]"
    puts "\t] ;"
  end
  puts "\thco:bandcolor\t\"#{data["GRCh38"][:col] || data["GRCh37"][:col]}\" ."
  puts
end