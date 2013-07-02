module Laziest
  autoload :VERSION, 'laziest/version'
  autoload :Counter, 'laziest/counter'

  require 'laziest/extensions'

  Enumerator::Lazy.send :include, Extensions::LazyEnumerator
end