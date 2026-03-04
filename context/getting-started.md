# Getting Started

This guide explains how to use the `async-pool` gem to manage connection pooling.

## Installation

Add this gem to your project:

~~~ bash
$ bundle add async-pool
~~~

## Core Concepts

- {ruby Async::Pool::Controller} provides support for both singleplex (one stream at a time) and multiplex resources (multiple streams at a time).
- {ruby Async::Pool::Resource} is provided as an interface and to document how to use the pools. However, you wouldn't need to use this in practice and just implement the appropriate interface on your own objects.

## Simplex Usage

A simplex pool is one where each resource can only be used one at a time. This is the most common type of pool, where each resource represents a single connection, e.g. `HTTP/1`.

~~~ ruby
pool = Async::Pool::Controller.new(Async::Pool::Resource)

pool.acquire do |resource|
	# resource is implicitly released when exiting the block.
end

resource = pool.acquire

# Return the resource back to the pool:
pool.release(resource)
~~~

## Multiplex Usage

A multiplex pool is one where each resource can be used multiple times concurrently. This is useful for resources that can handle multiple connections at once, e.g. `HTTP/2`.

~~~ ruby
pool = Async::Pool::Controller.wrap do
	# This resource can be used concurrently by up to 4 tasks:
	Async::Pool::Resource.new(2)
end

resources = 4.times.map do
	# Acquire a resource from the pool:
	pool.acquire
end

resources.each do |resource|
	# Return the resource back to the pool:
	pool.release(resource)
end
~~~

## Limit and Concurrency

There are two key parameters to consider when using a pool:

- `limit` is the maximum number of resources that can be acquired at once.
- `concurrency` is the maximum number of resources that can be created concurrently.

If the pool does not have any resources available, and the number of resources is less than the limit, a new resource will be created, otherwise the task will wait until a resource is available.

Creating resources can take time, and if multiple tasks are waiting for resources, it may be beneficial to create resources concurrently. Simplex resources are probably better created concurrently, while multiplex resources may be better created serially, as after a resource is created, it can be used by multiple tasks.
