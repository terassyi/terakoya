function tools_version_update -d "tools_version_update <cmd_name> <owner> <name> <version> <path>"

	# example
	# {
    #   "go": {
	#     "owner": "golang",
	#     "name": "go",
	#     "version": "1.24.0"
	#     "path": "$HOME/go/bin/go"
	#   },
    #   "kubectl": {
	#     "owner": "kubernetes",
	#     "name": "kubernetes",
	#     "version": "1.32.0"
	#     "path": "$HOME/tools/bin/kubectl"
	#   },
	# }
	#

	# This function must be safe
	tools_version_init
	set file "$HOME/tools/.versions.json"

	set cmd_name $argv[1]
	set owner $argv[2]
	set name $argv[3]
	set ver $argv[4]
	set bin_path $argv[5]

	set new_state (cat $file | jq --arg cmd_name "$cmd_name" --arg owner "$owner" --arg name "$name" --arg ver "$ver" --arg bin_path "$bin_path" '. + { $cmd_name: { "owner": $owner, "name": $name, "version": $ver, "path": $bin_path } }')

	echo $new_state | jq .
	if test $status = 0
		echo "Store new $owner/$name $ver to .versions.json"
		echo $new_state > $file
	end
end
