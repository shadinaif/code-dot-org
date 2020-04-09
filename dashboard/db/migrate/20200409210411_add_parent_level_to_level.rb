class AddParentLevelToLevel < ActiveRecord::Migration[5.0]
  def change
    add_column :levels, :parent_level_id, :integer
    add_index :levels, :parent_level_id
  end
end
