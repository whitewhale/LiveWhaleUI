$ = livewhale.jQuery || window.jQuery

$.widget 'lw.googlemaps',
  _create: ->
    @_markers = []

    @_map = new google.maps.Map $el.get(0),
      zoom: @options.zoom
      mapTypeId: google.maps.MapTypeId.ROADMAP
      scrollwheel: false
  # removes previous markers, and sets new marker and center 
  setLocation: (marker_title, latitude, longitude) ->
    @removeMarkers()
    @setCenter(latitude, longitude)
    @addMarker(marker_title, latitude, longitude)
  setCenter: (latitude, longitude) ->
    @_map.setCenter(new google.maps.LatLng(latitude, longitude))
    @_latitude = latitude
    @_longitude = longitude
  addMarker: (title, latitude, longitude) ->
    marker = new google.maps.Marker
      position: new google.maps.LatLng(latitude, longitude)
      map: this._map
      title: title
    @_markers.push(marker)
  removeMarkers: ->
    marker.setMap(null) for marker in this._markers
  _setOption: (key, value) ->
    # In jQuery UI 1.8, you have to manually invoke the _setOption method from the base widget
    $.Widget.prototype._setOption.apply(this, arguments);
