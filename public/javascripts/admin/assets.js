// the bucket class isn't needed at the moment; it is currently handled with onclick, as this is 
// easier to turn off again when reording the images. 
var Bucket = Class.create({
  initialize: function(element) {
    assets = $(element).select('a.controls');
    assets.each(function(link) {
      link.observe('click', function(e) {
        image_info = link.next();
        Effect.toggle(image_info, 'appear', { duration: 0.4 });
        e.stop();
      });
    });
  }
});

function asset_tabs(element) {
  var panes = $('assets').select('.pane');
  var tabs = $('asset-tabs').select('.asset-tab');
  var target = element.href.split('#')[1]
  tabs.each(function(tab) {tab.removeClassName('here')});
  panes.each(function(pane) {Element.hide(pane)});
  element.addClassName('here');
  Element.show($(target));
}

function toggle_image_info(element) {
  image_info = element.next('.info');
  Effect.toggle(image_info, 'appear', { duration: 0.4 });
}

function reorder_attachments(page, token) {
  // Toggles Reorder link
  $('reorder').toggle(); 
  $('done').toggle();
  var url = '/admin/assets/reorder/' + page 
  
  container = $('attachments');
  // attachments = container.select('li.bucket_asset');
  container.select('li.asset').each(function(asset) {
    link = asset.down();
    link.setStyle({ 
      cursor: 'move'
    }); 
    link.writeAttribute('onclick', 'return false;');
  });
  Sortable.create("attachments", {constraint:false,ghosting:false,onUpdate:function(){new Ajax.Request(url, {asynchronous:true, evalScripts:true, parameters:Sortable.serialize("attachments") + '&authenticity_token=' + encodeURIComponent(token)})}});

}

function done_reordering() {
  // Toggles Reorder link
  $('reorder').toggle(); 
  $('done').toggle();

  container = $('attachments');
  container.select('li.asset').each(function(asset,i) {
    index = 100 - i
    asset.setStyle({ 
      'z-index': index
    });
    link = asset.down();
    link.setStyle({ 
      'cursor': 'pointer'
    }); 
    link.writeAttribute('onclick', 'toggle_image_info(this); return false;');
  });
  Sortable.destroy('attachments');
  
}

