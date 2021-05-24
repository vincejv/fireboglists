#!/usr/bin/env bash

AUTHOR_NAME="Vince Jerald Villamora"
AUTHOR_EMAIL="vincevillamora@gmail.com"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36"
LAST_UPD=$(date -u)
GIT_CREDS=$(cat /opt/scripts/ads/.gittoken)

echo "Setting up git credentials"
git config user.name "$AUTHOR_NAME"
git config user.email "$AUTHOR_EMAIL"

echo "Cleaning up before start"
rm -rf target/
rm -rf working/
mkdir target/
mkdir working/

systemd-notify --ready --status="Downloading from sources"

echo "Downloading blocklist source"
curl https://v.firebog.net/hosts/lists.php?type=tick > working/fireboglist.txt
echo "Downloading blocklist"
wget -nv -U "$USER_AGENT" -i working/fireboglist.txt -P target/
echo "Combining lists"
cat target/* > working/combinedlist.txt
echo "Sorting and removing duplicates"
sort working/combinedlist.txt | uniq > ticklist

echo "Cleaning up repository before commit"
rm -rf target/
rm -rf working/

systemd-notify --status="Processing blocklists"

echo "# Firebog Tick List" > README.md
echo "Last updated: $LAST_UPD" >> README.md
echo "Commiting to repository"
git add -A .
git commit -m "Update tick list for ${LAST_UPD}"
echo "Pushing to repository"
git push "https://${GIT_CREDS}@github.com/vincejv/fireboglists"

echo "Wait for git cache..."
sleep 5
echo "Updating pihole lists"

systemd-notify --status="Updating pihole blocklists"
pihole -g
echo "Done!"
