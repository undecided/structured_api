module StructuredApi
  class Endpoint
    extend StructuredApi::StructuredApiable
    class InvalidRequest < StandardError; end

    def debug!(val = true)
      @debug = val
      self
    end

    def run!
      response = run_request
      return response unless block_given?

      yield response
      return self
    end

    def rerun!(&block)
      @run_request = nil
      run!(&block)
    end

    private # TODO: Use visitor pattern to prevent possible clashes

    def run_request
      @run_request ||= begin
        trigger_lifecycle_hooks(:before_request)
        final_params = typhoeus_params
        puts final_params.inspect if @debug
        client = Typhoeus::Request.new(*final_params).run
        response = {response: client.response_body, status: client.response_code, headers: client.response_headers, client: client}
        puts response if @debug
        trigger_lifecycle_hooks(:after_response, response)
        response[:response]
      end
    end

    def url_and_path
      my_url = get_attr(:url, nil)
      my_url = my_url.call if my_url.respond_to?(:call)
      raise InvalidRequest, 'At least a url is needed' unless my_url

      my_url = my_url[0..-2] if my_url[-1] == '/'
      my_path = get_method_or_attr(:path, '')
      my_path = my_path[1..-1] if my_path[0] == '/'
      [my_url, my_path].join('/')
    end

    def typhoeus_params
      [
        url_and_path,
        {
          method: get_method_or_attr(:verb, :get),
          body: get_method_or_attr(:body, nil),
          params: get_method_or_attr(:params, {}),
          headers: get_method_or_attr(:headers, {}),
          followlocation: true
        }
      ]
    end
  end
end
