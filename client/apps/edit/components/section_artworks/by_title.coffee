# #
# # Artworks section that shows artwork images in various layouts. A user can
# # add artworks from urls or search via autocomplete.
# #

# _ = require 'underscore'
# Artworks = require '../../../../collections/artworks.coffee'
# React = require 'react'
# { div, label, input, ul, li, img } = React.DOM
# sd = require('sharify').data

# module.exports = React.createClass

#   setUpAutocomplete: ->
#     console.log "setUpAutocomplete"
#     Autocomplete = require '../../../../components/autocomplete/index.coffee'
#     new Autocomplete
#       url: "#{sd.ARTSY_URL}/api/v1/search?q=%QUERY"
#       el: $('#autocomplete-search-input input')
#       filter: (res) ->
#         for result in res
#           { id: result._id }

#   getInitialState: ->
#     @setUpAutocomplete()
#     console.log "getInitialState"
#     { loading: false, artworks: [], highlighted: 0 }

#   componentDidMount: ->
#     console.log "componentDidMount"
#     @debouncedSearch = _.debounce _.bind(@search, this), 500

#   onSearch: (e) ->
#     console.log "onSearch"
#     @debouncedSearch e.target.value

#   search: (q) ->
#     # @setUpAutocomplete()
#     # @setState loading: true
#     # new Artworks().fetch
#     #   data: q: q
#     #   success: (artworks) =>
#     #     @setState artworks: artworks.toJSON(), loading: false

#   onKeyUp: (e) ->
#     switch e.which
#       when 38 # up key
#         if @state.highlighted <= 0
#           i = @state.artworks.length - 1
#         else
#           i = @state.highlighted - 1
#         @setState highlighted: i
#       when 40 # down key
#         if @state.highlighted >= @state.artworks.length
#           i = 0
#         else
#           i = @state.highlighted + 1
#         @setState highlighted: i
#       when 13 # enter
#         @addHighlighted()

#   addHighlighted: ->
#     @props.artworks.add @state.artworks[@state.highlighted]
#     @setState artworks: [], loading: false, highlighted: 0

#   onMouseOverLi: (index) -> =>
#     @setState highlighted: index

#   render: ->
#     label {
#       className: 'bordered-input-loading' if @state.loading
#     }, 'Search by title',
#       input {
#         placeholder: 'Try “Andy Warhol Skull”'
#         className: 'bordered-input bordered-input-dark'
#         id: 'autocomplete-search-input'
#         onChange: @onSearch
#         onKeyUp: @onKeyUp
#         ref: 'byTitle'
#       }
#       (
#         if @state.artworks.length
#           ul { className: 'esa-autocomplete-menu' },
#             (
#               for artwork, i in @state.artworks
#                 li {
#                   className: 'is-active' if @state.highlighted is i
#                   onMouseOver: @onMouseOverLi(i)
#                   onClick: @addHighlighted
#                 },
#                   div { className: 'esa-thumbnail-container' },
#                     img { src: artwork.image_urls.small }
#                   div { className: 'esa-thumbnail-right' },
#                     div {}, artwork.artists[0].name
#                     div {}, [
#                       artwork.artwork.title
#                       artwork.artwork.date
#                     ].join(', ')
#             )
#       )
