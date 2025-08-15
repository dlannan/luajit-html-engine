
// Full DOM export as CBOR
function exportDomAsCbor() {
    var struct = document.documentElement;
    return CBOR.encode(struct); // Uint8Array
}

// Partial export (by CSS selector)
function exportNodeAsCbor(selector) {
    var node = document.querySelector(selector);
    if (!node) return null;
    return CBOR.encode(node);
}

function loadHtmlAndPush(url) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4 && xhr.status === 200) {
            document.body.innerHTML = xhr.responseText;

            // After loading, export DOM to CBOR
            var buf = exportDomAsCbor();
            lj_loaddom(buf); // This calls your LuaJIT C binding
        }
    };
    xhr.open("GET", url, true);
    xhr.send();
}
