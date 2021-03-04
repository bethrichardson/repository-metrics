#!/bin/bash

APP_PORT=${1:-7101}
HEALTHCHECK_PORT=${2:-$APP_PORT}
BASE_URL="http://localhost:$APP_PORT"
HEALTHCHECK_URL="http://localhost:$HEALTHCHECK_PORT"

for TOOL in bc curl jq wc awk sort uniq tr head tail; do
    if ! which $TOOL >/dev/null; then
        echo "ERROR: $TOOL is not available in the PATH"
        exit 1
    fi
done

PASS=0
FAIL=0
TOTAL=0

function describe() {
    echo -n "$1"; let TOTAL=$TOTAL+1
}

function pass() {
    echo "pass"; let PASS=$PASS+1
}

function fail() {
    RESPONSE=$1
    EXPECTED=$2
    echo "fail [$RESPONSE != $EXPECTED]";  let FAIL=$FAIL+1
}

function report() {
    PCT=$(echo "scale=2; $PASS / $TOTAL * 100" |bc)
    echo "$PASS/$TOTAL ($PCT%) tests passed"
}

describe "test-01-01: healthcheck = "

ATTEMPTS=0
while true; do
    let ATTEMPTS=$ATTEMPTS+1
    RESPONSE=$(curl -s -o /dev/null -w '%{http_code}' "$HEALTHCHECK_URL/healthcheck")
    if [[ $RESPONSE == "200" ]]; then
        let TIME=$ATTEMPTS*15
        echo -n "($TIME seconds) "; pass
        break
    else
        if [[ $ATTEMPTS -gt 24 ]]; then
            let TIME=$ATTEMPTS*15
            echo -n "($TIME seconds) "; fail
            break
        fi
        sleep 15
    fi
done

describe "test-02-01: / key count = "

COUNT=$(curl -s "$BASE_URL" |jq -r 'keys |.[]' |wc -l |awk '{print $1}')

if [[ $COUNT -eq 32 ]]; then # matching current value from GitHub API
    pass
else
    fail "$COUNT" "32"
fi

describe "test-02-02: / repository_search_url value = "

VALUE=$(curl -s "$BASE_URL" |jq -r '.repository_search_url')

if [[ "$VALUE" == "https://api.github.com/search/repositories?q={query}{&page,per_page,sort,order}" ]]; then
    pass
else
    fail "$VALUE" "https://api.github.com/search/repositories?q={query}{&page,per_page,sort,order}"
fi

describe "test-02-03: / organization_repositories_url value = "

VALUE=$(curl -s "$BASE_URL" |jq -r '.organization_repositories_url')

if [[ "$VALUE" == "https://api.github.com/orgs/{org}/repos{?type,page,per_page,sort}" ]]; then
    pass
else
    fail "$VALUE" "https://api.github.com/orgs/{org}/repos{?type,page,per_page,sort}"
fi

describe "test-03-01: /orgs/Netflix key count = "

COUNT=$(curl -s "$BASE_URL/orgs/Netflix" |jq -r 'keys |.[]' |wc -l |awk '{print $1}')

if [[ $COUNT -eq 29 ]]; then
    pass
else
    fail "$COUNT" "29" # they must have added a key to the response
fi

describe "test-03-02: /orgs/Netflix avatar_url = "

VALUE=$(curl -s "$BASE_URL/orgs/Netflix" |jq -r '.avatar_url')

if [[ "$VALUE" == "https://avatars.githubusercontent.com/u/913567?v=4" ]]; then
    pass
else
    fail "$VALUE" "https://avatars.githubusercontent.com/u/913567?v=4" # Updated avatar URL
fi

describe "test-03-03: /orgs/Netflix location = "

VALUE=$(curl -s "$BASE_URL/orgs/Netflix" |jq -r '.location')

if [[ "$VALUE" == "Los Gatos, California" ]]; then
    pass
else
    fail "$VALUE" "Los Gatos, California"
fi

describe "test-04-01: /orgs/Netflix/members object count = "

COUNT=$(curl -s "$BASE_URL/orgs/Netflix/members" |jq -r '. |length')

if [[ $COUNT -gt 6 ]] && [[ $COUNT -lt 25 ]]; then # Current value is 23 from GitHub API
    pass
else
    fail "$COUNT" "6..10"
fi

describe "test-04-02: /orgs/Netflix/members login first alpha case-insensitive = "

VALUE=$(curl -s "$BASE_URL/orgs/Netflix/members" |jq -r '.[] |.login' |tr '[:upper:]' '[:lower:]' |sort |head -1)

if [[ "$VALUE" == "andrewhood125" ]]; then # Matches result from GitHub API
    pass
else
    fail "$VALUE" "andrewhood125"
fi

describe "test-04-03: /orgs/Netflix/members login first alpha case-sensitive = "

VALUE=$(curl -s "$BASE_URL/orgs/Netflix/members" |jq -r '.[] |.login' |sort |head -1)

if [[ "$VALUE" == "andrewhood125" ]]; then # Matches result from GitHub API
    pass
else
    fail "$VALUE" "andrewhood125"
fi

describe "test-04-04: /orgs/Netflix/members login last alpha case-insensitive = "

VALUE=$(curl -s "$BASE_URL/orgs/Netflix/members" |jq -r '.[] |.login' |tr '[:upper:]' '[:lower:]' |sort |tail -1)

if [[ "$VALUE" == "wesleytodd" ]]; then # Matches result from GitHub API
    pass
else
    fail "$VALUE" "wesleytodd"
fi

describe "test-04-05: /orgs/Netflix/members id first = "

VALUE=$(curl -s "$BASE_URL/orgs/Netflix/members" |jq -r '.[] |.id' |sort -n |head -1)

if [[ "$VALUE" == "132086" ]]; then # Matches result from GitHub API
    pass
else
    fail "$VALUE" "132086"
fi

describe "test-04-06: /orgs/Netflix/members id last = "

VALUE=$(curl -s "$BASE_URL/orgs/Netflix/members" |jq -r '.[] |.id' |sort -n |tail -1)

if [[ "$VALUE" == "8943572" ]]; then
    pass
else
    fail "$VALUE" "8943572"
fi

describe "test-04-07: /users/chali/orgs proxy = "

VALUE=$(curl -s "$BASE_URL/users/chali/orgs" |jq -r '.[] |.login' |tr '\n' ':')

if [[ "$VALUE" == "Netflix:nebula-plugins:" ]]; then
    pass
else
    fail "$VALUE" "Netflix:nebula-plugins:"
fi

describe "test-04-08: /users/rpalcolea/orgs proxy = "

VALUE=$(curl -s "$BASE_URL/users/rpalcolea/orgs" |jq -r '.[] |.login' |tr '\n' ':')

if [[ "$VALUE" == "Netflix:nebula-plugins:" ]]; then
    pass
else
    fail "$VALUE" "Netflix:nebula-plugins:"
fi

describe "test-05-01: /orgs/Netflix/repos object count = "

COUNT=$(curl -s "$BASE_URL/orgs/Netflix/repos" |jq -r '. |length')

if [[ $COUNT -gt 127 ]] && [[ $COUNT -lt 200 ]]; then # Current result from GitHub API is 196
    pass
else
    fail "$COUNT" "127..200"
fi

describe "test-05-02: /orgs/Netflix/repos full_name first alpha case-insensitive = "

VALUE=$(curl -s "$BASE_URL/orgs/Netflix/repos" |jq -r '.[] |.full_name' |tr '[:upper:]' '[:lower:]' |sort |head -1)

if [[ "$VALUE" == "netflix/.github" ]]; then # Current result from GitHub API
    pass
else
    fail "$VALUE" "netflix/.github"
fi

describe "test-05-03: /orgs/Netflix/members full_name first alpha case-sensitive = " # Should this be repos or members?

VALUE=$(curl -s "$BASE_URL/orgs/Netflix/repos" |jq -r '.[] |.full_name' |sort |head -1)

if [[ "$VALUE" == "Netflix/.github" ]]; then # Current result from GitHub API
    pass
else
    fail "$VALUE" "Netflix/.github"
fi

describe "test-05-04: /orgs/Netflix/members login last alpha case-insensitive = " # Should this be repos or members?

VALUE=$(curl -s "$BASE_URL/orgs/Netflix/repos" |jq -r '.[] |.full_name' |tr '[:upper:]' '[:lower:]' |sort |tail -1)

if [[ "$VALUE" == "netflix/zuul" ]]; then
    pass
else
    fail "$VALUE" "netflix/zuul"
fi

describe "test-05-05: /orgs/Netflix/repos id first = "

VALUE=$(curl -s "$BASE_URL/orgs/Netflix/repos" |jq -r '.[] |.id' |sort -n |head -1)

if [[ "$VALUE" == "2044029" ]]; then
    pass
else
    fail "$VALUE" "2044029"
fi

describe "test-05-06: /orgs/Netflix/repos id last = "

VALUE=$(curl -s "$BASE_URL/orgs/Netflix/repos" |jq -r '.[] |.id' |sort -n |tail -1)

if [[ "$VALUE" == "343540970" ]]; then # Current result from GitHub API
    pass
else
    fail "$VALUE" "343540970"
fi

describe "test-05-07: /orgs/Netflix/repos languages unique = "

VALUE=$(curl -s "$BASE_URL/orgs/Netflix/repos" |jq -r '.[] |.language' |sort -u |tr '\n' ':')

if [[ "$VALUE" == "C:C#:C++:Clojure:D:Dockerfile:Go:Groovy:HTML:Java:JavaScript:Kotlin:Python:R:Ruby:Scala:Shell:TypeScript:Vue:null:" ]]; then # Current result from GitHub API
    pass
else
    fail "$VALUE" "C:C#:C++:Clojure:D:Dockerfile:Go:Groovy:HTML:Java:JavaScript:Kotlin:Python:R:Ruby:Scala:Shell:TypeScript:Vue:null:"
fi

describe "test-06-01: /view/top/5/forks = "

VALUE=$(curl -s "$BASE_URL/view/top/5/forks" |tr -d '\n' |sed -e 's/ //g')

# Updated with current results. Moving target.
if [[ "$VALUE" == '[["Netflix/Hystrix",4317],["Netflix/eureka",3072],["Netflix/zuul",2008],["Netflix/SimianArmy",1117],["Netflix/ribbon",1052]]' ]]; then
    pass
else
    fail "$VALUE" '[["Netflix/Hystrix",4317],["Netflix/eureka",3072],["Netflix/zuul",2008],["Netflix/SimianArmy",1117],["Netflix/ribbon",1052]]'
fi

describe "test-06-02: /view/top/10/forks = "

VALUE=$(curl -s "$BASE_URL/view/top/10/forks" |tr -d '\n' |sed -e 's/ //g')

# Updated with current results. Moving target.

if [[ "$VALUE" == '[["Netflix/Hystrix",4317],["Netflix/eureka",3072],["Netflix/zuul",2008],["Netflix/SimianArmy",1117],["Netflix/ribbon",1052],["Netflix/Cloud-Prize",469],["Netflix/archaius",467],["Netflix/curator",437],["Netflix/asgard",437],["Netflix/netflix.github.com",371]]' ]]; then
    pass
else
    fail "$VALUE" '[["Netflix/Hystrix",4317],["Netflix/eureka",3072],["Netflix/zuul",2008],["Netflix/SimianArmy",1117],["Netflix/ribbon",1052],["Netflix/Cloud-Prize",469],["Netflix/archaius",467],["Netflix/curator",437],["Netflix/asgard",437],["Netflix/netflix.github.com",371]]'
fi


describe "test-06-03: /view/top/5/last_updated = "

VALUE=$(curl -s "$BASE_URL/view/top/5/last_updated" |tr -d '\n' |sed -e 's/ //g')

if [[ "$VALUE" == '[["Netflix/zuul","2021-03-04T04:19:05Z"],["Netflix/eureka","2021-03-04T02:40:16Z"],["Netflix/frigga","2021-03-04T02:38:09Z"],["Netflix/Hystrix","2021-03-04T02:14:35Z"],["Netflix/SimianArmy","2021-03-04T02:01:12Z"]]' ]]; then
    pass
else
    fail "$VALUE" '[["Netflix/zuul","2021-03-04T04:19:05Z"],["Netflix/eureka","2021-03-04T02:40:16Z"],["Netflix/frigga","2021-03-04T02:38:09Z"],["Netflix/Hystrix","2021-03-04T02:14:35Z"],["Netflix/SimianArmy","2021-03-04T02:01:12Z"]]'
fi

describe "test-06-04: /view/top/10/last_updated = "

VALUE=$(curl -s "$BASE_URL/view/top/10/last_updated" |tr -d '\n' |sed -e 's/ //g')

if [[ "$VALUE" == '[["Netflix/zuul","2021-03-04T04:19:05Z"],["Netflix/eureka","2021-03-04T02:40:16Z"],["Netflix/frigga","2021-03-04T02:38:09Z"],["Netflix/Hystrix","2021-03-04T02:14:35Z"],["Netflix/SimianArmy","2021-03-04T02:01:12Z"],["Netflix/Turbine","2021-03-03T17:53:41Z"],["Netflix/EVCache","2021-03-03T17:51:28Z"],["Netflix/ribbon","2021-03-03T17:45:23Z"],["Netflix/servo","2021-03-03T14:34:31Z"],["Netflix/asgard","2021-03-03T13:05:32Z"]]' ]]; then
    pass
else
    fail "$VALUE" '[["Netflix/zuul","2021-03-04T04:19:05Z"],["Netflix/eureka","2021-03-04T02:40:16Z"],["Netflix/frigga","2021-03-04T02:38:09Z"],["Netflix/Hystrix","2021-03-04T02:14:35Z"],["Netflix/SimianArmy","2021-03-04T02:01:12Z"],["Netflix/Turbine","2021-03-03T17:53:41Z"],["Netflix/EVCache","2021-03-03T17:51:28Z"],["Netflix/ribbon","2021-03-03T17:45:23Z"],["Netflix/servo","2021-03-03T14:34:31Z"],["Netflix/asgard","2021-03-03T13:05:32Z"]]'
fi

describe "test-06-05: /view/top/5/open_issues = "

VALUE=$(curl -s "$BASE_URL/view/top/5/open_issues" |tr -d '\n' |sed -e 's/ //g')

if [[ "$VALUE" == '[["Netflix/Hystrix",383],["Netflix/zuul",226],["Netflix/ribbon",200],["Netflix/astyanax",159],["Netflix/asgard",103]]' ]]; then
    pass
else
    fail "$VALUE" '[["Netflix/Hystrix",382],["Netflix/zuul",225],["Netflix/ribbon",198],["Netflix/astyanax",159],["Netflix/asgard",103]]'
fi

describe "test-06-06: /view/top/10/open_issues = "

VALUE=$(curl -s "$BASE_URL/view/top/10/open_issues" |tr -d '\n' |sed -e 's/ //g')

if [[ "$VALUE" == '[["Netflix/Hystrix",383],["Netflix/zuul",226],["Netflix/ribbon",200],["Netflix/astyanax",159],["Netflix/asgard",103],["Netflix/archaius",101],["Netflix/governator",64],["Netflix/Turbine",52],["Netflix/SimianArmy",46],["Netflix/Priam",37]]' ]]; then
    pass
else
    fail "$VALUE" '[["Netflix/Hystrix",383],["Netflix/zuul",226],["Netflix/ribbon",200],["Netflix/astyanax",159],["Netflix/asgard",103],["Netflix/archaius",101],["Netflix/governator",64],["Netflix/Turbine",52],["Netflix/SimianArmy",46],["Netflix/Priam",37]]'
fi

describe "test-06-07: /view/top/5/stars = "

VALUE=$(curl -s "$BASE_URL/view/top/5/stars" |tr -d '\n' |sed -e 's/ //g')

if [[ "$VALUE" == '[["Netflix/Hystrix",21173],["Netflix/zuul",10566],["Netflix/eureka",10238],["Netflix/SimianArmy",7741],["Netflix/ribbon",3893]]' ]]; then
    pass
else
    fail "$VALUE" '[["Netflix/Hystrix",21173],["Netflix/zuul",10566],["Netflix/eureka",10238],["Netflix/SimianArmy",7741],["Netflix/ribbon",3893]]'
fi

describe "test-06-08: /view/top/10/stars = "

VALUE=$(curl -s "$BASE_URL/view/top/10/stars" |tr -d '\n' |sed -e 's/ //g')

if [[ "$VALUE" == '[["Netflix/Hystrix",21173],["Netflix/zuul",10566],["Netflix/eureka",10238],["Netflix/SimianArmy",7741],["Netflix/ribbon",3893],["Netflix/archaius",2248],["Netflix/asgard",2227],["Netflix/curator",2105],["Netflix/EVCache",1596],["Netflix/servo",1348]]' ]]; then
    pass
else
    fail "$VALUE" '[["Netflix/Hystrix",21173],["Netflix/zuul",10566],["Netflix/eureka",10238],["Netflix/SimianArmy",7741],["Netflix/ribbon",3893],["Netflix/archaius",2248],["Netflix/asgard",2227],["Netflix/curator",2105],["Netflix/EVCache",1596],["Netflix/servo",1348]]'
fi

report
