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
        # Set attributes required for geofence and photo guards
        task.latitude = 27.7172
        task.longitude = 85.3240
        task.on_site = true
        task.current_lat = 27.7172
        task.current_lng = 85.3240
        task.completion_photo.attach(io: File.open(Rails.root.join('public/apple-touch-icon.png')), filename: 'test.png', content_type: 'image/png')
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

  describe 'geofencing' do
    let(:task) { create(:task, location: "Kathmandu", latitude: 27.7172, longitude: 85.3240, on_site: true) }

    describe '#within_geofence?' do
      it 'returns true if within 200m' do
        task.current_lat = 27.7173
        task.current_lng = 85.3241
        expect(task.within_geofence?).to be true
      end

      it 'returns false if outside 200m' do
        task.current_lat = 27.8
        task.current_lng = 85.4
        expect(task.within_geofence?).to be false
      end

      it 'returns true if not on_site' do
        task.update!(on_site: false)
        task.current_lat = 27.8
        task.current_lng = 85.4
        expect(task.within_geofence?).to be true
      end
    end

    describe '#check_in!' do
      before { task.update!(status: :assigned) }

      it 'transitions to in_progress if within geofence' do
        task.check_in!(27.7172, 85.3240)
        expect(task.status).to eq('in_progress')
      end

      it 'does not transition if outside geofence' do
        task.check_in!(27.8, 85.4)
        expect(task.status).to eq('assigned')
      end
    end

    describe 'completion requirements' do
      let(:task) { create(:task, status: :in_progress, latitude: 27.7172, longitude: 85.3240, on_site: true) }

      it 'blocks completion if photo is missing' do
        task.current_lat = 27.7172
        task.current_lng = 85.3240
        expect { task.complete! }.to raise_error(AASM::InvalidTransition)
      end

      it 'blocks completion if outside geofence' do
        task.completion_photo.attach(io: File.open(Rails.root.join('public/apple-touch-icon.png')), filename: 'test.png', content_type: 'image/png')
        task.current_lat = 27.8
        task.current_lng = 85.4
        expect { task.complete! }.to raise_error(AASM::InvalidTransition)
      end

      it 'allows completion if within geofence and photo attached' do
        task.completion_photo.attach(io: File.open(Rails.root.join('public/apple-touch-icon.png')), filename: 'test.png', content_type: 'image/png')
        task.current_lat = 27.7172
        task.current_lng = 85.3240
        expect { task.complete! }.not_to raise_error
        expect(task.status).to eq('completed')
      end
    end
  end
end
