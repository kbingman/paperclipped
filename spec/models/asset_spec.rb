require File.dirname(__FILE__) + '/../spec_helper'

describe Asset do
  def default_attributes
    {
      :asset_file_name =>  'asset.jpg',
      :asset_content_type =>  'image/jpeg',
      :asset_file_size => '46248'
    }
  end
  def new_asset(overrides={})
    Asset.new default_attributes.merge(overrides)
  end
  def create_asset(overrides={})
    Asset.create! default_attributes.merge(overrides)
  end
  
  it 'should be valid when instantiated' do
    new_asset.should be_valid
  end
  
  it 'should be valid when saved' do
    create_asset.should be_valid
  end
  
  describe '#thumbnail' do
    describe 'without argument' do
      it 'should return paperclip asset url for image' do
        image = new_asset :asset_content_type => 'image/jpeg'
        image.stub! :asset => mock('asset', :url => '/y/z/e.jpg')
        image.thumbnail.should == '/y/z/e.jpg'
      end
      
      it 'should return paperclip asset url for non-image' do
        asset = new_asset :asset_content_type => 'application/pdf'
        asset.stub! :asset => mock('asset', :url => '/y/z/e.pdf')
        asset.thumbnail.should == '/y/z/e.pdf'
      end
    end
    
    describe 'with size=original' do
      it 'should return paperclip asset url for image' do
        image = new_asset :asset_content_type => 'image/jpeg'
        image.stub! :asset => mock('asset', :url => '/y/z/e.jpg')
        image.thumbnail('original').should == '/y/z/e.jpg'
      end
      
      it 'should return paperclip asset url for non-image' do
        asset = new_asset :asset_content_type => 'application/pdf'
        asset.stub! :asset => mock('asset', :url => '/y/z/e.pdf')
        asset.thumbnail('original').should == '/y/z/e.pdf'
      end
    end
    
    it 'should return resized image for images when given size' do
      image = new_asset :asset_content_type => 'image/jpeg'
      image.stub! :asset => mock('asset')
      image.asset.stub!(:url).with(:thumbnail).and_return('/re/sized/image_thumbnail.jpg')
      image.thumbnail('thumbnail').should == '/re/sized/image_thumbnail.jpg'
    end
    
    it 'should return icon for non-image with a given size' do
      image = new_asset :asset_content_type => 'application/pdf'
      image.thumbnail('thumbnail').should == "/images/assets/pdf_thumbnail.png"
    end
  end

end
