# frozen_string_literal: true

# Verifies that retire + release on the same resource does not raise
# "Trying to reuse unacquired resource".
#
# In practice this happens with async-http when an HTTP/2 connection is reset:
# the background reader retires the connection, but retire's resource.close
# yields (e.g. sending GOAWAY), allowing another fiber to call release while
# the resource is deleted from @resources but still reports reusable? = true.

require "async/pool/controller"
require "async/pool/resource"
require "sus/fixtures/async/reactor_context"

# A resource whose close yields (simulating async IO like sending GOAWAY),
# but whose reusable? check is synchronous (no yield).
class SlowCloseResource < Async::Pool::Resource
	def close
		Async::Task.current.yield
		super
	end
end

describe Async::Pool::Controller do
	include Sus::Fixtures::Async::ReactorContext
	
	with "retire/release race on slow-close resource" do
		let(:pool) {subject.new(SlowCloseResource)}
		
		it "gracefully handles release after retire begins closing" do
			resource = pool.acquire
			
			# Start retire in a child task. It runs synchronously up to the
			# yield inside SlowCloseResource#close, then pauses. At that point
			# @resources[resource] has been deleted but resource.close hasn't
			# finished, so reusable? still returns true.
			retire_task = Async do
				pool.retire(resource)
			end
			
			# No yield needed — the child already ran to its yield point.
			# Verify the race window exists:
			expect(resource).to be(:reusable?)
			expect(pool.resources).not.to be(:key?, resource)
			
			# The client's error handler now tries to release the same resource.
			# This should not raise — retire already claimed ownership.
			pool.release(resource)
			
			retire_task.wait
		end
		
		it "gracefully handles multiplexed release after retire begins closing" do
			constructor = lambda{SlowCloseResource.new(128)}
			pool = subject.new(constructor)
			
			# Two streams on the same HTTP/2 connection:
			r1 = pool.acquire
			r2 = pool.acquire
			expect(r1).to be_equal(r2)
			
			# Background reader retires (yields during close):
			retire_task = Async do
				pool.retire(r1)
			end
			
			# The race window is open: resource deleted from pool but not
			# yet closed. First stream's error handler hits the race:
			expect(r1).to be(:reusable?)
			expect(pool.resources).not.to be(:key?, r1)
			
			# Should not raise:
			pool.release(r1)
			
			retire_task.wait
		end
	end
end
