#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :members do
    member_rows.map { |row| fragment(row => MemberRow).to_h }
  end

  private

  def member_table
    noko.css('div.itemFullText table')
  end

  def member_rows
    member_table.xpath('.//tr[td]')
  end
end

class MemberRow < Scraped::HTML
  field :name do
    tds[1].css('span').first.text.tidy
  end

  field :image do
    tds[0].css('img/@src').text
  end

  field :faction do
    return 'Sans Etiquette' if faction_text.include? 'Sans Etiquette'
    faction_text[/Membre du groupe politique (.*)/, 1].tidy
  end

  private

  def tds
    noko.css('td')
  end

  def faction_text
    tds[1].css('span').last.text
  end
end

url = 'http://www.conseil-national.mc/index.php/les-elus/les-elus-de-la-legislature-2013-2018'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name faction])
