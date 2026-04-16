require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'status transitions' do
    let(:task) { create(:task, status: :draft) }

    it 'starts as draft' do
      expect(task.status).to eq('draft')
    end

    describe '#toggle_draft!' do
      it 'toggles from draft to open' do
        task.toggle_draft!
        expect(task.status).to eq('open')
      end

      it 'toggles from open to draft' do
        task.status = :open
        task.save!
        task.toggle_draft!
        expect(task.status).to eq('draft')
      end

      it 'raises error if in other states' do
        task.status = :in_progress
        task.save!
        expect { task.toggle_draft! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe '#request_payment!' do
      it 'transitions from in_progress to pending_payment' do
        task.status = :in_progress
        task.save!
        task.request_payment!
        expect(task.status).to eq('pending_payment')
      end
    end

    describe '#release_payment!' do
      it 'transitions from pending_payment to completed' do
        task.status = :pending_payment
        task.save!
        task.release_payment!
        expect(task.status).to eq('completed')
      end
    end

    describe '#raise_dispute!' do
      it 'transitions from in_progress to dispute' do
        task.status = :in_progress
        task.save!
        task.raise_dispute!
        expect(task.status).to eq('dispute')
      end

      it 'transitions from open to dispute' do
        task.status = :open
        task.save!
        task.raise_dispute!
        expect(task.status).to eq('dispute')
      end
    end
  end
end
