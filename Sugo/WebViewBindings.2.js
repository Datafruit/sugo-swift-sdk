sugo_bindings.current_event_bindings = {};
for (var i = 0; i < sugo_bindings.h5_event_bindings.length; i++) {
    var b_event = sugo_bindings.h5_event_bindings[i];
    if (b_event.target_activity === sugo_bindings.current_page) {
        var key = JSON.stringify(b_event.path);
        sugo_bindings.current_event_bindings[key] = b_event;
    }
};
sugo_bindings.delegate = function(eventType, event) {
    function handle(e) {
        var evt = window.event ? window.event : e;
        
        var target = evt.target || evt.srcElement;
        var currentTarget = e ? e.currentTarget : this;
        var path = event.path.path;
        if (event.similar === true) {
            path = path.replace(/:nth-child\([0-9]*\)/g, '');
        }
        var eles = document.querySelectorAll(path);
        if (eles) {
            for (var eles_idx = 0; eles_idx < eles.length; eles_idx++) {
                var ele = eles[eles_idx];
                var parentNode = target;
                while (parentNode) {
                    if (parentNode === ele) {
                        var custom_props = {};
                        if (event.code && event.code.replace(/(^\s*)|(\s*$)/g, '') != '') {
                            var sugo_props = new Function(event.code);
                            custom_props = sugo_props();
                        }
                        custom_props.from_binding = true;
                        sugo.track(event.event_id, event.event_name, custom_props);
                        break;
                    }
                    parentNode = parentNode.parentNode
                }
            }
        }
    }
    document.body.addEventListener(eventType, handle);
};
sugo_bindings.bindEvent = function() {
    var paths = Object.keys(sugo_bindings.current_event_bindings);
    for (var idx = 0; idx < paths.length; idx++) {
        var path_str = paths[idx];
        var event = sugo_bindings.current_event_bindings[path_str];
        sugo_bindings.delegate(event.event_type, event);
    }
};