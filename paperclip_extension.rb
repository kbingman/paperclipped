require_dependency 'application'

class PaperclipExtension < Radiant::Extension
  version "1.0"
  description "Assets extension based on the lightweight Paperclip plugin."
  url "http://kbingman.com/assets"
  
  define_routes do |map|
    map.resources :assets, :path_prefix => "/admin"
    map.connect "/admin/assets/:id/remove", :controller => 'assets', :action => 'remove'
    map.connect "/admin/assets/:id/add",    :controller => 'assets', :action => 'add_bucket'
  end
  
  def activate
    require_dependency 'application'
    
    raise "The Shards extension is required and must be loaded first!" unless defined?(Shards)
    admin.page.edit.add :form_bottom, '/assets/assets_container', :before => "edit_buttons"
    
    Page.class_eval {
      include PageAssetAssociations
      # include AssetTags
    }
    UserActionObserver.send :include, ObserveAssets
    admin.tabs.add "Assets", "/admin/assets", :after => "Snippets", :visibility => [:all]
  end
  
  def deactivate
    # admin.tabs.remove "Assets"
  end
  
end