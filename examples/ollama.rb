require_relative 'example_utilities'
DEBUG = false # gets a bit noisy, but tells you exactly what's going on

class Ollama < StructuredApi::Endpoint
  url ASK['What URL is your ollama at?', 'http://localhost:11434'] # happens immediately, without waiting to run
  path 'api/chat'
  verb :post
  headers({'Content-Type' => 'application/json'}) # these merge, so you can add more or replace in a subclass

  # You can define your own attributes (like path, verb etc)
  # and you decide how they are used.
  stringish_attr :system_prompt, default: 'You are a helpful assistant'
  stringish_attr :prompt
  stringish_attr :model, default: 'gemma4:latest'
  array_attr :messages
  hash_attr :options

  prompt { ASK[%q{What's your question?}] } # The block delays the action until the attribute is accessed

  options(
    num_ctx: 4096,
    think: false # This seems to get ignored on gemma4
  )

  append_lifecycle_hook :before_request do |_|
    body(build_body.to_json) # stringish_attrs replace. Note that block-attributes such as prompt {...} run now
    puts "** Contacting Ollama..."
  end

  append_lifecycle_hook :after_response do |response_hash| # {response: ...} - you can completely change what gets returned
    response_hash[:response] = JSON.parse(response_hash[:response]).deep_symbolize_keys
    messages([response_hash.dig(:response, :message)]) # array_attrs append (with +) instead of replacing
  end

  def override_messages
    [
      {role: :system, content: get_method_or_attr(:system_prompt)},
      {role: :user, content: get_method_or_attr(:prompt)}
    ] + get_attr(:messages, []) # if we did get_method_or_attr here, we'd call override_messages til stack overflow
  end

  def build_body
    {
      messages: messages_without_thinking,
      model: get_method_or_attr(:model),
      options: get_method_or_attr(:options),
      stream: false # TODO: How to stream true? Should we add streaming functionality?
    }
  end

  def messages_without_thinking
    get_method_or_attr(:messages).map do |msg|
      msg.slice(:role, :name, :content, :tool_calls)
    end
  end
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

  def self.display_full_message(message)
    content, message[:content] = message[:content], "..." if message.key?(:content)
    thinking, message[:thinking] = message[:thinking], "..." if message.key?(:thinking)
    strong_puts message[:role].to_s.upcase
    faint_puts JSON.pretty_generate(message)
    faint_puts thinking if thinking
    faint_puts "\n#{ "-" * 80 }\n"
    puts content if content
    faint_puts "\n#{ "=" * 80 }\n"
  end

  def self.call(klass)
    # Note: this now returns a hash, thanks to the lifecycle hook
    runner = klass.new.debug!(DEBUG)
    response = runner.run! # we could just use this response, but we shan't for now

    runner.get_method_or_attr(:messages).each do |message|
      display_full_message(message)
    end

    runner.prompt { ASK[%q{What are your thoughts on this?}] }.rerun!
    runner.get_method_or_attr(:messages)
      .last
      .tap { |message| display_full_message(message) }
  rescue => e
    puts "Couldn't parse response: #{e.message}"
    puts response
  end
end


if __FILE__ == $0
  OllamaRunner.call(Ollama::SingSong)
end
