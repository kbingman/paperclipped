module UrlAdditions
  
  Paperclip.interpolates :no_original_style do |attachment, style|
    style ||= :original
    style == attachment.instance.default_style ? nil : "_#{style}"
  end
  
end
  

