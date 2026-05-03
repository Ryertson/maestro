class RenameGradesToLevels < ActiveRecord::Migration[8.1]
  def change
    rename_table :grades, :levels
  end
end
