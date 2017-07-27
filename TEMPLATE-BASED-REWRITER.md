# Usage

This gem provides a class,
`MediaWikiRewriteFromTemplate::WikiPage`, which helps you to
programmatically rewrite MediaWiki pages based on the parameters
of a template tag (or template tags) in that page. (This is a
model used by the
[Listeria](https://tools.wmflabs.org/listeria/) bot, for
example.)

For example, suppose you created a page on Wikidata with the
following wikitext:

```
{{Fibonacci
|max_fib=10
}}

<!-- OUTPUT BEGIN -->
<!-- OUTPUT END -->
```

... at https://www.wikidata.org/wiki/User:Mhl20/Fibonnacci_test

You could then use the following code to rewrite that page to
include the Fibonacci numbers less than or equal to `max_fib`
using:


```
require 'mediawiki_rewrite_from_template'

class FibonacciRewriter
  def rewrite(template_name:, template_parameters:, old_wikitext:)
    if template_name == 'Fibonacci'
      limit = Integer(template_parameters[:max_fib])
      "=== Some Fibonacci numbers ===\n:{| class=\"wikitable\"\n" +
        wikitext_rows(limit) +
        "|}"
    end
  end

  def wikitext_rows(limit)
    fibs = fibonacci_numbers(limit)
    "|-\n" + 0.upto(fibs.length - 1).map { |f| "| ''F''<sub>#{f}</sub>\n" }.join('') +
      "|-\n" + fibs.map { |n| "| #{n}\n" }.join('')
  end

  def fibonacci_numbers(limit)
    numbers = []
    i, j = 0, 1
    while i <= limit
      numbers << i
      i, j = j, i + j
    end
    numbers
  end
end

wiki_page = MediaWikiRewriteFromTemplate::WikiPage.new(
  username: ENV['WIKI_USERNAME'],
  password: ENV['WIKI_PASSWORD'],
  site: 'www.wikidata.org',
  title: 'User:Mhl20/Fibonnacci test'
)

wiki_page.rewrite_and_put(FibonacciRewriter.new)
```

The result of this code would be that the page would be
rewritten to have the following wikitext:

```
{{Fibonacci
|max_fib=10
}}

<!-- OUTPUT BEGIN -->
=== Some Fibonacci numbers ===
:{| class="wikitable"
|-
| ''F''<sub>0</sub>
| ''F''<sub>1</sub>
| ''F''<sub>2</sub>
| ''F''<sub>3</sub>
| ''F''<sub>4</sub>
| ''F''<sub>5</sub>
| ''F''<sub>6</sub>
|-
| 0
| 1
| 1
| 2
| 3
| 5
| 8
|}
<!-- OUTPUT END -->
```

The object you pass to the `rewrite_and_put` method should have
a method called rewrite that meets the following criteria:

* It should take the following keyword arguments:
    * `template_name`: the name of the template (between `{{` and
      the first `|` or `}}` in the page.
    * `old_wikitext`: what was between the `<!-- OUTPUT BEGIN -->`
      and `<!-- OUTPUT END -->` HTML comments after the template
      tag.
    * `template_parameters`: the named parameters in the
      template tag as a `Hash` with symbolized keys. e.g. in the
      example above, that would be: `{:max_fib => '10'}`

If this method throws an exception, returns `nil` or returns a
string equal to `old_wikitext`, no change will be made to the
text between the `<!-- OUTPUT BEGIN -->` and `<!-- OUTPUT END
-->` HTML comments.  Otherwise, the page will be rewritten with
the string returned by `rewrite` replacing the text between
those comments.

There can be multiple such templates followed by the special
HTML comments on a single page, and `rewrite` will be applied to
all of them.
