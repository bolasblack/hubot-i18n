# Hubot: hubot-i18n

A hubot script to support i18n.

## Basic usage

Use environment variable `HUBOT_LANG=language-tag` to specify hubot language.

```coffeescript
# Init
i18n = robot.i18n 'unique name'

# You can load i18n config serverl times
i18n.load(
  "language-tag":
    message: "${ robot_name } support i18n now"
    # simple way
    respond: /.*i18n\s+awesome.*/i
    # complex way
    respond:
      match: /.*i18n\s+awesome.*/i
      # You can modify `msg` before pass in Listener
      transform: (msg) ->
        msg.match = [null, 'R2-D2']
        msg
)

# Use it
robot.respond i18n.t('respond'), i18n.c 'respond', (msg) ->
  msg.send i18n.t('message', robot_name: msg.match[1])
  #=> R2-D2 support i18n now
```

## Patch mode

You can internationalize other plugin with patch mode by using environment variable `HUBOT_I18N_PATCH=true`.

Example for [hubot-help](https://github.com/hubot-scripts/hubot-help/blob/master/src/help.coffee#L56).

```coffeescript
# In your scripts/ file

module.exports = (robot) ->
  # The module name must be `patch`
  i18n = robot.i18n 'patch'

  i18n.load(
    'zh-CN':
      # key is RegExp.source
      'help\\s*(.*)?$':
        match: /(关于)?\s*(.*)?\s*(的)?命令$/i
        transform: (msg) ->
          match = msg.match
          msg.match = [match[0], match[2]]
          msg
  )
```
