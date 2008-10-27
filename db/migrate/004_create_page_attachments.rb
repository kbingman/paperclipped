class CreatePageAttachments < ActiveRecord::Migration
  def self.up
    create_table :page_attachments do |t|
      t.column :asset_id,     :integer
      t.column :page_id,      :integer
      t.column :position,    :integer
    end
    
  end
  
  def self.down
    drop_table :page_attachments
  end
end