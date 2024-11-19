#! /bin/bash
# Do not forget to give executable permission to your script
#Define directory and file parameters
directory="/etc/custom_sox_logs_workspace"
baseline_file_version="$directory/passwd.prev"
source_system_file="/etc/passwd"
current_file_version="$directory/passwd.curr"

# Create new directory defined in the $directory variable if it doesn't already exist
if [[ ! -d "$directory" ]]; then
echo "Creating Base Directory Workspace..."
mkdir -p "$directory"
echo "Base Directory Created - /etc/custom_sox_logs_workspace"
else
echo "Base Directory Exists !"
fi

# Check if the baseline passwd file exists and create if it doesn't in the $directory
if [[ ! -f "$baseline_file_version" ]]; then
echo "Creating Baseline File..."
cp "$source_system_file" "$baseline_file_version"
sudo chown root:root "$baseline_file_version"
sudo chmod 644 "$baseline_file_version"
echo "Baseline File Created - /etc/custom_sox_logs_workspace/passwd.prev"
else
echo "Baseline File Exists !"
fi

#Create the current version of the 'passwd' file to '/etc/custom_sox_logs_workspace/passwd.curr'
echo "Creating Comparison File in Workspace Directory..."
cp "$source_system_file" "$current_file_version"
sudo chown root:root "$current_file_version"
sudo chmod 644 "$current_file_version"
echo "Comparison File Created !"

echo "Checking for Line Modifications / Additions in the Comparison File..."
while IFS= read -r line_extract; do
user_name="${line_extract%%:*}"
if grep -q "$user_name" "$baseline_file_version"; then
user_name_match="1"
else
user_name_match="0"
fi
if grep -q "$line_extract" "$baseline_file_version"; then
line_match="1"
else
line_match="0"
fi
if [[ "$user_name_match" -eq "1" && "$line_match" -eq "1" ]]; then
echo -n ""
elif [[ "$user_name_match" -eq "1" && "$line_match" -eq "0" ]]; then
log_message="$(hostname -f)|passwd|Line Modification|$line_extract"
logger -p user.info -t passwd_changes "$log_message"
elif [[ "$user_name_match" -eq "0" && "$line_match" -eq "0" ]]; then
log_message="$(hostname -f)|passwd|Line Addition|$line_extract"
logger -p user.info -t passwd_changes "$log_message"
fi
done < "$current_file_version"
echo "Completed !"

echo "Checking for Line Deletions from the Baseline File..."
while IFS= read -r line_extract; do
if grep -q "$user_name" "$baseline_file_version"; then
user_name_match="1"
else
user_name_match="0"
fi
if grep -q "$line_extract" "$baseline_file_version"; then
line_match="1"
else
line_match="0"
fi
if [[ "$user_name_match" -eq "0" && "$line_match" -eq "0" ]]; then
log_message="$(hostname -f)|passwd|Line Deletion|$line_extract"
logger -p user.info -t passwd_changes "$log_message"
fi
done < "$baseline_file_version"
echo "Completed !"

echo "Deleting Current Comparison and Baseline Files..."
shred -u "$current_file_version"
shred -u "$baseline_file_version"
echo "Completed"

echo "Creating New Baseline File in Workspace Directory..."
cp "$source_system_file" "$baseline_file_version"
echo "Completed"
echo "All Operations Completed !"
