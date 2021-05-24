#!/usr/bin/env bash

LAST_UPD=$(date -u)

echo "Cleaning up before start"
rm -rf target/
rm -rf working/
mkdir target/
mkdir working/

echo "Downloading blocklist source"
curl https://v.firebog.net/hosts/lists.php?type=tick > working/fireboglist.txt
echo "Downloading blocklist"
wget -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36" -q --show-progress -i working/fireboglist.txt -P target/
echo "Combining lists"
cat target/* > working/combinedlist.txt
echo "Sorting and removing duplicates"
sort working/combinedlist.txt | uniq > ticklist

echo "Cleaning up repository before commit"
rm -rf target/
rm -rf working/

echo "# Firebog Tick List" > README.md
echo "Last updated: $LAST_UPD" >> README.md
echo "Commiting to repository"
git add -A .
git commit -m "Update tick list for ${LAST_UPD}"
echo "Pushing to repository"
git push

echo "Wait for git cache..."
sleep 5
echo "Updating pihole lists"
pihole -g
echo "Done!"
