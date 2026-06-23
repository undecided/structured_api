# StructuredApi

**The aim:** A library you can use to write quick API calls, or (more usefully)
produce classes that - with a very simple DSL - cleanly describe the API to be
connected to.

Eventually, this will encompass:

 - [X] One-liner api calls, e.g. `StructuredApi.new.url("google.com").run!`
 - [X] Simple class-based dsl where you specify url, params, body etc
 - [X] Class hierarchy - e.g. create an ApplicationClient with auth settings,
 and extend that for each endpoint
 - [X] Ability to define attributes and override previously defined attributes using methods
 - [X] Virtual Attributes - e.g. specify that your API takes a customer, and use
 - [ ] Data munging hooks - how do we transform our domain language into theirs?
 that customer in your data munging phase (or anywhere really)
 - [ ] Helpers for common methods, such as basic auth or JSON
 - [ ] Lifecycle hooks - e.g. easily log incoming / outgoing messages across your
 whole project

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'structured_api'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install structured_api

## Examples

See the `examples/` folder for real-world examples.

 - [Ghost CMS](examples/ghost_cms.rb) - this is a really simple example of using GhostCms' demo api to list posts & authors.
 - [Ollama](examples/ollama.rb) - slightly more advanced - here we use callbacks and advanced use of attributes to chat with an ollama instance
 - [Ollama (with tools!)](examples/ollama_with_tools.rb) - builds on the ollama example, shows how easily you can add tool support to your app.

## Usage

The easy one-liner way:

```
StructuredApi::Endpoint.new.url('https://foo.com').verb(:get).params(q: 'whee').headers(x: :y).run!
```

The better way, define the way you want to connect using a structured DSL:

```
class MyBlogApi < StructuredApi::Endpoint
  url 'https://myblog.com/v1/' # can contain part of the path if you like, trailing slashes ignored
  headers { "Authorization" => "Basic aa11aa11aa11aa11aa11aa11aa=" }
end

class CreateBlogPost < MyBlogApi
  verb :post
  path '/posts' # leading slashes ignored
end

CreateBlogPost.new.body("<h1>Hello World!</h1>").run!
```
For a real-world and executable example of this, see the `examples/`` folder or `spec/simple_structure_spec.rb`

For more information on the initial vision for this, check out ONE_DAY.md

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/undecided/structured_api.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
