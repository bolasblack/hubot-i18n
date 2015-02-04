# Description
#   A hubot script to add i18n support.
#
# Configuration:
#   HUBOT_LANG=language-tag
#
# Usage:
#   # Init
#   i18n = robot.i18n 'unique name'
#
#   # You can load i18n config serverl times
#   i18n.load(
#     "language-tag":
#       message: "${ robot_name } support i18n now"
#       # simple way
#       respond: /.*i18n\s+awesome.*/i
#       # complex way
#       respond:
#         match: /.*i18n\s+awesome.*/i
#         # You can modify `msg` before pass in Listener
#         transform: (msg) ->
#           msg.match = [null, 'R2-D2']
#           msg
#   )
#
#   # Use it
#   robot.respond i18n.t('respond'), i18n.c 'respond', (msg) ->
#     msg.send i18n.t('message', robot_name: msg.match[1])
#     #=> R2-D2 support i18n now
#
# Author:
#   c4605 <bolasblack@gmail.com>

_ = require 'lodash'

class I18nModule
  constructor: (@name) ->
    @langs = {}

  load: (config) ->
    _.forEach config, (map, lang) =>
      existedData = @langs[lang] ? {}
      @langs[lang] = _.extend existedData, map
    this

  get: (key) ->
    return unless key
    currentLanguage = process.env.HUBOT_LANG or 'en'
    @langs[currentLanguage]?[key.source or key]

  identity: _.identity

  t: (key, options) ->
    return key unless template = @get key
    result = if _(template).isRegExp()
      template
    else if _(template.match).isRegExp()
      template.match
    else
      _.template(template) options
    result._i18n = true
    result

  c: (key, callback) ->
    return callback unless config = @get key
    transform = config.transform or @identity
    (msg) ->
      callback.call this, transform(msg)

wrapRobotMethod = (robot) ->
  i18n = robot.i18n 'patch'
  Robot = robot.constructor
  wrapMethod = (originMethod) ->
    (regexp, callback) ->
      pluginNotUsingI18n = not regexp._i18n
      realRegexp = i18n.t regexp
      if pluginNotUsingI18n and realRegexp
        [regexp, callback] = [realRegexp, i18n.c regexp, callback]
      originMethod.call this, regexp, callback

  Robot::respond = wrapMethod Robot::respond
  Robot::hear    = wrapMethod Robot::hear

module.exports = (robot) ->
  modules = {}
  robot.i18n = (name) ->
    throw Error('[hubot-i18n] robot.i18n() need a name') unless name
    modules[name] ?= new I18nModule name
    modules[name]

  # You can expand it
  robot.i18n.Module = I18nModule

  if process.env.HUBOT_I18N_PATCH is 'true'
    wrapRobotMethod robot

  robot.emit 'i18n:ready'
