
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jyouro/version"

Gem::Specification.new do |spec|
  spec.name          = "jyouro"
  spec.version       = Jyouro::VERSION
  spec.authors       = ["imtama"]
  spec.email         = ["imtama@example.com"]

  spec.summary       = %q{Rails plugin for `watering` your seeds}
  spec.description   = <<~DESC
                       With this gem, your seeds.rb file becomes more structured, and `rake db:seed` commands shows friendly error details.
                       In summary, it's nice.
                       DESC
  spec.homepage      = "https://github.com/imtama/jyouro"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "activesupport"
end
