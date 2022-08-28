# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require 'nonblocking_resource'
require 'sus/fixtures/async/reactor_context'

describe Async::Pool::Controller do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:constructor) {lambda{Async::Pool::Resource.new(2)}}
	let(:pool) {subject.new(constructor)}
	
	with '#available' do
		it "is initially empty" do
			expect(pool.available).to be(:empty?)
		end
		
		it "will put object in available list after one use" do
			object = pool.acquire
			mock(object) do |mock|
				mock.replace(:reusable?) {true}
			end
			
			pool.release(object)
			
			expect(pool).to be(:active?)
			expect(pool.available).to be == [object]
		end
		
		it "can acquire and release the same object up to the concurrency limit" do
			object1 = pool.acquire
			mock(object1) do |mock|
				mock.replace(:reusable?) {true}
			end
			
			object2 = pool.acquire
			expect(object2).to be(:equal?, object1)
			
			expect(pool.available).to be(:empty?)
			
			pool.release(object1)
			expect(pool.available).to be == [object1]
			
			pool.release(object2)
			expect(pool.available).to be == [object1]
		end
	end
	
	with '#prune' do
		it "removes the item from the availabilty list when it is retired" do
			object = pool.acquire
			
			mock(object) do |mock|
				mock.replace(:reusable?) {false}
			end
			
			pool.release(object)
			
			pool.prune
			
			expect(pool.available).to be == []
		end
	end
end
