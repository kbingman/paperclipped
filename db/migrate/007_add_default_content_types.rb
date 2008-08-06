class AddDefaultContentTypes < ActiveRecord::Migration
  
  class Config < ActiveRecord::Base; end
  
  def self.up
    Radiant::Config['assets.content_types'] =  "image/jpeg, image/pjpeg, image/gif, image/png, image/x-png, image/jpg, video/x-m4v, video/quicktime, application/x-shockwave-flash, audio/mpeg"
    Radiant::Config['assets.max_asset_size'] = 2
    puts "-- Setting default content types in Radiant::Config"
  end

  def self.down

  end
  
end