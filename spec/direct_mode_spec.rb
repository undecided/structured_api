# frozen_string_literal: true

describe StructuredApi::Endpoint do
  let(:uri) { 'https://google.com' }
  let(:verb) { :get }
  let(:body) { nil }
  let(:params) { {} }

  let(:do_the_stubbing) do
    stub_request(:any, uri).to_return(body: 'dummy response')
  end

  context 'calling apis in direct mode' do
    before { do_the_stubbing }

    context 'with defaults on the non-required fields' do
      subject { described_class.new.url(uri).run! }

      it 'passes the request to Typhoeus' do
        expect(subject).to eq 'dummy response'
        expect(WebMock).to have_requested(verb, uri)
      end
    end

    context 'with explicitness' do
      subject { described_class.new.url(uri).verb(:get).params({}).headers({}).run! }

      it 'passes the request to Typhoeus' do
        expect(subject).to eq 'dummy response'
        expect(WebMock).to have_requested(verb, uri)
      end
    end
  end
end
