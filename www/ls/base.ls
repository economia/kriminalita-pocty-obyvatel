tooltip = new Tooltip!
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
fields = <[prepadeni_old prepadeni_new drogy_old drogy_new kradeze_old kradeze_new]>
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
west = 14.224
north = 50.177
east = 14.707
projection = d3.geo.mercator!
    ..scale 90 / (Math.PI * 2 * (Math.abs west - east) / 360)
    ..center [west, north]
    ..translate [0 0]

path = d3.geo.path!
    ..projection projection

for field in fields
    max = d3.max values_assoc[field]
    scales[field] = d3.scale.linear!
        ..domain [0, max * 0.125, max * 0.25, max * 0.375, max * 0.5, max * 0.625, max * 0.75, max * 0.875, max]
        ..range <[#FFFFCC #FFEDA0 #FED976 #FEB24C #FD8D3C #FC4E2A #E31A1C #BD0026 #800026]>

(err, topo)<~ d3.json "../data/rajony.topo.json"

field_to_use = "kradeze_new"
scale = null
geojson = topojson.feature topo, topo.objects.rajony

layerStyler = (feature, field = field_to_use) ->
    weight = 1
    value = if indexy_assoc[feature.properties.mop_id]
        indexy_assoc[feature.properties.mop_id][field]
    else
        0
    color = \#222
    fillColor = scales[field] value
    fillOpacity = 0.6
    opacity = 1
    {weight, fillColor, color, fillOpacity, opacity}

d3.select \ul#selector .selectAll \li
    .data fields
    .enter!append \li
        ..attr \class -> it
        ..classed \active -> it == field_to_use
        ..append \span
            ..html -> switch it
                | \prepadeni_old => "Přepadení<br />starý index"
                | \prepadeni_new => "Přepadení<br />nový index"
                | \drogy_old     => "Drogy<br />starý index"
                | \drogy_new     => "Drogy<br />nový index"
                | \kradeze_old   => "Krádeže<br />starý index"
                | \kradeze_new   => "Krádeže<br />nový index"
        ..on \click ->
            d3.selectAll 'ul#selector li' .classed \active no
            d3.select @ .classed \active yes
            changeField it
        ..append \svg
            ..attr \height 100
            ..attr \width 90
            ..selectAll \path
                .data geojson.features
                .enter!append \path
                    ..attr \d path
                    ..attr \fill (feature, index, parentIndex) ->
                        field = fields[parentIndex]
                        {fillColor} = layerStyler feature, field
                        fillColor
                    ..attr \stroke \black
                    ..attr \stroke-opacity 0.1
                    ..attr \stroke-width 1


changeField = (field) ->
    field_to_use := field
    rajonyLayer.setStyle layerStyler

rajonyLayer = L.geoJson do
    *   geojson
    *   style: layerStyler
        onEachFeature: (feature, layer) ->
            layer.on \mouseover ->
                index = indexy_assoc[feature.properties.mop_id]
                str = if index
                    "<b>#{index.nazev}:</b> #{index[field_to_use].toFixed 2}SD"
                else
                    "Bohužel pro tuto služebnu nemáme k dispozici data"
                tooltip.display str
            layer.on \mouseout -> tooltip.hide!
rajonyLayer.addTo map
