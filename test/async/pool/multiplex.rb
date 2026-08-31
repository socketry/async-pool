# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2026, by Samuel Williams.

require "nonblocking_resource"
require "sus/fixtures/async/reactor_context"

describe Async::Pool::Controller do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:constructor) {lambda{Async::Pool::Resource.new(2)}}
	let(:pool) {subject.new(constructor)}
	
	with "#available" do
		it "is initially empty" do
			expect(pool.available).to be(:empty?)
		end
		
		it "will put object in available list after one use" do
			object = pool.acquire
			mock(object) do |mock|
				mock.replace(:reusable?){true}
			end
			
			pool.release(object)
			
			expect(pool).to be(:active?)
			expect(pool.available.to_a).to be == [object]
		end
		
		it "can acquire and release the same object up to the concurrency limit" do
			object1 = pool.acquire
			mock(object1) do |mock|
				mock.replace(:reusable?){true}
			end
			
			object2 = pool.acquire
			expect(object2).to be(:equal?, object1)
			
			expect(pool.available).to be(:empty?)
			
			pool.release(object1)
			expect(pool.available.to_a).to be == [object1]
			
			pool.release(object2)
			expect(pool.available.to_a).to be == [object1]
		end
		
		it "acquires resources in insertion order" do
			resource1 = pool.acquire
			resource2 = pool.acquire
			resource3 = pool.acquire
			
			expect(resource2).to be_equal(resource1)
			expect(resource3).not.to be_equal(resource1)
			
			pool.release(resource1)
			
			expect(pool.available.to_a).to be == [resource3, resource1]
			
			pool.release(resource2)
			expect(pool.available.to_a).to be == [resource3, resource1]
			
			pool.acquire do |resource|
				expect(resource).to be_equal(resource3)
			end
			
			pool.release(resource3)
		end
	end
	
	with "a non-reusable resource" do
		let(:constructor) {lambda{Async::Pool::Resource.new(3)}}
		let(:pool) {subject.new(constructor, limit: 1)}
		
		it "retires the resource after the final release" do
			resource1 = pool.acquire
			resource2 = pool.acquire
			
			mock(resource1) do |mock|
				mock.replace(:reusable?){false}
			end
			
			pool.release(resource1)
			
			expect(pool.resources[resource1]).to be == 1
			expect(pool.available).to be(:empty?)
			expect(resource1).not.to be(:closed?)
			
			pool.release(resource2)
			
			expect(pool.resources).not.to be(:key?, resource1)
			expect(resource1).to be(:closed?)
		end
		
		it "continues to occupy the pool until the final release" do
			resource1 = pool.acquire
			resource2 = pool.acquire
			
			mock(resource1) do |mock|
				mock.replace(:reusable?){false}
			end
			
			pool.release(resource1)
			
			state = :waiting
			acquired = nil
			acquire_task = Async do
				acquired = pool.acquire
				state = :acquired
				pool.release(acquired)
			end
			
			expect(state).to be == :waiting
			expect(pool.size).to be == 1
			
			waited = false
			wait_task = Async do
				pool.wait_until_free
				waited = true
			end
			
			expect(waited).to be == false
			
			pool.release(resource2)
			
			acquire_task.wait
			wait_task.wait
			
			expect(state).to be == :acquired
			expect(acquired).not.to be_equal(resource1)
			expect(waited).to be == true
		end
		
		it "defers retirement when acquisition discovers an active non-viable resource" do
			resource = pool.acquire
			
			mock(resource) do |mock|
				mock.replace(:viable?){false}
				mock.replace(:reusable?){false}
			end
			
			state = :waiting
			acquired = nil
			acquire_task = Async do
				acquired = pool.acquire
				state = :acquired
				pool.release(acquired)
			end
			
			expect(state).to be == :waiting
			expect(pool.resources[resource]).to be == 1
			expect(pool.available).to be(:empty?)
			expect(resource).not.to be(:closed?)
			
			pool.release(resource)
			acquire_task.wait
			
			expect(state).to be == :acquired
			expect(acquired).not.to be_equal(resource)
			expect(resource).to be(:closed?)
		end
		
		it "allows explicit retirement while the resource is active" do
			resource1 = pool.acquire
			resource2 = pool.acquire
			
			expect(pool.retire(resource1)).to be == true
			
			expect(pool.resources).not.to be(:key?, resource1)
			expect(resource1).to be(:closed?)
			
			pool.release(resource1)
			pool.release(resource2)
		end
	end
	
	with "#prune" do
		it "removes the item from the availabilty list when it is retired" do
			object = pool.acquire
			
			mock(object) do |mock|
				mock.replace(:reusable?){false}
			end
			
			pool.release(object)
			
			pool.prune
			
			expect(pool.available).to be(:empty?)
		end
		
		it "puts the item back into the available list if it is reusable" do
			pool.acquire do |object|
				mock(object) do |mock|
					mock.replace(:reusable?){true}
				end
				
				pool.prune
				
				expect(pool.available.to_a).to be == [object]
			end
		end
	end
	
	with "slow constructor" do
		let(:constructor) {lambda{sleep 0.001; Async::Pool::Resource.new(2)}}
		
		it "correctly acquires two resources" do
			object1 = pool.acquire
			object2 = pool.acquire
			object3 = pool.acquire
			
			expect(object1).to be_equal(object2)
			expect(object1).not.to be_equal(object3)
			
			pool.release(object1)
			pool.release(object2)
			pool.release(object3)
		end
	end
end
