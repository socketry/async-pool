# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'async/pool/controller'
require 'async/pool/resource'
require 'async/queue'

require 'sus/fixtures/async/reactor_context'

describe Async::Pool::Controller do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:resources) {Async::Queue.new}
	
	let(:constructor) do
		lambda do
			resource = resources.dequeue
			
			if resource.is_a?(Exception)
				raise resource
			end
			
			resource
		end
	end
	
	let(:pool) {subject.new(constructor)}
	
	with "a constructor that fails" do
		it "robustly creates new resources" do
			resource1 = Async::Pool::Resource.new
			resource2 = Async::Pool::Resource.new
			
			resources.enqueue(RuntimeError.new("Failed to connect"))
			resources.enqueue(resource1)
			resources.enqueue(RuntimeError.new("Failed to connect"))
			resources.enqueue(resource2)
			
			expect{pool.acquire}.to raise_exception(RuntimeError)
			expect(pool.acquire).to be == resource1
			expect{pool.acquire}.to raise_exception(RuntimeError)
			expect(pool.acquire).to be == resource2
		ensure
			pool.release(resource1)
			pool.release(resource2)
		end
	end
end
