#!/usr/bin/env bash

set -e 
set -u

if [ $# -ne 2 ]
then
    echo >&2 "usage: add-project name yanaurl"
    exit 1
fi
PROJECT=$1
YANA_URL=$2

CURLOPTS="-k -f -s -S -L -c cookies -b cookies"
CURL="curl $CURLOPTS"
  
# Login
$CURL --data "j_username=admin&j_password=admin" \
    ${YANA_URL}/j_spring_security_check > curl.out

# List projects and convert it to well formed XML.
$CURL ${YANA_URL}/project/list >curl.out
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
        ${YANA_URL}/project/save >curl.out
    echo >&2 "Created project $PROJECT."
fi

# Load some model data.
model=/var/lib/tomcat6/webapps/yana2/WEB-INF/classes/import/example.xml
$CURL --form yanaimport=@$model \
    "${YANA_URL}/import/savexml?project=$PROJECT" > curl.out
echo >&2 "Imported example model: $model"

# List the nodes just imported.
$CURL ${YANA_URL}/api/node/list/xml?project=$PROJECT > nodes.xml
xmlstarlet val nodes.xml >/dev/null
echo >&2 "Listing nodes in $PROJECT"
# Print information about the nodes from the model.
xmlstarlet sel -t -m "/yana/nodes/node" \
    -v @name -o "[" -v @type -o "] " -v description -n nodes.xml


# Create a new node of type, Service. 
#
echo >&2 "Creating a node ..."
# List all the types
$CURL --request POST --header "Content-Type: application/json" \
    ${YANA_URL}/api/nodeType/list/xml?project=${PROJECT} > curl.out
xmlstarlet val curl.out >/dev/null

# Query the result for a type named 'Service' and print its id.
nodetype=$(xmlstarlet sel -t -m "//type[@name='Service']" -v @id curl.out)
if [ -z "$nodetype" ]
then
    echo >&2 "Expected type missing from project model: Service"
    exit 1
fi

# Create the node
$CURL --request POST --header "Content-Type: application/json" \
    -d "{name:'myservice',description:'this is a service',nodetype:{id:${nodetype}},tags:'tagA,tagB',basedir:'/tmp',port:'80'}" \
    ${YANA_URL}/api/node/xml?project=${PROJECT} > curl.out
xmlstarlet val curl.out

id=$(xmlstarlet sel -t -m "//node" -v @id curl.out)
echo >&2 "Created node id: $id"

# Edit the node. 
$CURL --request PUT --header "Content-Type: application/json" \
    -d "{id:$id,name:'myservice',description:'this is a description',nodetype:{id:${nodetype}},tags:'tagB,tagC',basedir:'/var/tmp',port:'8080'}" \
    $YANA_URL/api/node/xml?project=$PROJECT > curl.out
xmlstarlet val curl.out

# Delete the node
$CURL --request DELETE $YANA_URL/api/node/xml/$id?project=$PROJECT

# Export the model 
echo >& "Exporting the model."
$CURL $YANA_URL/export/xml?project=${PROJECT} > curl.out
xmlstarlet val curl.out


