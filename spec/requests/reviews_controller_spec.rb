require 'rails_helper'

RSpec.describe "ReviewsController", type: :request do
  let(:category) { create(:category) }
  let(:poster) { create(:user, active_role: :poster, onboarded: true) }
  let(:tasker) { create(:user, active_role: :tasker, onboarded: true) }
  let(:task) { create(:task, user: poster, category: category, budget: Money.new(1000_00, "NPR"), payment_type: :cash, status: :completed, completed_at: 1.day.ago) }
  let!(:bid) { create(:bid, task: task, user: tasker, amount: Money.new(1000_00, "NPR"), status: :accepted, message: "I can do this") }

  describe "POST /tasks/:task_id/reviews" do
    context "as the poster" do
      before { sign_in poster }

      it "creates a review with the tasker as reviewee" do
        expect {
          post task_reviews_path(task), params: { review: { rating: 5, comment: "Great job", is_public: true } }
        }.to change(Review, :count).by(1)

        review = Review.last
        expect(review.reviewer).to eq(poster)
        expect(review.reviewee).to eq(tasker)
        expect(response).to redirect_to(task_path(task))
      end

      it "prevents submitting a second review for the same task" do
        create(:review, task: task, reviewer: poster, reviewee: tasker)

        expect {
          post task_reviews_path(task), params: { review: { rating: 5, comment: "Again", is_public: true } }
        }.not_to change(Review, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context "as the tasker" do
      before { sign_in tasker }

      it "creates a review with the poster as reviewee" do
        expect {
          post task_reviews_path(task), params: { review: { rating: 4, comment: "Good client", is_public: true } }
        }.to change(Review, :count).by(1)

        review = Review.last
        expect(review.reviewer).to eq(tasker)
        expect(review.reviewee).to eq(poster)
      end
    end

    context "as an unrelated user" do
      it "denies the request" do
        sign_in create(:user, active_role: :poster, onboarded: true)

        expect {
          post task_reviews_path(task), params: { review: { rating: 5, comment: "Nice", is_public: true } }
        }.not_to change(Review, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the task is not yet completed" do
      let(:task) { create(:task, user: poster, category: category, budget: Money.new(1000_00, "NPR"), payment_type: :cash, status: :in_progress) }

      it "denies the request" do
        sign_in poster

        expect {
          post task_reviews_path(task), params: { review: { rating: 5, comment: "Too soon", is_public: true } }
        }.not_to change(Review, :count)

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
