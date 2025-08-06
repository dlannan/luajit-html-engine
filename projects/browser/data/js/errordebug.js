if (typeof Duktape !== 'object') {
    print('not Duktape');
} else if (Duktape.version >= 20403) {
    print('Duktape 2.4.3 or higher');
} else if (Duktape.version >= 10500) {
    print('Duktape 1.5.0 or higher (but lower than 2.4.3)');
} else {
    print('Duktape lower than 1.5.0');
}

function dumpDOM(elem, indent) {
    indent = indent || '';

    if (!elem) return;

    var nodeType = elem.nodeType;

    // Only print element nodes
    if (nodeType === 1) { // ELEMENT_NODE
        var tag = elem.tagName.toLowerCase();
        var id = elem.id ? "#" + elem.id : "";
        var classes = elem.className ? "." + elem.className.split(/\s+/).join('.') : '';
        print(indent + '<' + tag + id + classes + '>');

        var children = elem.childNodes;
        for (var i = 0; i < children.length; i++) {
            dumpDOM(children[i], indent + '  ');
        }

        print(indent + '</' + tag + '>');
    } else if (nodeType === 3) { // TEXT_NODE
        var text = elem.nodeValue.trim();
        if (text) {
            print(indent + text);
        }
    }
}