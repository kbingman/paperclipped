module AssetTags
  include Radiant::Taggable
  
  class TagError < StandardError; end
  
  desc %{
    The namespace for referencing images and assets.  You may specify the 'name'
    attribute on this tag for all contained tags to refer to that asset.  
    
    *Usage:* 
    <pre><code><r:asset [title="asset_title"] >...</r:asset></code></pre>
  }    
  tag 'assets' do |tag|
    tag.locals.asset = Asset.find_by_title(tag.attr['title'])
    tag.expand
  end
  
  desc %{
    The namespace for referencing images and assets.  You may specify the 'name'
    attribute on this tag for all contained tags to refer to that asset.  
    
    *Usage:* 
    <pre><code><r:asset [title="asset_title"] >...</r:asset></code></pre>
  }    
  tag 'assets:each' do |tag|
    result = []
    # all = tag.attr['all']
    # all == 'true' ? assets = Asset.find(:all) : assets = tag.locals.page.assets
    attachments = tag.locals.page.page_attachments
    tag.locals.assets = attachments
    attachments.each do |attachment|
      tag.locals.asset = attachment.asset
      result << tag.expand
    end
    result
  end
  
  tag 'assets:first' do |tag|
     # all = tag.attr['all']
     # all == 'true' ? assets = Asset.find(:all) : 
     attachmentss = tag.locals.page.page_attachments
     if first = attachmentss.first
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
  
  [:filename, :title, :caption, :content_type, :size, :width, :height, :id].each do |method|
    desc %{
      Renders the `#{method.to_s}' attribute of the asset.     
      The 'title' attribute is required on this tag or the parent tag.
    }
    tag "assets:#{method.to_s}" do |tag|
      raise TagError, "'title' attribute required" unless title = tag.attr['title'] or tag.locals.asset
      asset = tag.locals.asset || Asset.find_by_title(tag.attr['title'])
      asset.send(method) rescue nil
    end
  end
  
  desc %{
    
    *Usage:* 
    <pre><code><r:image [title="asset_title"] ></code></pre>
  }    
  tag 'assets:image' do |tag|
    options = tag.attr.dup
    raise TagError, "'title' attribute required" unless title = options.delete('title') or tag.locals.asset
    asset = tag.locals.asset || Asset.find_by_title(tag.attr['title'])
    size = options.delete('size') || 'original'
    # path = asset.asset.url(size)
    alt = " alt='#{asset.title}'" unless tag.attr['alt'] rescue nil
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes << alt unless alt.nil?
    %{<img src="#{asset.asset.url(size)}" #{attributes unless attributes.empty?} />} rescue nil
  end
  
  desc %{

    *Usage:* 
    <pre><code><r:image [title="asset_title"] ></code></pre>
  }    
  tag 'assets:url' do |tag|
    options = tag.attr.dup
    raise TagError, "'title' attribute required" unless title = options.delete('title') or tag.locals.asset
    asset = tag.locals.asset || Asset.find_by_title(tag.attr['title'])
    size = options.delete('size') || 'original'
    asset.asset.url(size)  rescue nil
  end
  
  tag 'assets:link' do |tag|
    options = tag.attr.dup
    asset = tag.locals.asset
    size = options['size'] ? options.delete('size') : 'original'
    anchor = options['anchor'] ? "##{options.delete('anchor')}" : ''
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes = " #{attributes}" unless attributes.empty?
    text = tag.double? ? tag.expand : tag.render('title')
    url = asset.asset.url(size)
    %{<a href="#{url  }#{anchor}"#{attributes}>#{text}</a>}
  end
  

  
  # Resets the page Url and title within the asset tag
  [:title, :url].each do |method|
    tag "assets:page:#{method.to_s}" do |tag|
      tag.locals.page.send(method)
    end
  end
  
end