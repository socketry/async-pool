source 'https://rubygems.org'

gemspec

# gem "async", path: "../async"

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
	
	gem "utopia-project"
	gem "bake-github-pages"
end

group :test do
	gem "bake-test"
	gem "bake-test-external"
end
