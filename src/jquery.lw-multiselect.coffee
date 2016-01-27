$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.multiselect',
  # default options
  options:
    name:      'name'
    data:      []
    type:      'items'
    selected:  []
    onlyone:   false
  _create: ->
    $el  = @element
    that = this
    opts = this.options
    items = ''

    # add the widget classes
    $el.addClass("lw-multiselect lw-multiselect-#{ opts.type }")

    # append ul
    @$ul = $ul = $('<ul/>').appendTo($el)

    # add items
    $.each opts.data, (index, item) ->
      li = """
        <li class="lw-item">
          <input type="checkbox" value="#{ item.id }" name="#{ opts.name }[]" />
          <span class="lw-name">#{ item.title }</span>
        </li>
        """
      $li = $(li).data('item', item).appendTo($ul)

      # add size
      if (item.size) then $li.css('font-size', item.size + 'em')

      # add locked class if locked
      if (item.is_locked) then $li.addClass('lw-locked')

      # add any custom classes
      if (item.custom_class) then $li.addClass(item.custom_class)

    @setSelected()

    # handle item click
    $el.on 'click', '.lw-item', (e) ->
      e.preventDefault()

      $this = $(this)

      # return right away if this item is locked
      return false if ($this.is('.lw-locked'))

      # highlight clicked and de-select others if opts.onlyone, otherwise toggle clicked
      if (opts.onlyone)
        that.deselectAll()
        that.selectItem($this)
      else
        if ($this.hasClass('lw-selected'))
          that.deselectItem($this)
        else
          that.selectItem($this)

      return true
  setSelected: ->
    selected = this.options.selected || [];
    sel_lookup = {}

    # make lookup table from opts.selected
    $.each selected, (i, val) ->
      sel_lookup[val.id] = true

    @$ul.children().each ->
      $li  = $(this)
      item = $li.data('item')

      # highlight if id in selected lookup table
      if (sel_lookup[item.id]?)
        $li.addClass('lw-selected').find('input').prop('checked', true)
      else
        $li.removeClass('lw-selected').find('input').prop('checked', false)
    return @
  getSelected: ->
    selected = []
    @$ul.children('.lw-selected').each (index, item) ->
      selected.push( $(item).data('item') )
    return selected
  # remove lock class from all lis
  unlockAll: ->
    @$ul.children().removeClass('lw-locked')
    return @
  # add lock class to all lis
  lockAll: ->
    @$ul.children().addClass('lw-locked')
    return @
  selectItem: ($li) ->
    $li.addClass('lw-selected').find('input').prop('checked', true)
    @_triggerChange(
      action: 'select'
      item: $li.data('item')
    )
    return @
  deselectItem: ($li) ->
    $li.removeClass('lw-selected').find('input').prop('checked', false)
    @_triggerChange(
      action: 'deselect'
      item: $li.data('item')
    )
    return @
  _triggerChange: (event_data) ->
    data = { selected: @getSelected() }
    if (event_data) then $.extend(data, event_data)
    @_trigger('change', null, data)
  selectAll: ->
    @$ul.find('input').prop('checked', true)
    @$ul.children().addClass('lw-selected')
    return @
  deselectAll: ->
    @$ul.find('input').prop('checked', false)
    @$ul.children().removeClass('lw-selected')
    return @
  resetSelection: ->
    @$ul.children().each ->
      $li = $(this)
      $input = $li.find('input')

      if ($input.prop('checked'))
        $li.addClass('lw-selected')
      else
        $li.removeClass('lw-selected')
    return @
  _setOption: (key, value) ->
    this._super( key, value )

    if (key is 'selected')
      @setSelected()
  _destroy: ->
    @element
      .removeClass("lw-multiselect")
      .removeClass("lw-multiselect-#{ @options.type }")
      .off 'click', '.lw-item'
    @$ul.remove()
