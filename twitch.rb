class TwitchBot
	require 'socket'

	TWITCH_IRC = 'irc.twitch.tv'

	def initialize(username, oauth, channel)
		@username = username
		@oauth = oauth
		@channel = channel

		@connected = false
		@joined = false

		@readthread = nil
		@socket = nil
		@twitch_message_events = []
		@twitch_join_events = []
		@twitch_part_events = []
		@twitch_connect_events = []

		on_connect do 
			irc_join(channel)
		end
	end

	def on_message(options, &block)
		sender = /.*/
		recipient = /.*/
		message = /.*/
		
		sender = options[:sender] if options[:sender] != nil
		recipient = options[:recipient] if options[:recipient] != nil
		message = options[:message] if options[:message] != nil

		@twitch_message_events << {[sender, recipient, message] => block}
	end

	def on_join(options, &block)
		user = /.*/
		channel = /.*/

		user = options[:user] if options[:user] != nil
		channel = options[:channel] if options[:channel] != nil

		@twitch_join_events << {[user, channel] => block}
	end

	def on_part(options, &block)
		user = /.*/
		channel = /.*/

		user = options[:user] if options[:user] != nil
		channel = options[:channel] if options[:channel] != nil

		@twitch_part_events << {[user, channel] => block}
	end

	def on_connect(&block)
		@twitch_connect_events << block
	end

	def process_message(prefix, command, args)
		if command.match /376|422/
			@twitch_connect_events.each do |event|
				event.call()
			end
		end

		if command.downcase == 'privmsg'
			@twitch_message_events.each do |event|
				options = event.keys.first
				sender_regexp    = options[0]
				recipient_regexp = options[1]
				message_regexp   = options[2]

				command_sender    = prefix.split('!')[0].downcase
				command_recipient = args[0]
				command_message   = args[1]

				if command_sender.match sender_regexp and 
				   command_recipient.match recipient_regexp and 
				   command_message.match message_regexp
					event.values.first.call(command_sender, command_recipient, command_message)
				end	
			end
		end

		if command.downcase == 'join'
			@twitch_join_events.each do |event|
				options = event.keys.first
				joiner_regexp = options[0]
				channel_regexp = options[1]

				command_joiner = prefix.split('!')[0].downcase
				command_channel = args[0]

				if command_joiner.match joiner_regexp and 
				   command_channel.match channel_regexp
					event.values.first.call(command_joiner, command_channel)
				end
			end
		end

		if command.downcase == 'part'
			@twitch_part_events.each do |event|
				options = event.keys.first
				user_regexp = options[0]
				channel_regexp = options[1]

				command_user = prefix.split('!')[0].downcase
				command_channel = args[0]

				if command_user.match user_regexp and 
				   command_channel.match channel_regexp
					event.values.first.call(command_user, command_channel)
				end
			end
		end
	end

	def say(message)
		irc_raw("PRIVMSG #{@channel} :#{message}")
	end

	# IRC functions
	def irc_raw(data)
		return if @socket.nil?
		@socket.print("#{data}\r\n")
	end
	
	def irc_pass(password)
		irc_raw("PASS #{password}")
	end

	def irc_nick(username)
		irc_raw("NICK #{username}")
	end

	def irc_user(username, hostname, servername, realname)
		irc_raw("USER #{username} #{hostname} #{servername} :#{realname}")
	end

	def irc_pong(server)
		irc_raw("PONG :#{server}")
	end

	def irc_join(channel)
		irc_raw("JOIN #{channel}")
	end

	def parse_command(raw)
		prefix  = ''
		command = ''
		args    = []
		rawsplit = raw.split(' ')

		hasPrefix = raw.start_with? ':'

		if hasPrefix
			prefix  = rawsplit[0].sub ':', ''
			command = rawsplit[1]
			args    = rawsplit[2..-1]
		else
			command = rawsplit[0]
			args    = rawsplit[1..-1]
		end

		argcopy = args.clone
		args = []
		argcopy.each_with_index do |e, i|
			if e.start_with? ':'
				args << argcopy[i..-1].join(" ").sub(':', '')
				break
			else
				args << e
			end
		end
		[prefix, command, args]
	end

	# Yeah
	def start_read_thread
		return if not @readthread.nil?
		@readthread = Thread.new {
			loop do
				data = @socket.gets.chomp
				parsed = parse_command(data)
				process_message(parsed[0], parsed[1], parsed[2])
			end
		}
	end

	def join
		return if @readthread.nil?
		@readthread.join
	end

	def connect
		return if not @socket.nil?

		@socket = TCPSocket.new TWITCH_IRC, 6667
		irc_pass(@oauth)
		irc_nick(@username)
		irc_user(@username, '8', '*', @username)
		irc_raw("CAP REQ :twitch.tv/membership")
		start_read_thread()
	end
end
