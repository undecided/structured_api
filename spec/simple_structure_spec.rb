# frozen_string_literal: true

class SimpleStructuredApi < StructuredApi::Endpoint
  verb :post
  url 'https://google.com/'
  body 'just keep swimming'
  params q: 'fish'
end

class SimpleExtendedApi < SimpleStructuredApi
  verb :get
  path '/about'
  body ''
  params q: 'cats'
end

class CustomizedApi < SimpleStructuredApi
  verb :get
  stringish_attr :id
  path :about
  body do
    @count ||= 0
    @count += 1
    "block ran #{@count} time(s)"
  end

  def override_path
    "#{get_attr(:path)}/#{get_attr(:id)}"
  end
end

class CustomizedExtendedApi < CustomizedApi
  body "Count never set"
  def override_body
    "#{get_attr(:body)} - count is #{@count.inspect}"
  end
end

describe SimpleStructuredApi do
  let(:uri) { 'https://google.com?q=fish' }

  let(:do_the_stubbing) do
    stub_request(:any, uri).to_return(body: 'dummy response')
  end

  context 'making api clients' do
    before do
      do_the_stubbing
    end

    context 'defaulting to the items given during setup' do
      subject { SimpleStructuredApi.new.run! }

      it 'passes the request to Typhoeus' do
        expect(subject).to eq 'dummy response'
        expect(WebMock).to have_requested(:post, uri).with(body: 'just keep swimming')
      end
    end

    context 'overriding the defaults manually' do
      let(:uri) { 'https://google.com?q=pizza' }
      subject { SimpleStructuredApi.new.verb(:get).params(q: :pizza).clear_body.run! }

      it 'passes the request to Typhoeus' do
        expect(subject).to eq 'dummy response'
        expect(WebMock).to have_requested(:get, uri).with { |req| req.body == '' }
      end
    end

    context 'overriding the defaults structurally' do
      let(:uri) { 'https://google.com/about?q=cats' }
      subject { SimpleExtendedApi.new.run! }

      it 'passes the request to Typhoeus' do
        expect(subject).to eq 'dummy response'
        expect(WebMock).to have_requested(:get, uri).with { |req| req.body == '' }
      end
    end

    context 'custom params' do
      let(:uri) { 'https://google.com/about/images?q=fish' }
      subject { CustomizedApi.new.id(:images).tap { |r| r.get_attr(:body) }.run! }

      it 'passes the request to Typhoeus' do
        expect(subject).to eq 'dummy response'
        expect(WebMock).to have_requested(:get, uri).with(body: "block ran 1 time(s)")
      end
    end

    context 'custom params with extended api' do
      let(:uri) { 'https://google.com/about/images?q=fish' }
      subject { CustomizedExtendedApi.new.id(:images).tap { |r| r.get_attr(:body) }.run! }

      it 'passes the request to Typhoeus' do
        expect(subject).to eq 'dummy response'
        expect(WebMock).to have_requested(:get, uri).with(body: "Count never set - count is nil")
      end
    end
  end
end
