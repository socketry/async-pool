#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require "async"
require "async/redis"

Async do |task|
	c = Async::Redis::Client.new
	
	10_000.times do |i|
		c.ping "foo#{i}"
	end
	
	available = c.instance_variable_get("@pool").instance_variable_get("@available")
	puts "available size #{available.size}, unique #{available.uniq.size}"
end
