autoload :Promise, 'promise'

module Laziest
  autoload :VERSION, 'laziest/version'
  autoload :Counter, 'laziest/counter'
  autoload :ArrayPromise, 'laziest/array'
  autoload :Group, 'laziest/group'
  autoload :MutexUtil, 'laziest/mutex_util'

  require 'laziest/extensions'

  Enumerator::Lazy.send :include, Extensions::LazyEnumerator
end