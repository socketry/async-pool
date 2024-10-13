# frozen_string_literal: true

require_relative "lib/async/pool/version"

Gem::Specification.new do |spec|
	spec.name = "async-pool"
	spec.version = Async::Pool::VERSION
	
	spec.summary = "A singleplex and multiplex resource pool for implementing robust clients."
	spec.authors = ["Samuel Williams", "Olle Jonsson", "Simon Perepelitsa", "Thomas Morgan"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/socketry/async-pool"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/async-pool/",
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
		"source_code_uri" => "https://github.com/socketry/async-pool.git",
	}
	
	spec.files = Dir.glob(["{lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.1"
	
	spec.add_dependency "async", ">= 1.25"
	spec.add_dependency "traces"
end
