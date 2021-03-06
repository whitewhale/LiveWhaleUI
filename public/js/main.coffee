$ = livewhale.jQuery

page =
  timepicker:
    init: ->
      $picker = $('#picker').timepicker()
      $('#format_toggle').click (e) ->
        e.preventDefault()
        show24 = if ($picker.timepicker('option', 'show24Hours')) then false else true
        format = $picker.timepicker 'option', 'show24Hours', show24
        return true
      return
  overlay:
    init: ->
      $overlay = $('#overlay_content').overlay
        autoOpen: false
        destroyOnClose: false
        closeOnBodyClick: true
        title: 'Overlay Example'
        footer: 'Overlay Footer'

      $('#overlay_open').click ->
        $overlay.overlay('open')
        return true

      $('#change_width').change ->
        $overlay.overlay('option', 'size', $(this).val())
        return true
      return
  hoverbox:
    init: ->
      $('.open_top').hoverbox
        position: 'top'
        html: '<p>Hello World!</p>'

      $('.open_bottom').hoverbox
        position: 'bottom'
        html: '<p>Hello Worlds!  Like you know who you are.  Saturn, Venus, Mar, Jupiter, Et al.</p>'
      
      $('.open_left').hoverbox
        position: 'left'
        html: '<p>Hello Worlds!  Like you know who you are.  Saturn, Venus, Mar, Jupiter, Et al.</p>'
      
      $right = $('.open_right').hoverbox
        position: 'right'
        html: '<p>Hello World!</p>'

      $('#delegation_links').on 'click', 'a', (e) ->
        e.preventDefault()
        $target = $(e.target)

        # return if the plugin is attached to this element i
        # this allows plugin to close currrently open hoverbox
        if ($target.hasClass('lwui-widget')) then return true
        
        e.stopPropagation()

        $target.hoverbox
          autoOpen: true
          beforeOpen: ->
            # close any open hoverbox
            $('body').click()
            $this = $(this)
            $this.hoverbox('html', $this.attr('data-text'))
          close: ->
            $(this).hoverbox('destroy')
  slideshow:
    init: ->
      initSlideshows = ->
        $('.slideshow_top').slideshow(
          controlPlacement: 'prepend'
          continuousScroll: true
        )
        $('.slideshow_bottom').slideshow()

      initSlideshows()
  multiselect:
    init: ->
      $('#multiselect_menu').multiselect(
        name: 'example'
        data: [
          { id: 1, title: 'Item 1' }
          { id: 2, title: 'Item 2' }
          { id: 3, title: 'Item 3' }
          { id: 4, title: 'Item 4' }
          { id: 5, title: 'Item 5' }
        ]
        selected: [
          { id: 2, title: 'empty' }
          { id: 4, title: 'empty2' }
        ]
      )

      $('#multiselect_menu_single').multiselect(
        name: 'example'
        onlyone: true
        selected: [
          { id: 2, title: 'Item 2' }
        ]
        data: [
          { id: 1, title: 'Item 1' }
          { id: 2, title: 'Item 2' }
          { id: 3, title: 'Item 3' }
          { id: 4, title: 'Item 4' }
          { id: 5, title: 'Item 5' }
        ]
      )

      $('.select_form').submit (e) ->
        e.preventDefault()
        selected = []

        $(this).find('.lw-item input').each ->
          $this = $(this)
          if $this.prop('checked') then selected.push $this.val()
        
        if (selected.length)
          msg = 'Item'
          if (selected.length > 1) then msg += 's'
          alert(msg + ' ' + selected.join(', ') + ' selected')
        else
          alert('No items selected')
        return true
      return true
  multisuggest:
    init: ->
      $('#multisuggest_field').multisuggest(
        create: true
        data: [
          { id: 1, title: 'Item 1', size: '1.5' }
          { id: 2, title: 'Item 2' }
          { id: 3, title: 'Item 3' }
          { id: 4, title: 'Item 4', size: '1.5' }
          { id: 5, title: 'Item 5' }
          { id: 6, title: 'Item 6' }
        ]
      )
      return true


# init page code
# each page should have a body id that matches a key in page object 
body_id = $('body').attr('id')
if (page[body_id])
  $tabs = $('.nav-tabs a')
  tab_selected = false

  if (location.hash)
    $tabs.each ->
      if (location.hash is $(this).attr('href'))
        $(this).tab('show')
        tab_selected = true
        return false

  if (!tab_selected) then $tabs.eq(0).tab('show')

  page[body_id].init()
