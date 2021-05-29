#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'httparty'
require 'json'

wikipedia_url = 'https://www.wikiwand.com/en/List_of_minor_planets_named_after_people'

if File.exist?('./tmp/')
html = HTTParty.get(wikipedia_url)


nokogiri_page = Nokogiri::HTML(html)

# make a csv out of the html table
csv = CSV.open('la_parishes.csv', 'w', { col_sep: ',', quote_char: '\'', force_quotes: true })

html.xpath('//table[2]//tr').each do |row|
  tarray = []
  row.xpath('td').each do |cell|
    tarray << cell.text
  end
  csv << tarray
end

csv.close
