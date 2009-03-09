class OldPageAttachment < ActiveRecord::Base
    def create_paperclipped_record
      options = {
        :asset_file_size => size,
        :asset_file_name => filename,
        :asset_content_type => content_type,
        :created_by_id => created_by
      }
      
      options[:title] = title if respond_to?(:title)
      options[:caption] = description if respond_to?(:description)
      
      a = Asset.new(options)
      a.save
      # re-attach the asset to it's page
      page = Page.find(page_id)
      page.assets << a
      a
    end          
end