# frozen_string_literal: true

class SimpleLifecycleApi < StructuredApi::Endpoint
  verb :patch
  url 'https://google.com/'
  body 'just keep swimming'
  params q: 'fish'

  append_lifecycle_hook :before_request do
    body "Good fish swim"
  end

  append_lifecycle_hook :after_response do |r|
    r[:response] = r[:response].reverse
  end
end

class InheritedLifecycleApi < SimpleLifecycleApi
  append_lifecycle_hook :before_request do
    verb :post
  end

  prepend_lifecycle_hook :after_response do |r|
    r[:response] = "Surprise!".reverse
  end
end


describe StructuredApi::Endpoint do
  subject { SimpleLifecycleApi.new.run! }
  before { stub_request(:any, uri).to_return(body: 'dummy response') }
  let(:uri) { 'https://google.com/?q=fish' }

  describe 'simple lifecycle' do
    it 'calls the hooks' do
      expect(subject).to eq "dummy response".reverse
      expect(WebMock).to have_requested(:patch, uri).with(body: "Good fish swim")
    end
  end

  describe 'inherited lifecycle' do
    it 'calls the hooks' do
      expect(InheritedLifecycleApi.new.run!).to eq 'Surprise!'
      expect(WebMock).to have_requested(:post, uri).with(body: "Good fish swim")
    end
  end
end
