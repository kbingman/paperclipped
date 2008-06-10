module UrlAdditions
  
  Paperclip::Attachment.interpolations[:test] = lambda do |attachment, style|
    style == attachment.default_style ? nil : "_#{style}"
  end
  
end
  

