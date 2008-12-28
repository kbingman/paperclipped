document.observe("dom:loaded", function() {
  $$('.textarea').each(function(box){
    Droppables.add(box, {
      accept: 'asset',
      onDrop: function(element) {
        var link = element.select('a.bucket_link')[0]
        var asset_id = element.id.split('_').last();
        var classes = element.className.split(' ');
        var tag_type = classes[0];
        var tag = '<r:assets:' + tag_type + ' id="' + asset_id + '" size="original" />'
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
  new Draggable('asset-bucket', { starteffect: false, endeffect: false });
});

var Asset = {};

Asset.Tabs = Behavior.create({
  onclick: function(e){
    e.stop();

    var pane = $(this.element.href.split('#')[1]);
    var panes = $('assets').select('.pane');
    
    var tabs = $('asset-tabs').select('.asset-tab');
    tabs.each(function(tab) {tab.removeClassName('here')});
    
    this.element.addClassName('here');;
    panes.each(function(pane) {Element.hide(pane)});
    Element.show($(pane));
  }
});

Asset.ShowBucket = Behavior.create({
  onclick: function(e){
    e.stop();
    var element = $('asset-bucket');
    center(element);
    element.show();
  }
});

Asset.HideBucket = Behavior.create({
  onclick: function(e){
    e.stop();
    var element = $('asset-bucket');
    element.hide();
  }
});

Asset.FileTypes = Behavior.create({
  onclick: function(e){
    e.stop();
    var element = this.element;
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
  }
});

Event.addBehavior({
  '#asset-tabs a'     : Asset.Tabs,
  '#close-link a'     : Asset.HideBucket,
  '#show-bucket a'    : Asset.ShowBucket,
  '#filesearchform a' : Asset.FileTypes
});



