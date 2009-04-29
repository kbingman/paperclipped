module UrlAdditions
  
  Paperclip::Attachment.interpolations[:no_original_style] = lambda do |attachment, style|
    style == attachment.default_style ? nil : "_#{style}"
  end
  
end
  

