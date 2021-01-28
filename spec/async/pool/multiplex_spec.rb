# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'controller_helper'

RSpec.describe Async::Pool::Controller, timeout: 1 do
	include_context Async::RSpec::Reactor
	
	let(:constructor) {lambda{Async::Pool::Resource.new(2)}}
	subject {described_class.new(constructor)}
	
	describe '#available' do
		it "is initially empty" do
			expect(subject.available).to be_empty
		end
		
		it "will put object in available list after one use" do
			object = subject.acquire
			allow(object).to receive(:reusable?).and_return(true)
			
			subject.release(object)
			
			expect(subject).to be_active
			expect(subject.available).to be == [object]
		end
		
		it "can acquire and release the same object up to the concurrency limit" do
			object1 = subject.acquire
			allow(object1).to receive(:reusable?).and_return(true)
			
			object2 = subject.acquire
			expect(object2).to be_equal(object1)
			
			expect(subject.available).to be_empty
			
			subject.release(object1)
			expect(subject.available).to be == [object1]
			
			subject.release(object2)
			expect(subject.available).to be == [object1]
		end
	end
	
	describe '#prune' do
		it "removes the item from the availabilty list when it is retired" do
			object = subject.acquire
			allow(object).to receive(:reusable?).and_return(false)
			
			subject.release(object)
			
			subject.prune
			
			expect(subject.available).to be == []
		end
	end
end
