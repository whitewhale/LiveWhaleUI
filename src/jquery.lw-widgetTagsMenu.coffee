$.widget 'lw.widgetTagsMenu',
  _create: -> 
    that        = this
    args        = $.deparam.fragment()
    $el         = @element
    opts        = @options
    $all_tags   = $el.find('.lw_widget_all_tags')
    tags        = @getDecodedTagsFromHash()

    # the widget that the tags menu controls
    @$widget = $el.prev()
    @$el     = $el
    
    # widgets may be configured to only show items with certain tags 
    # the tags menu maintains that constraint.  the tagged_only 
    # flag indicates when it should be enforced 
    @tagged_only = $el.hasClass('lw_widget_tagged_only')

    # float any tags next to a parent widget
    @$widget
      .width(@$widget.width() - $el.width() - 40)
      .css('float', 'left')

    # hashchange event provided by bbq plugin
    $(window).bind 'hashchange', ->
      that.updateWidget.apply(that)

    # set proper widget state if tagsmenu set in hash
    if (tags.length)
      $el.find('.lw_widget_tag').each (i, el) -> 
        $a = $('a', el)
        if ($.inArray($a.text(), tags) is not -1)
          $a.addClass('lw_widget_tag_selected')

      that.updateWidget.apply(that)
    else
      $all_tags.addClass('lw_widget_all_tags_selected')

    $el.removeClass('lw_hidden')

    # activate tag selector
    $el.on 'click', '.lw_widget_tag a', (evt) ->
      $this = $(this)
      tags = []

      # toggle selected class
      $this.toggleClass('lw_widget_tag_selected')

      # toggle off all tags if any tags are selected
      if ($el.find('.lw_widget_tag_selected').length)
        $all_tags.removeClass('lw_widget_all_tags_selected')
      else
        $all_tags.addClass('lw_widget_all_tags_selected')

      # get selected tags
      $.each $el.find('.lw_widget_tag_selected'), (key, val) ->
        tags.push(encodeURIComponent($(this).html()))

      that.pushState(tags)

      return false

    # handler for All Tags link 
    $el.on('click', '.lw_widget_all_tags', ->
      $this = $(this)

      # return right away if already showing all tags
      if ($this.hasClass('lw_widget_all_tags_selected')) then return false

      that.selectAll(this)

      return false
    )
  selectAll: (btn) ->
    # toggle selected class
    $(btn).addClass('lw_widget_all_tags_selected')

    # deselect all tags
    $.each(@$el.find('.lw_widget_tag a'), ->
      $(this).removeClass('lw_widget_tag_selected')
    )
    @pushState([], 2)
  # tags should be an array of encoded tag names 
  pushState: (tags) ->
    state = $.deparam.fragment() || {}

    # add tags to @_tagmenu_key if tags, otherwise remove @_tagmenu_key
    if (tags.length)
      state[@_tagmenu_key] = tags.join(',')
    else
      delete state[@_tagmenu_key]

    $.bbq.pushState(state, 2)
  getTagsFromHash: ->
    hash = $.deparam.fragment()
    tags = []

    if (@_tagmenu_key in hash)
      tags = hash[@_tagmenu_key].split(',')

    return tags
  getDecodedTagsFromHash: ->
    tags = @getTagsFromHash()
    return (decodeURIComponent(tag) for tag in tags)
  # tags should be an array of encoded tag names 
  updateWidget: ->
    decoded_tags = @getDecodedTagsFromHash()
    syntax_args = 'show_tags': 'false'
    all_tags = []
    
    # if tags, then add them as args, else set as empty or all depending on tagged_only setting
    if (decoded_tags.length)
      syntax_args.tag_mode = 'any'
      syntax_args.tag = decoded_tags
    else
      # if no tags, and tagged_only mode
      if (@tagged_only)
        syntax_args.tag_mode = 'any'
        
        # get all tags
        $.each(@$el.find('.lw_widget_tag a'), ->
          all_tags.push($(this).text())
        )
        syntax_args.tag = all_tags
      else
        syntax_args.tag = ''

    @refreshWidget(syntax_args)

  # replaces this widget by querying server with widget syntax in arg
  refreshWidget: (args) ->
    $widget = @element.prev()
    syntax = @getSyntax($widget, args)

    # return right away if $widget is not a widget or no syntax
    if (!($widget.hasClass('lw_widget') && ($widget.hasClass('lw_widget_news') || $widget.hasClass('lw_widget_events') || $widget.hasClass('lw_widget_blurbs') || $widget.hasClass('lw_widget_files') || $widget.hasClass('lw_widget_forms') || $widget.hasClass('lw_widget_galleries') || $widget.hasClass('lw_widget_pages') || $widget.hasClass('lw_widget_profiles')) && syntax))
      return false

    # fade out current results
    $widget.fadeTo 'fast', 0.1, -> 
      $widget.css('opacity', 0) # set opacity to 0
      url = livewhale.liveurl_dir + '/widget/preview/news/?syntax=' + encodeURIComponent(syntax)

      # swap in new widget
      $.get url, (result) ->
        # insert placeholder element
        placeholder = $('<div class="lw_placeholder"></div>').insertBefore($widget)
        $widget.replaceWith(result) # replace widget
        $widget = placeholder.next() # get new $widget
        placeholder.remove() # remove placeholder
        # if widget has a tag selector, re-float it next to the new widget
        if ($widget.next().hasClass('lw_widget_tags'))
          $widget.width($widget.width() - $widget.next().width() - 40).css('float', 'left')

        $widget.fadeIn('fast') # fade in new results

        # call paginate plugin if pagination
        if ($widget.find('.lw_paginate').length)
          $widget.paginate()
  # changes an existing widget's args
  getSyntax: ($widget, args) ->
    that = this

    return false if ($.isEmptyObject(args) || !$widget.find('.lw_widget_syntax').length)

    # get syntax
    syntax = $widget
      .find('.lw_widget_syntax')
        .attr('title')
        .replace(/&lt/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&amp;/g, '&')
        .replace(/&#34;/g, '"')

    # if syntax not empty 
    if (syntax)
      # remove all args being changed
      $.each args, (key, val) ->
        syntax = syntax.replace(new RegExp('<arg id="' + key + '">.*?</arg>', 'g'), '')

      # add all new args
      $.each args, (key, val) ->
        if ($.isArray(val))
          $.each val, (key2, val2) ->
            if (val2 isnt '')
              syntax = syntax.replace('</widget>', '<arg id="' + key + '">' + val2 + '</arg>' + '</widget>')
        else if (val isnt '')
          syntax = syntax.replace('</widget>', '<arg id="' + key + '">' + val + '</arg>' + '</widget>')

    return syntax
  _setOption: (key, value) ->
    # In jQuery UI 1.8, you have to manually invoke the _setOption method from the base widget
    $.Widget.prototype._setOption.apply(this, arguments)
