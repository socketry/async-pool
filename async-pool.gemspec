# frozen_string_literal: true

require_relative "lib/async/pool/version"

Gem::Specification.new do |spec|
	spec.name = "async-pool"
	spec.version = Async::Pool::VERSION
	
	spec.summary = "A singleplex and multiplex resource pool for implementing robust clients."
	spec.authors = ["Samuel Williams", "Olle Jonsson", "Simon Perepelitsa"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/async-pool"
	
	spec.metadata = {
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
	}
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 2.5"
	
	spec.add_dependency "async", ">= 1.25"
	
	spec.add_development_dependency "bake-test"
	spec.add_development_dependency "bake-test-external"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "sus", "~> 0.12"
	spec.add_development_dependency "sus-fixtures-async"
end
