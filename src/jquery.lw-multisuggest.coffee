$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.lw-multisuggest',
  options:
    name:      'name'
    data:      []
    type:      'items'
    create:    false
    selected:  []
    onlyone:   false
  _create: ->
    opts = @options
    $el  = @element

    toSpace = new RegExp(/[,\-_\s&\/\\]+/g)   # regexp for elements that should become spaces
    toRemove = new RegExp(/[^a-zA-Z 0-9]+/g)  # regexp for elements that should be removed

    $.each opts.data, ->
      this.keywords = this.title.toLowerCase().toLowerCase().replace('&amp;', 'and').replace(toSpace, ' ').replace(toRemove, '') + (this.keywords ? ' ' + this.keywords.toLowerCase().toLowerCase().replace('&amp;', 'and').replace(toSpace, ' ').replace(toRemove, '') : ''); # keyword for matching against

    var suggest = $('<div class="lw_multisuggest lw_multisuggest_' + s.type + (!(s.type === 'places' && livewhale.page === 'events_edit') ? ' lw_false_input' : ' lw_hidden') + '"><ul class="lw_multisuggest_suggestions"/></div>').appendTo(self),
    matches = s.data,
    lastquery = '',
    suggestions = suggest.find('.lw_multisuggest_suggestions'),
    hidesuggestions;

    input = $('<input type="text" class="lw_multisuggest_input"/>').appendTo(suggest);

    if (s.data.length) {
      var $show_link = $('<a class="lw_multisuggest_showall" href="#">' + (s.type === 'places' ? 'or ' : '') + 'Show all ' + s.type + '</a>').insertAfter(s.type !== 'places' ? suggest : $('#places_add_new')).click(function() {
        var all = $('<div id="lw_multisuggest_all"><h3>All ' + s.type + '</h3><input type="button" value="Use selected ' + s.type + '" id="lw_multisuggest_all_save"/><span class="lw_cancel">or <a href="#">cancel and close</a></span></div>'),
          items = $('<div id="lw_multisuggest_all_items"/>').insertAfter(all.find('h3')),
          selected = [];
        self.find('.lw_multisuggest_item:not(.lw_multisuggest_new) input').each(function() { # get selected items
          selected.push({
            id: $(this).val(),
            title: $.trim($(this).parent().text()),
            is_locked: $(this).parent().is('.lw_locked')
          });
        });
        items.multiselect({
          type: s.type,
          data: s.data,
          selected: selected,
          onlyone: s.onlyone
        });
        all.overlay({
          close: '.lw_cancel a'
        });
        $('#lw_multisuggest_all_save').click(function() {
          self.find('.lw_multisuggest_item:not(.lw_multisuggest_new)').remove();
          all.find('.lw_selected').each(function() {
            self.multisuggest('add', {
              title: $.trim($(this).text()),
              id: $(this).siblings('input').val(),
              is_locked: $(this).is('.lw_locked')
            });
          });
          if (!s.onlyone || selected.length < 1) {
            input.css('visibility', 'visible').focus().keyup();
          }
          all.overlay('remove');
        });
        return false;
      });

      # add message to separate with commas if not places
      if (s.type === 'tags') {
        $('<p/>').addClass('lw_multisuggest_help').text('Separate ' + s.type + ' with commas').insertAfter($show_link);
      }
    }

    self.on('click', '.lw_multisuggest', function() {
      $(this).find('.lw_multisuggest_item.lw_selected').removeClass('lw_selected'); # deselect any selected items
      if (s.onlyone && $('.lw_multisuggest_item').length >= 1) {
        return false; # only one is wanted, don't allow clicking in
      }

      input.css('visibility', 'visible').focus().keyup();
    }).on('click', '.lw_multisuggest_item', function() {
      $(this).addClass('lw_selected').siblings().removeClass('lw_selected');
      input.val('').css('visibility', 'visible').focus().css('visibility', 'hidden'); # it must be visible to focus it
      return false; # cancel bubbling
    }).on('click', '.lw_multisuggest_remove', function(e) {
      e.preventDefault();

      var $item = $(this).closest('.lw_multisuggest_item');

      # remove item if not locked
      if (!$item.is('.lw_locked')) {
        $item.remove();
        input.css('visibility', 'visible').show(0);
      }
      self.trigger('change'); # trigger the change event on the suggestor
      self.trigger('remove_multisuggest'); # trigger the change event on the suggestor
      return false; # cancel bubbling
    }).on('click', '.lw_multisuggest_suggestions li', function(e) {
      var id = $(this).find('input').val(),
        existing = self.find('.lw_multisuggest_item input[value=' + id + ']').parent();
      if (!existing.length) {
        self.multisuggest('add', {
          title: $.trim($(this).text()),
          id: id
        });

        if (!s.onlyone) {
          input.val('').focus();
        } else {
          input.val('').hide(0);
        }
      } else {
        existing.addClass('lw_selected');
        input.val('').focus().css('visibility', 'hidden');
      }
      return false; # cancel bubbling
    });

    # .blur() doesn't QUITE work here; that's why we have to have an annoying 200ms timeout
    input.blur(function() {
      self.find('.lw_multisuggest_item.lw_selected').removeClass('lw_selected');
      lastquery = '';
      hidesuggestions = setTimeout(function() { # after 200ms
        suggestions.hide(); # hide the suggestion popup (we can't hide it earlier, in case the user has clicked it)
        # We do the following inside the timer in case clicking on a suggestion has already selected a result
        if (input.val()) {
          var e = $.Event('keydown'); # create a fake keydown event
          e.which = 13; # in which the 'return' key is pressed
          input.trigger(e); # and trigger it
        }
      }, 200);
    })
    # on each keypress, filter the results
    .keyup(function(e) {
      var query = $.trim($(this).val().toLowerCase().replace(/[,\-\/\s]+/g, ' ').replace(/[^a-zA-Z 0-9\.]+/g, '')),
        # grab query, sanitize it // TODO COMPILE THESE REGEXPS
        subquery, results;
      if (query === lastquery) return; # do nothing if the query is unchanged
      suggestions.empty().hide(); # empty and hide the suggestions list
      if (query.indexOf(lastquery) !== 0 || !lastquery.length) { # if this query is NOT a subset of the last query, reinitialize the matches and search on all terms
        matches = s.data;
        subquery = query;
      } else subquery = query.substring(query.lastIndexOf(' ') + 1, query.length); # otherwise, since this query IS a subset of the last query, no need to search the last query's terms
      lastquery = query; # store the last query
      if (!query.length) return; # cancel here if the query is zero length
      $.each(subquery.split(' '), function() { # filter the result for each word in the query
        var search = this;
        results = $.grep(matches, function(item) {
          return (' ' + item.keywords).indexOf(' ' + search) >= 0;
        });
      });
      var query_exp = new RegExp('(\\b' + query.replace(/\s/g, '|\\b') + ')', 'ig'); # for highlighting the query terms
      if (results.length) {
        $.each(results, function(index, item) { # list the match, with highlighting
          suggestions.append('<li ' + (query === item.keywords ? 'class="lw_selected"' : '') + '><input type="hidden" value="' + item.id + '"/>' + (' ' + item.title).replace(query_exp, '<span class="lw_multisuggest_highlight">$1</span>') + '</li>');
        });
        var position = input.position();
        suggestions.css({
          left: position.left + 'px',
          top: position.top + 'px'
        }).show();
        if (!s.create) { # if creation is disabled
          suggestions.children().eq(0).addClass('lw_selected'); # force select the first item
        }
      }
    })

    # capture special keys on keydown
    .keydown(function(e) {
      var selected_item = self.find('.lw_multisuggest_item.lw_selected'); # selected item
      # First, handle the case of a selected item
      if (selected_item.length) {
        switch (e.which) {
        case 13:
          # enter/return
        case 32:
          # space
          e.preventDefault();
          var item = selected_item.find('.lw_item_name').text();
          selected_item.find('.lw_multisuggest_remove').trigger('click'); # remove the item
          input.val(item).keyup(); # and enter the item for editing
          break;
        case 37:
          # left arrow
          e.preventDefault();
          var prev = selected_item.removeClass('lw_selected').prev();
          if (prev.length) { # if there's a previous item
            prev.addClass('lw_selected'); # select it
            return; # and return
          }
          break;
        case 39:
          # right arrow
        case 9:
          # tab
          e.preventDefault();
          var next = selected_item.removeClass('lw_selected').next();
          if (next.is('.lw_multisuggest_item')) { # if the next item is selectable
            next.addClass('lw_selected'); # select it
            return; # and return
          }
          break;
        case 8:
          # del/backspace
          e.preventDefault();
          selected_item.find('.lw_multisuggest_remove').trigger('click');
          break;
        default:
          # any other key
          self.find('.lw_multisuggest_item.lw_selected').removeClass('lw_selected'); # deselect any selected items
          break;
        }
        input.css('visibility', 'visible'); # and show the input
        return;
      }

      # remove previous suggestions that were not selected this time
      var suggestall = function() {
        suggestions.empty();
        if (s.data.length) { # if there are items
          $.each(s.data, function(index, item) { # list all items
            suggestions.append('<li><input type="hidden" value="' + item.id + '"/>' + item.title + '</li>');
          });
          var position = input.position();
          suggestions.css({
            left: position.left + 'px',
            top: position.top + 'px'
          }).show();
        }
      };

      # Otherwise, handle the autocomplete
      switch (e.which) {
      case 38:
        # up arrow
        e.preventDefault();
        if (suggestions.is(':hidden')) suggestall(); # if there are no matches, show all matches
        var selected = suggestions.find('.lw_selected');
        var position;

        # if there's only one result and it's a match, don't let users deselect it
        if (selected.siblings().length === 0 && $.trim(input.val().toLowerCase()) === selected.find("span").text().toLowerCase()) {
          break;
        }

        selected.removeClass('lw_selected');

        if (selected.prev().length) {
          selected = selected.prev().addClass('lw_selected');
          position = selected.position().top;
          if (position < 0) {
            suggestions.scrollTop(suggestions.scrollTop() + position);
          }
        } else if (!selected.length) {
          selected = suggestions.show().find('li:last-child').addClass('lw_selected');
          position = (selected.position().top + selected.outerHeight()) - (suggestions.height() - suggestions.scrollTop());
          if (position > 0) {
            suggestions.scrollTop(position);
          }
        }
        break;
      case 40:
        # down arrow
        e.preventDefault();

        if (suggestions.is(':hidden')) suggestall(); # if there are no matches, show all matches
        selected = suggestions.find('.lw_selected');

        # if there's only one result and it's a match, don't let users deselect it
        if (selected.siblings().length === 0 && $.trim(input.val().toLowerCase()) === selected.find("span").text().toLowerCase()) {
          break;
        }

        selected.removeClass('lw_selected');
        if (selected.next().length) {
          selected = selected.next().addClass('lw_selected');
          position = (selected.position().top + selected.outerHeight()) - (suggestions.height() - suggestions.scrollTop());
          if (position > 0) {
            suggestions.scrollTop(position);
          }
        } else {
          suggestions.scrollTop(0);
          if (!selected.length) {
            selected = suggestions.children().eq(0).addClass('lw_selected');
          }
        }
        break;
      case 13:
        # enter/return
      case 44:
        # comma
      case 188:
        # comma again, some versions of jQuery return 188 for comma
      case 9:
        # tab
        if (e.which === 13) e.preventDefault(); # always prevent enter
        # disable adding item with comma if we're not editing tags
        if (s.type !== 'tags' && (e.which === 44 || e.which === 188)) {
          break;
        }

        selected = suggestions.find('.lw_selected');
        var existing = [];
        if (selected.length) {
          e.preventDefault();
          var id = selected.find('input').val(); # selected item id
          existing = self.find('.lw_multisuggest_item input[value=' + id + ']').parent();
          if (!existing.length) {
            self.multisuggest('add', {
              title: $.trim(selected.text()),
              id: id
            });
          }
        } else {
          if (!s.create) { # if there are no matches but creation is disabled
            return true;
          }
          var value = $.trim(input.val());
          if (value.length) {
            var lcvalue = value.toLowerCase();
            existing = self.find('.lw_multisuggest_item .lw_multisuggest_item_name').filter(function() {
              return $.trim($(this).text().toLowerCase()) === lcvalue; # match if the string matches the value
            }).parent();
            if (!existing.length) {
              e.preventDefault();
              self.multisuggest('new', value);
            }
          }
        }
        input.val('').keyup();
        suggestions.hide();
        if (existing.length) {
          existing.addClass('lw_selected');
          input.css('visibility', 'hidden');
        }
        break;
      case 37:
        # left arrow
      case 8:
        # del/backspace
        if (!$.trim(input.val()).length && input.siblings('.lw_multisuggest_item').length) { # if there's no input, but there are older suggestions
          e.preventDefault(); # cancel the keypress
          input.val('') # remove any spaces just in case
          .css('visibility', 'hidden') # hide the input
          .prev().addClass('lw_selected'); # and select the last item
          suggestions.empty().hide(); # hide suggestions
        }
        break;
      }
    });

    suggestions.scroll(function() { # when scrolling the suggestions
      clearTimeout(hidesuggestions); # don’t hide the suggestions list
      input.focus(); # and keep the focus in the input
    });
    if (s.selected.length) { # if we need to preselect
      $.each(s.selected, function() { # with each preselected tag
        if (this.id) { # if an existing tag
          self.multisuggest('add', this); # select it;
        } else { # otherwise
          self.multisuggest('new', this.title); # add it as a new tag
        }
      });
      if (s.onlyone && s.selected.length > 0) {
        input.css('visibility', 'hidden').blur();
      } # don't show input if onlyone is on and we have one
    }

  add: (value) ->
    input.before('<div class="lw_multisuggest_item' + (value.is_locked ? ' lw_locked' : '') + '"><input type="hidden"' + (!value.is_locked ? ' name="' + s.name + '[]"' : '') + ' value="' + value.id + '"><span class="lw_item_name">' + value.title + '</span><span class="lw_multisuggest_remove">×</span></div>');
    self.trigger('change.multisuggest'); # trigger the change event on the suggestor
  new: (value) ->
    item = $('<div class="lw_multisuggest_item lw_multisuggest_new"><span class="lw_multisuggest_item_name">' + value + '</span><span class="lw_multisuggest_remove">×</span></div>').insertBefore(input);
    $('<input type="hidden" name="' + s.name + '_added[]"/>').val($.trim(value)).prependTo(item);
    self.trigger('change.multisuggest'); # trigger the change event on the suggestor
