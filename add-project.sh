#!/usr/bin/env bash

set -e 
set -u

if [ $# -ne 2 ]
then
    echo >&2 "usage: add-project name yanaurl"
    exit 1
fi
PROJECT=$1
YANAURL=$2

CURLOPTS="-k -f -s -S -L -c cookies -b cookies"
CURL="curl $CURLOPTS"
  
# Login
$CURL --data "j_username=admin&j_password=admin" \
    ${YANAURL}/j_spring_security_check > curl.out

# List projects and convert it to well formed XML.
$CURL ${YANAURL}/project/list >curl.out
xmlstarlet fo -R -H curl.out > projects.html 2>/dev/null
# Query the HTML for project references (HTML screenscrape alert!)
if ! xmlstarlet sel -t \
    -m "//a[contains(@href,'project/select?project=')]" \
    -v . -n projects.html > projects.txt
then
    echo >&2 "No projects exist yet."
fi

# Check if specified project already exists:
if ! grep -q "${PROJECT}" projects.txt
then
   # Not there so create the project.
    $CURL --data "name=$PROJECT&description=none" \
        ${YANAURL}/project/save >curl.out
    echo >&2 "Created project $PROJECT."
fi

# Load some model data.
model=/var/lib/tomcat6/webapps/yana2/WEB-INF/classes/import/example.xml
$CURL --form yanaimport=@$model \
    "${YANAURL}/import/savexml?project=$PROJECT" > curl.out
echo >&2 "Imported model: $model"

# List the nodes just imported.
$CURL ${YANAURL}/api/node/list/xml?project=$PROJECT > nodes.xml
xmlstarlet val nodes.xml >/dev/null
echo >&2 "Listing nodes in $PROJECT"
# Print information about the nodes from the model.
xmlstarlet sel -t -m "/yana/nodes/node" \
    -v @name -o "[" -v @type -o "] " -v description -n nodes.xml