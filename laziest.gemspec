# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'laziest/version'

Gem::Specification.new do |spec|
  spec.name          = 'laziest'
  spec.version       = Laziest::VERSION
  spec.authors       = ['David Masover']
  spec.email         = ['masover@iastate.edu']
  spec.description   = 'The laziest possible enumerables and enumerators'
  spec.summary       = <<-END
                        When there's just no O(1) way to compute something, this gem provides
                        both promises (lazy evaluation) and partial evaluation, along with
                        implicit, softref-based memoization. For example, (foo.lazy.count > 5) will
                        invoke the iterator at most six times.
                      END
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency 'promise'
  spec.add_dependency 'soft_reference'
end
