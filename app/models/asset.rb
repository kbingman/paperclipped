class Asset < ActiveRecord::Base
  order_by 'title'
  
  has_attached_file :asset,
                    :styles => { :square => ["42x42#", :png],
                                 :normal => "640x640",
                                 :small  => "100x100>" }
                                 
  has_many :attachments
  has_many :pages, :through => :attachments
                                 
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  
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
