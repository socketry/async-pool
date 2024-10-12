#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require "async"

require "async/pool/controller"
require "async/pool/resource"

class MyResource < Async::Pool::Resource
	def self.call
		Async::Task.current.sleep(1)
		self.new
	end
end

Async do
	progress = Console.logger.progress("Pool Usage", 10*10)
	pool = Async::Pool::Controller.new(MyResource, concurrency: 10)
	
	10.times do
		Async do
			10.times do
				resource = pool.acquire
				pool.release(resource)
				progress.increment
			end
		end
	end
end
