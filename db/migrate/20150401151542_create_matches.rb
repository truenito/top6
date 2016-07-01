class CreateMatches < ActiveRecord::Migration
  def change
    create_table :matches do |t|
      t.integer :battlenet_id
      t.string :password
      t.string :name
      t.string :status, default: "waiting"
      t.integer :creator_id
      t.boolean :winner_team

      t.timestamps null: false
    end
  end
end
