require_relative 'example_utilities'
DEBUG = false # gets a bit noisy, but tells you exactly what's going on

class Ollama < StructuredApi::Endpoint
  url ASK['What URL is your ollama at?', 'http://localhost:11434']
  path 'api/chat'
  verb :post
  headers({'Content-Type' => 'application/json'})
  stringish_attr :system_prompt, default: 'You are a helpful assistant'
  stringish_attr :prompt
  stringish_attr :model, default: 'gemma4:latest'
  array_attr :messages
  hash_attr :options

  system_prompt 'You are a helpful assistant' # note we override this in a subclass
  prompt ASK[%q{What's your question?}]
  options(
    num_ctx: 4096,
    think: false # This seems to get ignored on gemma4
  )

  append_lifecycle_hook :before_request do |_|
    puts "** Contacting Ollama..."
    body(build_body.to_json) # stringish_attrs replace
  end

  append_lifecycle_hook :after_response do |response_hash| # {response: ...} - you can completely change what gets returned
    response_hash[:response] = JSON.parse(response_hash[:response]).deep_symbolize_keys
    messages([response_hash.dig(:response, :message)]) # array_attrs append (with +) instead of replacing
  end

  def override_messages
    [
      {role: :system, content: get_method_or_attr(:system_prompt)},
      {role: :user, content: get_method_or_attr(:prompt)}
    ] + get_attr(:messages, [])
  end

  def build_body
    {
      messages: get_method_or_attr(:messages).map { |msg| msg.slice(:role, :name, :content, :tool_calls) }, # reduce tokens
      model: get_method_or_attr(:model),
      options: get_method_or_attr(:options),
      stream: false # TODO: How to stream true? Should we add streaming functionality?
    }
  end
  # # might need bearer key (how?)
end


class Ollama::SingSong < Ollama
  system_prompt do
    # Note: block-syntax only works with replacable fields (such as stringish_attr),
    # allows us to delay execution until needed, or never execute if it's replaced first
    ASK[
      %q{What's the agent's background?},
      'You are a helpful assistant, but you do like to respond with a short song.'
    ]
  end
end


class OllamaRunner
  def self.faint_puts(str)
    puts "\033[2m#{str}\033[0m"
  end

  def self.strong_puts(str)
    puts "\033[1;4m#{str}\033[0m"
  end

  def self.call(klass)
    # Note: this now returns a hash, thanks to the lifecycle hook
    runner = klass.new.debug!(DEBUG)
    response = runner.run! # we could just use this response, but we shan't for now

    runner.get_method_or_attr(:messages).each do |message|
      content, message[:content] = message[:content], "..." if message.key?(:content)
      thinking, message[:thinking] = message[:thinking], "..." if message.key?(:thinking)
      strong_puts message[:role].to_s.upcase
      faint_puts JSON.pretty_generate(message)
      faint_puts thinking if thinking
      puts content if content
      faint_puts "\n#{ "=" * 80 }\n"
    end
  rescue => e
    puts "Couldn't parse response: #{e.message}"
    puts response
  end
end


if __FILE__ == $0
  OllamaRunner.call(Ollama::SingSong)
end
