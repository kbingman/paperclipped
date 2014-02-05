require File.dirname(__FILE__) + '/../spec_helper'

describe 'Asset Tags' do
  dataset :pages

  describe '<r:assets:image>' do
    before(:each) do
      @image = Asset.create({
        :asset_file_name => 'foo.jpg',
        :asset_content_type => 'image/jpeg',
        :asset_file_size => '24680'
      })
      Asset.stub!(:find).and_return(@image)
    end

    it 'should render an img tag by ID with a default alt text' do
      tag = %{<r:assets:image id="#{@image.id}" />}
      expected = %r{\A<img +src=\"/assets/#{@image.id}/foo.jpg\" +alt=\"foo\" */>\z}

      pages(:home).should render(tag).matching(expected)
    end

    it 'should render an img tag by title with a default alt text' do
      tag = %{<r:assets:image title="My Title" />}
      expected = %r{\A<img +src=\"/assets/#{@image.id}/foo.jpg\" +alt=\"foo\" */>\z}

      pages(:home).should render(tag).matching(expected)
    end

    it 'should use the given title as the alt text' do
      @image.stub!(:title).and_return('My Title')
      tag = %{<r:assets:image id="#{@image.id}" />}
      expected = %r{\A<img +src=\"/assets/#{@image.id}/foo.jpg\" +alt=\"My Title\" */>\z}

      pages(:home).should render(tag).matching(expected)
    end

    it 'should escape the title in the alt text' do
      @image.stub!(:title).and_return(%{Harry "Snapper" Organs & Stig O'Tracey})
      tag = %{<r:assets:image id="#{@image.id}" />}
      expected = %r{\A<img +src=\"/assets/#{@image.id}/foo.jpg\" +alt=\"Harry &quot;Snapper&quot; Organs &amp; Stig O'Tracey\" */>\z}

      pages(:home).should render(tag).matching(expected)
    end

    it 'should use the given alt text' do
      tag = %{<r:assets:image id="#{@image.id}" alt="Alternate title" />}
      expected = %r{\A<img +src=\"/assets/#{@image.id}/foo.jpg\" +alt=\"Alternate title\" */>\z}

      pages(:home).should render(tag).matching(expected)
    end

    it 'should include the image dimensions' do
      @image.stub!(:dimensions).and_return([200,100])
      tag = %{<r:assets:image id="#{@image.id}" />}
      expected = %r{\A<img +src=\"/assets/#{@image.id}/foo.jpg\" +alt=\"foo\" +width=\"200\" height=\"100\" */>\z}

      pages(:home).should render(tag).matching(expected)
    end

    it 'should override the image dimensions with the given dimensions' do
      @image.stub!(:dimensions).and_return([200,100])
      tag = %{<r:assets:image id="#{@image.id}" width="100" height="50" />}
      expected = %r{\A<img +src=\"/assets/#{@image.id}/foo.jpg\" +alt=\"foo\" +width=\"100\" height=\"50\" */>\z}

      pages(:home).should render(tag).matching(expected)
    end
  end
end
