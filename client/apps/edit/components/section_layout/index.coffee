React = require 'react'
moment = require 'moment'
_ = require 'underscore'
HeroSection = React.createFactory require '../hero_section/index.coffee'
HeaderSection = React.createFactory require '../section_header/index.coffee'
SectionList = React.createFactory require '../section_list/index.coffee'
{ div, p, textarea } = React.DOM


module.exports = React.createClass
  displayName: 'SectionLayout'

  componentWillMount: ->
    @debouncedSave = _.debounce((->
      @props.article.save()
      @forceUpdate()
    ), 800)
    @props.article.sections.on 'change', => @saveArticle()

  saveArticle: ->
    unless @props.article.get('published')
      $('#edit-save').addClass('is-saving')
      @debouncedSave()
    else
      $('#edit-save').removeClass('is-saving').addClass 'attention'

  render: ->
    div {className: 'edit-section-layout'},

      if @props.article.get('hero_section') != null or @props.channel.hasFeature 'hero'
        div { id: 'edit-hero-section'},
          HeroSection {
            section: @props.article.heroSection
          }

      HeaderSection {
        article: @props.article
        saveArticle: @saveArticle
      }

      div { id: 'edit-sections', className: 'edit-body-container' },
        SectionList {
          sections: @props.article.sections
          saveArticle: @saveArticle
        }
