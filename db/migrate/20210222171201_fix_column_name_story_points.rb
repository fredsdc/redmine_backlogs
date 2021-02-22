class FixColumnNameStoryPoints < ActiveRecord::Migration[5.2]
  def change
    rename_column :issues, :story_points, :rb_story_points
  end
end
