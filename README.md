# Firebog Tick List
Last updated: Tue 25 May 2021 05:29:09 PM UTC

#### Blocklist source: https://firebog.net/

Download script log is located at: `cronlog/` to check which sources were downloaded successfully and compiled to the main blocklist

------------

##### Systemd Configuration (need own git repository)
- Runs daily
- Updates pihole blocklists if older than 7 days
- Repository must be stored in `/opt/scripts/ads/fireboglists` (WIP install script)
- Git credentials must be stored in `/opt/scripts/ads/.gittoken` in the format of `${USERNAME}:${TOKEN/PASSWORD}`
- Generate token, follow [this guide](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- Must host own git repository in github, gitlab or bitbucket
- Update git credentials, `AUTHOR_NAME`, `AUTHOR_EMAIL`, `GIT_PROT`, `GIT_URL`
- Add to pihole adlists `https://raw.githubusercontent.com/${USERNAME}/${REPO_NAME}/master/blocklists/${BLOCKLIST_FILE}` 

#### Alternate Systemd Configuration (git-less approach)
- Almost Same as above but git steps can be skipped and use alternative adlist source - localhost
- (Optional, can be skipped) Unset git credentials, no need for token file
- Set `PIHOLE_HTML_DIR` to pihole root `wwww` directory, this is usally `/var/www/html/`
- Add to pihole adlists `http://127.0.0.1/blocklists/${BLOCKLIST_FILE}` (add port if necessary)
- Make sure no existing files or directory are in `"${PIHOLE_HTML_DIR}/${BLOCKLIST_PATH}"` or else it will get overwritten

#### Install as Systemd service (you may copy paste this to terminal, run as root)

    mkdir -p /opt/scripts/ads/
    cd /opt/scripts/ads/
    git clone https://github.com/vincejv/fireboglists
    ln -s /opt/scripts/ads/fireboglists/systemd/* /etc/systemd/system
    systemctl enable --now blocklist-repo-update.timer

