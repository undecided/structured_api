## One Day...

Here's some things I've thought about, in order of desire. Feel free to open an issue - or even a PR - if these things are bugging you too.


### end_with_slash

Currently, it's not easy to force `posts/` instead of `posts`. We should have an `end_with_slash` method that can be called to ensure the path ends with a slash.


### Visitor Pattern

Rather than having the Typhoeus methods baked into the request, we should have a requestor object that uses the StructuredApi::Endpoint child as a configuration object.

Same with the lifecycle methods.

And then, switching out from Typhoeus (faraday, httparty etc) could be easy:

```ruby
class MyApi < StructuredApi::Endpoint
  use_requestor MyRequestor # calls MyRequestor.new(self).run!
end
```


### Chained struct and proper JSON / XML support

Currently, you can specify that you want the response treated as JSON - but that's all on you. That's great for flexibility, but poor for first-timers.

Also, an option to be able to do `response.content.posts` instead of `response.dig("content", "posts")` would be nice. The deep_symbolize_keys in the example_utilities.rb file is a start, but it's not a real struct.


### More lifecycle methods

We currently have before_request and after_response, and we can append and prepend them.

This allows a simple form of transformation within the callbacks; however, it might be nice to be able to do a more structured pipeline of data?

Feels like someone else's job though.


### Better hook management

Not entirely sure here - after all, the best hook is no hook at all. People can - and should - manage their hooks outside of the structured API, then they can sort the ordering themselves.

However, it might be nice to give people more tools when they want to daisy-chain their hooks. Maybe give a hook a name, and create a method `insert_hook_before(:after_response, :my_jsonificator) do ...`

