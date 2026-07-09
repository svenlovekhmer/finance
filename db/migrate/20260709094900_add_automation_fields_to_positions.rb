class AddAutomationFieldsToPositions < ActiveRecord::Migration[8.1]
  def change
    add_column :positions, :data_source, :string, null: false, default: "manual"
    add_column :positions, :auto_dca, :boolean, null: false, default: false
  end
end
