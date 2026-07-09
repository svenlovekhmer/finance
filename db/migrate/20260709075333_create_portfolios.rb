class CreatePortfolios < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolios do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :account_type, null: false
      t.date :opening_date

      t.timestamps
    end
  end
end
