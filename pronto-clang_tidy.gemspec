
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pronto/clang_tidy/version'

Gem::Specification.new do |spec|
  spec.name          = 'pronto-clang_tidy'
  spec.version       = Pronto::ClangTidy::VERSION
  spec.authors       = ['Michael Jabbour']
  spec.email         = ['micjabbour@gmail.com']

  spec.summary       = 'Pronto runner for clang-tidy, a clang-based C++ ' \
                       '"linter" tool.'
  spec.homepage      = 'https://github.com/micjabbour/pronto-clang_tidy'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.extra_rdoc_files = ['LICENSE.txt', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'pronto', '~> 0.9.0'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.4'
end
