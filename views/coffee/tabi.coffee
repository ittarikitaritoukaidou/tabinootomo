Tabi =
  getPageId: ->
    $('body').attr('data-page-id')
  doHandler: ->
    f = Tabi.Handlers[Tabi.getPageId()]
    do f if f
  Handlers:
    index: ->
      console.log '旅'

    tabi_edit: ->
      $('ul.js-sortable').sortable(
        handle: '.js-handle'
      )

    activity_edit: ->
      center = new google.maps.LatLng(35, 135)
      options =
        center: center
        zoom: 4
        mapTypeId: google.maps.MapTypeId.ROADMAP
      map = new google.maps.Map($('.js-map')[0], options)

      $address_input = $('.js-address-input')
      autocomplete = new google.maps.places.Autocomplete($address_input[0])
      autocomplete.bindTo('bounds', map)

      marker = new google.maps.Marker(
        map: map,
        anchorPoint: new google.maps.Point(0, -29)
      )

      google.maps.event.addListener autocomplete, 'place_changed', ->
        place = autocomplete.getPlace()

        return unless place?.geometry?.viewport || place?.geometry?.location

        if place.geometry.viewport
          map.fitBounds place.geometry.viewport
        else
          map.setCenter place.geometry.location
          map.setZoom 15

        marker.setPosition place.geometry.location
$ ->
  Tabi.doHandler()
  console.log '旅'
