ActionController::Routing::Routes.draw do |map|

  # Main RESTful routes for Assets
  map.namespace :admin, :member => { :remove => :get }, :collection => { :refresh => :post } do |admin|
    admin.resources :assets
  end
  
  # Bucket routes
  map.with_options(:controller => 'admin/assets') do |asset|
    asset.add_bucket        '/admin/assets/:id/add',                   :action => 'add_bucket'
    # asset.refresh_assets    "/admin/assets/:id/refresh",               :action => 'regenerate_thumbnails'
    
    asset.clear_bucket      '/admin/assets/clear_bucket',              :action => 'clear_bucket'
    asset.reorder_assets    '/admin/assets/reorder/:id',               :action => 'reorder'
    asset.attach_page_asset '/admin/assets/attach/:asset/page/:page',  :action => 'attach_asset'
    asset.remove_page_asset '/admin/assets/remove/:asset/page/:page',  :action => 'remove_asset'
  end    
  
end

