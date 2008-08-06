class Asset < ActiveRecord::Base
  # used for extra mime types that dont follow the convention
  @@content_types = ['image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png', 'image/jpg']
  @@extra_content_types = { :audio => ['application/ogg'], :movie => ['application/x-shockwave-flash'], :pdf => ['application/pdf'] }.freeze
  cattr_reader :extra_content_types, :content_types

  # use #send due to a ruby 1.8.2 issue
  @@movie_condition = send(:sanitize_sql, ['content_type LIKE ? OR content_type IN (?)', 'video%', extra_content_types[:movie]]).freeze
  @@audio_condition = send(:sanitize_sql, ['content_type LIKE ? OR content_type IN (?)', 'audio%', extra_content_types[:audio]]).freeze
  cattr_reader *%w(movie audio image other).collect! { |t| "#{t}_condition".to_sym }
  
  
  class << self
    def image?(asset_content_type)
      content_types.include?(asset_content_type)
    end
    
    def movie?(asset_content_type)
      asset_content_type.to_s =~ /^video/ || extra_content_types[:movie].include?(asset_content_type)
    end
        
    def audio?(asset_content_type)
      asset_content_type.to_s =~ /^audio/ || extra_content_types[:audio].include?(asset_content_type)
    end
    
    def other?(asset_content_type)
      ![:image, :movie, :audio].any? { |a| send("#{a}?", asset_content_type) }
    end

    def pdf?(asset_content_type)
      extra_content_types[:pdf].include? asset_content_type
    end

    def find_all_by_asset_content_types(types, *args)
      with_asset_content_types(types) { find *args }
    end

    def with_asset_content_types(types, &block)
      with_scope(:find => { :conditions => types_to_conditions(types).join(' OR ') }, &block)
    end

    def types_to_conditions(types)
      types.collect! { |t| '(' + send("#{t}_condition") + ')' }
    end
  end
  
  
  order_by 'title'
  
  if Radiant::Config["assets.additional_thumbnails"]
    thumbnails = Radiant::Config["assets.additional_thumbnails"].split(', ').collect{|s| s.split('=')}.inject({}) {|ha, (k, v)| ha[k.to_sym] = v; ha}
  else
    thumbnails = {}
  end
  thumbnails[:icon] = ['42x42#', :png]
  thumbnails[:thumbnail] = '100x100>'
  
  has_attached_file :asset,
                    :styles => thumbnails,
                    :whiny_thumbnails => false,
                    :url => "/:class/:id/:basename:no_original_style.:extension",
                    :path => ":rails_root/public/:class/:id/:basename:no_original_style.:extension"
                                 
  has_many :page_attachments, :dependent => :destroy
  has_many :pages, :through => :page_attachments
                                 
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  
  validates_attachment_presence :asset, :message => "You must choose a file to upload!"
  validates_attachment_content_type :asset, 
    :content_type => Radiant::Config["assets.content_types"].split(', ') if Radiant::Config["assets.content_types"]
  validates_attachment_size :asset, 
    :less_than => Radiant::Config["assets.max_asset_size"].to_i.megabytes if Radiant::Config["assets.max_asset_size"]
    
    
  before_save :assign_title
  
  
  
  def thumbnail(size = nil)
    if size == 'original' or size.nil?
      self.asset.url
    else
      if self.pdf?
        "/images/assets/pdf_#{size.to_s}.png"
      elsif self.movie?
        "/images/assets/movie_#{size.to_s}.png"
      elsif self.audio?
        "/images/assets/audio_#{size.to_s}.png"
      elsif self.other?
        "/images/assets/doc_#{size.to_s}.png"
      else
        self.asset.url(size)
      end
    end
  end
  
  def basename
    File.basename(asset_file_name, ".*") if asset_file_name
  end
  
  def extension
    asset_file_name.split('.').last.downcase if asset_file_name
  end
  
  [:movie, :audio, :image, :other, :pdf].each do |content|
    define_method("#{content}?") { self.class.send("#{content}?", asset_content_type) }
  end
  
  
  private
  
    def assign_title
      self.title = basename if title.blank?
    end
    
    def additional_thumbnails
      Radiant::Config["assets.additional_thumbnails"].split(',').collect{|s| s.split('=')}.inject({}) {|ha, (k.to_sym, v)| ha[k] = v; ha}
    end
end
