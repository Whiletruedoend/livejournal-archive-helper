// ==UserScript==
// @name         LiveJournal Archive Helper
// @namespace    Whiletruedoend
// @original-script https://gist.github.com/Whiletruedoend
// @original-script https://greasyfork.org/ru/scripts/461690-livejournal-comments-expander
// @version      1.0
// @description  Automatically moves all comments to one page and expands them
// @author       Whiletruedoend
// @match        https://*.livejournal.com/*
// @match        https://livejournal.com/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=livejournal.com
// @grant        none
// @license      GNU GPLv3
// ==/UserScript==

var pages_items = document.getElementsByClassName("comments-pages-items");
var pages_count = (pages_items.length > 0) ? pages_items[0].childElementCount-2:0;

var post = new URL(window.location.origin+window.location.pathname);

const queryString = window.location.search;
const urlParams = new URLSearchParams(queryString);

var doc_obj = Site.page["LJ_cmtinfo"];

async function clear_sidebar(doc){
    var sel = ''; // tmp var
    Array.from(doc.getElementsByClassName("sidebar")).forEach(el => el.remove());
	Array.from(doc.querySelectorAll(".s-nav-actions")).forEach(el => el.remove());
    Array.from(doc.querySelectorAll(".cookies-banner")).forEach(el => el.remove());
    Array.from(doc.querySelectorAll(".b-discoverytimes-container")).forEach(el => el.remove());
    Array.from(doc.querySelectorAll(".header")).forEach(el => el.remove());
    Array.from(doc.querySelectorAll(".s-header")).forEach(el => el.remove());
    sel = doc.querySelector('body');
    if (sel !== null) { sel.style.paddingTop = 0; }
    Array.from(doc.querySelectorAll(".s-header__nav")).forEach(el => el.remove());
    Array.from(doc.querySelectorAll(".video-autoplay-adv.js--autoplay-video")).forEach(el => el.remove());
    sel = doc.querySelector('.content-inner');
    if (sel !== null) { sel.style.marginLeft = 0; }
    sel = doc.querySelector('.content');
    if (sel !== null) { sel.style.paddingTop = 0; }
    Array.from(doc.querySelectorAll(".entry-title.entry-linkbar")).forEach(el => el.remove());
    sel = doc.querySelector('html-s2-no-adaptive.html-desktop');
    if (sel !== null) { sel.style.paddingBottom = 0; }
    Array.from(doc.querySelectorAll("footer")).forEach(el => el.remove());
}

async function run(doc){
    let promises = []
    for (let i = 2; i < pages_count+1; i++){
        promises.push(myAsyncFunction(post, i, doc));
    }

    Promise.all(promises).then((res) => expand(doc));
}

async function myAsyncFunction(post, i,doc) {
    try {
        post.searchParams.append('page', i);

        var url = await fetch(post);
        var res = await url.text();

        var side_doc = doc.createElement( 'html' );
        side_doc.innerHTML = res

		var scripts = side_doc.querySelectorAll("script[type='text/javascript']:not([async='']):not([src])")

		// without this the comments doesn't expand
		for (var s in scripts) {
			eval(scripts[s].innerHTML);
		}
		//eval(scripts[1].innerHTML); // 1 - bypassed number where located Site.page

		Object.assign(doc_obj,Site.page["LJ_cmtinfo"]);

        var side_comments = side_doc.getElementsByClassName("comment-wrap");
        var side_comments_length = side_comments.length;
        var current_comments = doc.getElementsByClassName("entry-comments-text");
        var last_index = current_comments[0].children.length-3 // skip rows with comments count & pages count

        for(var j = 0; j < side_comments_length; j++){
            current_comments[0].insertBefore(side_comments[0], current_comments[0].children[last_index+1+j]);
        }
    } catch (ex) { return ex; }
}

async function expand(doc){
	var comm_style_1 = doc.querySelectorAll('[id^="expand_"], [class^=" mdspost-comment-actions__item  mdspost-comment-actions__item--expandchilds   "]');

	if (comm_style_1.length > 0){
		for (var i in comm_style_1) {
			var elem_1 = comm_style_1[i].lastChild;
			if (elem_1 && elem_1.nodeName!="#text"){
				elem_1.click();
			}
		}
	} else {
        setTimeout(function() {
            var comm_style_2 = doc.querySelectorAll('[class^="b-pseudo"]');
            if (comm_style_2.length > 0){
                for (var j in comm_style_2) {
                    var elem_2 = comm_style_2[j];
                    var elem_2_child = elem_2.lastChild;
                    if (elem_2 && elem_2_child && elem_2_child.nodeValue=="Expand"){
                        elem_2.click();
                    }
                }
            }
        }, 2000);
    }
	doc.querySelectorAll('.lj-spoiler b a').forEach(el => el.click());
}

if (pages_count > 1){
    Array.from(document.getElementsByClassName("comments-pages")).forEach(el => el.remove());
}

// small fix for correct PDF background printing
var bgstyle = document.getElementsByTagName('body')[0].style;
bgstyle['webkitPrintColorAdjust'] = 'exact';
bgstyle['colorAdjust'] = 'exact';
//

clear_sidebar(document); // optional, for default template
run(document);