class CreatePositions < ActiveRecord::Migration[8.1]
  def change
    create_table :positions do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.string :asset_name, null: false
      t.string :ticker
      t.string :benchmark_name, null: false
      t.string :asset_class, null: false
      t.decimal :ter_pct, precision: 5, scale: 2

      t.timestamps
    end
  end
end
