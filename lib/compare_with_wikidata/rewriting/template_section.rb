module CompareWithWikidata
  class TemplateSection
    def initialize(original_wikitext:)
      @original_wikitext = original_wikitext
    end

    def template_name
      top_level_split[:template_name].strip
    end

    def all_parameters
      # This returns all parameters, including anonymous, numbered and
      # named parameters. (Though we only handle named parameters at
      # the moment.)
      top_level_split[:parameters].split('|').select do |s|
        s.strip!
        s.empty? ? nil : s
      end
    end

    def named_parameters
      all_parameters.map do |p|
        m = /(.*?)=(.*)/m.match(p)
        [m[1].strip.to_sym, m[2]]
      end.to_h
    end

    attr_accessor :original_wikitext

    private

    TEMPLATE_RE = /
        \{\{
        (?<template_name>[^\|]*)
        (?<parameters>.*?)
        \}\}
        (?<between>.*?)
        (?<content_begin><!--\ [\w\ ]*OUTPUT\ BEGIN\ -->)
        (?<content>.*?)
        (?<content_end><!--\ [\w\ ]*OUTPUT\ END\ -->)
    /xm

    def top_level_split
      @top_level_split ||= TEMPLATE_RE.match(original_wikitext)
    end
  end
end
