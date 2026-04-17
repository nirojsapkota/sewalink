require 'rails_helper'

RSpec.describe Review, type: :model do
  let(:task) { create(:task, status: :completed, completed_at: 1.day.ago) }
  let(:reviewer) { create(:user) }
  let(:reviewee) { create(:user) }

  describe 'associations' do
    it { should belong_to(:task) }
    it { should belong_to(:reviewer).class_name('User') }
    it { should belong_to(:reviewee).class_name('User') }
  end

  describe 'validations' do
    it { should validate_presence_of(:rating) }
    it { should validate_inclusion_of(:rating).in_array((1..5).to_a) }

    context 'when review is public' do
      subject { build(:review, task: task, reviewer: reviewer, reviewee: reviewee, is_public: true, comment: nil) }
      it { should validate_presence_of(:comment) }
    end

    context 'when review is not public' do
      subject { build(:review, task: task, reviewer: reviewer, reviewee: reviewee, is_public: false, comment: nil) }
      it { should_not validate_presence_of(:comment) }
    end
  end

  describe 'blind logic (`visible?` and `scope :visible`)' do
    let(:task_old_completed) { create(:task, status: :completed, completed_at: 15.days.ago) }
    let(:review1) { create(:review, task: task, reviewer: reviewer, reviewee: reviewee, is_public: true) }
    let(:review2) { create(:review, task: task, reviewer: reviewee, reviewee: reviewer, is_public: true) }
    let(:review_old) { create(:review, task: task_old_completed, reviewer: reviewer, reviewee: reviewee, is_public: true) }

    context 'when only one review exists for a task' do
      it 'is not visible' do
        expect(review1).to_not be_visible
      end

      it 'is not included in the visible scope' do
        expect(Review.visible).to_not include(review1)
      end
    end

    context 'when both reviews exist for a task' do
      before { review1; review2 } # Create both reviews
      it 'is visible' do
        expect(review1).to be_visible
        expect(review2).to be_visible
      end

      it 'is included in the visible scope' do
        expect(Review.visible).to include(review1, review2)
      end
    end

    context 'when task was completed more than 14 days ago' do
      it 'is visible regardless of counterpart review' do
        expect(review_old).to be_visible
      end

      it 'is included in the visible scope' do
        expect(Review.visible).to include(review_old)
      end
    end

    context 'when task was completed less than 14 days ago and only one review' do
      it 'is not visible' do
        expect(review1).to_not be_visible
      end

      it 'is not included in the visible scope' do
        expect(Review.visible).to_not include(review1)
      end
    end
  end
end
