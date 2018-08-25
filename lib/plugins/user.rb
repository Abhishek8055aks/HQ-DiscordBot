module User
  extend Discordrb::Commands::CommandContainer

  command(:id, min_args: 0) do |event, *namearg|
    name = namearg.join(' ') unless namearg.length.zero?
    key = CONFIG['api']

    findid = RestClient.get('https://api-quiz.hype.space/users',
                            params: { q: name },
                            Authorization: key,
                            'Content-Type': :json)

    iddata = JSON.parse(findid)['data']

    if iddata.length.zero?
      begin
        event.channel.send_embed do |embed|
          embed.title = 'Error while searching for stats'
          embed.colour = 'E6286E'
          embed.description = 'Username not found.'
        end
      rescue Discordrb::Errors::NoPermission
        event.respond 'That user doesn\'t exist!'
      end
      break
    end

    id = iddata[0]['userId']

    event.respond "HQ User ID for #{name} is #{id}"
  end

  command(:user, min_args: 0) do |event, *namearg|
    keys = JSON.parse(File.read('keys.json'))
    name = namearg.join(' ') unless namearg.length.zero?
    filename = "profiles/#{event.user.id}.yaml"
    if File.exist?(filename) && namearg.length.zero?
      profile = YAML.load_file(filename)
      name = profile['username']
    elsif namearg.length.zero?
      name = event.user.nickname || event.user.name
    end

    key = CONFIG['api']

    if namearg.length.zero? && File.exist?(filename) && profile['authkey']
      key = keys[profile['keyid']]

      teste = RestClient.get('https://api-quiz.hype.space/users/me',
                             Authorization: key,
                             'Content-Type': :json)

      teste = JSON.parse(teste)

      unless teste['username'].casecmp(profile['username']).zero?
        key = CONFIG['api']
        profile['lives'] = false
        profile['streak'] = false
        event.respond 'Auth key doesn\'t match your profile username, not returning any extra stats!'
      end
    end

    findid = RestClient.get('https://api-quiz.hype.space/users',
                            params: { q: name },
                            Authorization: key,
                            'Content-Type': :json)

    iddata = JSON.parse(findid)['data']

    if iddata.length.zero?
      begin
        event.channel.send_embed do |embed|
          embed.title = 'Error while searching for stats'
          embed.colour = 'E6286E'
          embed.description = 'Username not found.'
        end
      rescue Discordrb::Errors::NoPermission
        event.respond 'That user doesn\'t exist!'
      end
      break
    end

    id = iddata[0]['userId']

    data = RestClient.get("https://api-quiz.hype.space/users/#{id}",
                          Authorization: key,
                          'Content-Type': :json)

    data = JSON.parse(data)

    begin
      event.channel.send_embed do |embed|
        embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "User stats for #{data['username']}", url: URI.escape(data['referralUrl']))
        embed.colour = '36399A'

        embed.add_field(name: 'Game Stats', value: [
          "Games Played - #{data['gamesPlayed']}",
          "Win Count - #{data['winCount']}"
        ].join("\n"), inline: true)

        embed.add_field(name: 'Amount Won', value: data['leaderboard']['total'], inline: true)

        embed.add_field(name: 'High Score', value: "#{data['highScore']} questions", inline: true)

        embed.add_field(name: 'Badges', value: "#{data['achievementCount']} badges", inline: true) unless data['achievementCount'].zero?

        if namearg.length.zero? && File.exist?(filename)
          embed.add_field(name: 'Extra Lives', value: "#{data['lives']} Lives", inline: true) if profile['lives']
          if profile['streak']
            embed.add_field(name: 'Streak Info', value: [
              "#{data['streakInfo']['target'] - data['streakInfo']['current']} days left",
              "#{data['streakInfo']['total']} total streak"
            ].join("\n"), inline: true)
          end
        end

        embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: 'Account created on')
        embed.timestamp = Time.parse(data['created'])
        embed.thumbnail = { url: data['avatarUrl'].to_s }
      end
    rescue Discordrb::Errors::NoPermission
      event.respond 'Hey, Scott Rogowsky here. I need some memes, dreams, and the ability to embed links! You gotta grant me these permissions!'
    end
  end
end
