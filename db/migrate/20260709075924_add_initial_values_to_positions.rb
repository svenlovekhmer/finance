class AddInitialValuesToPositions < ActiveRecord::Migration[8.1]
  def change
    add_column :positions, :initial_capital, :decimal, precision: 14, scale: 2, null: false, default: 0
    add_column :positions, :initial_contribution, :decimal, precision: 14, scale: 2, null: false, default: 0
  end
end
