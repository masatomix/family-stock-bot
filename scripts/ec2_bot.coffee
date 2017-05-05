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
#   zaikobot サーバ情報 - EC2のサーバ情報を返します。
#   zaikobot <インスタンスID>の起動 - EC2の指定したインスタンスを起動します。
#   zaikobot <インスタンスID>の停止 - EC2の指定したインスタンスを停止します。
#   zaikobot サーバ起動 - 対話的にEC2インスタンスを起動します。
#   zaikobot サーバ停止 - 対話的にEC2インスタンスを停止します。
#
# Author:
#   Masatomi KINO <masatomix@ki-no.org>

AWS = require 'aws-sdk';
utils = require '../utils.js'
Conversation = require 'hubot-conversation'


module.exports = (robot) ->
  options =
    region: 'ap-northeast-1'

  conversation = new Conversation(robot)

  robot.respond /サーバ起動/i, (res) ->
    dialog = conversation.startDialog res, 60000; # timeout = 1min
    dialog.timeout = (res) ->
      res.emote('タイムアウトです')

    # 対話形式スタート
    input_instanceId res, dialog

  input_instanceId = (res, dialog) ->
    res.send "サーバの起動コマンドを受信しました。インスタンスIDを教えてください。[instanceId を入力] もしくは[やめる]"

    dialog.addChoice /やめる/, (res2)->
      res2.send 'わかりました。起動するのはやめます。'

    dialog.addChoice /(.*)/, (res2)->
      instanceId = res2.match[1].split(' ')[1] # なんかバグってる気がする
      confirm instanceId, res2, dialog


  confirm = (instanceId, res, dialog)->
    res.send "#{instanceId} のインスタンスを起動します。よろしいでしょうか？[はい,ok,yes,いいえ,no]"

    dialog.addChoice /(yes|ok|OK|YES|はい)/, (res2) ->
      res2.send 'わかりました！起動します！！！'
      startInstance res2, instanceId

    dialog.addChoice /(no|NO|いいえ)/, (res2) ->
      res2.send 'わかりました。起動するのはやめます。'



  robot.respond /サーバ停止/i, (res) ->
    dialog = conversation.startDialog res, 60000; # timeout = 1min
    dialog.timeout = (res) ->
      res.emote('タイムアウトです')

    # 対話形式スタート
    input_instanceId res, dialog

  input_instanceId = (res, dialog) ->
    res.send "サーバの停止コマンドを受信しました。インスタンスIDを教えてください。[instanceId を入力] もしくは[やめる]"

    dialog.addChoice /やめる/, (res2)->
      res2.send 'わかりました。停止するのはやめます。'

    dialog.addChoice /(.*)/, (res2)->
      instanceId = res2.match[1].split(' ')[1] # なんかバグってる気がする
      confirm instanceId, res2, dialog


  confirm = (instanceId, res, dialog)->
    res.send "#{instanceId} のインスタンスを停止します。よろしいでしょうか？[はい,ok,yes,いいえ,no]"

    dialog.addChoice /(yes|ok|OK|YES|はい)/, (res2) ->
      res2.send 'わかりました！停止します！！！'
      stopInstance res2, instanceId

    dialog.addChoice /(no|NO|いいえ)/, (res2) ->
      res2.send 'わかりました。停止するのはやめます。'




  robot.respond /(サーバ情報)/i, (res) ->

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


  robot.respond /(.*)(の起動)/i, (res) ->
    text = res.match[0]
    instanceId = res.match[1].trim()

    console.log "#{text}"
    startInstance res, instanceId


  startInstance = (res, instanceId) ->
    console.log "#{instanceId}"
    params = {
      InstanceIds: [instanceId]
    }
    utils.startInstances(options, params).then
    (instatnces) ->
      res.send "#{instanceId} の起動を指示しました！",
    (error) ->
      res.send "#{instanceId} の起動はエラーになっちゃった! #{error.message}"


  robot.respond /(.*)(の停止)/i, (res) ->
    text = res.match[0]
    instanceId = res.match[1].trim()

    console.log "#{text}"
    stopInstance res, instanceId


  stopInstance = (res, instanceId) ->
    console.log "#{instanceId}"
    params = {
      InstanceIds: [instanceId]
    }
    utils.stopInstances(options, params).then
    (instatnces) ->
      res.send "#{instanceId} の停止を指示しました！"
    (error) ->
      res.send "#{instanceId} の停止はエラーになっちゃった! #{error.message}"




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
