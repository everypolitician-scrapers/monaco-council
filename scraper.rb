#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :name do
    noko.css('h2.itemTitle').text.tidy
  end

  field :image do
    noko.css('.itemFullText img/@src').map(&:text).first
  end

  field :faction do
    return 'Sans Etiquette' if faction_text.include? 'Sans Etiquette'
    faction_text[/groupe politique (.*)/, 1].tidy
  end

  private

  def faction_text
    noko.xpath('//*[contains(.,"du groupe politique")]').last.text
  end
end

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :members do
    member_items.map { |a| Scraped::Scraper.new(a.attr('href') => MemberPage).scraper.to_h }
  end

  private

  def member_items
    noko.css('#k2ModuleBox88 a.moduleItemTitle')
  end
end

url = 'http://www.conseil-national.mc/index.php/la-presidence'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name faction])
