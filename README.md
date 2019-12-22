# Async::Pool

Provides support for connection pooling both singleplex and multiplex resources.

[![Build Status](https://travis-ci.com/socketry/async-pool.svg)](https://travis-ci.com/socketry/async-pool)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'async-pool'
```

And then execute:

	$ bundle

Or install it yourself as:

	$ gem install async-pool

## Usage

`Async::Pool::Controller` provides support for both singleplex (one stream at a time) and multiplex resources (multiple streams at a time).

`Async::Pool::Resource` is provided as an interface and to document how to use the pools. However, you wouldn't need to use this in practice and just implement the appropriate interface on your own objects.

```ruby
pool = Async::Pool::Controller.new(Async::Pool::Resource)

pool.acquire do |resource|
	# resource is implicitly released when exiting the block.
end

resource = pool.acquire

# Return the resource back to the pool:
pool.release(resource)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2019, by [Samuel G. D. Williams](http://www.codeotaku.com).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
