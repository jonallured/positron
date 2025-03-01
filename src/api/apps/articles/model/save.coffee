_ = require 'underscore'
_s = require 'underscore.string'
db = require '../../../lib/db'
stopWords = require '../../../lib/stopwords'
async = require 'async'
moment = require 'moment'
xss = require 'xss'
cheerio = require 'cheerio'
url = require 'url'
Q = require 'bluebird-q'
request = require 'superagent'
Article = require './index'
ArticleModel = require './../../../../api/models/article.coffee'
{ getArticleUrl, indexForSearch } = require './distribute'
{ ARTSY_URL, GEMINI_CLOUDFRONT_URL } = process.env
artsyXapp = require('artsy-xapp')
{ sanitizeLink } = require "./sanitize.js"
chalk = require 'chalk'
{ cloneDeep } = require 'lodash'

@onPublish = (article, cb) =>
  unless article.published_at or article.scheduled_publish_at
    article.published_at = new Date
  @generateSlugs article, cb

@onUnpublish = (article, cb) =>
  @generateSlugs article, (err, article) =>
    cb null, article

setOnPublishFields = (article) =>
  article.email_metadata = article.email_metadata or {}
  article.email_metadata.image_url = article.thumbnail_image unless article.email_metadata?.image_url
  if article.contributing_authors?.length > 0
    ca = _.pluck(article.contributing_authors, 'name').join(', ')
  article.email_metadata.author = ca or article.author?.name unless article.email_metadata?.author
  article.email_metadata.headline = article.thumbnail_title unless article.email_metadata?.headline
  article.description = article.description or getDescription(article)
  article

getDescription = (article) =>
  $ = cheerio.load(@getTextSections(article))
  text = []
  $('p').map( (i, el) ->
    text.push $(el).text()
  )
  text = text.join(' ').substring(0,150).concat('...')
  text

removeStopWords = (title) ->
  title = title.replace(/[.\/#!$%\^\*;{}=_`’~()]/g,"")
  title = title.replace(/[,&:\—_]/g," ")
  newTitle = _.difference(title.toLocaleLowerCase().split(' '), stopWords.stopWords)
  if newTitle.length > 1 then newTitle.join(' ') else title

@generateSlugs = (article, cb) ->
  stoppedTitle = ''
  if article.thumbnail_title
    stoppedTitle = removeStopWords article.thumbnail_title
  if article.layout is 'series'
    slug = _s.slugify stoppedTitle
  else
    slug = _s.slugify article.author?.name + ' ' + stoppedTitle

  # Does not add the slug to the array if the same slug is already the last item in the slugs array
  return cb null, article if slug is _.last(article.slugs)

  # Moves the slug to the end of the slugs array if it already exists in the array
  if article.slugs && article.slugs.includes(slug)
    article.slugs.push(article.slugs.splice(article.slugs.indexOf(slug), 1)[0])
    return cb null, article

  # # Appends published_at to slug if that slug already exists
  db.articles.count { slugs: slug }, (err, count) ->
    return cb(err) if err
    if count
      format = if article.published then 'MM-DD-YY' else 'X'
      publishedDate = new Date(article.published_at)
      if moment(publishedDate).isValid()
        formattedDate = moment(publishedDate).format(format)
      else
        formattedDate = moment().format(format)

      slug = slug + '-' + formattedDate

      # Does not add date with appended slug if the last slug has the same date appended
      return cb null, article if slug is _.last(article.slugs)

      # If the slug with the appended date already exists in the array it moves it to the end
      if article.slugs && article.slugs.includes(slug)
        article.slugs.push(article.slugs.splice(article.slugs.indexOf(slug), 1)[0])
        return cb null, article

    article.slugs = (article.slugs or []).concat slug
    cb(null, article)

@generateKeywords = (input, article, cb) ->
  unless (
    input.primary_featured_artist_ids or
    input.featured_artist_ids or
    input.fair_ids or
    input.partner_ids or
    input.contributing_authors or
    input.tags
  )
    return cb null, article
  keywords = []
  callbacks = []
  token = artsyXapp.token or ''
  if input.primary_featured_artist_ids
    for artistId in input.primary_featured_artist_ids
      do (artistId) ->
        callbacks.push (callback) ->
          request
            .get("#{ARTSY_URL}/api/v1/artist/#{artistId}")
            .set('X-Xapp-Token': token)
            .end callback
  if input.featured_artist_ids
    for artistId in input.featured_artist_ids
      do (artistId) ->
        callbacks.push (callback) ->
          request
            .get("#{ARTSY_URL}/api/v1/artist/#{artistId}")
            .set('X-Xapp-Token': token)
            .end callback
  if input.fair_ids
    for fairId in input.fair_ids
      do (fairId) ->
        callbacks.push (callback) ->
          request
            .get("#{ARTSY_URL}/api/v1/fair/#{fairId}")
            .set('X-Xapp-Token': token)
            .end callback
  if input.partner_ids
    for partnerId in input.partner_ids
      do (partnerId) ->
        callbacks.push (callback) ->
          request
            .get("#{ARTSY_URL}/api/v1/partner/#{partnerId}")
            .set('X-Xapp-Token': token)
            .end callback
  async.parallel callbacks, (err, results) =>
    if err
      console.log chalk.red('[ERROR: articles/model/save @ generateKeywords]'), err.response.error

      # TODO: because there was an error saving keywords (eg artwork was
      # unpublished, or artist deleted, or hyperlink incorrect), we return
      # article as is, without updated keywords. It would be better if there
      # was a way to surface this in the UI, either as an error state or as
      # a validation.

      return cb(null, article)

    keywords = article.tags or []
    keywords = keywords.concat (res.body.name for res in results)
    if article.contributing_authors?.length > 0
      for author in article.contributing_authors
        keywords.push author.name
    article.keywords = keywords[0..9]
    cb(null, article)

@sanitizeAndSave = (callback) => (err, article) =>
  return callback err if err
  if article.published or article.scheduled_publish_at
    article = setOnPublishFields article
    indexForSearch(article, ->) if article.indexable
    db.articles.save sanitize(article), callback
  else
    indexForSearch(article, ->) if article.indexable
    db.articles.save sanitize(article), callback

# TODO: Create a Joi plugin for this https://github.com/hapijs/joi/issues/577
sanitize = (article) ->
  if article.sections
    sections = for section in article.sections
      section.body = sanitizeHtml section.body if section.type is 'text'
      section.url = sanitizeLink section.url if section.type in ['video', 'social_embed', 'embed']
      if section.type is 'slideshow'
        for item in section.items when item.type is 'image' or item.type is 'video'
          item.caption = sanitizeHtml item.caption if item.type is 'image'
          item.url = sanitizeLink item.url if item.type is 'video'
      if section.type in ['image_collection', 'image_set']
        for item in section.images when item.type is 'image'
          item.caption = sanitizeHtml item.caption
      section
  else
    sections = []
  sanitized = _.extend article,
    title: sanitizeHtml article.title?.replace /\n/g, ''
    thumbnail_title: sanitizeHtml article.thumbnail_title
    lead_paragraph: sanitizeHtml article.lead_paragraph
    postscript: sanitizeHtml article.postscript
    sections: sections
  if article.news_source?.url
    sanitized.news_source.url = sanitizeLink article.news_source.url
  if article.hero_section?.caption
    sanitized.hero_section.caption = sanitizeHtml article.hero_section.caption
  if article.media
    media = article.media
    sanitized.media.description = sanitizeHtml media.description if media.description
    sanitized.media.credits = sanitizeHtml media.credits if media.credits
  sanitized

sanitizeHtml = (html) ->
  return xss html unless try $ = cheerio.load html, decodeEntities: false
  $('a').each ->
    if $(this).attr 'href'
      u = sanitizeLink $(this).attr 'href'
      $(this).attr 'href', u
  xss $.html(),
    whiteList: _.extend xss.getDefaultWhiteList(),
      a: ['target', 'href', 'title', 'name', 'class', 'data-id']
      span: ['style']

@getTextSections = (article) ->
  condensedHTML = article.lead_paragraph or ''
  _.map article.sections, (section) ->
    condensedHTML = condensedHTML.concat section.body if section.type is 'text'
  condensedHTML

