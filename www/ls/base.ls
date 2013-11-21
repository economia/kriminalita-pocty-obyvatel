map = L.map do
    *   'map'
    *   minZoom: 11,
        maxZoom: 14,
        zoom: 11,
        center: [50.0598, 14.465]
        maxBounds: [[50.239, 14.094], [49.896, 14.800]]

mapLayer = L.tileLayer do
    *   "http://ihned-mapy.s3.amazonaws.com/desaturized/{z}/{x}/{y}.png"
    *   zIndex: 1
        attribution: 'mapová data &copy; přispěvatelé OpenStreetMap, obrazový podkres <a target="_blank" href="http://ihned.cz">IHNED.cz</a>'

mapLayer.addTo map
fields = <[prepadeni_old prepadeni_new drogy_old drogy_new kradzeze_old kradeze_new]>
(err, indexy) <~ d3.csv "../data/indexy.csv", (row) ->
    for field in fields
        row[field] = parseFloat row[field]
    row
indexy_assoc = {}
values_assoc = {}
for index in indexy
    indexy_assoc[index.mop_id] = index
    for field in fields
        values_assoc[field] ?= []
        values_assoc[field].push index[field]
scales = {}
for field in fields
    max = d3.max values_assoc[field]
    scales[field] = d3.scale.linear!
        ..domain [0, max * 0.125, max * 0.25, max * 0.375, max * 0.5, max * 0.625, max * 0.75, max * 0.875, max]
        ..range <[#FFFFCC #FFEDA0 #FED976 #FEB24C #FD8D3C #FC4E2A #E31A1C #BD0026 #800026]>
(err, topo)<~ d3.json "../data/rajony.topo.json"

field_to_use = "prepadeni_new"
scale = null
geojson = topojson.feature topo, topo.objects.rajony

rajonyLayer = L.geoJson do
    *   geojson
    *   style: (feature) ->
            weight = 1
            value = if indexy_assoc[feature.properties.mop_id]
                indexy_assoc[feature.properties.mop_id][field_to_use]
            else
                0
            color = \#222
            fillColor = scales[field_to_use] value
            fillOpacity = 0.6
            opacity = 1
            {weight, fillColor, color, fillOpacity, opacity}
rajonyLayer.addTo map
