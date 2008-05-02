require_dependency 'application'

class PaperclipExtension < Radiant::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/assets"
  
  define_routes do |map|
    map.resources :assets, :path_prefix => "/admin"
  end
  
  def activate
    admin.tabs.add "Assets", "/admin/assets", :after => "Snippets", :visibility => [:all]
  end
  
  def deactivate
    # admin.tabs.remove "Assets"
  end
  
end