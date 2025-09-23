
// Loading html from JS - generates DOM in Luajit in HTMLtoDOM
$.get('projects/browser/data/html/sample01.html', function(err, status, xhr) {
    print(status);
    //print(xhr.responseText);
    // Returns a dom document which can be tested/interrogated.
    //   The main document is set via this. However partial document 
    //   updates and changes should be possible.
    HTMLtoDOM(xhr.responseText, document);
    
    // doc = DOMClean(doc);
    // print(JSON.stringify(doc));

    // TODO: This may be useful for large scale DOM injection. 
    // lj_loaddom(CBOR.encode(doc));
});		
    