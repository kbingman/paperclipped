require 'mime_type_ext'

class Asset < ActiveRecord::Base
  Mime::Type.register 'image/png', :image, %w[image/png image/x-png image/jpeg image/pjpeg image/jpg image/gif]
  Mime::Type.register 'video/mpeg', :video, %w[video/mpeg video/mp4 video/ogg video/quicktime video/x-ms-wmv video/x-flv]
  Mime::Type.register 'audio/mpeg', :audio, %w[audio/mpeg audio/ogg application/ogg audio/x-ms-wma audio/vnd.rn-realaudio audio/x-wav]
  Mime::Type.register 'application/x-shockwave-flash', :swf
  Mime::Type.register 'application/pdf', :pdf
  # A “movie” can be a swf or a video file (retained for back-compat)
  Mime::Type.register Mime::SWF.to_s, :movie, Mime::VIDEO.all_types
  
  def self.known_types
    [:image, :video, :audio, :swf, :pdf, :movie]
  end  

  class << self
    Asset.known_types.each do |type|
      define_method "#{type}?" do |asset_content_type|
        Mime::Type.lookup_by_extension(type.to_s) == asset_content_type.to_s
      end

      define_method "#{type}_condition" do
        types = Mime::Type.lookup_by_extension(type.to_s).all_types
        # use #send due to a ruby 1.8.2 issue
        send(:sanitize_sql, ['asset_content_type IN (?)', types])
      end
    end
    
    def other?(asset_content_type)
      !known_types.any? { |type| send("#{type}?", asset_content_type) }
    end
    
    def other_condition
      excluded_types = Mime::IMAGE.all_types + Mime::AUDIO.all_types + Mime::MOVIE.all_types
      # use #send due to a ruby 1.8.2 issue
      send(:sanitize_sql, ['asset_content_type NOT IN (?)', excluded_types])
    end    
  end
  (known_types + [:other]).each do |type|
    named_scope type.to_s.pluralize.intern, :conditions => self.send("#{type}_condition".intern)
  end
  
  class << self
    def search(search, filter, page)
      unless search.blank?

        search_cond_sql = []
        search_cond_sql << 'LOWER(asset_file_name) LIKE (:term)'
        search_cond_sql << 'LOWER(title) LIKE (:term)'
        search_cond_sql << 'LOWER(caption) LIKE (:term)'

        cond_sql = search_cond_sql.join(" or ")

        @conditions = [cond_sql, {:term => "%#{search.downcase}%" }]
      else
        @conditions = []
      end

      options = { :conditions => @conditions,
                  :order => 'created_at DESC',
                  :page => page,
                  :per_page => 10 }

      @file_types = filter.blank? ? [] : filter.keys
      if not @file_types.empty?
        options[:total_entries] = count_by_conditions
        Asset.paginate_by_content_types(@file_types, :all, options )
      else
        Asset.paginate(:all, options)
      end
    end

    def find_all_by_content_types(types, *args)
      with_content_types(types) { find *args }
    end

    def with_content_types(types, &block)
      with_scope(:find => { :conditions => types_to_conditions(types).join(' OR ') }, &block)
    end
    
    def count_by_conditions
      type_conditions = @file_types.blank? ? nil : Asset.types_to_conditions(@file_types.dup).join(" OR ")
      @count_by_conditions ||= @conditions.empty? ? Asset.count(:all, :conditions => type_conditions) : Asset.count(:all, :conditions => @conditions)
    end
    
    def types_to_conditions(types)
      types.collect! { |t| '(' + send("#{t}_condition") + ')' }
    end
    
    def thumbnail_sizes
      if Radiant::Config.table_exists? && Radiant::Config["assets.additional_thumbnails"]
        thumbnails = additional_thumbnails
      else
        thumbnails = {}
      end
      thumbnails[:icon] = ['42x42#', :png]
      thumbnails[:thumbnail] = ['100x100>', :png]
      thumbnails
    end

    def thumbnail_names
      thumbnail_sizes.keys
    end
    
    private
      def additional_thumbnails
        Radiant::Config["assets.additional_thumbnails"].gsub(' ','').split(',').collect{|s| s.split('=')}.inject({}) {|ha, (k, v)| ha[k.to_sym] = v; ha}
      end
  end
  
  # order_by 'title'
    
  has_attached_file :asset,
                    :styles => thumbnail_sizes,
                    :whiny_thumbnails => false,
                    :storage => Radiant::Config["assets.storage"] == "s3" ? :s3 : :filesystem, 
                    :s3_credentials => {
                      :access_key_id => Radiant::Config["assets.s3.key"],
                      :secret_access_key => Radiant::Config["assets.s3.secret"]
                    },
                    :bucket => Radiant::Config["assets.s3.bucket"],
                    :url => Radiant::Config["assets.url"] ? Radiant::Config["assets.url"] : "/:class/:id/:basename:no_original_style.:extension", 
                    :path => Radiant::Config["assets.path"] ? Radiant::Config["assets.path"] : ":rails_root/public/:class/:id/:basename:no_original_style.:extension"
                                 
  has_many :page_attachments, :dependent => :destroy
  has_many :pages, :through => :page_attachments
                                 
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  
  validates_attachment_presence :asset, :message => "You must choose a file to upload!"
  validates_attachment_content_type :asset, 
    :content_type => Radiant::Config["assets.content_types"].gsub(' ','').split(',') if Radiant::Config.table_exists? && Radiant::Config["assets.content_types"] && Radiant::Config["assets.skip_filetype_validation"] == nil
  validates_attachment_size :asset, 
    :less_than => Radiant::Config["assets.max_asset_size"].to_i.megabytes if Radiant::Config.table_exists? && Radiant::Config["assets.max_asset_size"]
    
  before_save :assign_title
    
  def thumbnail(size='original')
    return asset.url if size == 'original'
    case 
      when self.pdf?   : "/images/assets/pdf_#{size.to_s}.png"
      when self.movie? : "/images/assets/movie_#{size.to_s}.png"
      when self.video? : "/images/assets/movie_#{size.to_s}.png"
      when self.swf? : "/images/assets/movie_#{size.to_s}.png" #TODO: special icon for swf-files
      when self.audio? : "/images/assets/audio_#{size.to_s}.png"
      when self.other? : "/images/assets/doc_#{size.to_s}.png"
    else
      self.asset.url(size.to_sym)
    end
  end
  
  def generate_style(name, args={}) 
    size = args[:size] 
    format = args[:format] || :jpg
    asset = self.asset
    unless asset.exists?(name.to_sym)
      self.asset.styles[name.to_sym] = { :geometry => size, :format => format, :whiny => true, :convert_options => "", :processors => [:thumbnail] } 
      self.asset.reprocess!
    end
  end
  
  def basename
    File.basename(asset_file_name, ".*") if asset_file_name
  end
  
  def extension
    asset_file_name.split('.').last.downcase if asset_file_name
  end
  
  def dimensions(size='original')
    @dimensions ||= {}
    @dimensions[size] ||= image? && begin
      image_file = "#{RAILS_ROOT}/public#{self.thumbnail(size)}"
      image_size = ImageSize.new(open(image_file).read)
      [image_size.get_width, image_size.get_height]
    rescue
      [0, 0]
    end
  end
  
  def width(size='original')
    image? && self.dimensions(size)[0]
  end
  
  def height(size='original')
    image? && self.dimensions(size)[1]
  end

  #delegating methods like image? to class
  (known_types+[:other]).each do |type|
    define_method("#{type}?") { self.class.send("#{type}?", asset_content_type) }
  end
  
  private
  
    def assign_title
      self.title = basename if title.blank?
    end
    
end
