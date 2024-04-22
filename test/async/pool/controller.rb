# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'nonblocking_resource'
require 'sus/fixtures/async/reactor_context'

describe Async::Pool::Controller do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:pool) {subject.new(Async::Pool::Resource)}
	
	with 'an empty pool' do
		it 'is not available?' do
			expect(pool).not.to be(:available?)
		end
		
		it 'is empty?' do
			expect(pool).to be(:empty?)
		end
		
		with '#as_json' do
			it 'generates a JSON representation' do
				expect(pool.as_json).to be == {
					limit: nil,
					concurrency: 1,
					usage: 0,
					availability_summary: []
				}
			end
			
			it "generates a JSON string" do
				expect(JSON.dump(pool)).to be == pool.to_json
			end
		end
	end
	
	with 'a limited pool' do
		let(:pool) {subject.new(Async::Pool::Resource, limit: 1)}
		
		it 'waits to acquire' do
			resource = pool.acquire
			expect(resource).not.to be_nil
			
			task = Async do
				pool.acquire do |another_resource|
					expect(another_resource).to be_equal(resource)
				end
			end
			
			pool.release(resource)
			
			task.wait
		end
		
		it 'can wait for a resource to be available' do
			sequence = []
			
			resource = pool.acquire
			expect(resource).not.to be_nil
			
			task = Async do
				sequence << :wait
				pool.wait
				sequence << :waited
			end
			
			sequence << :release
			pool.release(resource)
			
			task.wait
			expect(sequence).to be == [:wait, :release, :waited]
		end
	end
	
	with '#concurrency' do
		it "adjust the concurrency limit" do
			expect(pool.concurrency).to be == 1
			
			pool.concurrency = 2
			expect(pool.concurrency).to be == 2
		end
	end
	
	with 'policy' do
		let(:policy) {proc{|pool| pool.prune(2)}}
		let(:pool) {subject.new(Async::Pool::Resource, policy: policy)}
		
		it "can execute a policy" do
			resources = 4.times.map do
				pool.acquire
			end
			
			resources.each do |resource|
				pool.release(resource)
			end
			
			Async::Task.current.sleep(0.001)
			
			expect(pool.available).to have_attributes(
				size: be == 2
			)
		end
	end
	
	with '#close' do
		it 'closes all resources' do
			resource = pool.acquire
			expect(resource).not.to be_nil
			pool.release(resource)
			
			pool.close
			expect(resource).to be(:closed?)
		end
	end
	
	with '#acquire' do
		it "can allocate resources" do
			resource = pool.acquire
			
			expect(resource).not.to be_nil
			expect(pool).to be(:busy?)
			
			pool.release(resource)
			expect(pool).not.to be(:busy?)
		end
		
		it "retires resources if they are no longer viable" do
			resource = pool.acquire
			pool.release(resource)
			
			expect(resource).to receive(:viable?).and_return(false)
			
			pool.acquire do |another_resource|
				expect(another_resource).not.to be_equal(resource)
			end
		end
	end
	
	with '#release' do
		it "will reuse resources" do
			resource = pool.acquire
			
			expect(resource).to receive(:reusable?).and_return(true)
			
			pool.release(resource)
			
			expect(pool).to be(:active?)
		end
		
		it "will retire unusable resources" do
			resource = pool.acquire
			
			expect(resource).to receive(:reusable?).and_return(false)
			
			pool.release(resource)
			
			expect(pool).not.to be(:active?)
		end
		
		it "will fail when releasing an unacquired resource" do
			resource = pool.acquire
			
			mock(resource) do |mock|
				mock.replace(:reusable?) {true}
			end
			
			pool.release(resource)
			
			expect do
				pool.release(resource)
			end.to raise_exception(RuntimeError, message: be =~ /unacquired resource/)
		end
	end
	
	with '#retire' do
		it "can retire a resource at any time" do
			resource = pool.acquire
			pool.release(resource)
			
			pool.retire(resource)
			expect(pool).to be(:available?)
			
			# Acquiring a resource should not return the retired resource:
			pool.acquire do |another_resource|
				expect(another_resource).not.to be_equal(resource)
			end
		end
	end
	
	with '#prune' do
		it "can prune unused resources" do
			pool.acquire{}
			
			expect(pool).to be(:active?)
			
			pool.prune
			
			expect(pool).not.to be(:active?)
		end
		
		it "can prune unused resources with a block" do
			pool.acquire{}
			
			expect(pool).to be(:active?)
			
			pool.prune do |resource|
				pool.retire(resource)
				expect(resource).to be(:closed?)
			end
			
			expect(pool).not.to be(:active?)
		end
		
		it "can prune with in-use resources" do
			resource = pool.acquire
			
			pool.prune
			
			pool.release(resource)
			
			expect(pool).to be(:available?)
		end
	end
	
	with '#close' do
		it "will no longer be active" do
			resource = pool.acquire
			expect(resource).to receive(:reusable?).and_return(true)
			pool.release(resource)
			
			pool.close
			
			expect(pool).not.to be(:active?)
		end
		
		it "should clear list of available resources" do
			resource = pool.acquire
			expect(resource).to receive(:reusable?).and_return(true)
			pool.release(resource)
			
			expect(pool.available).not.to be(:empty?)
			
			pool.close
			
			expect(pool.available).to be(:empty?)
		end
		
		it "can acquire resource during close" do
			resource = pool.acquire
			
			mock(resource) do |mock|
				mock.replace(:close) do
					pool.acquire{}
				end
			end
				
			pool.release(resource)
			
			pool.close
			
			expect(pool).not.to be(:active?)
		end
		
		it "warns if closing while a resource is acquired" do
			pool.acquire
			
			expect(Console.logger).to receive(:warn).and_return(nil)
			
			pool.close
		end
	end
	
	with '#to_s' do
		it "can inspect empty pool" do
			expect(pool.to_s).to be(:match?, "0/∞")
		end
		
		it "can inspect a non-empty pool" do
			pool.acquire do
				expect(pool.to_s).to be(:match?, "1/∞")
			end
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
		let(:timeout) {60}
		
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
				resource = pool.acquire
				expect(resource).not.to be_nil
				pool.release(resource)
				
				# There is some resource which is still open:
				expect(pool.resources).not.to be(:empty?)
			end
			
			expect(pool.resources).to be(:empty?)
		end
	end
end
