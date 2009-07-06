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
  
  describe 'content types' do
    describe 'images' do
      ['image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png', 'image/jpg'].each do |mime|
        it "should be an image if it has a content type of #{mime}" do
          new_asset(:asset_content_type => mime).should be_image
        end
        (Asset.known_types - [:image]).each do |other|
          it "should not be #{other}" do
            new_asset(:asset_content_type => mime).send("#{other}?").should_not be_true
          end
        end
      end
      
      describe 'scope' do
        it 'should only return image assets' do
          jpeg = create_asset :asset_content_type => 'image/jpeg'
          gif = create_asset :asset_content_type => 'image/gif'
          pdf = create_asset :asset_content_type => 'application/pdf'
          Asset.images.should == [jpeg, gif]
        end
      end
    end
    
    describe 'audio' do
      it 'should be audio when its an mp3' do
        new_asset(:asset_content_type => 'audio/mpeg').should be_audio
      end

      it 'should be audio when its a windows media audio file' do
        new_asset(:asset_content_type => 'audio/x-ms-wma').should be_audio
      end
      
      it 'should be audio when its an ogg file' do
        new_asset(:asset_content_type => 'application/ogg').should be_audio
      end
      
      describe 'scope' do
        it 'should only return audio files' do
          qt = create_asset :asset_content_type => 'video/quicktime'
          mp3 = create_asset :asset_content_type => 'audio/mpeg'
          ogg = create_asset :asset_content_type => 'application/ogg'
          pdf = create_asset :asset_content_type => 'application/pdf'
          Asset.audios.should == [mp3, ogg]
        end
      end
    end
    
    describe 'movies' do
      it 'should be movie when it has video/* content-type' do
        new_asset(:asset_content_type => 'video/quicktime').should be_movie
      end
      it 'should be movie when it has flash content type' do
        new_asset(:asset_content_type => 'application/x-shockwave-flash').should be_movie
      end
      describe 'scope' do
        it 'should return swf and video assets, not others' do
          create_asset :asset_content_type => 'audio/mpeg'
          qt = create_asset :asset_content_type => 'video/quicktime'
          create_asset :asset_content_type => 'application/pdf'
          swf = create_asset :asset_content_type => 'application/x-shockwave-flash'
          Asset.movies.should == [qt, swf]
        end
      end
    end
    
    describe 'flash' do
      it 'should be swf when it has flash content type' do
        new_asset(:asset_content_type => 'application/x-shockwave-flash').should be_swf
      end
      
      describe 'scope' do
        it 'should only return swf assets' do
          gif = create_asset :asset_content_type => 'image/gif'
          pdf = create_asset :asset_content_type => 'application/pdf'
          swf = create_asset :asset_content_type => 'application/x-shockwave-flash'
          Asset.swfs.should == [swf]
        end
      end
    end
    
    describe 'video' do
      it 'should be video when it has a quicktime content-type' do
        new_asset(:asset_content_type => 'video/quicktime').should be_video
      end
      
      describe 'scope' do
        it 'should only return video assets' do
          qt = create_asset :asset_content_type => 'video/quicktime'
          pdf = create_asset :asset_content_type => 'application/pdf'
          swf = create_asset :asset_content_type => 'application/x-shockwave-flash'
          Asset.videos.should == [qt]
        end
      end
    end
    
    describe 'pdf' do
      it 'should be pdf when it has pdf content-type' do
        new_asset(:asset_content_type => 'application/pdf').should be_pdf
      end
      
      describe 'scope' do
        it 'should only return pdf assets' do
          gif = create_asset :asset_content_type => 'image/gif'
          pdf = create_asset :asset_content_type => 'application/pdf'
          swf = create_asset :asset_content_type => 'application/x-shockwave-flash'
          Asset.pdfs.should == [pdf]
        end
      end
    end
    
    describe 'other' do
      it 'text document should be other' do
        new_asset(:asset_content_type => 'text/plain').should be_other
      end

      it 'binary should be other' do
        new_asset(:asset_content_type => 'application/octet-stream').should be_other
      end
      
      describe 'scope' do
        it 'should only return types not covered by other scopes' do
          # create_asset :asset_content_type => 'application/pdf'
          create_asset :asset_content_type => 'application/x-shockwave-flash'
          txt = create_asset :asset_content_type => 'text/plain'
          create_asset :asset_content_type => 'image/gif'
          create_asset :asset_content_type => 'video/quicktime'
          create_asset :asset_content_type => 'audio/mpeg'
          bin = create_asset :asset_content_type => 'application/octet-stream'
          create_asset :asset_content_type => 'application/ogg'
          
          Asset.others.should == [txt, bin]
        end
      end
    end
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
