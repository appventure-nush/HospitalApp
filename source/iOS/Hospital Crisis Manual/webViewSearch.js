var webView_SearchResultCount = 0;

/*!
 @method     webView_HighlightAllOccurencesOfStringForElement
 @abstract   // helper function, recursively searches in elements and their child nodes
 @discussion // helper function, recursively searches in elements and their child nodes

 element    - HTML elements
 keyword    - string to search
 */

function webView_HighlightAllOccurencesOfStringForElement(element,keyword) {
    if (element) {
        if (element.nodeType == 3) {        // Text node

            var count = 0;
            var elementTmp = element;
            while (true) {
                var value = elementTmp.nodeValue;  // Search for keyword in text node
                var idx = value.toLowerCase().indexOf(keyword);

                if (idx < 0) break;

                count++;
                elementTmp = document.createTextNode(value.substr(idx+keyword.length));
            }

            webView_SearchResultCount += count;

            var index = webView_SearchResultCount;
            while (true) {
                var value = element.nodeValue;  // Search for keyword in text node
                var idx = value.toLowerCase().indexOf(keyword);

                if (idx < 0) break;             // not found, abort

                //we create a SPAN element for every parts of matched keywords
                var span = document.createElement("span");
                var text = document.createTextNode(value.substr(idx,keyword.length));
                span.appendChild(text);

                span.setAttribute("class","webViewHighlight");
                span.style.backgroundColor="yellow";
                span.style.color="black";

                index--;
                span.setAttribute("id", "SEARCH_WORD_ID"+(index));

                text = document.createTextNode(value.substr(idx+keyword.length));
                element.deleteData(idx, value.length - idx);

                var next = element.nextSibling;
                element.parentNode.insertBefore(span, next);
                element.parentNode.insertBefore(text, next);
                element = text;
            }


        } else if (element.nodeType == 1) { // Element node
            if (element.style.display != "none" && element.nodeName.toLowerCase() != 'select') {
                for (var i=element.childNodes.length-1; i>=0; i--) {
                    webView_HighlightAllOccurencesOfStringForElement(element.childNodes[i],keyword);
                }
            }
        }
    }
}

// the main entry point to start the search
function webView_HighlightAllOccurencesOfString(keyword) {
    webView_RemoveAllHighlights();
    if (keyword !== null && keyword !== undefined && keyword != "") {
        webView_HighlightAllOccurencesOfStringForElement(document.body, keyword.toLowerCase());
    }
}

// helper function, recursively removes the highlights in elements and their childs
function webView_RemoveAllHighlightsForElement(element) {
    if (element) {
        if (element.nodeType == 1) {
            if (element.getAttribute("class") == "webViewHighlight") {
                var text = element.removeChild(element.firstChild);
                element.parentNode.insertBefore(text,element);
                element.parentNode.removeChild(element);
                return true;
            } else {
                var normalize = false;
                for (var i=element.childNodes.length-1; i>=0; i--) {
                    if (webView_RemoveAllHighlightsForElement(element.childNodes[i])) {
                        normalize = true;
                    }
                }
                if (normalize) {
                    element.normalize();
                }
            }
        }
    }
    return false;
}

// the main entry point to remove the highlights
function webView_RemoveAllHighlights() {
    webView_SearchResultCount = 0;
    webView_RemoveAllHighlightsForElement(document.body);
}

function webView_ScrollToSearch(idx) {
    var ele = document.getElementById("SEARCH_WORD_ID" + (webView_SearchResultCount - idx - 1));
    if (ele) ele.scrollIntoView();
}
