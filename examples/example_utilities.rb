## Just a few utilities that I've been using in the examples.

require_relative '../lib/structured_api'
require 'json'

class Hash
  def deep_dup
    Marshal.load(Marshal.dump(self))
  end
end

# Simplified version of Rails' str.constantize
# Note: AIs sometimes fail to do :: and do : instead, so we gotta be a bit flexible
def Class.fetch(str) = str.split(/:+/).inject(self, &:const_get)

ASK = lambda { |q, default = ''|
  print "\n#{q}  (Default: #{default})>  "
  out = STDIN.gets.strip
  out.[](/[^\s]+/) ? out : default
}
