(function() {
  var $, $tabs, body_id, page, tab_selected;

  $ = livewhale.jQuery;

  page = {
    timepicker: {
      init: function() {
        var $picker;
        $picker = $('#picker').timepicker();
        $('#format_toggle').click(function(e) {
          var format, show24;
          e.preventDefault();
          show24 = $picker.timepicker('option', 'show24Hours') ? false : true;
          format = $picker.timepicker('option', 'show24Hours', show24);
          return true;
        });
      }
    },
    overlay: {
      init: function() {
        var $overlay;
        $overlay = $('#overlay_content').overlay({
          autoOpen: false,
          destroyOnClose: false,
          closeOnBodyClick: true,
          title: 'Overlay Example',
          footer: 'Overlay Footer'
        });
        $('#overlay_open').click(function() {
          $overlay.overlay('open');
          return true;
        });
        $('#change_width').change(function() {
          $overlay.overlay('option', 'size', $(this).val());
          return true;
        });
      }
    },
    hoverbox: {
      init: function() {
        var $right;
        $('.open_top').hoverbox({
          position: 'top',
          html: '<p>Hello World!</p>'
        });
        $('.open_bottom').hoverbox({
          position: 'bottom',
          html: '<p>Hello World!</p>'
        });
        $('.open_left').hoverbox({
          position: 'left',
          html: '<p>Hello World!</p>'
        });
        $right = $('.open_right').hoverbox({
          position: 'right',
          html: '<p>Hello World!</p>'
        });
        return $('#delegation_links').on('click', 'a', function(e) {
          var $target;
          e.preventDefault();
          $target = $(e.target);
          if ($target.hasClass('lwui-widget')) {
            return true;
          }
          e.stopPropagation();
          return $target.hoverbox({
            autoOpen: true,
            beforeOpen: function() {
              var $this;
              $('body').click();
              $this = $(this);
              return $this.hoverbox('html', $this.attr('data-text'));
            },
            close: function() {
              return $(this).hoverbox('destroy');
            }
          });
        });
      }
    },
    slideshow: {
      init: function() {
        var initSlideshows;
        initSlideshows = function() {
          $('.slideshow_top').slideshow({
            controlPlacement: 'prepend',
            continuousScroll: true
          });
          return $('.slideshow_bottom').slideshow();
        };
        return initSlideshows();
      }
    },
    multiselect: {
      init: function() {
        $('#multiselect_menu').multiselect_beta({
          name: 'example',
          data: [
            {
              id: 1,
              title: 'Item 1'
            }, {
              id: 2,
              title: 'Item 2'
            }, {
              id: 3,
              title: 'Item 3'
            }, {
              id: 4,
              title: 'Item 4'
            }, {
              id: 5,
              title: 'Item 5'
            }
          ],
          selected: [
            {
              id: 2,
              title: 'empty'
            }, {
              id: 4,
              title: 'empty2'
            }
          ]
        });
        $('#multiselect_menu_single').multiselect_beta({
          name: 'example',
          onlyone: true,
          selected: [
            {
              id: 2,
              title: 'Item 2'
            }
          ],
          data: [
            {
              id: 1,
              title: 'Item 1'
            }, {
              id: 2,
              title: 'Item 2'
            }, {
              id: 3,
              title: 'Item 3'
            }, {
              id: 4,
              title: 'Item 4'
            }, {
              id: 5,
              title: 'Item 5'
            }
          ]
        });
        $('.select_form').submit(function(e) {
          var msg, selected;
          e.preventDefault();
          selected = [];
          $(this).find('.lw-item input').each(function() {
            var $this;
            $this = $(this);
            if ($this.prop('checked')) {
              return selected.push($this.val());
            }
          });
          if (selected.length) {
            msg = 'Item';
            if (selected.length > 1) {
              msg += 's';
            }
            alert(msg + ' ' + selected.join(', ') + ' selected');
          } else {
            alert('No items selected');
          }
          return true;
        });
        return true;
      }
    },
    multisuggest: {
      init: function() {
        $('#multisuggest_field').multisuggest({
          create: true,
          data: [
            {
              id: 1,
              title: 'Item 1'
            }, {
              id: 2,
              title: 'Item 2'
            }, {
              id: 3,
              title: 'Item 3'
            }, {
              id: 4,
              title: 'Item 4'
            }, {
              id: 5,
              title: 'Item 5'
            }, {
              id: 6,
              title: 'Item 6'
            }
          ]
        });
        return true;
      }
    }
  };

  body_id = $('body').attr('id');

  if (page[body_id]) {
    $tabs = $('.nav-tabs a');
    tab_selected = false;
    if (location.hash) {
      $tabs.each(function() {
        if (location.hash === $(this).attr('href')) {
          $(this).tab('show');
          tab_selected = true;
          return false;
        }
      });
    }
    if (!tab_selected) {
      $tabs.eq(0).tab('show');
    }
    page[body_id].init();
  }

}).call(this);
