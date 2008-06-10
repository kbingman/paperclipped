module UrlAdditions
  
  Paperclip::Attachment.interpolations[:no_original_style] = lambda do |attachment, style|
    style == 'original' ? nil : "_#{style}"
  end
  
end
  

