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
#   zaikobot サーバ情報 - インスタンス情報など、EC2のサーバ情報を返します。
#   zaikobot サーバを起動する - EC2のサーバを起動します。あらかじめインスタンスIDを調べておいてください。
#   zaikobot サーバを停止する - EC2のサーバを停止します。あらかじめインスタンスIDを調べておいてください。
#   zaikobot サーバ* - ボットが理解できれば、EC2のサーバを起動・停止します。
#
# Author:
#   Masatomi KINO <masatomix@ki-no.org>

AWS = require 'aws-sdk'
utils = require '../utils'
logger = require '../logger'

Conversation = require 'hubot-conversation'
config = require 'config'



module.exports = (robot) ->
  options =
    region: 'ap-northeast-1'

  conversation = new Conversation(robot)

  conditions = {'起動': {'key': 0, 'value': '起動'}, '停止': {'key': 1, 'value': '停止'}}

  select_logic = (res) ->
    #    console.dir res
    text = res.match[0].split(' ')[1]
    #  他の関数が答えてほしい文字の場合は何もしないで抜ける
    if text == 'サーバ情報'
      return

    watson_config = config.watson;
    watson = require('watson-developer-cloud');

    nlc = watson.natural_language_classifier({
      username: watson_config.username,
      password: watson_config.password,
      version: 'v1'
    })

    nlc.classify({
      text: text,
      classifier_id: watson_config.classifier_id
    }, (err, response)->
      if err
        console.log('error:', err)
      else
        console.log("入力値: " + response.text);
        confidence = response.classes[0].confidence;

        header = ''
#        header = "認識されました！"  if confidence > 0.95
#        header = "決定的じゃないけどコレかも？"  if 0.90 < confidence <= 0.95
#        header = "よく分からんけど一番近いのはコレ"  if confidence <= 0.90

        clazz = response.classes[0]
        if confidence > 0.95
          if clazz.class_name == '起動する' or  clazz.class_name == '停止する'
            console.log "0"
            start_or_stop res,response.classes[0]
          else
            console.log "1"
            header = "サーバの起動/停止を指示していますかね？\n「サーバを起動して」とか、もすこしわかりやすく言ってくれればやりますよ！"
        else if  confidence > 0.90
          console.log "2"
          header = "サーバの起動/停止を指示していますかね？\n「サーバを起動して」とか、もすこしわかりやすく言ってくれればやりますよ！"

        else
          console.log "3"
          header = "一応聞くけど、サーバ起動/停止についてのお願いでしょうか？\n「サーバを起動して」とか、もすこしわかりやすく言ってくれればやりますよ！"

        message = ''
#        message = "[" + response.classes[0].class_name + "]  信頼度: " + response.classes[0].confidence
        res.send [header, message].join("\n")

        log_message = '"' + response.text + '",' + response.classes[0].class_name + ",  信頼度: " + response.classes[0].confidence
        logger.main.info(log_message);
    )

  start_or_stop = (res,clazz) ->
    start_server res if clazz.class_name == '起動する'
    stop_server res if clazz.class_name == '停止する'
#      起動しない、とかの場合
    if clazz.class_name == '停止はしない' or  clazz.class_name == '起動はしない'
      header = "サーバの起動/停止を指示していますかね？\n「サーバを起動して」とか、もすこしわかりやすく言ってくれればやりますよ！"
      res.send [header].join("\n")

  start_server = (res) ->
    dialog = conversation.startDialog res, 60000; # timeout = 1min
    dialog.timeout = (res) ->
      res.emote('タイムアウトです')

    # 対話形式スタート
    input_instanceId res, dialog, conditions['起動']

  stop_server = (res) ->
    dialog = conversation.startDialog res, 60000; # timeout = 1min
    dialog.timeout = (res) ->
      res.emote('タイムアウトです')

    # 対話形式スタート
    input_instanceId res, dialog, conditions['停止']


  input_instanceId = (res, dialog, condition) ->
    res.send "サーバの#{condition.value}ですね！インスタンスIDを教えてください。[instanceId を入力] もしくは[やめる,0]"

    dialog.addChoice /(やめる|0)/, (res2)->
      res2.send "わかりました。#{condition.value}するのはやめます。"

    dialog.addChoice /(.*)/, (res2)->
      instanceId = res2.match[1].split(' ')[1] # なんかバグってる気がする
      confirm instanceId, res2, dialog, condition


  confirm = (instanceId, res, dialog, condition)->
    res.send "#{instanceId} のインスタンスを#{condition.value}します。よろしいでしょうか？[はい,いいえ,ok,yes,no,1(ok),0(no)]"

    dialog.addChoice /(yes|ok|OK|YES|はい|1)/, (res2) ->
      res2.send "わかりました！#{condition.value}します！！！"

      startInstance res2, instanceId if condition.key == 0
      stopInstance res2, instanceId if condition.key == 1

    dialog.addChoice /(no|NO|いいえ|0)/, (res2) ->
      res2.send "わかりました。#{condition.value}するのはやめます。"


  disp_server_info = (res) ->
    onSuccessed = (instances) ->
      for instance in instances
        message = "サーバ情報とってきました！\n"
        key = "previousIP_#{instance.InstanceId}"
        console.log key
        message += "----\n"
        message += "InstanceId: " + instance.InstanceId + '\n'
        message += "PublicDnsName: " + instance.PublicDnsName + '\n'
        message += "PublicIpAddress: " + instance.PublicIpAddress + '\n'
        message += "State: " + instance.State.Name + '\n'
        message += "前回とおなじIPですね" + '\n' if instance.PublicIpAddress == robot.brain.get(key)
        message += "----\n"

        robot.brain.set(key, instance.PublicIpAddress)
        res.send message

      for instance in instances
        res.send instance.InstanceId

    #    条件 null ですべてのインスタンスを取ってきて、起動する。
    utils.searchInstances(options).then onSuccessed



  #    起動サンプル
  #    onSuccessed = (instances) ->
  #      console.log "startInstances start"
  #      for instance in instances
  #        ec2 = new AWS.EC2(options);
  #        ec2.startInstances({InstanceIds:[instance.InstanceId]}, (err, data) ->
  #          if err
  #            console.log err.message
  #            res.send err.message
  #          else
  #            console.log "#{instance.InstanceId} の起動が開始されました"
  #            res.send "#{instance.InstanceId} の起動を指示しました！"
  #        )
  #      console.log "startInstances end"


  bot_start_instance = (res) ->
    text = res.match[0]
    instanceId = res.match[1].trim()

    console.log "#{text}"
    startInstance res, instanceId

  bot_stop_instance = (res) ->
    text = res.match[0]
    instanceId = res.match[1].trim()

    console.log "#{text}"
    stopInstance res, instanceId


  startInstance = (res, instanceId) ->
    console.log "#{instanceId}"
    params = {
      InstanceIds: [instanceId]
    }

    onSuccessed = (instatnces) ->
      res.send "#{instanceId} の起動を指示しました！"
      return

    onRejected = (error) ->
      res.send "#{instanceId} の起動はエラーになっちゃった! #{error.message}"
      return

    utils.startInstances(options, params).then onSuccessed, onRejected

  stopInstance = (res, instanceId) ->
    console.log "#{instanceId}"
    params = {
      InstanceIds: [instanceId]
    }

    utils.stopInstances(options, params)
    .then (instatnces) ->
      res.send "#{instanceId} の停止を指示しました！"
      return
    ,(error) ->
      res.send "#{instanceId} の停止はエラーになっちゃった! #{error.message}"
      return

#    promise = utils.searchInstances(options,params);
#
#    onRejected = (error) ->
#      res.send "#{instanceId} の起動はエラーになっちゃった! #{error}"
#
#    onSuccessed = (instances) ->
#      console.log "startInstances start"
#      for instance in instances
#        ec2 = new AWS.EC2(options);
#        ec2.startInstances({InstanceIds:[instance.InstanceId]}, (err, data) ->
#          if err
#            console.log err.message
#            res.send err.message
#          else
#            console.log "#{instanceId} の起動が開始されました"
#            res.send "#{instanceId} の起動を指示しました！"
#        )
#
#      console.log "startInstances end"
#
#    promise.then onSuccessed,onRejected

  robot.respond /(サーバ情報)/i, disp_server_info
  robot.respond /(.*)(サーバ)(.*)/i, select_logic
#  robot.respond /サーバ起動/i, start_server
#  robot.respond /サーバ停止/i, stop_server
#  robot.respond /(.*)(の起動)/i, bot_start_instance
#  robot.respond /(.*)(の停止)/i, bot_stop_instance
