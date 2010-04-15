module AssetTags
  include Radiant::Taggable
  
  class TagError < StandardError; end
  
  desc %{
    The namespace for referencing images and assets. You may specify the @title@
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
    Use the @limit@ and @offset@ attribute to render a specific number of assets.
    Use @by@ and @order@ attributes to control the order of assets.
    Use @extensions@ attribute to specify which assets to be rendered.
    
    *Usage:* 
    <pre><code><r:assets:each [limit=0] [offset=0] [order="asc|desc"] [by="position|title|..."] [extensions="png|pdf|doc"]>...</r:assets:each></code></pre>
  }    
  tag 'assets:each' do |tag|
    options = tag.attr.dup
    result = []
    assets = tag.locals.page.assets.find(:all, assets_find_options(tag))
    tag.locals.assets = assets
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
  
  desc %{
    Renders the contained elements only if the current asset is the first
    asset attached to the current page.
  
    *Usage:*
    <pre><code><r:if_first>...</r:if_first></code></pre>
  }
  tag 'assets:if_first' do |tag|
    attachments = tag.locals.assets
    asset = tag.locals.asset
    if asset == attachments.first
      tag.expand
    end
  end  
  
  
  desc %{
    Renders the contained elements only if the current asset is not the first
    asset attached to the current page.
    
    *Usage:*
    <pre><code><r:unless_first>...</r:unless_first></code></pre>
  }
  tag 'assets:unless_first' do |tag|
    attachments = tag.locals.assets
    asset = tag.locals.asset
    if asset != attachments.first
      tag.expand
    end
  end
  
  desc %{
    Renders the contained elements only if the current contextual page has one or
    more assets. The @min_count@ attribute specifies the minimum number of required
    assets. You can also filter by extensions with the @extensions@ attribute.
  
    *Usage:*
    <pre><code><r:if_assets [min_count="n"] [extensions="pdf|jpg"]>...</r:if_assets></code></pre>
  }
  tag 'if_assets' do |tag|
    count = tag.attr['min_count'] && tag.attr['min_count'].to_i || 1
    assets = tag.locals.page.assets.count(:conditions => assets_find_options(tag)[:conditions])
    tag.expand if assets >= count
  end
  
  desc %{
    The opposite of @<r:if_assets/>@.
  }
  tag 'unless_assets' do |tag|
    count = tag.attr['min_count'] && tag.attr['min_count'].to_i || 1
    assets = tag.locals.page.assets.count(:conditions => assets_find_options(tag)[:conditions])
    tag.expand unless assets >= count
  end
  
  desc %{
    Renders the value for a top padding for the image. Put the image in a
    container with specified height and using this tag you can vertically
    align the image within it's container.
  
    *Usage*:
    <pre><code><r:assets:top_padding container = "140" [size="icon"]/></code></pre>
  
    *Working Example*:
    <pre><code>
      <ul>
        <r:assets:each>
          <li style="height:140px">
            <img style="padding-top:<r:top_padding size='category' container='140' />px" 
                 src="<r:url />" alt="<r:title />" />
          </li>
        </r:assets:each>
      </ul>
    </code></pre>
  }
  tag 'assets:top_padding' do |tag|
    asset, options = asset_and_options(tag)
    raise TagError, 'Asset is not an image' unless asset.image?
    raise TagError, "'container' attribute required" unless options['container']
    size = options['size'] ? options.delete('size') : 'icon'
    container = options.delete('container')
    img_height = asset.height(size)
    (container.to_i - img_height.to_i)/2
  end
  
  ['height','width'].each do |dimension|
    desc %{
      Renders the #{dimension} of the asset.
    }
    tag "assets:#{dimension}" do |tag|
      asset, options = asset_and_options(tag)
      unless asset.dimensions_known?
        raise TagError, "Can't determine #{dimension} for this Asset. It may not be a supported type."
      end
      size = options['size'] ? options.delete('size') : 'original'
      asset.send(dimension, size)
    end
  end

  desc %{
    Renders the containing elements only if the asset's content type matches
    the regular expression given in the @matches@ attribute. If the
    @ignore_case@ attribute is set to false, the match is case sensitive. By
    default, @ignore_case@ is set to true.
      
    The @title@ attribute is required on the parent tag unless this tag is used in @assets:each@.

    *Usage:* 
    <pre><code><r:assets:each><r:if_content_type matches="regexp" [ignore_case=true|false"]>...</r:if_content_type></r:assets:each></code></pre>
  }
  tag 'assets:if_content_type' do |tag|
    options = tag.attr.dup
    # XXX build_regexp_for comes from StandardTags
    # XXX its cool if I use it, right?
    regexp = build_regexp_for(tag,options)
    asset_content_type = tag.locals.asset.asset_content_type
    tag.expand unless asset_content_type.match(regexp).nil?
  end
  
  #TODO: could use better docs for Asset#other? case explaining what types it covers
  Asset.known_types.each do |known_type|
    desc %{
      Renders the contents only of the asset is of the type #{known_type}
    }
    tag "assets:if_#{known_type}" do |tag|
      tag.expand if find_asset(tag, tag.attr.dup).send("#{known_type}?".to_sym)
    end

    desc %{
      Renders the contents only of the asset is not of the type #{known_type}
    }
    tag "assets:unless_#{known_type}" do |tag|
      tag.expand unless find_asset(tag, tag.attr.dup).send("#{known_type}?".to_sym)
    end
  end
  
  [:title, :caption, :asset_file_name, :asset_content_type, :asset_file_size, :id].each do |method|
    desc %{
      Renders the @#{method.to_s}@ attribute of the asset
    }
    tag "assets:#{method.to_s}" do |tag|
      asset, options = asset_and_options(tag)
      asset.send(method) rescue nil
    end
  end
  
  tag 'assets:filename' do |tag|
    asset, options = asset_and_options(tag)
    asset.asset_file_name rescue nil
  end
  
  desc %{
    Renders an image tag for the asset.
    
    Using the optional @size@ attribute, different sizes can be display.
    “thumbnail” and “icon” sizes are built in, but custom ones can be set
    using by changing assets.addition_thumbnails in the Radiant::Config
    settings.
    
    *Usage:* 
    <pre><code><r:assets:image [title="asset_title"] [size="icon|thumbnail"]></code></pre>
  }    
  tag 'assets:image' do |tag|
    asset, options = asset_and_options(tag)
    raise TagError, 'Asset is not an image' unless asset.image?
    size = options['size'] ? options.delete('size') : 'original'
    geometry = options['geometry'] ? options.delete('geometry') : nil
    #This is very experimental and will generate new sizes on the fly
    asset.generate_style(size, { :size => geometry }) if geometry
    
    alt = " alt='#{asset.title}'" unless tag.attr['alt'] rescue nil
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes << alt unless alt.nil?
    url = asset.thumbnail(size)
    %{<img src="#{url}" #{attributes unless attributes.empty?} />} rescue nil
  end
  
  desc %{
    Embeds a flash-movie in a cross-browser-compatible fashion using only HTML
    If no width and height attributes are given it will use the intrinsic
    dimensions of the swf file
    
    *Usage:*
    <pre><code><r:assets:flash [title="asset_title"] [width="100"] [height="100"]>Fallback content</flash></code></pre>
    
    *Example with text fallback:*
    <pre><code><r:assets:flash title="flash_movie">
        Sorry, you need to have flash installed, <a href="http://adobe.com/flash">get it here</a>
    </flash></code></pre>
    
    *Example with image fallback and explicit dimensions:*
    <pre><code><r:assets:flash title="flash_movie" width="300" height="200">
        <r:assets:image title="flash_screenshot" />
      </flash></code></pre>
  }
  tag 'assets:flash' do |tag|
    asset, options = asset_and_options(tag)
    raise TagError, 'Must be flash' unless asset.swf?
    url = asset.thumbnail('original')
    dimensions = [(tag.attr['width'] || asset.width),(tag.attr['height'] || asset.height)]
    swf_embed_markup url, dimensions, tag.expand
  end
  
  tag 'assets:thumbnail' do |tag|
    asset, options = asset_and_options(tag)
    asset.generate_thumbnail('test', ['24x24#',nil])
    asset.save    
  end
  
  desc %{
    Renders the url for the asset. If the asset is an image, the <code>size</code> attribute can be used to 
    generate the url for that size. 
    
    *Usage:* 
    <pre><code><r:url [title="asset_title"] [size="icon|thumbnail"]></code></pre>
  }    
  tag 'assets:url' do |tag|
    asset, options = asset_and_options(tag)
    size = options['size'] ? options.delete('size') : 'original'
    asset.thumbnail(size) rescue nil
  end
  
  desc %{
    Renders a link to the asset. If the asset is an image, the <code>size</code> attribute can be used to 
    generate a link to that size. 
    
    *Usage:* 
    <pre><code><r:assets:link [title="asset_title"] [size="icon|thumbnail"] /></code></pre>
  }
  tag 'assets:link' do |tag|
    asset, options = asset_and_options(tag)
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

  desc %{
  Renders the extension of the asset, as extracted from its filename.
  
  *Usage*:
    <pre><code>
      <ul>
        <r:assets:each extensions="doc|pdf">
          <li class="<r:extension/>">
            <r:link/>
          </li>
        </r:assets:each>
      </ul>
    </code></pre>
  }
  tag 'assets:extension' do |tag|
    raise TagError, 'must be nested inside an assets or assets:each tag' unless tag.locals.asset
    asset = tag.locals.asset
    asset.asset_file_name[/\.(\w+)$/, 1]
  end
  
  private
    def asset_and_options(tag)
      options = tag.attr.dup
      [find_asset(tag, options), options]
    end
    
    def find_asset(tag, options)
      raise TagError, "'title' attribute required" unless title = options.delete('title') or id = options.delete('id') or tag.locals.asset
      tag.locals.asset || Asset.find_by_title(title) || Asset.find(id)
    end
    
    def assets_find_options(tag)
      attr = tag.attr.symbolize_keys
      extensions = attr[:extensions] && attr[:extensions].split('|') || []
      conditions = unless extensions.blank?
        [ extensions.map { |ext| "assets.asset_file_name LIKE ?"}.join(' OR '), 
          *extensions.map { |ext| "%.#{ext}" } ]
      else
        nil
      end
      
      by = attr[:by] || 'page_attachments.position'
      order = attr[:order] || 'asc'
      
      options = {
        :order => "#{by} #{order}",
        :limit => attr[:limit] || nil,
        :offset => attr[:offset] || nil,
        :conditions => conditions
      }
    end
    
    def swf_embed_markup(url, dimensions, fallback_content)
      width, height = dimensions
      %{<!--[if !IE]> -->
        <object type="application/x-shockwave-flash" data="#{url}" width="#{width}" height="#{height}">
      <!-- <![endif]-->
      <!--[if IE]>
        <object width="#{width}" height="#{height}"
          classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
          codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0">
          <param name="movie" value="#{url}" />
      <!-->
      #{fallback_content}
        </object>
      <!-- <![endif]-->}
    end
end

