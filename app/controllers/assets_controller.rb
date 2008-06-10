class AssetsController < ApplicationController
  
  make_resourceful do 
    actions :all
    response_for :create, :update do |format|
      format.html { redirect_to(params[:continue] ? edit_asset_path(@asset) : assets_path) }
    end
  end
  
  def add_bucket
    @asset = Asset.find(params[:id])
    if (session[:bucket] ||= {}).key?(@asset.asset.url)
      render :nothing => true and return
    end
    session[:bucket][@asset.asset.url] = { :thumbnail => @asset.asset.url(:square), :id => @asset.id, :title => @asset.title }

    render :update do |page|
      page[:bucket].replace_html "#{render :partial => 'bucket'}"
    end
  end
  
  def attach_image
  end
  
  def clear_bucket
    session[:bucket] = nil
    render :update do |page|
      page[:bucket].replace_html '<li><p class="note"><em>Your bucket is empty.</em></p></li>'
    end
  end
  
  def remove 
    @asset = Asset.find(params[:id])
    # This is a temporary measure!
    if request.post?
      @asset.destroy
      redirect_to assets_path
    end 
  end
  
  protected
  
    def current_objects
      Asset.paginate(:all, :order => 'created_at', :page => params[:page], :per_page => 10)
    end

end
