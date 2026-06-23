## One Day...

### About this document

Bear in mind, this is ripped pretty much verbatim out of my notes - I wrote the code below
before I had started writing the gem, so that I had some idea where I was going and
whether it would even be possible.

There are some ideas here I'd rather not follow through with - for example, I don't think
I'm going to do `prefix` and will instead produce some kind of URL or path appending maybe?
Don't know. Feel like there's a more flexible way than this.

And again, `log_incoming` and `log_outgoing` are definitely features I want, but it
would be far preferable to have proper request lifecycle management (e.g. `after_initialize`,
`before_transform`, `before_send`, `before_response` (!), `after_response`, `after_detransform`)

### Initially intended roadmap

Simple Usage:

```ruby
module Ghost::Settings < StructuredApi::Settings
  # anything here can also be defined directly on the Endpoint, but why would you?
  url("https://demo.ghost.io")
  prefix("ghost/api/v3/content")
  headers(a: "b", content_type: :some_method, "X-reason-for": "basic what")
  params(key: :fetch_api_key) # additive - unless you "clear_params" / "clear_headers"
  end_with_slash(true) # e.g. always /posts/?..., never /posts?...

  # response is a Ghost::BlogPost::Response instance, with .headers, .data, .raw_data
  # e.g "<h1>derp</h1>", {}, 404
  # and also .request, in case you need something from that
  log_incoming do |response|
    # do something with it
  end

  # request is a Ghost::BlogPost::Request instance, with .path, .headers, .data, .raw_data
  # - this will get called even if the vm gets killed, so no .response is
  # available here (you could always use log_incoming if you need both)
  log_outgoing do |request|
    # do something with it
  end

  def fetch_api_key
    ENV.fetch("GHOST_API_KEY")
  end
end


class Ghost::BlogPost < StructuredApi::Endpoint
  include Ghost::Settings ## brings in all the Api Settings (or specify them here)

  attributes :including
  verb(:get)
  action('posts')
  params(include: -> { including.join(",") })

  process_request do
    # or maybe def process_request to make self clearer?
    raw_data.to_json
  end

  format_response do
    JSON.parse(raw_data)
  end

end


# ... then...

Ghost::BlogPost.new(including: %w[tags authors]).run! do |response|
  # use this if you need the full response object
end

Ghost::BlogPost.new(including: %w[tags authors]).run! # returns just the .data

# or if it's a post, you can
Ghost::BlogPost::Create.new.data({}).run!
# (both new and run! can accept params: {} or data: {} at any time, unless these
# are overridden as attributes / methods. Personal preference!)

Ghost::BlogPost.new.clear_params.params(only: "me").run!
Ghost::BlogPost.new.headers(api_version: "v2").run!

# or maybe we're being real heathens:

StructuredApi::Endpoint.new.url("https://google.com").verb(:get).run!

```


### Phase 2

Again, this is me just spitballing - I have no idea whether this is possible...

```ruby
class Ghost::General < StructuredApi::Endpoint
  ## All these could be implemented using before_request / after_request
  url "https://demo.ghost.io"
  add_path "ghost/api/v3/content" # clear_path, merge_params, clear_params
  verb :post

  ## endpoint needs to know what state it's in - e.g. endpoint.request.state
  ## request = nil
  ##  => request.state => [:configuring] # <= should be a struct instead of array btw
  ##  => [:before_request, 4(an internal idx), [PayloadStore, :from_endpoint]]
  ##  => [:in_my_cup, 5, #<proc#badcad1...>]
  ##  => [:two_shots, 6, #<proc#badcad1...>]
  ##  => [:performing_request]
  ##  => [:after_request, 0, #<proc#badcad1...>]
  ## before_request! cancels request and raises the exception - maybe can be resumed with .resume or .restart
  ## before_request catches any exceptions (configurable catcher so you can make some always raise)

  ## Note: this is the only one that replaces. All the others append
  exception_catcher ->(endpoint, error) { ... swallow, spit or quit quietly with endpoint.cancel ...}

  on_state_change ->(endpoint, request_or_response) { ... request_or_response.state ...}

  before_request ->(endpoint) { endpoint.request.payload = JSON.parse(endpoint.request.body) }
  before_request name: :skippy, do |endpoint| ... end
  before_request! PayloadStore, :from_endpoint # <= calls this with endpoint
  before_request EndpointLoggerService # <= defaults to .call(endpoint)
  before_request :log_to_disk # <= just called (doesn't need args, has self)
  before_request ->(...) {...}, name: :two_shots
  before_request ->(...) {...}, name: :in_my_cup, before: :two_shots

  skip_request :skippy

  after_request ->(endpoint) { endpoint.response.body = JSON.parse(endpoint.response.body) }
  after_request! PayloadStore, :from_endpoint # ... etc. endpoint.response is nil if we haven't started

  executor do |request, response| # request full, response empty and ready to go
    typh_response = Typhoeus::....(request....)
    response.populate(headers: typh_response.headers, ...)
  end
end




```
