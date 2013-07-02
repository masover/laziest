module LazyCount
  autoload :VERSION, 'lazy_count/version'
  autoload :Counter, 'lazy_count/counter'

  require 'lazy_count/extensions'

  Enumerator::Lazy.send :include, Extensions::LazyEnumerator
end