require 'test_helper'

class CompareWithWikidataTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::CompareWithWikidata::VERSION
  end
end
