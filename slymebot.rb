class SlymeBot
	require 'json'

	require './twitch.rb'
	require './osu.rb'

	MEDIA_MESSAGE = 'Twitter: @xbadf00d | Github: AlmostZeroCool | Website: slyme.me'

	def initialize
		config_file = File.open('conf.json')
		config = JSON.parse(config_file.read)
		config_file.close

		osu_key         = config['osu_key']
		twitch_username = config['twitch_username']
		twitch_oauth    = config['twitch_oauth']
		twitch_channel  = config['twitch_channel']

		osu = Osu.new(osu_key)
		@twitch = TwitchBot.new(twitch_username, twitch_oauth, twitch_channel)

		@twitch.on_connect do 
			puts "[+] Connected"
		end

		@twitch.on_join({}) do |user, channel|
			puts "[+] #{user} joined #{channel}"
		end

		@twitch.on_message :message => /^!media$/ do |sender, target, message|
			@twitch.say(MEDIA_MESSAGE)
		end

		@twitch.on_message :message => /^!osustat [A-Za-z0-9_\-\[\]]*$/ do |sender, target, message|
			begin
				user = JSON.parse(osu.getUser(:u => message.split(' ')[1])).first
				user_country = user['country']
				country_rank = user['pp_country_rank']
				count300     = user['count300']
				count100     = user['count100']
				count50      = user['count50']
				playcount    = user['playcount']
				ranked_score = user['ranked_score']
				total_score  = user['total_score']
				pp_rank      = user['pp_rank']
				level        = user['level']
				accuracy     = user['accuracy']


				message = "Stats for #{user['user_id']} | " +
					"Country: #{user_country} | " +
					"Country rank: #{country_rank} | " + 
					"Count300: #{count300} | " + 
					"Count100: #{count100} | " +
					"Count50: #{count50} | " +
					"Play count: #{playcount} | " +
					"Ranked score: #{ranked_score} | " +
					"Total score: #{total_score} | " +
					"PP rank: #{pp_rank} | " +
					"Level: #{level} | " + 
					"Accuracy: #{accuracy}"
				@twitch.say(message)
			rescue NoMethodError
				@twitch.say("@#{sender}: I can't find a user with that name")
			end
		end
	end

	def run()
		@twitch.connect
		@twitch.join
	end
end



slymebot = SlymeBot.new
slymebot.run()
