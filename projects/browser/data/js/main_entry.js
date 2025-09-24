
var testfiles =[ 
    // 'projects/browser/data/html/sample01.html',
    // 'projects/browser/data/html/tests/01-simple-document.html',
    // 'projects/browser/data/html/tests/02-inline-vs-block.html',
    // 'projects/browser/data/html/tests/03-attributes-quoting.html',
    'projects/browser/data/html/tests/04-classes-and-ids.html',
    // 'projects/browser/data/html/tests/05-css-basic-style.html',
    // 'projects/browser/data/html/tests/06-lists-nesting.html',
    // 'projects/browser/data/html/tests/07-whitespace-handling.html',
    // 'projects/browser/data/html/tests/08-forms-basic.html',
    // 'projects/browser/data/html/tests/09-images-links.html',
    // 'projects/browser/data/html/tests/10-text-formatting.html'
];

// example: 'projects/browser/data/html/sample01.html'
function runHtmlDoc( filename ) {

    // Loading html from JS - generates DOM in Luajit in HTMLtoDOM
    $.get(filename, function(err, status, xhr) {
        // print(status);
        // print(xhr.responseText);

        if (status != "success") {
            print_error("Failed to load file:" + filename + " Status:" +  status);
            return;
        }
        if (!xhr || !xhr.responseText) {
            print_error("Empty or invalid response for file:" + filename);
            return;
        }
    
        var html = xhr.responseText.trim();
        if (html.length === 0) {
            print_warn("HTML content is empty for file:" + filename);
            return;
        }

        // Clear document!
        defaultDocument();

        // Returns a dom document which can be tested/interrogated.
        //   The main document is set via this. However partial document 
        //   updates and changes should be possible.
        var doc = HTMLtoDOM(xhr.responseText, document);
                
        // doc = DOMClean(doc);
        // print(JSON.stringify(doc));

        // TODO: This may be useful for large scale DOM injection. 
        // lj_loaddom(CBOR.encode(doc));
        lj_renderdom()
    });		
}


var timecount = 1000.0;
var currtest = 0;
   
var intervalId = setInterval(function() {
    if(currtest > testfiles.length -1 ) {
        clearInterval(intervalId);
        return;
    }
    else {
        var testfile = testfiles[currtest];
        print( "Rendering test file: " + testfile);
        runHtmlDoc( testfile );
        currtest += 1;
    }
}, timecount );
