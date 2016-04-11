class Osu
	require 'net/http'

	def initialize(api_key, api_frontend='https://osu.ppy.sh/')
		@api_key = api_key
		@api_frontend = api_frontend
	end

	def getEndPoint(endpoint, params)
		params['k'] = @api_key

		uri = URI(@api_frontend + endpoint)
		uri.query = URI.encode_www_form(params)
		res = Net::HTTP.get_response(uri)
		if res.is_a? Net::HTTPSuccess
			return res.body
		end
		res.code
	end

	# I don't use most of these but whatever
	def getBeatMaps(options={})
		getEndPoint('api/get_beatmaps', options)	
	end

	def getUser(options={})
		getEndPoint('api/get_user', options)
	end

	def getScores(options={})
		getEndPoint('api/get_scores', options)
	end

	def getUserBest(options={})
		getEndPoint('api/get_user_best', options)
	end

	def getUserRecent(options={})
		getEndPoint('api/get_user_recent', recent)
	end

	def getMatch(options={})
		getEndPoint('api/get_match', options)
	end

	def getReplay(options={})
		getEndPoint('api/get_replay', options)
	end
end

