Tabi =
  getPageId: ->
    $('body').attr('data-page-id')
  doHandler: ->
    f = Tabi.Handlers[Tabi.getPageId()]
    do f if f

  Map:
    latLngFromString: (str) ->
      return unless str
      center_string = str.split(',')
      return unless center_string.length == 2
      new google.maps.LatLng(center_string[0], center_string[1])
    mapFromCenter: ($map, center) ->
      options =
        center: center
        zoom: 4
      map = new google.maps.Map($map[0], options)

      marker = new google.maps.Marker(
        map: map,
        anchorPoint: center
      )
      marker.setPosition center

  Handlers:
    index: ->
      console.log '旅'

    tabi_edit: ->
      $('ul.js-sortable').sortable(
        handle: '.js-handle'
      )

    activity: ->
      show_map = ->
        $map_container = $('.js-map')
        return unless $map_container[0]
        center = Tabi.Map.latLngFromString($map_container.attr('data-location'))
        map = Tabi.Map.mapFromCenter($('.js-map'), center)

      show_map()
    activity_edit: ->
      $map = $('.js-map')

      center = Tabi.Map.latLngFromString($('.js-location-input').val())
      unless center
        $map.hide()
        center = new google.maps.LatLng(35, 135)
      options =
        center: center
        zoom: 4
        mapTypeId: google.maps.MapTypeId.ROADMAP
      map = new google.maps.Map($map[0], options)

      $address_input = $('.js-address-input')
      autocomplete = new google.maps.places.Autocomplete($address_input[0])
      autocomplete.bindTo('bounds', map)

      marker = new google.maps.Marker(
        map: map,
        anchorPoint: new google.maps.Point(0, -29)
      )
      marker.setPosition center

      set_geometry = (geometry) ->
        return unless geometry?.viewport || geometry?.location

        $map.show()
        if geometry.viewport
          map.fitBounds geometry.viewport
        else
          map.setCenter geometry.location
          map.setZoom 15

        $('.js-location-input').val(geometry.location.toUrlValue())

        marker.setPosition geometry.location

      placeService = new google.maps.places.PlacesService(map)
      $('.js-search-form').on 'submit', ->
        text = $('.js-address-input').val()
        placeService.textSearch {query: text}, (res) ->
          return unless res[0]
          $('.js-address-input').val res[0].name
          set_geometry res[0].geometry
        return false

      google.maps.event.addListener autocomplete, 'place_changed', ->
        place = autocomplete.getPlace()

        set_geometry place.geometry
$ ->
  Tabi.doHandler()
