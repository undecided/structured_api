## Just a few utilities that I've been using in the examples.
## Feel free to steal from here if you need it

require_relative '../lib/structured_api'
require 'json'

class Hash
  def deep_symbolize_keys
    map do |k, v|
      new_key = k.is_a?(String) ? k.to_sym : k
      new_value = v.respond_to?(:deep_symbolize_keys) ? v.deep_symbolize_keys : v

      [new_key, new_value]
    end.to_h
  end
end

class Array
  def deep_symbolize_keys
    map { |item| item.respond_to?(:deep_symbolize_keys) ? item.deep_symbolize_keys : item }
  end
end

ASK = lambda { |q, default = ''|
  print "\n#{q}  (Default: #{default})>  "
  out = STDIN.gets.strip
  out.[](/[^\s]+/) ? out : default
}
