require 'everypolitician'

module Mapping
  class EPIdentifierToWikidata
    def initialize(ep_slug:, ep_id_scheme:)
      @ep_slug = ep_slug
      @ep_id_scheme = ep_id_scheme
    end

    def to_h
      @to_h = popolo.persons.map { |p| [p.identifier(ep_id_scheme), p.wikidata] }.to_h
    end

    private

    attr_reader :ep_slug, :ep_id_scheme

    def split_ep_slug
      ep_slug.split('/')
    end

    def ep_country_slug
      split_ep_slug[0]
    end

    def ep_house_slug
      split_ep_slug[1]
    end

    def popolo
      @popolo ||= Everypolitician::Index.new.country(ep_country_slug).legislature(ep_house_slug).popolo
    end
  end
end
