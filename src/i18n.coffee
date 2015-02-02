# Description
#   A hubot script to add i18n support.
#
# Configuration:
#   HUBOT_LANG=language-tag
#
# Usage:
#   data = {
#     "language-tag": {
#       "message": "${ robot_name } support i18n now",
#       "respond": /.*i18n\s+awesome.*/
#     }
#   }
#
#   i18n = robot.i18n 'plugin name'
#
#   # You can call it serverl times
#   i18n.load data
#
#   robot.respond i18n.t('respond'), (msg) ->
#     msg.send i18n.t('message', robot_name: 'R2-D2')
#     #=> R2-D2 support i18n now
#
#
# Author:
#   c4605 <bolasblack@gmail.com>

_ = require 'lodash'

class I18nModule
  constructor: ->
    @langs = {}

  load: (config) ->
    _(config).forEach (map, lang) =>
      existedData = @langs[lang] ? {}
      @langs[lang] = _.extend existedData, map
    this

  t: (key, options) ->
    template = @langs[process.env.HUBOT_LANG][key]
    if _(template).isRegExp() then template else _.template(template)(options)

module.exports = (robot) ->
  # You can expand it
  robot.I18nModule = I18nModule

  robot.i18n = do ->
    modules = {}

    (name) ->
      modules[name] ?= new I18nModule
      modules[name]
