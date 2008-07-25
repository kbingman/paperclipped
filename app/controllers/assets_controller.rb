class AssetsController < ApplicationController
  
  make_resourceful do 
    actions :all
    response_for :index do |format|
      format.html { render }
      format.js {
        if params[:asset_page]
          @asset_page = Page.find(params[:asset_page])
          render :partial => 'assets/search_results.html.haml', :layout => false
        else
          render :partial => 'assets/asset_table.html.haml', :layout => false
        end
      }
    end
    after :create do
      if params[:page]
        @page = Page.find(params[:page])
        @asset.pages << @page
      end
    end
    response_for :update do |format|
      format.html { 
        flash[:notice] = "Asset successfully updated."
        redirect_to(params[:continue] ? edit_asset_path(@asset) : assets_path) 
      }
    end
    response_for :create do |format|
      format.html { 
        flash[:notice] = "Asset successfully uploaded."
        redirect_to(@page ? page_edit_url(@page) : (params[:continue] ? edit_asset_path(@asset) : assets_path)) 
      }
    end
     
  end
  
  def regenerate_thumbnails
    if request.post? 
      unless params[:id]
        @assets = Asset.find(:all)
        @assets.each do |asset|
          asset.asset.reprocess!
          asset.save
        end
        flash[:notice] = "Thumbnails successfully refreshed."
        redirect_to assets_path
      else
        @asset = Asset.find(params[:id])
        @asset.asset.reprocess!
        @asset.save
        flash[:notice] = "Thumbnails successfully refreshed."
        redirect_to edit_asset_path(@asset)
      end
    else
      render "Do not access this url directly"
    end
    
  end
  
  def add_bucket
    @asset = Asset.find(params[:id])
    if (session[:bucket] ||= {}).key?(@asset.asset.url)
      render :nothing => true and return
    end
    session[:bucket][@asset.asset.url] = { :thumbnail => @asset.thumbnail(:thumbnail), :id => @asset.id, :title => @asset.title }

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
  
  def attach_asset
    @asset = Asset.find(params[:asset])
    @page = Page.find(params[:page])
    @page.assets << @asset unless @page.assets.include?(@asset)
    render :update do |page|
      page[:attachments].replace_html "#{render :partial => 'page_assets', :locals => {:page => @page}}"
    end
  end
  
  def remove_asset    
    @asset = Asset.find(params[:asset])
    @page = Page.find(params[:page])
    @page.assets.delete(@asset)
    render :nothing => true
  end
  
  def reorder
    params[:attachments].each_with_index do |id,idx| 
      page_attachment = PageAttachment.find(id)
      page_attachment.position = idx+1
      page_attachment.save
    end
    render :nothing => true
  end
  
  def remove 
    @asset = Asset.find(params[:id])
    # This is a temporary measure! It is not very RESTful, but I like the confirm page... 
    if request.post?
      @asset.destroy
      redirect_to assets_path
    end 
  end
  
  protected
  
    def current_objects
      term = params['search'].downcase + '%' if params['search']
      condition = [ 'LOWER(title) LIKE ? or LOWER(caption) LIKE ? or LOWER(asset_file_name) LIKE ?', '%' + term, '%' + term, '%' + term  ] if term
      @mark_term = params['search']
      
      if @mark_term
        Asset.paginate(:all, :conditions => condition, :order => 'created_at DESC', :page => params[:page], :per_page => 10)
      else
        Asset.paginate(:all, :order => 'created_at DESC', :page => params[:page], :per_page => 10)
      end
    end

end
