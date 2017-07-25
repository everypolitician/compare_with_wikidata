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

    def dup_with(new_content:)
      TemplateSection.new(
        original_wikitext: '{{%<template_name>s%<parameters>s}}' \
                           "%<between>s%<content_begin>s\n#{new_content}\n" \
                           '%<content_end>s' % top_level_split
      )
    end

    def rewrite(rewriter)
      dup_with(
        new_content: rewriter.rewrite(
          old_content: top_level_split[:content],
          parameters:  named_parameters
        )
      )
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

    TEMPLATE_RE_NO_GROUPS = Regexp.new(TEMPLATE_RE.to_s.gsub(/\?<\w+>/, '?:'))

    def top_level_split
      # The version of Ruby we're using at the moment (2.3) doesn't
      # have Hash.named_captures yet, which would make this a bit
      # simpler.
      @top_level_split ||= top_level_split_matchdata.names.map(&:to_sym).zip(
        top_level_split_matchdata.captures
      ).to_h
    end

    def top_level_split_matchdata
      @top_level_split_matchdata ||= TEMPLATE_RE.match(original_wikitext)
    end
  end
end
