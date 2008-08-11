document.observe("dom:loaded", function() {

  $$('.textarea').each(function(box){
    Droppables.add(box, {
      accept: 'asset',
      onDrop: function(element) {
        var link = element.select('a.bucket_link')[0]
        var classes = element.className.split(' ')
        var tag_type = classes[0];
        var tag = '<r:assets:' + tag_type + ' title="' + link.title + '" />'
        //Form.Element.focus(box);
        
      	if(!!document.selection){
      		box.focus();
      		var range = (box.range) ? box.range : document.selection.createRange();
      		range.text = tag;
      		range.select();
      	}else if(!!box.setSelectionRange){
      		var selection_start = box.selectionStart;
      		box.value = box.value.substring(0,selection_start) + tag + box.value.substring(box.selectionEnd);
      		box.setSelectionRange(selection_start + tag.length,selection_start + tag.length);
      	}
      	
      	box.focus();
      	
      }
    });
  });
  

});

function respondToClick(el) {
  alert(el.id);
}

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
  container.select('li').each(function(asset) {
    link = asset.down();
    link.setStyle({ 
      cursor: 'move'
    }); 
    link.writeAttribute('onclick', 'return false;');
  });
  Sortable.create("attachments", {constraint:'horizontal',handle:'reorder',ghosting:false,onUpdate:function(){new Ajax.Request(url, {asynchronous:true, evalScripts:true, parameters:Sortable.serialize("attachments") + '&authenticity_token=' + encodeURIComponent(token)})}});

}

function done_reordering() {
  // Toggles Reorder link
  $('reorder').toggle(); 
  $('done').toggle();

  Sortable.destroy('attachments');
  
}

