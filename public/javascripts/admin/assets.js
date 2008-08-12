document.observe("dom:loaded", function() {
  $$('#filesearchform a').each(function(element){
    element.observe('click', function(){
      var type_id = element.text.downcase();
      var type_check = $(type_id + '-check');
      var search_form = $('filesearchform')
      if(element.hasClassName('pressed')) {
        element.removeClassName('pressed');
        type_check.removeAttribute('checked');
      } else {
        element.addClassName('pressed');
        type_check.setAttribute('checked', 'checked');
      }
      new Ajax.Updater('assets_table', search_form.action, {
        asynchronous: true, 
        evalScripts:  true, 
        parameters:   Form.serialize(search_form),
        method: 'get',
        onComplete: 'assets_table'
      }); 
      return false;
    });
    
  }); 
  
  $$('.textarea').each(function(box){
    Droppables.add(box, {
      accept: 'asset',
      onDrop: function(element) {
        var link = element.select('a.bucket_link')[0]
        var asset_id = element.id.split('_').last();
        var classes = element.className.split(' ');
        var tag_type = classes[0];
        var tag = '<r:assets:' + tag_type + ' id="' + asset_id + '" />'
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

function asset_tabs(element) {
  var panes = $('assets').select('.pane');
  var tabs = $('asset-tabs').select('.asset-tab');
  var target = element.href.split('#')[1]
  tabs.each(function(tab) {tab.removeClassName('here')});
  panes.each(function(pane) {Element.hide(pane)});
  element.addClassName('here');
  Element.show($(target));
}



