class Asset < ActiveRecord::Base
  order_by 'title'
  
  has_attached_file :asset,
                    :styles => { :square => ["42x42#", :png],
                                 :normal => "640x640",
                                 :small  => "100x100>" }
                                 
  has_many :page_attachments, :dependent => :destroy
  has_many :pages, :through => :page_attachments
                                 
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  
<<<<<<< HEAD:app/models/asset.rb
=======
  validates_attachment_presence :asset, :message => "You must choose a file to upload!"

>>>>>>> 63ea031083ad57d8313947861b623201fb69012f:app/models/asset.rb
  before_save :assign_title
  
  def basename
    File.basename(asset_file_name, ".*") if asset_file_name
  end
  
  def extension
    asset_file_name.split('.').last.downcase
  end
  
  private
  
    def assign_title
      self.title = basename if title.blank?
    end
  
end
