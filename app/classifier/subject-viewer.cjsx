React = require 'react'
SubjectViewer = require '../components/subject-viewer'
Draggable = require '../lib/draggable'
drawingTools = require './drawing-tools'

NOOP = Function.prototype

module.exports = React.createClass
  displayName: 'SubjectViewer' # TODO: Rename this.

  getDefaultProps: ->
    onLoad: NOOP

  getInitialState: ->
    naturalWidth: 0
    naturalHeight: 0
    proportion: 'square'
    frame: 0

  getScale: ->
    ALMOST_ZERO = 0.01 # Prevent divide-by-zero errors when there is no image.
    rect = @refs.sizeRect?.getDOMNode().getBoundingClientRect()
    horizontal = (rect?.width || ALMOST_ZERO) / (@state.naturalWidth || ALMOST_ZERO)
    vertical = (rect?.height || ALMOST_ZERO) / (@state.naturalHeight || ALMOST_ZERO)
    {horizontal, vertical}

  getEventOffset: (e) ->
    rect = @refs.sizeRect.getDOMNode().getBoundingClientRect()
    scale = @getScale()
    x = (e.pageX - pageXOffset - rect.left) / scale.horizontal
    y = (e.pageY - pageYOffset - rect.top) / scale.vertical
    {x, y}

  render: ->
    scale = @getScale()

    <div className="subject-area #{@state.proportion}">
      <SubjectViewer subject={@props.subject} frame={@state.frame} onLoad={@handleSubjectFrameLoad} onFrameChange={@handleFrameChange}>
        <svg viewBox={"0 0 #{@state.naturalWidth} #{@state.naturalHeight}"} preserveAspectRatio="none" style={SubjectViewer.overlayStyle}>
          <rect ref="sizeRect" width="100%" height="100%" fill="rgba(0, 0, 0, 0.01)" fillOpacity="0.01" stroke="none" />

          {if @props.annotation?._toolIndex?
            <Draggable onStart={@handleInitStart} onDrag={@handleInitDrag} onEnd={@handleInitRelease}>
              <rect className="marking-initializer" width="100%" height="100%" fill="transparent" stroke="none" />
            </Draggable>}

          {for annotation in @props.classification.annotations
            annotation._key ?= Math.random()
            disabled = annotation isnt @props.annotation
            task = @props.workflow.tasks[annotation.task]
            if task.type is 'drawing'
              <g key={annotation._key} className="marks-for-annotation" data-disabled={disabled or null}>
                {for mark, m in annotation.value
                  mark._key ?= Math.random()
                  tool = task.tools[mark.tool]

                  toolProps =
                    classification: @props.classification
                    annotation: annotation
                    tool: tool
                    mark: mark
                    scale: scale
                    disabled: disabled
                    selected: not disabled and m is annotation.value.length - 1
                    select: @selectMark.bind this, mark
                    getEventOffset: @getEventOffset

                  ToolComponent = drawingTools[tool.type]
                  <ToolComponent key={mark._key} {...toolProps} />}
              </g>}
        </svg>
      </SubjectViewer>
    </div>

  handleSubjectFrameLoad: (e) ->
    if e.target.tagName.toUpperCase() is 'IMG'
      {naturalWidth, naturalHeight} = e.target
      unless @state.naturalWidth is naturalWidth and @state.naturalHeight is naturalHeight
        proportion = naturalWidth / naturalHeight
        proportion = if proportion <= 0.4
          'very-tall'
        else if 0.4 < proportion <= 0.9
          'tall'
        else if 0.9 < proportion <= 1.1
          'square'
        else if 1.1 < proportion <= 1.6
          'wide'
        else if 1.6 < proportion
          'very-wide'

        @setState {naturalWidth, naturalHeight, proportion}
      @props.onLoad? arguments...

  handleFrameChange: (e) ->
    @setState frame: parseFloat e.target.value

  handleInitStart: (e) ->
    task = @props.workflow.tasks[@props.annotation.task]
    mark = @props.annotation.value[@props.annotation.value.length - 1]

    markIsComplete = true
    if mark?
      MarkComponent = drawingTools[task.tools[mark.tool].type]
      if MarkComponent.isComplete?
        markIsComplete = MarkComponent.isComplete mark

    mouseCoords = @getEventOffset e

    if markIsComplete
      mark =
        tool: @props.annotation._toolIndex
      @props.annotation.value.push mark
      MarkComponent = drawingTools[task.tools[mark.tool].type]

      if MarkComponent.defaultValues?
        defaultValues = MarkComponent.defaultValues mouseCoords
        for key, value of defaultValues
          mark[key] = value

    if MarkComponent.initStart?
      initValues = MarkComponent.initStart mouseCoords, mark, e
      for key, value of initValues
        mark[key] = value

    @props.classification.update 'annotations'

  handleInitDrag: (e) ->
    task = @props.workflow.tasks[@props.annotation.task]
    mark = @props.annotation.value[@props.annotation.value.length - 1]
    MarkComponent = drawingTools[task.tools[mark.tool].type]

    mouseCoords = @getEventOffset e

    if MarkComponent.initMove?
      initMoveValues = MarkComponent.initMove mouseCoords, mark, e
      for key, value of initMoveValues
        mark[key] = value
      @props.classification.update 'annotations'

  handleInitRelease: (e) ->
    task = @props.workflow.tasks[@props.annotation.task]
    mark = @props.annotation.value[@props.annotation.value.length - 1]
    MarkComponent = drawingTools[task.tools[mark.tool].type]

    mouseCoords = @getEventOffset e

    if MarkComponent.initRelease?
      initReleaseValues = MarkComponent.initRelease mouseCoords, mark, e
      for key, value of initReleaseValues
        mark[key] = value
      @props.classification.update 'annotations'

  selectMark: (mark) ->
    index = @props.annotation.value.indexOf mark
    unless index is -1
      @props.annotation.value.splice index, 1
      @props.annotation.value.push mark
