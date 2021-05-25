#!/usr/bin/env bash

GRAVITY_DB="/etc/pihole/gravity.db"
GIT_CREDS_FILE="/opt/scripts/ads/.gittoken"
BLOCKLIST_PATH="blocklists/"
README_FILE="README.md"

# check if files exist
prevalidation() {
  if [ ! -f "$GRAVITY_DB" ] || [ ! -f "$GIT_CREDS_FILE" ]; then
    echo "Check if ${GRAVITY_DB} and ${GIT_CRED_FILE} exists" 1>&2
    exit 1 # terminate and indicate error
  fi
}
prevalidation

# Wget options
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36"  # Custom user agent string to prevent detection
DELAY_WGET="4"                                    # Add wait to prevent scraping detection
FIREBOG_TICKLIST="https://v.firebog.net/hosts/lists.php?type=tick"

# Gravity lists options
LAST_UPD=$(date -u)                                       # Full UTC Date
DAYS_TO_CHECK="7"
DAYS_AGO=$(date -u -d "now - ${DAYS_TO_CHECK} days" +%s)  # Max Last gravity update
GRAVITY_LAST_UPD=$(date -u -r "$GRAVITY_DB" +%s)          # Gravity DB Last update in UTC

# Git options
AUTHOR_NAME="Vince Jerald Villamora"             # Author name
AUTHOR_EMAIL="vincevillamora@gmail.com"          # Author email
GIT_CREDS=$(cat "$GIT_CREDS_FILE")      # Git token in the format of ${USERNAME}:${TOKEN/PASSWORD}
GIT_PROT="https"                                 # Git Protocol to use
GIT_URL="github.com/vincejv/fireboglists"        # Destination repo, without protocol specified

echo "Setting up git credentials"
/usr/bin/git config user.name "$AUTHOR_NAME"
/usr/bin/git config user.email "$AUTHOR_EMAIL"

echo "Cleaning up before start"
rm -rf target/
rm -rf working/
mkdir target/
mkdir working/
mkdir -p "$BLOCKLIST_PATH"

/usr/bin/systemd-notify --ready --status="Downloading from sources"

echo "Downloading blocklist source: %FIREBOG_TICKLIST"
/usr/bin/curl --no-progress-meter --user-agent "$USER_AGENT" "$FIREBOG_TICKLIST" > working/fireboglist.txt
echo "Downloading blocklists from list file"
/usr/bin/wget -w "$DELAY_WGET" --random-wait -nv -U "$USER_AGENT" -i working/fireboglist.txt -P target/
echo "Combining files"
cat target/* > working/combinedlist.txt
echo "Sorting and removing duplicates"
/usr/bin/sort working/combinedlist.txt | /usr/bin/uniq > "${BLOCKLIST_PATH}ticklist"

echo "Cleaning up repository before commit"
rm -rf target/
rm -rf working/

/usr/bin/systemd-notify --status="Processing blocklists"

/usr/bin/sed -i '2s/.*/Last updated: ${LAST_UPD}/' "$README_FILE"

echo "Commiting to repository"
/usr/bin/git add -A "$BLOCKLIST_PATH"                         # only commit blocklists
/usr/bin/git commit -m "Update blocklists for ${LAST_UPD}"
echo "Pushing to repository"
/usr/bin/git push "${GIT_PROT}://${GIT_CREDS}@${GIT_URL}"

# Only update if Gravity list is older than DAYS_AGO
echo "Gravity was last updated on $(date -d @${GRAVITY_LAST_UPD})"
if (( GRAVITY_LAST_UPD <= DAYS_AGO )); then
  echo "Updating gravity db since last update was already ${DAYS_TO_CHECK} days ago"
  echo "Wait for git cache..."
  /usr/bin/sleep 5
  echo "Updating pihole lists"

  /usr/bin/systemd-notify --status="Updating pihole blocklists"
  /usr/local/bin/pihole -g
else
  echo "Gravity db was recently updated, skipping update"
fi

echo "Done!"
/usr/bin/systemd-notify --status="Done"
