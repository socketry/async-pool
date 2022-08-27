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
	
	let(:pool) {subject.new(Async::Pool::Resource)}
	
	with '#acquire' do
		it "can allocate resources" do
			object = pool.acquire
			
			expect(object).not.to be_nil
			expect(pool).to be(:busy?)
			
			pool.release(object)
			expect(pool).not.to be(:busy?)
		end
	end
	
	with '#release' do
		it "will reuse resources" do
			object = pool.acquire
			
			expect(object).to receive(:reusable?).and_return(true)
			
			pool.release(object)
			
			expect(pool).to be(:active?)
		end
		
		it "will retire unusable resources" do
			object = pool.acquire
			
			expect(object).to receive(:reusable?).and_return(false)
			
			pool.release(object)
			
			expect(pool).not.to be(:active?)
		end
		
		it "will fail when releasing an unacquired resource" do
			object = pool.acquire
			
			mock(object) do |mock|
				mock.replace(:reusable?) {true}
			end
			
			pool.release(object)
			
			expect do
				pool.release(object)
			end.to raise_exception(RuntimeError, message: /unacquired resource/)
		end
	end
	
	with '#prune' do
		it "can prune unused resources" do
			pool.acquire{}
			
			expect(pool).to be(:active?)
			
			pool.prune
			
			expect(pool).not.to be(:active?)
		end
	end
	
	with '#close' do
		it "will no longer be active" do
			object = pool.acquire
			expect(object).to receive(:reusable?).and_return(true)
			pool.release(object)
			
			pool.close
			
			expect(pool).not.to be(:active?)
		end
		
		it "should clear list of available resources" do
			object = pool.acquire
			expect(object).to receive(:reusable?).and_return(true)
			pool.release(object)
			
			expect(pool.available).not.to be(:empty?)
			
			pool.close
			
			expect(pool.available).to be(:empty?)
		end
		
		it "can acquire resource during close" do
			object = pool.acquire
			
			mock(object) do |mock|
				mock.replace(:close) do
					pool.acquire{}
				end
			end
				
			pool.release(object)
			
			pool.close
			
			expect(pool).not.to be(:active?)
		end
	end
	
	with '#to_s' do
		it "can inspect empty pool" do
			expect(pool.to_s).to be(:match?, "0/∞")
		end
	end
	
	with 'a small limit' do
		let(:pool) {subject.new(Async::Pool::Resource, limit: 1)}
		
		with '#to_s' do
			it "can inspect empty pool" do
				expect(pool.to_s).to be(:match?, "0/1")
			end
		end
		
		with '#acquire' do
			it "will limit allocations" do
				state = nil
				inner = nil
				outer = pool.acquire
				
				reactor.async do
					state = :waiting
					inner = pool.acquire
					state = :acquired
					pool.release(inner)
				end
				
				expect(state).to be == :waiting
				pool.release(outer)
				reactor.yield
				expect(state).to be == :acquired
				
				expect(outer).to be == inner
			end
		end
	end
	
	with "with non-blocking connect" do
		let(:pool) do
			subject.wrap do
				# Simulate a non-blocking connection:
				Async::Task.current.sleep(0.1)
				
				Async::Pool::Resource.new
			end
		end
		
		with '#acquire' do
			it "can reuse resources" do
				3.times do
					pool.acquire{}
				end
				
				expect(pool.size).to be == 1
			end
		end
	end
	
	with 'a busy connection pool' do
		let(:pool) {subject.new(NonblockingResource)}
		
		def failures(repeats: 500, time_scale: 0.001, &block)
			count = 0
			backtraces = Set.new
			
			Sync do |task|
				while count < repeats
					begin
						task.with_timeout(rand * time_scale, &block)
					rescue Async::TimeoutError => error
						backtraces << error.backtrace.first(10)
						count += 1
					else
						if count.zero?
							time_scale /= 2
						end
					end
				end
			end
			
			# pp backtraces
		end
		
		it "robustly releases resources" do
			failures do
				begin
					resource = pool.acquire
				ensure
					pool.release(resource) if resource
				end
			end
			
			expect(pool).not.to be(:busy?)
		end
	end
end

describe Async::Pool::Controller do
	let(:pool) {subject.new(Async::Pool::Resource)}
	
	with '#close' do
		it "closes all resources when going out of scope" do
			Async do
				object = pool.acquire
				expect(object).not.to be_nil
				pool.release(object)
				
				# There is some resource which is still open:
				expect(pool.resources).not.to be(:empty?)
			end
			
			expect(pool.resources).to be(:empty?)
		end
	end
end
