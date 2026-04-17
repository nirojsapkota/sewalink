require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:user) { create(:user) }
  let(:task) { create(:task) }
  let(:bid) { create(:bid, task: task, user: user) }
  let(:conversation) { bid.conversation } # Use the conversation created by the bid callback
  let(:message_with_pii) { create(:message, conversation: conversation, sender: user, content: "My number is 9841234567 and email is test@example.com") }

  describe '#filtered_content' do
    context 'when the task is not assigned' do
      it 'masks PII' do
        expect(message_with_pii.filtered_content).to eq('My number is [CONTACT MASKED] and email is [CONTACT MASKED]')
      end
    end

    context 'when the task is assigned' do
      before do
        allow(task).to receive(:assigned?).and_return(true)
      end

      it 'does not mask PII' do
        expect(message_with_pii.filtered_content).to eq(message_with_pii.content)
      end
    end
  end
end
