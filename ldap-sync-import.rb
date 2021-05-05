#!/usr/bin/env ruby

require 'httparty'
require 'yaml'
require './mattermost.rb'

log_output = STDOUT

if ARGV.length > 0
	if ARGV[0] == "--apply"
		$apply_changes = true
	else
		exit "Invalid argument"
	end
end

$log = Logger.new(log_output)
$log.level = Logger::INFO

$log.info('Starting LDAP Sync Import...')

required_env_vars = ['MATTERMOST_URL', 'MATTERMOST_USERNAME', 'MATTERMOST_AUTH_TOKEN']
error = false

required_env_vars.each do |var|
	unless ENV.keys.include? var
		error = true
		$log.error("Environment Variable #{var} is not set"	)
	end
end

if error
	$log.fatal('Missing environment variables. Please set them before running again')
	exit 1
end

$apply_changes = false
if ENV.keys.include?('APPLY_CHANGES') and ENV['APPLY_CHANGES'] == 'true'
	$log.warn('Applying changes!')
	$apply_changes = true
else
	$log.info('Dry Run. No changes will be made.')
end

mattermost_config = {url: ENV['MATTERMOST_URL'], login_id: ENV['MATTERMOST_USERNAME'], auth_token: ENV['MATTERMOST_AUTH_TOKEN']}

mattermost_api = MattermostApi.new(mattermost_config)

sync_mapping = YAML.load(
	File.open('./sync-mapping.yml').read
)

sync_mapping.each do |group_name, teams|
	found_group = mattermost_api.get_group_id_by_name(group_name)

	case 
	when found_group.length == 1
		$log.info("Found group id for #{group_name} (#{found_group[0]['id']})")
		group_id = found_group[0]['id']
	when found_group.length == 0
		$log.warn("Could not find a linked group with the name #{group_name}, skipping")
		next
	when found_group.length > 1
		$log.warn("Found more than one group with the name #{group_name}, skipping")
		next
	end

	teams.each do |team_name, channels|
		team_auto_add = false

		found_team = mattermost_api.get_team_id_by_name(team_name)

		if found_team.nil? || !found_team.keys.include?('id')
			$log.warn("Could not find team #{team_name}, skipping")
			next
		else
			team_id = found_team['id']
		end

		if channels.nil? || channels == 'enforce'
			$log.info("Linking team #{team_name} (#{team_id}) to group #{group_name} (#{group_id})")
			
			if channels == 'enforce'
				$log.info("Enforcing membership in team #{team_name} (#{team_id}) for #{group_name} (#{group_id})")
				team_auto_add = true
			end

			if $apply_changes === true
				if mattermost_api.link_team_to_group(team_id, group_id, team_auto_add).nil?
					$log.error(" - LINK FAILED!")
				else
					$log.info(" - Link Successful!")
				end
			else
				$log.info(" - Dry run, no changes made"	)
			end

			next
		end

		channels.each do |channel_name, channel|
			channel_auto_add = false

			found_channel = mattermost_api.get_channel_id_by_name(channel_name, team_name)

			if found_channel.nil? || !found_channel.keys.include?('id')
				$log.info("Could not find channel #{team_name}:#{channel_name}, skipping")
				next
			else
				channel_id = found_channel['id']
			end

			$log.info("Linking channel #{team_name}:#{channel_name} (#{channel_id}) to group #{group_name} (#{group_id})")
			if channel == 'enforce'
				channel_auto_add = true
				$log.info("Enforcing membership in #{team_name}:#{channel_name} (#{channel_id}) for #{group_name} (#{group_id})")
			end
			
			if $apply_changes === true
				if mattermost_api.link_channel_to_group(channel_id, group_id).nil?
					$log.info(" - LINK FAILED!")
				else
					$log.info(" - Link Successful! ")
				end
			else
				$log.info(" - Dry run, no changes made"	)
			end
		end
	end
end