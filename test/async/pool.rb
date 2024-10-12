# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "async/pool"

describe Async::Pool do
	it "has a version number" do
		expect(Async::Pool::VERSION).to be =~ /\d+\.\d+\.\d+/
	end
end
