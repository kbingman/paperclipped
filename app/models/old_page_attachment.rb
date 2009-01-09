class OldPageAttachment < ActiveRecord::Base
    def create_paperclipped_record
      a = Asset.new(
        :asset_file_size => size,
        :asset_file_name => filename,
        :asset_content_type => content_type,
        :created_by_id => created_by
        )
      a.save
      # re-attach the asset to it's page
      page = Page.find(page_id)
      page.assets << a
      a
    end          
end