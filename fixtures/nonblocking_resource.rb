# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require 'async/pool/controller'
require 'async/pool/resource'

class Async::Pool::Controller
	attr :available
end

class NonblockingResource < Async::Pool::Resource
	# Whether this resource can be acquired.
	# @return [Boolean] whether the resource can actually be used.
	def viable?
		Async::Task.current.yield
		super
	end
	
	# Whether the resource has been closed by the user.
	# @return [Boolean] whether the resource has been closed or has failed.
	def closed?
		Async::Task.current.yield
		super
	end
	
	# Close the resource explicitly, e.g. the pool is being closed.
	def close
		Async::Task.current.yield
		super
	end
	
	# Whether this resource can be reused. Used when releasing resources back into the pool.
	def reusable?
		Async::Task.current.yield
		super
	end
end
