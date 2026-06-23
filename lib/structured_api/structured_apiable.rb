module StructuredApi
  module StructuredApiable
    # TODO: Raise an exception on the singleton methods if self.class == StructuredApi::Endpoint (it will pollute everything)

    # This is where the magic happens, and I agree - it's too much magic.
    # TODO: Document a bit better - lots of sharp corners here
    # Note: empty_value cannot be nil
    def define_attr(name, empty_value, unset_value, concat_or_replace = :concat, fn_concat = ->(a,b) { a + b }, fn_cast: ->(x){x})
      raise "concat_or_replace must be :concat or :replace" unless [:concat, :replace].include?(concat_or_replace)
      fn_concat = ->(a,b) { b } if concat_or_replace == :replace

      instance_variable_set(:"@#{name}", unset_value) unless unset_value == empty_value

      define_singleton_method "has_#{name}?" do
        instance_variable_defined?(:"@#{name}")
      end

      define_singleton_method(name.to_sym) do |incoming = nil, &block|
        raise "Cannot pass both incoming and block" if incoming && block
        raise "Cannot use a block on concat-style fields" if block && concat_or_replace == :concat

        incoming = fn_cast.call(incoming)
        value = if concat_or_replace == :replace
          block || incoming  # we don't want to try to call a block we don't need
        else
          fn_concat.call(get_attr(name, empty_value).dup, incoming)
        end
        instance_variable_set(:"@#{name}", value)
        self
      end

      define_singleton_method :"clear_#{name}" do
        instance_variable_set(:"@#{name}", empty_value)
        self
      end if concat_or_replace == :concat

      define_method(name.to_sym) do |incoming = nil, &block|
        incoming = instance_exec(&block) if block
        incoming = fn_cast.call(incoming)
        value = fn_concat.call(get_attr(name, empty_value), incoming)
        instance_variable_set(:"@#{name}", value)
        self
      end

      define_method :"clear_#{name}" do
        instance_variable_set(:"@#{name}", empty_value)
        self
      end
    end
    module_function :define_attr

    def hash_attr(name, empty_value: {}, default: empty_value, if_exists: :concat)
      define_attr(name, empty_value, default, if_exists, ->(a,b) { a.merge(b) })
    end
    module_function :hash_attr

    def array_attr(name, empty_value: [], default: empty_value, if_exists: :concat)
      define_attr(name, empty_value, default, if_exists, fn_cast: ->(x){Array(x)})
    end
    module_function :array_attr

    def stringish_attr(name, empty_value: '', default: empty_value, if_exists: :replace)
      define_attr(name, empty_value, default, if_exists) # no cast - we allow blocks, symbols... all sorts
    end
    module_function :stringish_attr

    def self.extended(other)
      other.define_singleton_method :has_attr? do |name|
        instance_variable_defined?(:"@#{name}") ||
          (superclass&.has_attr?(name) if superclass&.respond_to?(:has_attr?)) ||
          false
      end

      other.define_singleton_method :get_attr do |name, default = nil|
        result = instance_variable_get(:"@#{name}") ||
          (superclass&.get_attr(name, nil) if superclass&.respond_to?(:get_attr)) ||
          default
        return result unless result.respond_to?(:call)
        instance_variable_set(:"@#{name}", result.call) # cache the result and return
      end

      other.define_singleton_method :append_lifecycle_hook do |hook_name, &block|
        lifecycle_hooks([{ name: hook_name, block: block }])
        self
      end

      other.define_singleton_method :prepend_lifecycle_hook do |hook_name, &block|
        get_attr(:lifecycle_hooks, []).unshift({ name: hook_name, block: block })
        self
      end

      other.define_method :get_method_or_attr do |name, default = nil|
        return send(:"override_#{name}") if respond_to?(:"override_#{name}")
        get_attr(name, default)
      end

      other.define_method :get_attr do |name, default = nil|
        attr = instance_variable_get(:"@#{name}") ||
          self.class.get_attr(name, default)
        attr || default&.dup&.tap { |d| instance_variable_set(:"@#{name}", d) }
      end

      other.define_method :trigger_lifecycle_hooks do |hook_name, additional_data = {}|
        self.class.get_attr(:lifecycle_hooks, {})
          .select { |h| h[:name] == hook_name }
          .each do |h|
            puts "executing #{hook_name} hook from #{h[:block].source_location&.join(':') || 'unknown location'} on #{self.class.name}" if @debug
            instance_exec(additional_data, &h[:block])
          end
      end

      other.send :stringish_attr, :url
      other.send :stringish_attr, :path
      other.send :stringish_attr, :verb
      other.send :hash_attr, :params
      other.send :hash_attr, :headers
      other.send :stringish_attr, :body
      other.send :array_attr, :lifecycle_hooks
    end
  end
end
