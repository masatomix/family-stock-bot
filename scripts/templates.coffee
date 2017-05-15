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
#   zaikobot templates - テンプレート名を一覧します。
#   zaikobot template <テンプレ名> - 指定したテンプレートを表示します。
#
# Author:
#   Masatomi KINO <masatomix@ki-no.org>

module.exports = (robot) ->
  datas =
    'github close':
      'desc': 'GitHubのIssueをclose するときのコメントの打ち方'
      'message': ()->
        urls = [
          "https://help.github.com/articles/closing-issues-via-commit-messages/",
          "http://qiita.com/maeda_t/items/d9ef98bf651bd491b16d"]
        return "closes #20,closes #21" + '\n' + urls.join('\n')


    'hello':
      'desc': 'Hello World.'
      'message': ()->
        return "Hello World."

    'hubot reg':
      'desc': 'どちらかに、完全一致。'
      'message': ()->
        return "\s(やめる|0)$"


  robot.respond /template\s(.*)/i, (res) ->
    key = res.match[1].trim()
    console.log key
    if datas[key]?   #NULLチェック
      message = datas[key].message()
      res.send message

  robot.respond /templates/i, (res) ->
    messages = []
    for prop of datas
      messages.push "#{prop} : #{datas[prop].desc}"
    res.send messages.join('\n')

