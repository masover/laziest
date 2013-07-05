module Laziest
  autoload :VERSION, 'laziest/version'
  autoload :Counter, 'laziest/counter'
  autoload :ArrayPromise, 'laziest/array'

  require 'laziest/extensions'

  Enumerator::Lazy.send :include, Extensions::LazyEnumerator
end