# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

source 'https://rubygems.org'

gemspec

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
	
	gem "utopia-project"
	gem "bake-github-pages"
end

group :test do
	gem "sus", "~> 0.15"
	gem "sus-fixtures-async"
	gem "covered"
	
	gem "bake-test"
	gem "bake-test-external"
end
