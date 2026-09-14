require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:user) { create(:user) }
  let(:task) { create(:task) }
  let(:bid) { create(:bid, task: task, user: user) }
  let(:conversation) { bid.conversation } # Use the conversation created by the bid callback
  let(:message_with_pii) { create(:message, conversation: conversation, sender: user, content: "My number is 9841234567 and email is test@example.com") }

  describe '#filtered_content' do
    it 'always masks PII (used for public broadcasts and unauthorized viewers)' do
      expect(message_with_pii.filtered_content).to eq('My number is [CONTACT MASKED] and email is [CONTACT MASKED]')
    end
  end

  describe '#viewer_aware_content' do
    context 'when the task is not assigned' do
      it 'masks PII for a non-sender viewer' do
        other_user = create(:user)
        expect(message_with_pii.viewer_aware_content(other_user)).to eq('My number is [CONTACT MASKED] and email is [CONTACT MASKED]')
      end
    end

    context 'when the task is assigned and viewer is an authorized participant' do
      before { task.update!(status: :assigned) }

      it 'does not mask PII for the poster' do
        expect(message_with_pii.viewer_aware_content(task.user)).to eq(message_with_pii.content)
      end
    end

    it 'always returns unmasked content for the sender' do
      expect(message_with_pii.viewer_aware_content(user)).to eq(message_with_pii.content)
    end
  end
end
