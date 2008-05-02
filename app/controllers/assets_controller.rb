class AssetsController < ApplicationController
  
  make_resourceful do 
    actions :all
    
    response_for :create, :update do |format|
      format.html { redirect_to(params[:continue] ? edit_asset_path(@asset) : assets_path) }
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
  
end
