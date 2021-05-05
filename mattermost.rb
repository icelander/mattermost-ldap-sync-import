require 'httparty'
require 'uri'

class MattermostApi
	include HTTParty
	attr_accessor :groups

	format :json
	# debug_output $stdout
	
	def initialize(config)
		# Default Options
		@options = {
			headers: {
				'Content-Type' => 'application/json'
			},
			# TODO Make this more secure
			# verify: false
		}

		if config.key?(:url) && !config[:url].nil?
			unless config[:url].end_with? '/'
				config[:url] = config[:url] + '/'
			end

			unless url_valid?(config[:url])
				raise "URL #{url} is invalid"
			end
		else
			raise 'url is required in configuration'
		end

		@base_uri = config[:url] + 'api/v4/'

		token = nil

		if config.key?(:auth_token)
			token = config[:auth_token]
		else
			raise 'auth token not set'
		end

		if token.nil?
			raise 'auth token not set'
		else
			@options[:headers]['Authorization'] = "Bearer #{token}"
		end

		@options[:body] = nil
		@options[:query] = nil
	end

	def get_current_user
		get_url('users/me')
	end

	def get_team_id_by_name(team_name)
		url = "teams/name/#{team_name}"
		response = self.get_url(url)
		
		return response
	end

	def get_group_id_by_name(group_name)
		url = 'groups'
		query = {q: group_name}

		response = self.get_url(url, query)

		return response
	end

	def link_team_to_group(team_id, group_id, auto_add=false)
		url = "groups/#{group_id}/teams/#{team_id}/link"
		groupteam = {
			team_id: team_id,
  			group_id: group_id,
  			auto_add: auto_add
		}
		response = self.post_data(groupteam, url)
		# pp response
		return response
	end

	def link_channel_to_group(channel_id, group_id, auto_add=false)
		url = "groups/#{group_id}/channels/#{channel_id}/link"
		groupchannel = {
			channel_id: channel_id,
  			group_id: group_id,
  			auto_add: auto_add
		}
		response = self.post_data(groupchannel, url)
		# pp response
		return response
	end


	def get_channel_id_by_name(provided_channel_name, provided_team_name=nil)
		if provided_team_name.nil? and provided_channel_name.include?(':')
			(team_name, channel_name) = provided_channel_name.split(':')
		else
			team_name = provided_team_name
			channel_name = provided_channel_name
		end

		if team_name.nil? || channel_name.include?(':')
			raise "Invalid channel and team name: #{provided_channel_name} #{team_name}"
		end

		url = "teams/name/#{team_name}/channels/name/#{channel_name}"

		response = self.get_url(url)
		
		return response
	end

	private

	def url_valid?(url)
		url = URI.parse(url) rescue false
	end

	def get_url(url, query=nil)
		@options[:query] = nil
		
		unless query.nil?
			@options[:query] = query
		end

		response = self.class.get("#{@base_uri}#{url}", @options)

		@options[:query] = nil

		if response.code >= 200 && response.code <= 300 # Successful
			JSON.parse(response.to_s)	
		else
			return nil
		end		
	end

	def post_data(payload, request_url)
		
		@options[:body] = nil
		
		unless payload.nil? 
			@options[:body] = payload.to_json
		end
		
		response = self.class.post("#{@base_uri}#{request_url}", @options)

		@options[:body] = nil

		if response.code >= 200 && response.code <= 300 # Successful
			return JSON.parse(response.to_s)	
		else
			return nil
		end

		
	end

	def put_data(payload, request_url)
		options = @options
		options[:body] = payload.to_json

		self.class.put("#{@base_uri}#{request_url}", options)
	end
end