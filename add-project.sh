#!/usr/bin/env bash

# Exit immediately on error or undefined variable.
set -e 
set -u

# Process command line arguments.
if [ $# -ne 2 ]
then
    echo >&2 "usage: add-project name yanaurl"
    exit 1
fi
PROJECT=$1
YANA_URL=$2

# API examples using curl.
# -----------------------

# Set up curl to fail on error and run silently.
CURLOPTS="-k -f -s -S -L -c cookies -b cookies"
CURL="curl $CURLOPTS"

#
# Login.
#
$CURL --data "j_username=admin&j_password=admin" \
    ${YANA_URL}/j_spring_security_check > curl.out

#
# List projects. 
# --------------

# There isn't an API for listing projects so get the page content ...
$CURL ${YANA_URL}/project/list >curl.out
# ...and convert it to well formed XML.
xmlstarlet fo -R -H curl.out > projects.html 2>/dev/null
# Query the HTML for anchor tags with the word project (HTML screenscrape alert!)
if ! xmlstarlet sel -t -m "//a[contains(@href,'project/select?project=')]" \
    -v . -n projects.html > projects.txt
then
    echo >&2 "No projects exist yet."
fi
# Check if specified project is contained in the project listing.
if ! grep -q "${PROJECT}" projects.txt
then
   # Project does not exist, so create the $PROJECT.
    $CURL --data "name=$PROJECT&description=none" \
        ${YANA_URL}/project/save >curl.out
    echo >&2 "Created project $PROJECT."
fi

# 
# Import model.
# ------------

# Load some example model data into the project.
model=/var/lib/tomcat6/webapps/yana2/WEB-INF/classes/import/example.xml
$CURL --form yanaimport=@$model \
    "${YANA_URL}/import/savexml?project=$PROJECT" > curl.out
echo >&2 "Imported example model: $model"

#
# List types.
# -----------

# List the types in the project. 
$CURL --request POST --header "Content-Type: application/json" \
    ${YANA_URL}/api/nodeType/list/xml?project=${PROJECT} > curl.out
xmlstarlet val curl.out >/dev/null
# Query the type list for one named 'Service' and print its id.
nodetype=$(xmlstarlet sel -t -m "//type[@name='Service']" -v @id curl.out)
if [ -z "$nodetype" ]
then
    echo >&2 "Type missing from project model: Service"
    exit 1
fi
# The Create node API requires the nodetype ID. We'll use the nodetype's id later.

#
# List nodes.
# -----------

# Get a listing of the nodes just imported.
echo >&2 "Listing nodes in $PROJECT"
$CURL ${YANA_URL}/api/node/list/xml?project=$PROJECT > nodes.xml
xmlstarlet val nodes.xml >/dev/null
# Output information about the node listing with this format:
#
#        name[type] description
#
xmlstarlet sel -t -m "/yana/nodes/node" \
    -v @name -o "[" -v @type -o "] " -v description -n nodes.xml

#
# Search nodes.
# -------------

query="nodetype:Service"; # The colon char will be encoded as %3A in the url.

echo >&2 "Searching for nodes in $PROJECT matching $query"
$CURL -X GET "${YANA_URL}/search/index?format=xml&project=${PROJECT}&q=${query/:/%3A}" > curl.out
xmlstarlet val curl.out
xmlstarlet sel -t -m "//node[@type='Service']" -v @name -o ":" -v @tags -n curl.out

#
# Create node.
# ------------

# Add a new node of type, Service. 
# Reference the Service's node type id as a parameter to the request.
# Type specific attributes like basedir and port are specified, too.
echo >&2 "Creating a node ..."
$CURL --request POST --header "Content-Type: application/json" \
    -d "{name:'myservice',description:'this is a service',nodetype:{id:${nodetype}},tags:'tagA,tagB',basedir:'/tmp',port:'80'}" \
    ${YANA_URL}/api/node/xml?project=${PROJECT} > curl.out

# The API output contains a model of the new node. Print its id.
xmlstarlet val curl.out
id=$(xmlstarlet sel -t -m "//node" -v @id curl.out)
echo >&2 "Created node id: $id"

#
# Edit node. 
# ----------

# Change some of new node values.
echo >&2 "Updating the node..."
$CURL --request PUT --header "Content-Type: application/json" \
    -d "{id:$id,name:'myservice',description:'this is a description',nodetype:{id:${nodetype}},tags:'tagB,tagC',basedir:'/var/tmp',port:'8080'}" \
    $YANA_URL/api/node/xml?project=$PROJECT > curl.out
xmlstarlet val curl.out

#
# Delete node.
# ------------

# Delete the node by its id.
echo >&2 "Deleting node..."
$CURL --request DELETE $YANA_URL/api/node/xml/$id?project=$PROJECT

#
# Export model.
# -------------

# Export the model specifying the project name.
# This exported model can be imported to this or another project later.
echo >&2 "Exporting the model..."
$CURL $YANA_URL/export/xml?project=${PROJECT} > curl.out
xmlstarlet val curl.out

# Done.
exit $?
