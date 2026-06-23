require_relative 'ollama'
DEBUG = true # turn this off if it's all too noisy for you

module Tool
  class CheckLimerick
    def self.to_ollama_tool
      {
        type: 'function',
        function: {
          name: name, # i.e. Tool::CheckLimerick - we're taking ollama output and constantizing, bit dangerous.
          description: 'If there is a limerick involved in your answer, ALWAYS use this tool before responding. VERY IMPORTANT.',
          parameters: {
            type: 'object',
            properties: {
              verse: {
                type: 'string',
                description: 'The whole limerick, all 5 lines, line separator = //'
              }
            },
            required: ['verse']
          }
        }
      }
    end

    def self.ingest_response(verse:)
      if verse.split("//").length != 5
        {result: "FAILED: Limerick must have exactly 5 lines! Check you used '//' as the line separator, and try again."}
      else
        {result: "SUCCESS: Limerick checked and found to be perfect!"}
      end.to_json # Ollama expects a string message, always
    end
  end
end

class Ollama::LimerickFun < Ollama
  array_attr :tools

  # We're already handling the JSONification in ollama.rb
  append_lifecycle_hook :after_response do |response_hash| # {response: ...} - you can completely change what gets returned
    tool_calls = response_hash[:response].dig("message", "tool_calls") || []
    tool_responses = tool_calls.each_with_object([]) do |tool, outputs|
      begin
        klass = Class.fetch tool.dig("function", "name") # DANGER: A malicious AI could cause mischief
        next unless klass
        outputs << {
          role: :tool, name: klass.name,
          content: klass.ingest_response(**tool.dig("function", "arguments").transform_keys(&:to_sym))
        }
      rescue => e
        puts "Tool execution failed: #{e.message} - gonna ignore it and carry on"
      end
    end.compact
    unless tool_responses.empty?
      messages(tool_responses)
      messages([{role: :system, content: "Tools executed; if they failed, you may re-attempt them, otherwise please prepare a response for the user."}])
      response_hash[:response] = rerun! # DANGER: infinite loops are possible here
    end
  end

  def build_body
    super.merge(
      tools: get_method_or_attr(:tools)
    )
  end

  def override_tools
    [
      Tool::CheckLimerick.to_ollama_tool
    ]
  end
end

OllamaRunner.call(Ollama::LimerickFun)
