module PaperclippedInterface
  def self.included(base)
    base.class_eval {
      before_filter :add_paperclipped_styles
      include InstanceMethods
    }
  end

  module InstanceMethods
    def add_paperclipped_styles
      include_javascript 'admin/assets.js'
      include_javascript 'admin/dragdrop.js'
      include_stylesheet 'admin/assets'
    end
  end
end