import keyMirror from 'client/lib/keyMirror'

export const actions = keyMirror(
  'CHANGE_SAVED_STATUS',
  'CHANGE_VIEW',
  'DELETE_ARTICLE',
  'EDIT_SECTION',
  'ERROR',
  'NEW_SECTION',
  'PUBLISH_ARTICLE',
  'REMOVE_SECTION',
  'SAVE_ARTICLE'
)

export const changeSavedStatus = (article, isSaved) => ({
  type: actions.CHANGE_SAVED_STATUS,
  payload: {
    article,
    isSaved,
    lastUpdated: new Date()
  }
})

export const changeView = (activeView) => ({
  // Content, Admin, Display
  type: actions.CHANGE_VIEW,
  payload: {
    activeView
  }
})

export const deleteArticle = (article) => {
  article.destroy({
    success: () => {
      article.trigger('finished')
    }
  })

  return {
    type: actions.DELETE_ARTICLE,
    payload: {
      isDeleting: true
    }
  }
}

export const editSection = (sectionIndex) => ({
  // Index of article section currently editing
  type: actions.EDIT_SECTION,
  payload: {
    sectionIndex
  }
})

export const newSection = (type, sectionIndex) => {
  const section = setupSection(type)

  return {
    type: actions.NEW_SECTION,
    payload: {
      section,
      sectionIndex
    }
  }
}

export const publishArticle = (article, published) => {
  article.set('published', published)
  article.save()
  article.trigger('finished')

  return {
    type: actions.PUBLISH_ARTICLE,
    payload: {
      isPublishing: true
    }
  }
}

export const removeSection = (sectionIndex) => ({
  type: actions.REMOVE_SECTION,
  payload: {
    sectionIndex
  }
})

export const saveArticle = (article) => {
  article.save()

  return {
    type: actions.SAVE_ARTICLE,
    payload: {
      isSaving: true
    }
  }
}

// EDITING ERRORS
export const logError = (error) => ({
  type: actions.ERROR,
  payload: {
    error
  }
})

export const resetError = () => ({
  type: actions.ERROR,
  payload: {
    error: null
  }
})

// ACTION UTILS
export function setupSection (type) {
  // set initial state of new section
  switch (type) {
    case 'video':
      return {
        type: 'video',
        url: '',
        layout: 'column_width'
      }
    case 'image_collection':
      return {
        type: 'image_collection',
        layout: 'overflow_fillwidth',
        images: []
      }
    case 'embed':
      return {
        type: 'embed',
        url: '',
        layout: 'column_width',
        height: ''
      }
    case 'text':
      return {
        type: 'text',
        body: ''
      }
  }
}
