require 'daff'

data1 = [
  ['Country','Capital'],
  ['Ireland','Dublin'],
  ['France','Paris'],
  ['Spain','Barcelona']
]

data2 = [
  ['Country','Code','Capital'],
  ['Ireland','ie','Dublin'],
  ['France','fr','Paris'],
  ['Spain','es','Madrid'],
  ['Germany','de','Berlin']
]

t1 = Daff::TableView.new(data1)
t2 = Daff::TableView.new(data2)

alignment = Daff::Coopy.compare_tables(t1, t2).align

data_diff = []
table_diff = Daff::TableView.new(data_diff)

flags = Daff::CompareFlags.new
highlighter = Daff::TableDiff.new(alignment, flags)
highlighter.hilite(table_diff)

p data_diff

__END__

$ ruby experiments/daff.rb
[["!", "", "+++", ""], ["@@", "Country", "Code", "Capital"], ["+", "Ireland", "ie", "Dublin"], ["+", "France", "fr", "Paris"], ["->", "Spain", "es", "Barcelona->Madrid"], ["+++", "Germany", "de", "Berlin"]]
