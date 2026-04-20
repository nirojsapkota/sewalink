require 'rails_helper'

RSpec.describe Gemini::LiveService do
  let(:on_message) { double('on_message') }
  subject { described_class.new(on_message: on_message) }

  it 'initializes with the correct URL' do
    # API key is missing in test env, so it will be empty
    expect(subject.instance_variable_get(:@url)).to include("wss://generativelanguage.googleapis.com")
  end

  it 'responds to connect' do
    expect(subject).to respond_to(:connect)
  end

  it 'responds to send_audio' do
    expect(subject).to respond_to(:send_audio)
  end
end
