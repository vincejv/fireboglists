#!/usr/bin/env bash

AUTHOR_NAME="Vince Jerald Villamora"             # Author name
AUTHOR_EMAIL="vincevillamora@gmail.com"          # Author email
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36"  # Custom user agent string to prevent detection
LAST_UPD=$(date -u)
GIT_CREDS=$(cat /opt/scripts/ads/.gittoken)      # Git token in the format of ${USERNAME}:${TOKEN/PASSWORD}
GIT_PROT="https"                                 # Git Protocol to use
GIT_URL="github.com/vincejv/fireboglists"        # Destination repo, without protocol specified
DELAY_WGET="4"                                  # Add wait to prevent scraping detection

echo "Setting up git credentials"
/usr/bin/git config user.name "$AUTHOR_NAME"
/usr/bin/git config user.email "$AUTHOR_EMAIL"

echo "Cleaning up before start"
rm -rf target/
rm -rf working/
mkdir target/
mkdir working/

/usr/bin/systemd-notify --ready --status="Downloading from sources"

echo "Downloading blocklist source"
/usr/bin/curl --user-agent "$USER_AGENT" https://v.firebog.net/hosts/lists.php?type=tick > working/fireboglist.txt
echo "Downloading blocklist"
/usr/bin/wget -w "$DELAY_WGET" --random-wait -nv -U "$USER_AGENT" -i working/fireboglist.txt -P target/
echo "Combining lists"
cat target/* > working/combinedlist.txt
echo "Sorting and removing duplicates"
/usr/bin/sort working/combinedlist.txt | /usr/bin/uniq > ticklist

echo "Cleaning up repository before commit"
rm -rf target/
rm -rf working/

/usr/bin/systemd-notify --status="Processing blocklists"

echo "# Firebog Tick List" > README.md
echo "Last updated: $LAST_UPD" >> README.md
echo "Commiting to repository"
/usr/bin/git add -A .
/usr/bin/git commit -m "Update tick list for ${LAST_UPD}"
echo "Pushing to repository"
/usr/bin/git push "${GIT_PROT}://${GIT_CREDS}@${GIT_URL}"

echo "Wait for git cache..."
/usr/bin/sleep 5
echo "Updating pihole lists"

/usr/bin/systemd-notify --status="Updating pihole blocklists"
/usr/local/bin/pihole -g
echo "Done!"
/usr/bin/systemd-notify --status="Done"
