module AssetPageTags
  include Radiant::Taggable
  include AssetTags

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
  
  # Resets the page Url and title within the asset tag
  [:title, :url].each do |method|
    tag "assets:page:#{method.to_s}" do |tag|
      tag.locals.page.send(method)
    end
  end
end
