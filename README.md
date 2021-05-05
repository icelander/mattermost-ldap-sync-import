# Mattermost Recipe: LDAP Sync Import

## Problem

You want to automate linking AD/LDAP groups to Mattermost LDAP Group Sync

## TODO

- [x] Read sync-mapping.yml
- [x] Link teams and groups
- [x] Add team/channel membership enforcement

## Solution

### 0. Read this document completely

### 1. Create Sync Mapping

This step tells the script how to map AD/LDAP groups to Mattermost teams and channels. Modify `sync-mapping.yml` to match your environment. Make sure that:

 - The group names match what you see when you go to `System Console` > `Groups`, and only linked groups will be processed
 - Use team and channel names, not display names. e.g. "planet-express" and not "Planet Express"
 - If you want a whole team to be linked to a group, just provide the team name

Note that teams/channels will **not** be unlinked from groups during this process. Only new links will be created.

### 3. Run the Docker container

First, build the Docker container with this command:

```bash
docker build -t ldap-sync-import .
```

To perform a dry run, use this command. Be sure to replace the `--volume` with the absolute path to your sync-mapping.yml file.

```bash
docker run -it --name ldap-sync-import-dry-run\
MATTERMOST_URL='http://mattermost.planex.com'\
	--env MATTERMOST_USERNAME='admin'\
	--env MATTERMOST_AUTH_TOKEN='ywfeuhfmuifmujba3ui5zu4fbh'\
	--volume "`pwd`/sync-mapping.yml":/usr/src/app/sync-mapping.yml\
	ldap-sync-import
```

Review the log entries to verify that the mappings are correct. To retrieve the logs from the dry run container, use this command:

```bash
docker logs ldap-sync-import-dry-run
```

To apply these changes, add the `APPLY` environment variable:

```bash
docker run -it --name ldap-sync-import-apply-changes\
	--env MATTERMOST_URL='http://mattermost.planex.com'\
	--env MATTERMOST_USERNAME='admin'\
	--env MATTERMOST_AUTH_TOKEN='ywfeuhfmuifmujba3ui5zu4fbh'\
	--volume "`pwd`/sync-mapping.yml":/usr/src/app/sync-mapping.yml\
	--env APPLY_CHANGES='true'\
	ldap-sync-import
```

To retrieve the log entries, run this command:

```bash
docker logs ldap-sync-import-apply-changes
```

### 4. Clean Up (optional)

Delete the containers you created with these commands

```bash
docker container rm ldap-sync-import-dry-run
docker container rm ldap-sync-import-apply-changes
```