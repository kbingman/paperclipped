class Asset < ActiveRecord::Base
  order_by 'title'
  
  has_attached_file :file,
                    :styles => { :square => ["42x42#", :png],
                                 :small  => "100x100>" }
                                 
  # belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
  # belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'
  
end
