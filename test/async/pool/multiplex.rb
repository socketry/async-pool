# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, pool to the following conditions:
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
