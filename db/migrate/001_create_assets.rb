class CreateAssets < ActiveRecord::Migration
  def self.up
    create_table :assets do |t|
      t.column :title,              :string
      t.column :caption,            :string
    end
    
  end
  
  def self.down
    drop_table :assets
  end
end