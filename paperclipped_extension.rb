require_dependency 'application'

class PaperclippedExtension < Radiant::Extension
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
    
    admin.page.edit.add :form_bottom, '/assets/assets_container', :before => "edit_buttons"
    
    Page.class_eval {
      include PageAssetAssociations
      # include AssetTags
    }
    
    # join already observed models with forum extension models 
    observables = UserActionObserver.instance.observed_classes | [Asset] 

    # update list of observables 
    UserActionObserver.send :observe, observables 

    # connect UserActionObserver with my models 
    UserActionObserver.instance.send :add_observer!, Asset 
    
    admin.tabs.add "Assets", "/admin/assets", :after => "Snippets", :visibility => [:all]
  end
  
  def deactivate
    # admin.tabs.remove "Assets"
  end
  
end