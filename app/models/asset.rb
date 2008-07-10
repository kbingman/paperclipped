class Asset < ActiveRecord::Base
  order_by 'title'
  
  additional_thumbnails = Radiant::Config["assets.additional_thumbnails"].split(',').collect{|s| s.split('=')}.inject({}) {|ha, (k, v)| ha[k.to_sym] = v; ha}
  additional_thumbnails[:icon] = ['42x42#', :png]
  additional_thumbnails[:thumbnail] = '100x100>'
  
  has_attached_file :asset,
                    :styles => additional_thumbnails,
                    :whiny_thumbnails => false,
                    :url => "/:class/:id/:basename:no_original_style.:extension",
                    :path => ":rails_root/public/:class/:id/:basename:no_original_style.:extension"
                                 
  has_many :page_attachments, :dependent => :destroy
  has_many :pages, :through => :page_attachments
                                 
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  
  validates_attachment_presence :asset, :message => "You must choose a file to upload!"

  before_save :assign_title
  
  
  def basename
    File.basename(asset_file_name, ".*") if asset_file_name
  end
  
  def extension
    asset_file_name.split('.').last.downcase if asset_file_name
  end
  
  private
  
    def assign_title
      self.title = basename if title.blank?
    end
    
    def additional_thumbnails
      Radiant::Config["assets.additional_thumbnails"].split(',').collect{|s| s.split('=')}.inject({}) {|ha, (k.to_sym, v)| ha[k] = v; ha}
    end
end
