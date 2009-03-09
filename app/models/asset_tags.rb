module AssetTags
  include Radiant::Taggable
  
  class TagError < StandardError; end
  
  desc %{
    The namespace for referencing images and assets.  You may specify the 'title'
    attribute on this tag for all contained tags to refer to that asset.  
    
    *Usage:* 
    <pre><code><r:assets [title="asset_title"]>...</r:assets></code></pre>
  }    
  tag 'assets' do |tag|
    tag.locals.asset = Asset.find_by_title(tag.attr['title']) || Asset.find(tag.attr['id']) unless tag.attr.empty?
    tag.expand
  end
  
  desc %{
    Cycles through all assets attached to the current page.  
    This tag does not require the title atttribute, nor do any of its children.
    Use the `limit' attribute to render a specific number of assets.
    
    *Usage:* 
    <pre><code><r:assets:each [limit="5"]>...</r:assets:each></code></pre>
  }    
  tag 'assets:each' do |tag|
    options = tag.attr.dup
    result = []
    limit = options['limit'] ? options.delete('limit') : nil
    offset = options['offset'] ? options.delete('offset') : :nil
    assets = tag.locals.page.assets.find(:all, :limit => limit, :offset => offset, :order => 'page_attachments.position')
    assets.each do |asset|
      tag.locals.asset = asset
      result << tag.expand
    end
    result
  end
  
  desc %{
    References the first asset attached to the current page.  
    
    *Usage:* 
    <pre><code><r:assets:first>...</r:assets:first></code></pre>
  }
  tag 'assets:first' do |tag|
     attachments = tag.locals.page.page_attachments
     if first = attachments.first
       tag.locals.asset = first.asset
       tag.expand
     end
   end
   
   tag 'assets:if_first' do |tag|
     attachments = tag.locals.assets
     asset = tag.locals.asset
     if asset == attachments.first.asset
       tag.expand
     end
   end
   
   desc %{
     Renders the contained elements only if the current contextual page has one or
     more assets. The @min_count@ attribute specifies the minimum number of required
     assets.

     *Usage:*
     <pre><code><r:if_assets [min_count="n"]>...</r:if_assets></code></pre>
   }
   tag 'if_assets' do |tag|
     count = tag.attr['min_count'] && tag.attr['min_count'].to_i || 0
     assets = tag.locals.page.assets.count
     tag.expand if assets >= count
   end
   
   desc %{The opposite of @<r:if_attachments/>@.}
   tag 'unless_assets' do |tag|
     count = tag.attr['min_count'] && tag.attr['min_count'].to_i || 0
     assets = tag.locals.page.assets.count
     tag.expand unless assets >= count
   end

  desc %{
    Renders the containing elements only if the asset's content type matches the regular expression given in the matches attribute.
    The 'title' attribute is required on the parent tag unless this tag is used in assets:each.
    If the 'ignore_case' attribute is set to false, the match is case sensitive. By default, 'ignore_case' is set to true.

    *Usage:* 
    <pre><code><r:assets:each:if_content_type matches="regexp" [ignore_case=true|false"]>...</r:assets:each:if_content_type></code></pre>
  }
  tag 'assets:if_content_type' do |tag|
    options = tag.attr.dup
    # XXX build_regexp_for comes from StandardTags
    # XXX its cool if I use it, right?
    regexp = build_regexp_for(tag,options)
    asset_content_type = tag.locals.asset.asset_content_type
    tag.expand unless asset_content_type.match(regexp).nil?
  end
  
  [:title, :caption, :asset_file_name, :asset_content_type, :asset_file_size, :id].each do |method|
    desc %{
      Renders the `#{method.to_s}' attribute of the asset.     
      The 'title' attribute is required on this tag or the parent tag.
    }
    tag "assets:#{method.to_s}" do |tag|
      options = tag.attr.dup
      asset = find_asset(tag, options)
      asset.send(method) rescue nil
    end
  end
  
  tag "assets:filename" do |tag|
    options = tag.attr.dup
    asset = find_asset(tag, options)
    asset.asset_file_name rescue nil
  end
  
  desc %{
    Renders an image tag for the asset. Using the option size attribute, different sizes can be display. Thumbnail and icon are built 
    in, but custom sizes can be set using assets.addition_thumbnails in the Radiant::Config settings.
    
    *Usage:* 
    <pre><code><r:assets:image [title="asset_title"] [size="icon|thumbnail"]></code></pre>
  }    
  tag 'assets:image' do |tag|
    options = tag.attr.dup
    asset = find_asset(tag, options)
    if asset.image?
      size = options['size'] ? options.delete('size') : 'original'
      alt = " alt='#{asset.title}'" unless tag.attr['alt'] rescue nil
      attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
      attributes << alt unless alt.nil?
      url = asset.thumbnail(size)
      %{<img src="#{url}" #{attributes unless attributes.empty?} />} rescue nil
    else
      raise TagError, "Asset is not an image"
    end
  end
  
  tag 'assets:thumbnail' do |tag|
    options = tag.attr.dup
    asset = find_asset(tag, options)
    asset.generate_thumbnail('test', ['24x24#',nil])
    asset.save    
  end
  
  desc %{
    Renders the url for the asset. If the asset is an image, the <code>size</code> attribute can be used to 
    generate the url for that size. 
    
    *Usage:* 
    <pre><code><r:image [title="asset_title"] [size="icon|thumbnail"]></code></pre>
  }    
  tag 'assets:url' do |tag|
    options = tag.attr.dup
    asset = find_asset(tag, options)
    size = options['size'] ? options.delete('size') : 'original'
    asset.thumbnail(size) rescue nil
  end
  
  desc %{
    Renders a link to the asset. If the asset is an image, the <code>size</code> attribute can be used to 
    generate a link to that size. 
    
    *Usage:* 
    <pre><code><r:image [title="asset_title"] [size="icon|thumbnail"]></code></pre>
  }
  tag 'assets:link' do |tag|
    options = tag.attr.dup
    asset = find_asset(tag, options)
    size = options['size'] ? options.delete('size') : 'original'
    text = options['text'] || asset.title
    anchor = options['anchor'] ? "##{options.delete('anchor')}" : ''
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes = " #{attributes}" unless attributes.empty?
    text = tag.double? ? tag.expand : text
    url = asset.thumbnail(size)
    %{<a href="#{url  }#{anchor}"#{attributes}>#{text}</a>} rescue nil
  end
  
  # Resets the page Url and title within the asset tag
  [:title, :url].each do |method|
    tag "assets:page:#{method.to_s}" do |tag|
      tag.locals.page.send(method)
    end
  end
  
  private
    
    def find_asset(tag, options)
      raise TagError, "'title' attribute required" unless title = options.delete('title') or id = options.delete('id') or tag.locals.asset
      tag.locals.asset || Asset.find_by_title(title) || Asset.find(id)
    end
    
end
