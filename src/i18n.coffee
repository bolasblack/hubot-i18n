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
#       # for normal use case
#       message: "${ robot_name } support i18n now"
#
#       # for listener
#       respond: /.*i18n\s+awesome.*/i  # simple way
#       respond:                        # complex way
#         match: /.*i18n\s+awesome.*/i
#         # You can modify `msg` before pass in Listener
#         transform: (msg) ->
#           msg.match = [null, 'R2-D2']
#           msg
#   )
#
#   # use i18n.m can match all language
#   robot.listen i18n.m('respond'), (resp) ->
#
#   # use i18n.t to translate content
#   # use i18n.c make `transform` take effect
#   robot.respond i18n.t('respond'), i18n.c('respond', (msg) ->
#     msg.send i18n.t('message', robot_name: msg.match[1])
#     #=> R2-D2 support i18n now
#   )
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

  translate: (key, options) ->
    return key unless config = @get key
    result = if _(config).isRegExp()
      config
    else if _(config.match).isRegExp()
      config.match
    else
      _.template(config) options
    result._i18n = true
    result

  matcher: (key) ->
    (message) =>
      lastValue = null
      _.find @langs, (locale, lang) ->
        matcher = locale[key]
        lastValue = if _(matcher).isRegExp()
          message.match matcher
        else if _(matcher.match).isRegExp()
          message.match matcher.match
        else
          matcher is message
      lastValue

  preprocessCallback: (key, callback) ->
    return callback unless config = @get key
    transform = config.transform or @identity
    (msg) ->
      callback.call this, transform(msg)

I18nModule::c = I18nModule::preprocessCallback
I18nModule::t = I18nModule::translate
I18nModule::m = I18nModule::matcher

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
