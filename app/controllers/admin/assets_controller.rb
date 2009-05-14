class Admin::AssetsController < Admin::ResourceController
    
  def index 
    @assets = Asset.search(params[:search], params[:filter], params[:page])
    @page = Page.find(params[:asset_page]) if params[:asset_page]

    respond_to do |format|
      format.html { render }
      format.js {
        @template_name = 'index'
        if !@page.nil?
          render :partial => 'admin/assets/search_results.html.haml', :layout => false
        else
          render :partial => 'admin/assets/asset_table.html.haml', :locals => { :assets => @assets }, :layout => false
        end
      }
    end
  end
    
  
  # Refreshes the paperclip thumbnails
  def refresh
    unless params[:id]
      @assets = Asset.find(:all)
      @assets.each do |asset|
        asset.asset.reprocess!
      end
      flash[:notice] = "Thumbnails successfully refreshed."
      redirect_to admin_assets_path
    else
      @asset = Asset.find(params[:id])
      @asset.asset.reprocess!
      flash[:notice] = "Thumbnail successfully refreshed."
      redirect_to edit_admin_asset_path(@asset)
    end
  end
  
  
  # Bucket related actions. These may need to be spun out into a seperate controller
  # update?
  def add_bucket
    @asset = Asset.find(params[:id])
    if (session[:bucket] ||= {}).key?(@asset.asset.url)
      render :nothing => true and return
    end
    asset_type = @asset.image? ? 'image' : 'link'
    session[:bucket][@asset.asset.url] = { :thumbnail => @asset.thumbnail(:thumbnail), :id => @asset.id, :title => @asset.title, :type => asset_type }

    render :update do |page|
      page[:bucket_list].replace_html "#{render :partial => 'bucket'}"
    end
  end
  
  def clear_bucket
    session[:bucket] = nil
    render :update do |page|
      page[:bucket_list].replace_html '<li><p class="note"><em>Your bucket is empty.</em></p></li>'
    end
  end
  
  # Attaches an asset to the current page
  def attach_asset
    @asset = Asset.find(params[:asset])
    @page = Page.find(params[:page])
    @page.assets << @asset unless @page.assets.include?(@asset)
    clear_model_cache
    render :partial => 'page_assets', :locals => { :page => @page }
    # render :update do |page|
    #   page[:attachments].replace_html "#{render :partial => 'page_assets', :locals => {:page => @page}}"
    # end
  end
  
  # Removes asset from the current page
  def remove_asset    
    @asset = Asset.find(params[:asset])
    @page = Page.find(params[:page])
    @page.assets.delete(@asset)
    clear_model_cache
    render :nothing => true
  end
  
  def reorder
    params[:attachments].each_with_index do |id,idx| 
      page_attachment = PageAttachment.find(id)
      page_attachment.position = idx+1
      page_attachment.save
    end
    clear_model_cache
    render :nothing => true
  end
  
end
