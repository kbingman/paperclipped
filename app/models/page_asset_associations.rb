module PageAssetAssociations
  def self.included(base)
    base.class_eval {
      has_many :attachments, :order => :position
      has_many :assets, :through => :attachments
    }
  end
  
end