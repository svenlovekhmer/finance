class CreateMonthlyEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :monthly_entries do |t|
      t.references :position, null: false, foreign_key: true
      t.date :month, null: false
      t.decimal :benchmark_variation_pct, precision: 8, scale: 4, null: false
      t.decimal :actual_variation_pct, precision: 8, scale: 4
      t.decimal :contribution_amount, precision: 14, scale: 2
      t.decimal :planned_contribution_amount, precision: 14, scale: 2, null: false
      t.decimal :cumulative_contribution, precision: 14, scale: 2
      t.decimal :cumulative_capital, precision: 14, scale: 2
      t.decimal :delta, precision: 14, scale: 2
      t.text :notes

      t.timestamps
    end

    add_index :monthly_entries, [ :position_id, :month ], unique: true
  end
end
