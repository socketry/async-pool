# Async::Pool

Provides support for connection pooling both singleplex and multiplex resources.

[![Development Status](https://github.com/socketry/async-pool/workflows/Test/badge.svg)](https://github.com/socketry/async-pool/actions?workflow=Test)

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'async-pool'
```

And then execute:

``` bash
$ bundle
```

Or install it yourself as:

``` bash
$ gem install async-pool
```

## Usage

`Async::Pool::Controller` provides support for both singleplex (one stream at a time) and multiplex resources (multiple streams at a time).

`Async::Pool::Resource` is provided as an interface and to document how to use the pools. However, you wouldn't need to use this in practice and just implement the appropriate interface on your own objects.

``` ruby
pool = Async::Pool::Controller.new(Async::Pool::Resource)

pool.acquire do |resource|
	# resource is implicitly released when exiting the block.
end

resource = pool.acquire

# Return the resource back to the pool:
pool.release(resource)
```

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.
