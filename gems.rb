# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

source "https://rubygems.org"

gemspec

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
	
	gem "utopia-project"
end

group :test do
	gem "sus", "~> 0.15"
	gem "covered"
	gem "decode"
	gem "rubocop"
	
	gem "traces"
	gem "sus-fixtures-async"
	
	gem "bake-test"
	gem "bake-test-external"
end
