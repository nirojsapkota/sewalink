require 'rails_helper'

RSpec.describe ConversationPolicy, type: :policy do
  # Skip geocoding callback for Task model within this spec to prevent external HTTP calls
  before(:all) do
    Task.skip_callback(:validation, :after, :geocode, if: ->(obj){ obj.location.present? && obj.location_changed? })
  end

  after(:all) do
    Task.set_callback(:validation, :after, :geocode, if: ->(obj){ obj.location.present? && obj.location_changed? })
  end

  # Users can be reused across examples
  let(:poster) { create(:user, :poster) }
  let(:tasker_assigned) { create(:user, :tasker) }
  let(:tasker_bidder) { create(:user, :tasker) }
  let(:tasker_other) { create(:user, :tasker) }

  # --- Setup for Assigned Conversation (these are created per example due to 'let') ---
  let(:assigned_task) { create(:task, user: poster) }
  let(:assigned_bid) { create(:bid, task: assigned_task, user: tasker_assigned, status: :accepted) }
  let(:conversation_assigned) { assigned_bid.conversation }

  # --- Setup for Other Conversation (not assigned, these are created per example due to 'let') ---
  let(:other_task) { create(:task, user: poster) }
  let(:other_bid) { create(:bid, task: other_task, user: tasker_bidder, status: :pending) }
  let(:conversation_other) { other_bid.conversation }

  # --- Setup for Unrelated Conversation (for scope tests) ---
  let(:unrelated_poster) { create(:user, :poster) }
  let(:unrelated_tasker) { create(:user, :tasker) }
  let(:unrelated_task) { create(:task, user: unrelated_poster) }
  let(:unrelated_bid) { create(:bid, task: unrelated_task, user: unrelated_tasker) }
  let(:unrelated_conversation) { unrelated_bid.conversation }



  # Ensure tasks are in the correct state for each example
  before do
    # Link the assigned_bid to the assigned_task's accepted_bid association
    # The Task model uses `has_one :accepted_bid` and `has_one :tasker, through: :accepted_bid`
    assigned_task.update(accepted_bid: assigned_bid)
    assigned_task.assign! # Transition task to assigned state
  end

  subject { described_class }

  permissions :show? do
    it "grants access if user is the poster of the task" do
      expect(subject).to permit(poster, conversation_assigned)
      expect(subject).to permit(poster, conversation_other)
    end

    it "grants access if user is the tasker associated with the conversation's bid" do
      expect(subject).to permit(tasker_assigned, conversation_assigned)
      expect(subject).to permit(tasker_bidder, conversation_other)
    end

    it "denies access if user is another tasker" do
      expect(subject).not_to permit(tasker_other, conversation_assigned)
      expect(subject).not_to permit(tasker_other, conversation_other)
    end

    # Admin tests commented out as User model does not have an 'admin' role directly in active_role enum.
    # If admin functionality needs to be tested, a proper admin role/attribute needs to be defined in User model.
    # it "denies access if user is an admin" do
    #   expect(subject).not_to permit(admin, conversation_assigned)
    # end
  end

  permissions :index? do
    it "grants access to any user (scope handles visibility)" do
      expect(subject).to permit(poster, Conversation)
      expect(subject).to permit(tasker_assigned, Conversation)
      expect(subject).to permit(tasker_other, Conversation)
      # expect(subject).to permit(admin, Conversation) # Admin test commented out
    end
  end

  permissions :archive? do
    it "grants access if user is the poster and the bidder is NOT the assigned tasker" do
      expect(subject).to permit(poster, conversation_other) # tasker_bidder is not assigned
    end

    it "denies access if user is the poster and the bidder IS the assigned tasker" do
      expect(subject).not_to permit(poster, conversation_assigned) # tasker_assigned is assigned
    end

    it "denies access if user is not the poster" do
      expect(subject).not_to permit(tasker_assigned, conversation_other)
      expect(subject).not_to permit(tasker_bidder, conversation_other)
      # expect(subject).not_to permit(admin, conversation_other) # Admin test commented out
    end
  end

  describe "Scope" do
    before do
      @poster_user = create(:user, :poster)
      @tasker_one = create(:user, :tasker)
      @tasker_two = create(:user, :tasker)

      @task_one = create(:task, user: @poster_user)
      @task_two = create(:task, user: @poster_user)

      @bid_one = create(:bid, task: @task_one, user: @tasker_one)
      @bid_two = create(:bid, task: @task_two, user: @tasker_two)

      @conversation_one = @bid_one.conversation
      @conversation_two = @bid_two.conversation

      # For tasker scope test
      @tasker_current = create(:user, :tasker)
      @task_for_tasker = create(:task, user: @poster_user)
      @bid_for_tasker = create(:bid, task: @task_for_tasker, user: @tasker_current)
      @conversation_for_tasker = @bid_for_tasker.conversation

      @unrelated_user = create(:user, :tasker)
    end

    it "poster can see their own conversations" do
      expect(Pundit.policy_scope!(@poster_user, Conversation).to_a).to include(@conversation_one, @conversation_two)
    end

    it "tasker can see conversations where they are the bidder" do
      expect(Pundit.policy_scope!(@tasker_current, Conversation).to_a).to include(@conversation_for_tasker)
      expect(Pundit.policy_scope!(@tasker_current, Conversation).to_a).not_to include(@conversation_one, @conversation_two)
    end

    it "other users cannot see any conversations" do
      expect(Pundit.policy_scope!(@unrelated_user, Conversation).to_a).to be_empty
    end
  end
end
