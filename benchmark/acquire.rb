# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "sus/fixtures/benchmark"
require "sus/fixtures/async/scheduler_context"

require "async/pool"
require "async/pool/resource"

include Sus::Fixtures::Benchmark
include Sus::Fixtures::Async::SchedulerContext

describe Async::Pool::Controller do
	let(:pool) {subject.new(Async::Pool::Resource)}
	measure Async::Pool::Controller do |repeats|
		pool = self.pool
		
		repeats.times do
			pool.acquire do |resource|
			end
		end
	end
end
