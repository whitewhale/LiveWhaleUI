$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.multiselect_beta',
  # default options
  options: {
    name:      'name',
    data:      [],
    type:      'items',
    selected:  [],
    onlyone:   false
  },
  _create: ->
    $el  = @element
    that = this
    opts = this.options
    items = ''
    sel_lookup = {}

    # add the widget classes 
    $el.addClass("lw-multiselect lw-multiselect-#{ opts.type }")

    # append ul
    @$ul = $ul = $('<ul/>').appendTo($el)

    # make lookup table from opts.selected
    $.each opts.selected, (i, val) ->
      sel_lookup[val.id] = true

    # add items
    $.each opts.data, (index, item) ->
      li = """ 
        <li class="lw-item">
          <input type="checkbox" value="#{ item.id }" name="#{ opts.name }[]" />
          <span class="lw-name">#{ item.title }</span>
        </li>
        """
      $li = $(li).data('item', item).appendTo($ul)

      # add locked class if locked
      if (item.is_locked) then $li.addClass('lw-locked')

      # highlight if id in selected lookup table 
      if (sel_lookup[item.id]?)
        $li.addClass('lw-selected').find('input').prop('checked', true)

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
  # remove lock class from all lis 
  unlockAll: ->
    @$ul.children().removeClass('lw-locked')
  # add lock class to all lis 
  lockAll: ->
    @$ul.children().addClass('lw=locked')
  selectItem: ($li) ->
    $li.addClass('lw-selected').find('input').prop('checked', true)
    @_triggerChange()
    return this
  deselectItem: ($li) ->
    $li.removeClass('lw-selected').find('input').prop('checked', false)
    @_triggerChange()
    return this
  _triggerChange: ->
    selected = []
    @$ul.children('.lw-selected').each (index, item) ->
      selected.push( $(item).data('item') )
    @_trigger('change', null, { selected: selected })
  selectAll: ->
    @$ul.find('input').prop('checked', true)
    @$ul.children().addClass('lw-selected')
  deselectAll: ->
    @$ul.find('input').prop('checked', false)
    @$ul.children().removeClass('lw-selected')
  resetSelection: ->
    @selectNone()
    @_highlightSelected()
  _setOption: $.noop,
  _destroy: ->
    @element
      .removeClass("lw-multiselect")
      .removeClass("lw-multiselect-#{ @options.type }")
      .off 'click', '.lw-item'
    @$ul.remove()
