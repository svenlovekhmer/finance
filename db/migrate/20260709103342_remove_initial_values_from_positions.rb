class RemoveInitialValuesFromPositions < ActiveRecord::Migration[8.1]
  def change
    remove_column :positions, :initial_capital, :decimal, precision: 14, scale: 2, default: "0.0", null: false
    remove_column :positions, :initial_contribution, :decimal, precision: 14, scale: 2, default: "0.0", null: false
  end
end
