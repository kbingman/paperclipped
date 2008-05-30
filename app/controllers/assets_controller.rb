class AssetsController < ApplicationController
  
  make_resourceful do 
    actions :all
    
    response_for :create, :update do |format|
      format.html { redirect_to(params[:continue] ? edit_asset_path(@asset) : assets_path) }
    end
    
  end
  
  def add_bucket
    @asset = Asset.find(params[:id])
    # if (session[:bucket] ||= {}).key?(url(@asset))
    #  render :nothing => true and return
    # end
    args = asset_image_args_for(@asset)
    session[:bucket][@asset.asset.url] = args
    render :update do |page|
      page[:bucket].replace_html "#{render :partial => 'bucket'}"
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
  
    def asset_image_args_for(asset, thumbnail = :icon, options = {})
      # thumb_size = Array.new(2).fill(Asset.attachment_options[:thumbnails][thumbnail].to_i).join('x')
      # options    = options.reverse_merge(:title => "#{asset.title}")
      [asset.asset.url, thumbnail, options]
    end
    
    def current_objects
      Asset.paginate(:all, :order => 'created_at', :page => params[:page], :per_page => 10)
    end

end
