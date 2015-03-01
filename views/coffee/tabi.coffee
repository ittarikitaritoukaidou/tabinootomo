Tabi =
  getPageId: ->
    $('body').attr('data-page-id')
  doHandler: ->
    f = Tabi.Handlers[Tabi.getPageId()]
    do f if f

  Map:
    destroyPOI: ->
      google.maps.InfoWindow.prototype.set = ->
    latLngFromString: (str) ->
      return unless str
      center_string = str.split(',')
      return unless center_string.length == 2
      new google.maps.LatLng(center_string[0], center_string[1])
    mapFromCenter: ($map, center) ->
      options =
        center: center
        zoom: 14
        clickable: false
        draggable: false
        disableDefaultUI: true
        disableDoubleClickZoom: true

      map = new google.maps.Map($map[0], options)

      marker = new google.maps.Marker(
        map: map,
        anchorPoint: center
        clickable: false
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
      Tabi.Map.destroyPOI()
      show_map = ->
        $map_container = $('.js-map')
        return unless $map_container[0]
        center = Tabi.Map.latLngFromString($map_container.attr('data-location'))
        map = Tabi.Map.mapFromCenter($('.js-map'), center)

      show_map()
    activity_edit: ->
      $map = $('.js-map')

      Tabi.Map.destroyPOI()
      center = Tabi.Map.latLngFromString($('.js-location-input').val())
      unless center
        $map.hide()
        center = new google.maps.LatLng(35, 135)
      options =
        center: center
        zoom: 14
        mapTypeId: google.maps.MapTypeId.ROADMAP
        streetViewControl: false
        mapTypeControl: false
      map = new google.maps.Map($map[0], options)

      $address_input = $('.js-address-input')
      autocomplete = new google.maps.places.Autocomplete($address_input[0])
      autocomplete.bindTo('bounds', map)

      marker = new google.maps.Marker(
        map: map,
        anchorPoint: new google.maps.Point(0, -29)
        draggable: true
      )
      marker.setPosition center

      google.maps.event.addListener map, 'click', (event) ->
        console.log 'click!!'
        event.stop()

      google.maps.event.addListener marker, 'dragend', =>
        set_location marker.getPosition()

      set_location = (location) ->
        return unless location

        $map.show()
        map.setCenter location
        map.setZoom 14

        $('.js-location-input').val(location.toUrlValue())

        marker.setPosition location

      placeService = new google.maps.places.PlacesService(map)
      $('.js-search-form').on 'submit', ->
        text = $('.js-address-input').val()
        placeService.textSearch {query: text}, (res) ->
          return unless res[0]
          $('.js-address-input').val res[0].name
          set_location res[0].geometry?.location
        return false

      google.maps.event.addListener autocomplete, 'place_changed', ->
        place = autocomplete.getPlace()

        set_location place.geometry
$ ->
  Tabi.doHandler()
