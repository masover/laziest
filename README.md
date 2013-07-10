# Laziest

Extends Enumerable#lazy (aka Enumerator::Lazy) with additional
opportunities for lazy and especially *partial* evaluation.
For example:

    (1..Float::INFINITY).lazy.count > 10

evaluates almost instantaneously.

## Installation

Add this line to your application's Gemfile:

    gem 'laziest'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install laziest

## Usage

Simply add this before working with any lazy enumerators:

    require 'laziest'

This will extend Enumerator::Lazy (and the Enumerable#lazy method)
to have lazier versions of the following methods:

 * chunk
 * count
 * entries
 * group_by
 * max
 * min
 * minmax
 * partition
 * slice_before
 * to_a

The somewhat ambitious goal is to defer as much as possible, while maintaining
full compatibility with the existing API. Some more examples:

    (1..Float::INFINITY).lazy.group_by{|x| x.to_s.length}[3].first(2)  # => [100, 101]
    Prime.lazy.max > 1000  # => true
    Prime.lazy.partition{|x| x%10 == 1}.all? {|x| x.count > 100} # => true

As with any self-respecting Ruby laziness, proxy classes
(specifically, Promises from the promise ("promising future") gem)
are abused, to ensure that traditional, non-lazy usage is correct.

    (1..5).lazy.group_by(&:even?)  # => {false=>[1, 3, 5], true=>[2, 4]}

Not everything is as lazy as possible yet, but anything not lazy should still
work, eventually, on anything finite.

Warning: Be careful in IRB! Remember that IRB calls #inspect on the result
of any expression you type. This will almost always force a complete
evaluation. For example, if you type this:

    evens, odds = (1..Float::INFINITY).lazy.partition(&:even?)

This will attempt to #inspect the resulting arrays, and you have created an
infinite loop. You can avoid this by adding a useless expression to the end:

    evens, odds = (1..Float::INFINITY).lazy.partition(&:even?); nil
    evens.first(10)

Of course, abusing one-liners is the easiest way to avoid this:

    (1..Float::INFINITY).lazy.group_by(&:even?)[true].first(10)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
