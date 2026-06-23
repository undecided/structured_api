require_relative 'ollama'
DEBUG = false # gets a bit noisy, but tells you exactly what's going on

module Tool
  def self.fetch(str)
    return unless str[/^Tool:/]
    str.split(/:+/).tap(&:shift).inject(self, &:const_get)
  end

  def self.execute_all(arr)
    Array(arr).each_with_object([]) do |tool, outputs|
      execute(tool[:function], outputs)
    end.compact
  end

  def self.execute(tool, outputs)
    fetch(tool[:name])&.tap do |klass|
      outputs << {
        role: :tool, name: klass.name,
        content: klass.new.ingest_response(**tool[:arguments])
      }
    end
  rescue => e
    outputs << { role: :tool, name: tool[:name], content: "FAILED: #{e.message}" }
  end

  def to_ollama_tool(description, **properties)
    {
      type: 'function',
      function: {
        name: self.class.name,
        description: description,
        parameters: {
          type: 'object',
          properties: properties,
          required: properties.keys
        }
      }
    }
  end

  class CheckLimerick
    include Tool

    def to_ollama_tool
      super(
        'If there is a limerick involved in your answer, ALWAYS use this tool before responding. VERY IMPORTANT.',
        verse: {
          type: 'string',
          description: 'The whole limerick, all 5 lines, line separator = //'
        }
      )
    end

    def ingest_response(verse:)
      if verse.split("//").length != 5
        "FAILED: Limerick must have exactly 5 lines! " \
        "Check you consistenly used double-forward-slash (//) as the line separator, and try again."
      else
        "SUCCESS: Limerick checked and found to be perfect!"
      end
    end
  end
end

class Ollama::LimerickFun < Ollama
  array_attr :tools

  tools(Tool::CheckLimerick)

  # We're already handling the JSONification and symbolization in ollama.rb
  append_lifecycle_hook :after_response do |response_hash| # {response: ...} - you can completely change what gets returned
    tool_responses = Tool.execute_all(response_hash[:response].dig(:message, :tool_calls))
    unless tool_responses.empty?
      messages(tool_responses)
      messages([{role: :system, content: "Tools executed; if they failed, you may re-attempt them, otherwise please prepare a response for the user."}])
      puts "** Re-running with tool responses"
      response_hash[:response] = rerun! # DANGER: infinite loops are possible here
    end
  end

  def build_body
    tools = get_method_or_attr(:tools).map { |t| t.new.to_ollama_tool }
    super.merge(tools: tools)
  end
end

OllamaRunner.call(Ollama::LimerickFun)
