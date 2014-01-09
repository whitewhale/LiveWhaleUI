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

      $('#overlay_open').click ->
        $overlay.overlay('open')
        return true

      $('#change_width').change ->
        $overlay.overlay('option', 'width', $(this).val())
        return true
      return
  popover:
    init: ->
      $('.open_top').popover
        position: 'top'
        html: '<p>Hello World!</p>'

      $('.open_bottom').popover
        position: 'bottom'
        html: '<p>Hello World!</p>'
      
      $('.open_left').popover
        position: 'left'
        html: '<p>Hello World!</p>'
      
      $right = $('.open_right').popover
        position: 'right'
        html: '<p>Hello World!</p>'

      $('#delegation_links').on 'click', 'a', (e) ->
        e.preventDefault()
        $target = $(e.target)

        # return if the plugin is attached to this element i
        # this allows plugin to close currrently open popover
        if ($target.hasClass('lwui-widget')) then return true
        
        e.stopPropagation()

        $target.popover
          autoOpen: true
          beforeOpen: ->
            # close any open popovers
            $('body').click()
            $this = $(this)
            $this.popover('html', $this.attr('data-text'))
          close: ->
            $(this).popover('destroy')
  slideshow:
    init: ->
      initSlideshows = ->
        $('.slideshow_top').slideshow({ controlPlacement: 'prepend' })
        $('.slideshow_bottom').slideshow()

      initSlideshows()

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
