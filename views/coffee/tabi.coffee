Tabi =
  getPageId: ->
    $('body').attr('data-page-id')
  doHandler: ->
    f = Tabi.Handlers[Tabi.getPageId()]
    do f if f

  Map:
    destroyPOI: ->
      set = google.maps.InfoWindow::set

      google.maps.InfoWindow::set = (key, val) ->
        if key == 'map'
          if !@get('noSupress')
            return
        set.apply this, arguments

    latLngFromString: (str) ->
      return unless str
      center_string = str.split(',')
      return unless center_string.length == 2
      new google.maps.LatLng(center_string[0], center_string[1])

    showMap: ->
      $map_container = $('.js-map')
      Tabi.Map.mapFromLocations($map_container, Tabi.Map.collectLocations())

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
        icon: '/images/marker.svg'
        animation: google.maps.Animation.BOUNCE
        cursor: 'normal'
      )
      marker.setPosition center

      map

    collectLocations: ->
      locations = []
      $('.js-activity').each ->
        l = $(this).attr('data-location')
        if l
          l = Tabi.Map.latLngFromString(l)
          title = $(this).attr('data-title')
          url = $(this).attr('data-url')
          locations.push
            center: l
            title: title
            url: url
      locations

    mapFromLocations: ($map, locations) ->
      options =
        zoom: 14
        disableDefaultUI: true
        clickable: false
        draggable: false
        disableDefaultUI: true
        disableDoubleClickZoom: true

      map = new google.maps.Map($map[0], options)

      bounds = new google.maps.LatLngBounds

      prevCenter = null
      _.each locations, (l) ->
        center = l.center
        title = l.title
        url = l.url
        bounds.extend center

        marker = new google.maps.Marker
          map: map
          anchorPoint: center
          title: title
          zIndex: 10
          icon: '/images/marker.svg'
          animation: google.maps.Animation.BOUNCE

        google.maps.event.addListener marker, 'click', ->
          new google.maps.InfoWindow(
            content: '<a href="' + url + '">' + title + '</a>'
            noSupress: true
        ).open(marker.getMap(), marker)

        marker.setPosition center

        if prevCenter
          lineSymbol = path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW
          lineCoordinates = [ prevCenter, marker.getPosition() ]
          line = new google.maps.Polyline(
            path: lineCoordinates
            icons: [ {
              icon: lineSymbol
              offset: '100%'
            } ]
            strokeColor: '#FFA466'
            zIndex: 20
            map: map)

          params =
            saddr: prevCenter.toUrlValue()
            daddr: marker.getPosition().toUrlValue()
          route = 'https://www.google.co.jp/maps?' + $.param params
          google.maps.event.addListener line, 'click', ->
            window.open route

        prevCenter = marker.getPosition()

      if locations.length > 1
        map.fitBounds bounds
      else if locations.length > 0
        map.setCenter(locations[0].center)
        map.setZoom(14)
      else
        kyoto = Tabi.Map.latLngFromString('40,135.5')
        map.setCenter(kyoto)
        map.setZoom(4)
        google.maps.event.trigger(map, 'resize')

      map

    # 見つかったら，locationを返す
    searchLocation: (map, text) ->
      found = $.Deferred()
      placeService = new google.maps.places.PlacesService(map)
      query =
        # location: map.getCenter()
        # radius: 10*1000
        query: text

      placeService.textSearch query, (res) ->
        location = res[0]?.geometry?.location
        if location
          found.resolve location
        else
          found.reject()

      found.promise()

  Handlers:
    index: ->
      console.log '旅'

    tabi: ->
      Tabi.Map.destroyPOI()

      map = Tabi.Map.showMap()

      submit_by_values = (title, location) ->
        $form = $('.js-hidden-append-new-activity-form')
        $form.find('input[name="title"]').val(title)
        $form.find('input[name="location"]').val(location)
        $form[0].submit()

      $form = $('.js-append-new-activity-form')
      $submit = $form.find('input[type="submit"]')
      $form.on 'submit', ->
        $submit.attr('disabled', true)
        $form.find('input[type="submit"]').attr('disabled', true)
        title = $form.find('input[name="title"]').val()

        Tabi.Map.searchLocation(map, title).done (location) ->
          submit_by_values(title, location.toUrlValue())
        .fail ->
          submit_by_values(title, null)
        .always ->
          $submit.attr('disabled', false)

        false

      setup_select = ->
        $('.js-copy-url').on 'click', ->
          @setSelectionRange(0, 9999)

      setup_select()

    tabi_edit: ->
      Tabi.Map.showMap()

      $('ul.js-sortable').sortable
        axis: 'y'
        handle: '.js-handle'
        update: ->
          Tabi.Map.showMap()

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
      $delete_location = $('.js-delete-location')

      Tabi.Map.destroyPOI()
      center = Tabi.Map.latLngFromString($('.js-location-input').val())
      if center
        $map.show()
      else
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
        icon: '/images/marker.svg'
        animation: google.maps.Animation.BOUNCE
      )
      marker.setPosition center

      google.maps.event.addListener marker, 'dragend', =>
        set_location marker.getPosition()

      set_location = (location) ->
        return unless location

        $map.show()
        google.maps.event.trigger(map, 'resize')
        map.setCenter location
        map.setZoom 14

        $('.js-location-input').val(location.toUrlValue())

        marker.setPosition location
        $delete_location.show()

      delete_location = ->
        $map.hide()
        $address_input.val('')
        $('.js-location-input').val('')
        $delete_location.hide()

      $delete_location.on 'click', delete_location

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
        l = place?.geometry?.location
        set_location l if l
$ ->
  Tabi.doHandler()
