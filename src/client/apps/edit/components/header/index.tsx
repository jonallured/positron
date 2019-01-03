import { color, Flex, space } from "@artsy/palette"
import colors from "@artsy/reaction/dist/Assets/Colors"
import Icon from "@artsy/reaction/dist/Components/Icon"
import { ArticleData } from "@artsy/reaction/dist/Components/Publishing/Typings"
import React, { Component } from "react"
import { connect } from "react-redux"
import styled from "styled-components"
import {
  deleteArticle,
  publishArticle,
  saveArticle,
} from "../../../../../client/actions/edit/articleActions"
import { changeView } from "../../../../../client/actions/edit/editActions"

interface Props {
  article: ArticleData
  beforeUnload: () => void
  changeViewAction: (e) => void
  channel: Channel
  deleteArticleAction: () => void
  edit: Edit
  forceURL: string
  isAdmin: boolean
  publishArticleAction: () => void
  saveArticleAction: () => void
}

interface Channel {
  id: string
  name: string
  type: string
}

interface Edit {
  activeView: string
  article: ArticleData
  currentSession: object
  error: object
  isDeleting: boolean
  isPublishing: boolean
  isSaved: true
  isSaving: false
  mentioned: object
  section: object
  sectionIndex: number
  setYoastKeyword: string
}

export class EditHeader extends Component<Props> {
  isPublishable = () => {
    return this.finishedContent() && this.finishedDisplay()
  }

  finishedContent = () => {
    const { title } = this.props.article

    return title && title.length > 0
  }

  finishedDisplay = () => {
    const { thumbnail_image, thumbnail_title } = this.props.article
    const finishedImg = thumbnail_image && thumbnail_image.length > 0
    const finishedTitle = thumbnail_title && thumbnail_title.length > 0

    return finishedImg && finishedTitle
  }

  onPublish = () => {
    const { publishArticleAction } = this.props

    if (this.isPublishable()) {
      publishArticleAction()
    }
  }

  onSave = () => {
    const { saveArticleAction } = this.props

    this.removeUnsavedAlert()
    saveArticleAction()
  }

  onDelete = () => {
    const { deleteArticleAction } = this.props

    if (confirm("Are you sure?")) {
      this.removeUnsavedAlert()
      deleteArticleAction()
    }
  }

  removeUnsavedAlert = () => {
    const { beforeUnload } = this.props
    // dont show popup for unsaved changes when saving/deleting
    window.removeEventListener("beforeunload", beforeUnload)
  }

  getSaveColor = () => {
    const { isSaving, isSaved } = this.props.edit

    if (isSaving) {
      return colors.greenRegular
    } else if (isSaved) {
      return "black"
    } else {
      return colors.redMedium
    }
  }

  getSaveText = () => {
    const { article, edit } = this.props
    const { isSaving } = edit

    if (isSaving) {
      return "Saving..."
    } else if (article.published) {
      return "Save Article"
    } else {
      return "Save Draft"
    }
  }

  getPublishText = () => {
    const { article, edit } = this.props
    const { isPublishing } = edit
    const isPublished = article.published

    if (isPublishing && isPublished) {
      return "Unpublishing..."
    } else if (isPublishing) {
      return "Publishing..."
    } else if (isPublished) {
      return "Unpublish"
    } else {
      return "Publish"
    }
  }

  render() {
    const {
      article,
      changeViewAction,
      channel,
      edit,
      forceURL,
      isAdmin,
    } = this.props

    const { activeView, isDeleting } = edit
    const { grayMedium, greenRegular } = colors

    return (
      <EditHeaderContainer>
        <Flex>
          <div>
            <LeftHeaderButton
              className="avant-garde-button check"
              onClick={() => changeViewAction("content")}
              data-active={activeView === "content"}
            >
              <span>Content</span>
              <CheckIcon
                fontSize="10px"
                className="icon"
                name="check"
                color={this.finishedContent() ? greenRegular : grayMedium}
              />
            </LeftHeaderButton>

            <LeftHeaderButton
              className="avant-garde-button check"
              onClick={() => changeViewAction("display")}
              data-active={activeView === "display"}
            >
              <span>Display</span>
              <CheckIcon
                fontSize="10px"
                className="icon"
                name="check"
                color={this.finishedDisplay() ? greenRegular : grayMedium}
              />
            </LeftHeaderButton>

            {isAdmin && (
              <LeftHeaderButton
                className="avant-garde-button"
                onClick={() => changeViewAction("admin")}
                data-active={activeView === "admin"}
              >
                Admin
              </LeftHeaderButton>
            )}
          </div>

          <div>
            <LeftHeaderButton
              className="avant-garde-button publish"
              data-disabled={!this.isPublishable()}
              onClick={this.onPublish}
            >
              {this.getPublishText()}
            </LeftHeaderButton>

            {channel.type === "editorial" && (
              <LeftHeaderButton className="avant-garde-button autolink">
                Auto-link
              </LeftHeaderButton>
            )}
          </div>
        </Flex>

        <Flex>
          <RightHeaderButton
            className="avant-garde-button delete"
            onClick={this.onDelete}
          >
            {isDeleting ? "Deleting..." : "Delete"}
          </RightHeaderButton>

          <SaveButton
            className="avant-garde-button"
            color={this.getSaveColor()}
            onClick={this.onSave}
          >
            {this.getSaveText()}
          </SaveButton>

          <Link href={`${forceURL}/article/${article.slug}`} target="_blank">
            <RightHeaderButton className="avant-garde-button">
              {article.published ? "View" : "Preview"}
            </RightHeaderButton>
          </Link>
        </Flex>
      </EditHeaderContainer>
    )
  }
}

const EditHeaderContainer = styled(Flex)`
  justify-content: space-between;
  padding: ${space(1)}px;
`

const HeaderButton = styled.button`
  border-radius: 0;
  padding: 11px 18px;

  &[data-disabled="true"] {
    background: ${color("black10")};
    color: ${color("black60")};
  }

  &[data-disabled="false"],
  &[data-active="true"] {
    color: ${color("black100")};
  }

  &.delete {
    border: none;
  }
`

const LeftHeaderButton = styled(HeaderButton)`
  margin-right: ${space(1)}px;
  color: ${color("black30")};

  &:hover {
    color: ${color("black100")};
  }

  &.check {
    margin: 0;
    border-right: 0;
  }
`

const RightHeaderButton = styled(HeaderButton)`
  margin-left: ${space(1)}px;
`

const CheckIcon = styled(Icon)`
  margin-right: 0;
  margin-left: ${space(1)}px;
`
const Link = styled.a`
  background-image: none;
`

const mapStateToProps = state => ({
  article: state.edit.article,
  channel: state.app.channel,
  edit: state.edit,
  forceURL: state.app.forceURL,
  isAdmin: state.app.isAdmin,
})

const mapDispatchToProps = {
  changeViewAction: changeView,
  deleteArticleAction: deleteArticle,
  publishArticleAction: publishArticle,
  saveArticleAction: saveArticle,
}

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(EditHeader)

const SaveButton = styled.button`
  color: ${props => props.color};
`
