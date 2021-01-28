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
	
	subject {described_class.new(Async::Pool::Resource)}
	
	describe '#acquire' do
		it "can allocate resources" do
			object = subject.acquire
			
			expect(object).to_not be_nil
			expect(subject).to be_busy
			
			subject.release(object)
			expect(subject).to_not be_busy
		end
	end
	
	describe '#release' do
		it "will reuse resources" do
			object = subject.acquire
			
			expect(object).to receive(:reusable?).and_return(true)
			
			subject.release(object)
			
			expect(subject).to be_active
		end
		
		it "will retire unusable resources" do
			object = subject.acquire
			
			expect(object).to receive(:reusable?).and_return(false)
			
			subject.release(object)
			
			expect(subject).to_not be_active
		end
	end
	
	describe '#prune' do
		it "can prune unused resources" do
			subject.acquire{}
			
			expect(subject).to be_active
			
			subject.prune
			
			expect(subject).to_not be_active
		end
	end
	
	describe '#to_s' do
		it "can inspect empty pool" do
			expect(subject.to_s).to match("0/∞")
		end
	end
	
	context "with limit" do
		subject {described_class.new(Async::Pool::Resource, limit: 1)}
		
		describe '#to_s' do
			it "can inspect empty pool" do
				expect(subject.to_s).to match("0/1")
			end
		end
		
		describe '#acquire' do
			it "will limit allocations" do
				state = nil
				inner = nil
				outer = subject.acquire
				
				reactor.async do
					state = :waiting
					inner = subject.acquire
					state = :acquired
					subject.release(inner)
				end
				
				expect(state).to be :waiting
				subject.release(outer)
				reactor.yield
				expect(state).to be :acquired
				
				expect(outer).to be inner
			end
		end
	end
	
	context "with non-blocking connect" do
		subject do
			described_class.wrap do
				# Simulate a non-blocking connection:
				Async::Task.current.sleep(0.1)
				
				Async::Pool::Resource.new
			end
		end
		
		describe '#acquire' do
			it "can reuse resources" do
				3.times do
					subject.acquire{}
				end
				
				expect(subject.size).to be == 1
			end
		end
	end
end

RSpec.describe Async::Pool::Controller, timeout: 1 do
	subject {described_class.new(Async::Pool::Resource)}
	
	describe '#close' do
		it "closes all resources when going out of scope" do
			Async do
				object = subject.acquire
				expect(object).to_not be_nil
				subject.release(object)
				
				# There is some resource which is still open:
				expect(subject.resources).to_not be_empty
			end
			
			expect(subject.resources).to be_empty
		end
	end
end
