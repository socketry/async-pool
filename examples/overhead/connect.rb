#!/usr/bin/env ruby

require 'async'

require 'async/pool/controller'
require 'async/pool/resource'

class MyResource < Async::Pool::Resource
	def self.call
		Async::Task.current.sleep(1)
		self.new
	end
end

Async do
	progress = Console.logger.progress("Pool Usage", 10*10)
	pool = Async::Pool::Controller.new(MyResource)
	
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
