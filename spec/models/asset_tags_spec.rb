require File.dirname(__FILE__) + '/../spec_helper'

describe 'Asset Tags' do
  dataset :pages

  describe '<r:assets:image>' do
    before(:each) do
      @image = Asset.create({
        :asset_file_name => 'foo.jpg',
        :asset_content_type => 'image/jpeg',
        :asset_file_size => '24680',
        :title => 'Foo'
      })
    end

    it 'should render an img tag by ID' do
      tag = %{<r:assets:image id="#{@image.id}" />}
      expected = %r{\A<img +src=\"/assets/#{@image.id}/foo.jpg\" +alt=\"Foo\" */>\z}

      pages(:home).should render(tag).matching(expected)
    end

    it 'should render an img tag by title' do
      tag = %{<r:assets:image title="Foo" />}
      expected = %r{\A<img +src=\"/assets/#{@image.id}/foo.jpg\" +alt=\"Foo\" */>\z}

      pages(:home).should render(tag).matching(expected)
    end

    it 'should escape the title in the alt attribute value' do
      @image.update_attributes!(:title => %{Harry "Snapper" Organs & Stig O'Tracey})
      tag = %{<r:assets:image id="#{@image.id}" />}
      expected = %r{\A<img +src=\"/assets/#{@image.id}/foo.jpg\" +alt=\"Harry &quot;Snapper&quot; Organs &amp; Stig O'Tracey\" */>\z}

      pages(:home).should render(tag).matching(expected)
    end

    it 'should use the alt attribute if given' do
      tag = %{<r:assets:image id="#{@image.id}" alt="Alternate title" />}
      expected = %r{\A<img +src=\"/assets/#{@image.id}/foo.jpg\" +alt=\"Alternate title\" */>\z}

      pages(:home).should render(tag).matching(expected)
    end
  end
end
