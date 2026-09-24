class AllowNullLocationOnTasks < ActiveRecord::Migration[7.1]
  def change
    # Task#location is only required once a task leaves draft status
    # (see `validates :location, presence: true, unless: :draft?` in app/models/task.rb).
    # The voice assistant creates draft tasks with title/description only, so the DB
    # constraint must allow a nil location for drafts.
    change_column_null :tasks, :location, true
  end
end
