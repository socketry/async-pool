# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'async/logger'

require 'async/notification'
require 'async/semaphore'

module Async
	module Pool
		class Controller
			def self.wrap(**options, &block)
				self.new(block, **options)
			end
			
			def initialize(constructor, limit: nil)
				@resources = {}
				
				@available = []
				@notification = Async::Notification.new
				
				@limit = limit
				
				@constructor = constructor
				@guard = Async::Semaphore.new(1)
			end
			
			# @attr [Hash<Resource, Integer>] all allocated resources, and their associated usage.
			attr :resources
			
			def size
				@resources.size
			end
			
			# Whether the pool has any active resources.
			def active?
				!@resources.empty?
			end
			
			# Whether there are resources which are currently in use.
			def busy?
				@resources.collect do |_, usage|
					return true if usage > 0
				end
				
				return false
			end
			
			# Wait until a pool resource has been freed.
			def wait
				@notification.wait
			end
			
			def empty?
				@resources.empty?
			end
			
			def acquire
				resource = wait_for_resource
				
				return resource unless block_given?
				
				begin
					yield resource
				ensure
					release(resource)
				end
			end
			
			# Make the resource resources and let waiting tasks know that there is something resources.
			def release(resource)
				# A resource that is not good should also not be reusable.
				if resource.reusable?
					reuse(resource)
				else
					retire(resource)
				end
			end
			
			def close
				@resources.each_key(&:close)
				@resources.clear
			end
			
			def to_s
				if @resources.empty?
					"\#<#{self.class}(#{usage_string})>"
				else
					"\#<#{self.class}(#{usage_string}) #{availability_string}>"
				end
			end
			
			# Retire (and close) all unused resources. If a block is provided, it should implement the desired functionality for unused resources.
			# @param retain [Integer] the minimum number of resources to retain.
			# @yield resource [Resource] unused resources.
			def prune(retain = 0)
				unused = []
				
				@resources.each do |resource, usage|
					unused << resource if usage.zero?
				end
				
				unused.each do |resource|
					if block_given?
						yield resource
					else
						retire(resource)
					end
					
					break if @resources.size <= retain
				end
				
				return unused.size
			end
			
			def retire(resource)
				Async.logger.debug(self) {"Retire #{resource}"}
				
				@resources.delete(resource)
				
				resource.close
				
				@notification.signal
			end
			
			protected
			
			def usage_string
				"#{@resources.size}/#{@limit || '∞'}"
			end
			
			def availability_string
				@resources.collect do |resource,usage|
					"#{usage}/#{resource.concurrency}#{resource.viable? ? nil : '*'}/#{resource.count}"
				end.join(";")
			end
			
			def reuse(resource)
				Async.logger.debug(self) {"Reuse #{resource}"}
				
				@resources[resource] -= 1
				@available.push(resource)
				
				@notification.signal
			end
			
			def wait_for_resource
				# If we fail to create a resource (below), we will end up waiting for one to become resources.
				until resource = available_resource
					@notification.wait
				end
				
				Async.logger.debug(self) {"Wait for resource -> #{resource}"}
				
				# if resource.concurrency > 1
				# 	@notification.signal
				# end
				
				return resource
			end
			
			def create_resource
				# This might return nil, which means creating the resource failed.
				if resource = @constructor.call
					@resources[resource] = 1
					
					@available.push(resource) if resource.concurrency > 1
				end
				
				return resource
			end
			
			def available_resource
				@guard.acquire do
					while resource = @available.last
						if usage = @resources[resource] and usage < resource.concurrency
							if resource.viable?
								@resources[resource] += 1
								
								return resource
							else
								retire(resource)
								@available.pop
							end
						else
							@available.pop
						end
					end
					
					if @limit.nil? or @resources.size < @limit
						Async.logger.debug(self) {"No resources resources, allocating new one..."}
						
						return create_resource
					end
				end
				
				return nil
			end
		end
	end
end
