function tools_version_init
	mkdir -p ~/tools/
	if not test -s ~/tools/.versions.json
		echo "{}" > ~/tools/.versions.json
	end
end
