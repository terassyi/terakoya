function gh_release -d 'Get releases from Github
  exp) gh_release kubernetes kubernetes latest'

    set msg (gh auth status)
    if test $status -eq 1
        echo $msg
        return 1
    end
    set owner $argv[1]
    set name $argv[2]
    set ver $argv[3]

    set pattern (__build_pattern $ver)

    set versions (__gh_release $owner $name | jq '.data.repository.releases.nodes')

    if test (echo $versions | jq 'length') -eq 0
        set versions (__gh_tag $owner $name | jq -r '.data.repository.refs.nodes.[].name')
        if test $pattern = latest
            set versions (__extract_semver "\d+\.\d+\.\d+" $versions)
        else
            set versions (__extract_semver $pattern $versions)
        end
        echo $versions | tr ' ' '\n' | sort -Vr | tr ' ' '\n' | head -n 1
    else
        if test $pattern = latest
            set versions (echo $versions | jq -r '.[] | select(.isLatest==true) | .tag.name')
        else
            set versions (echo $versions | jq -r '.[] | select(.isPrerelease==false and .isDraft==false) | .tag.name')
        end
        set versions (__extract_semver $pattern $versions)
        echo $versions | tr ' ' '\n' | sort -Vr | tr ' ' '\n' | head -n 1
    end
end

function __gh_release
    set owner $argv[1]
    set name $argv[2]

    gh api graphql -F owner=$owner -F name=$name -f query='
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        releases(first: 100, orderBy: {field: CREATED_AT, direction: DESC}) {
          nodes { name tag { name } isLatest isPrerelease isDraft }
        }
      }
    }'
end

function __gh_tag
    set owner $argv[1]
    set name $argv[2]

    gh api graphql -F owner=$owner -F name=$name -f query='
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        refs(refPrefix: "refs/tags/", first: 100, orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) {
          nodes { name }
        }
      }
    }'
end

function __build_pattern
    set pattern1 "\d+\.\d+\.\d+"
    set pattern2 "\d+\.\d+"
    set pattern3 "\d+"

    set ver $argv[1]

    if string length -q -- (echo $ver | string match -r $pattern1)
        echo $ver
    else if string length -q -- (echo $ver | string match -r $pattern2)
        set escaped_ver (string escape $ver)
        echo "$escaped_ver\.\d+"
    else if string length -q -- (echo $ver | string match -r $pattern3)
        set escaped_ver (string escape $ver)
        echo "$escaped_ver\.\d+\.\d+"
    else
        echo latest
    end
end

function __extract_semver
    set pattern $argv[1]

    set versions

    for v in $argv[2..-1]
        set vv (echo $v | string match -r $pattern)
        set versions $versions $vv
    end

    echo $versions
end
