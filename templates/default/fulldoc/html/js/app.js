(function() {

var localStorage = {}, sessionStorage = {};
try { localStorage = window.localStorage; } catch (e) { }
try { sessionStorage = window.sessionStorage; } catch (e) { }

function createSourceLinks() {
    $('.method_details_list .source_code, .attr_details .source_code').
        before("<span class='showSource'>[<a href='#' class='toggleSource'>View source</a>]</span>");
    $('.toggleSource').toggle(function() {
       $(this).parent().nextAll('.source_code').slideDown(100);
       $(this).text("Hide source");
    },
    function() {
        $(this).parent().nextAll('.source_code').slideUp(100);
        $(this).text("View source");
    });
}

function createDefineLinks() {
    var tHeight = 0;
    $('.defines').after(" <a href='#' class='toggleDefines'>more...</a>");
    $('.toggleDefines').toggle(function() {
        tHeight = $(this).parent().prev().height();
        $(this).prev().css('display', 'inline');
        $(this).parent().prev().height($(this).parent().height());
        $(this).text("(less)");
    },
    function() {
        $(this).prev().hide();
        $(this).parent().prev().height(tHeight);
        $(this).text("more...");
    });
}

function createFullTreeLinks() {
    var tHeight = 0;
    $('.inheritanceTree').toggle(function() {
        tHeight = $(this).parent().prev().height();
        $(this).parent().toggleClass('showAll');
        $(this).text("(hide)");
        $(this).parent().prev().height($(this).parent().height());
    },
    function() {
        $(this).parent().toggleClass('showAll');
        $(this).parent().prev().height(tHeight);
        $(this).text("show all");
    });
}

function searchFrameButtons() {
  $('.full_list_link').click(function() {
    toggleSearchFrame(this, $(this).attr('href'));
    return false;
  });
  window.addEventListener('message', function(e) {
    if (e.data === 'navEscape') {
      $('#nav').slideUp(100);
      $('#search a').removeClass('active inactive');
      $(window).focus();
    }
  });

  $(window).resize(function() {
    if ($('#search:visible').length === 0) {
      $('#nav').removeAttr('style');
      $('#search a').removeClass('active inactive');
      $(window).focus();
    }
  });
}

function toggleSearchFrame(id, link) {
  var frame = $('#nav');
  $('#search a').removeClass('active').addClass('inactive');
  if (frame.attr('src') === link && frame.css('display') !== "none") {
    frame.slideUp(100);
    $('#search a').removeClass('active inactive');
  }
  else {
    $(id).addClass('active').removeClass('inactive');
    if (frame.attr('src') !== link) frame.attr('src', link);
    frame.slideDown(100);
  }
}

function linkSummaries() {
  $('.summary_signature').click(function() {
    document.location = $(this).find('a').attr('href');
  });
}

function summaryToggle() {
  $('.summary_toggle').click(function(e) {
    e.preventDefault();
    localStorage.summaryCollapsed = $(this).text();
    $('.summary_toggle').each(function() {
      $(this).text($(this).text() == "collapse" ? "expand" : "collapse");
      var next = $(this).parent().parent().nextAll('ul.summary').first();
      if (next.hasClass('compact')) {
        next.toggle();
        next.nextAll('ul.summary').first().toggle();
      }
      else if (next.hasClass('summary')) {
        var list = $('<ul class="summary compact" />');
        list.html(next.html());
        list.find('.summary_desc, .note').remove();
        list.find('a').each(function() {
          $(this).html($(this).find('strong').html());
          $(this).parent().html($(this)[0].outerHTML);
        });
        next.before(list);
        next.toggle();
      }
    });
    return false;
  });
  if (localStorage.summaryCollapsed == "collapse") {
    $('.summary_toggle').first().click();
  } else { localStorage.summaryCollapsed = "expand"; }
}

function constantSummaryToggle() {
  $('.constants_summary_toggle').click(function(e) {
    e.preventDefault();
    localStorage.summaryCollapsed = $(this).text();
    $('.constants_summary_toggle').each(function() {
      $(this).text($(this).text() == "collapse" ? "expand" : "collapse");
      var next = $(this).parent().parent().nextAll('dl.constants').first();
      if (next.hasClass('compact')) {
        next.toggle();
        next.nextAll('dl.constants').first().toggle();
      }
      else if (next.hasClass('constants')) {
        var list = $('<dl class="constants compact" />');
        list.html(next.html());
        list.find('dt').each(function() {
           $(this).addClass('summary_signature');
           $(this).text( $(this).text().split('=')[0]);
          if ($(this).has(".deprecated").length) {
             $(this).addClass('deprecated');
          };
        });
        // Add the value of the constant as "Tooltip" to the summary object
        list.find('pre.code').each(function() {
          console.log($(this).parent());
          var dt_element = $(this).parent().prev();
          var tooltip = $(this).text();
          if (dt_element.hasClass("deprecated")) {
             tooltip = 'Deprecated. ' + tooltip;
          };
          dt_element.attr('title', tooltip);
        });
        list.find('.docstring, .tags, dd').remove();
        next.before(list);
        next.toggle();
      }
    });
    return false;
  });
  if (localStorage.summaryCollapsed == "collapse") {
    $('.constants_summary_toggle').first().click();
  } else { localStorage.summaryCollapsed = "expand"; }
}

function mainFocus() {
  var hash = window.location.hash;
  if (hash !== '' && $(hash)[0]) {
    $(hash)[0].scrollIntoView();
  }

  setTimeout(function() { $('#main').focus(); }, 10);
}

function navigationChange() {
  // This works around the broken anchor navigation with the YARD template.
  window.onpopstate = function() {
    var hash = window.location.hash;
    if (hash !== '' && $(hash)[0]) {
      $(hash)[0].scrollIntoView();
    }
  };
}

function enableToggles() {
  // show/hide nested classes on toggle click
  $('.sidebar-links a.toggle').on('click', function(evt) {
    evt.stopPropagation();
    evt.preventDefault();
    $(this).parent().parent().toggleClass('collapsed');
    $(this).toggleClass('down');
    $(this).toggleClass('right');
  });

  $('.sidebar-button').on('click', function(evt) {
    evt.stopPropagation();
    evt.preventDefault();
    $('#app').toggleClass("sidebar-open");
  });
}

function enableHovers() {
  $('.dropdown-wrapper').hover(
    function() {
      $('.nav-dropdown').show();
    },
    function() {
      $('.nav-dropdown').hide();
    }
  );
}

function selectVersion() {
  if (document.location.pathname.startsWith("/openhab-jruby/5.2/")) {
    $(".version-button.stable").toggleClass("current");
  } else if (document.location.pathname.startsWith("/docs/") ||
    document.location.pathname.startsWith("/openhab-jruby/main/") ||
    document.location.protocol === "file:") {
    $(".version-button.main").toggleClass("current");
  }
}

var searchTimeout = null;
var searchCache = [];
var caseSensitiveMatch = false;
var ignoreKeyCodeMin = 8;
var ignoreKeyCodeMax = 46;
var commandKey = 91;

RegExp.escape = function(text) {
  return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
}

function populateSearchCacheClasses(classes) {
  var toRecurse = []

  classes.forEach(klass => {
    if (klass.hasOwnProperty("c")) {
      klass.c.forEach(child => {
        var parent;
        if (klass.hasOwnProperty("p")) {
          parent = klass.p + "::" + klass.n;
        } else {
          parent = klass.n;
        }
        child.p = parent;
        toRecurse.push(child);
      });
      delete klass["c"]
    }
    searchCache.push(klass)
  });

  if (toRecurse.length !== 0) {
    populateSearchCacheClasses(toRecurse);
  }
}

function populateSearchCache() {
  $.ajax(indexpath, { cache: true, dataType: "json" }).success(function(data) {
    populateSearchCacheClasses(data.classes);

    searchCache = searchCache.concat(data.methods);

    enableSearch();
    escapeShortcut();
    clickToHideSearch();
  });
}

function enableSearch() {
  $('.search-box').show();
  $('#search-input').keyup(function(event) {
    if (ignoredKeyPress(event)) return;
    if (this.value === "") {
      clearSearch();
    } else {
      performSearch(this.value);
    }
  });
}

function ignoredKeyPress(event) {
  if (
    (event.keyCode > ignoreKeyCodeMin && event.keyCode < ignoreKeyCodeMax) ||
    (event.keyCode == commandKey)
  ) {
    return true;
  } else {
    return false;
  }
}

function escapeShortcut() {
  $(document).keydown(function(evt) {
    if (evt.which == 27) {
      clearSearch();
    }
  });
}

function clickToHideSearch() {
  $(document).on("click", function (event) {
    var $trigger = $(".search-box");
    if ($trigger !== event.target && !$trigger.has(event.target).length) {
      clearSearch();
    }
  });
}

function clearSearchTimeout() {
  clearTimeout(searchTimeout);
  searchTimeout = null;
}

function clearSearch() {
  clearSearchTimeout();
  $('.search-results li').remove();
  $('.search-results').hide();
}

function performSearch(searchString) {
  clearSearchTimeout();
  $('.search-results li').remove();
  $('.search-results').show();
  partialSearch(searchString, 0);
}

function partialSearch(searchString, offset) {
  var i = null;
  var matchString = buildMatchString(searchString);
  var matchRegexp = new RegExp(matchString, caseSensitiveMatch ? "" : "i");
  var fullNameSearch = searchString.indexOf('::') !== -1;
  search_list = $(".search-results ul");

  for (i = offset; i < Math.min(offset + 50, searchCache.length); i++) {
    var item = searchCache[i];
    var searchName = fullNameSearch ? item.p + "::" + item.n : item.n;
    if (searchName.match(matchRegexp) !== null) {
      var href = base_url + item.u;
      html = "<li><div class='item'><span class='object_link'><a href='" + href + "' + title='" + item.p + "::" + item.n + "'>" + item.n + "</a></span>";
      if (item.hasOwnProperty("s")) {
        html += "&lt; " + item.s;
      }
      html += "\n<small class='search_info'>" + (item.p || "Top-level Namespace") + "</small></div></li>"

      search_list.append(html);
    }
  }
  if(i == searchCache.length) {
    searchDone();
  } else {
    searchTimeout = setTimeout(function() {
      partialSearch(searchString, i);
    }, 0);
  }
}

function searchDone() {
  searchTimeout = null;
  if ($('.search-results li').size() === 0) {
    $(".search-results ul").append("<li>No Results</li>");
  }
}

function buildMatchString(searchString) {
  caseSensitiveMatch = searchString.match(/[A-Z]/) != null;
  return RegExp.escape(searchString);
}

$(document).ready(function() {
  createSourceLinks();
  createDefineLinks();
  createFullTreeLinks();
  searchFrameButtons();
  linkSummaries();
  summaryToggle();
  constantSummaryToggle();
  mainFocus();
  navigationChange();
  enableToggles();
  enableHovers();
  selectVersion();
  populateSearchCache();
});

})();
