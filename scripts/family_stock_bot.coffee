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
    console.log "["+res.match[0]+"]"
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
      for value, index in  obj
        message += [value[0],value[1],value[6],value[7]].join('\t')
        message += '\n'

      message += ["\n",bot_config.gas_document_url,"\n"].join('');
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


  robot.respond /(在庫|zaiko)$/i, getZaiko
  robot.respond /(在庫変更|zaikohenko|zaikohenkou) (.*) (.*)/i, updateZaiko
