# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md
#
#
# Commands:
#   hubot 在庫 - 家の在庫情報を返します。
#   hubot 在庫詳細 - 家の在庫情報を返します(詳細)。
#   hubot 在庫変更 <商品名> <個数> - 家の在庫情報を引数の個数で増減させます。(減らしたい時はマイナス値を。)
#
# Author:
#   Masatomi KINO <masatomix@ki-no.org>

request = require 'request'
config = require 'config'

module.exports = (robot) ->

  bot_config = config.bot
  url = bot_config.gas_url

  robot.respond /(天気|てんき|tenki)/i, (res) ->
    res.http(bot_config.weather_url)
      .get() (error, response, body) ->
        res.send JSON.parse(body).description.text


  getZaiko = (res) ->
    # 通常、[@hubot 在庫] がはいってくるので、zaiko/在庫で「おわるもの」を検索
    input = res.match[0]
    console.log "["+input+"]"
    console.log /(詳細)$/.test(input)

    options =
      url: url
      method: "POST"
#      timeout: 2000
      followAllRedirects: true  # リダイレクトに対応する
      form:{"command": "slackFindAll"}

    request options, (error, response, body) ->
#   bodyは本文文字かな
      console.log body
      obj = JSON.parse body

      message = ""
      # 詳細 / detail とかでおわる文字の場合
      if /(詳細|detail)$/.test(input)
        message = createDetailMessage obj
      else
        message = createMessage obj

      message += '\n'
      message += createHokyuMessage obj
      res.send message


  updateZaiko = (res) ->
    text = res.match[0]
    name = res.match[2].trim()
    zaiko = res.match[3].trim()
    console.log "["+text+"]"
    console.log "["+name+"]"
    console.log "["+zaiko+"]"

    res.http(url)
      .query(command: "update")
      .query(name: name)
      .query(zaiko: zaiko)
      .post() (error, response, body) ->
        getZaiko res


  # message作成
  createMessage = (obj)->
    message = ""
    for value, index in  obj
      message += [value[1],value[6]].join('\t')
      message += '\n'

    message += ["\n",bot_config.gas_document_url,"\n"].join('');
    return message



  # 詳細 message作成
  createDetailMessage = (obj) ->
    message = ""
    for value, index in  obj
      message += [value[0],value[1],value[6],value[7]].join('\t')
      message += '\n'

    message += ["\n",bot_config.gas_document_url,"\n"].join('');
    return message


  # message作成
  createHokyuMessage = (obj)->
    message = ""
    flag = false
    for value, index in  obj
#      在庫がなかったら
      if value[6]==0
        flag = true
        message += [value[1],value[7]].join('\t')
        message += '\n'

    if flag
      message = "以下は、在庫がないため購入した方がよいですよー\n" + message
    return message


  robot.respond /(在庫|zaiko)$/i, getZaiko
  robot.respond /(在庫詳細|zaikodetail)$/i, getZaiko
  robot.respond /(在庫変更|zaikohenko|zaikohenkou) (.*) (.*)/i, updateZaiko
