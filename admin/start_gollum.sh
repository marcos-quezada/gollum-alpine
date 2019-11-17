#!/usr/bin/env bash

# Configure
#setup include path
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then
    DIR="$PWD"
fi

source /wiki_admin/functions.sh

create_variables $1

########### End of configuration section

# start gollum server
### does not report if it fails -see the log...
program="gollum"
proclive=`ps -ax |grep -E -e 'bin/ruby.*/bin/gollum' |grep -v 'grep'`

if [ "$proclive" ]; then
    id=`echo $proclive | awk '{print $1}'`
    echo "NOTICE: it appears that $program is already running with PID $id! Skipping startup for $program"
else
    cd $config_wikidir
    echo $config_gollum_plantuml_url
    command="gollum --port $config_gollumport --config $config_gollumconfigfile --plantuml-url $config_gollum_plantuml_url --emoji --mathjax --live-preview --allow-uploads=page --collapse-tree --css --template-dir $config_templatedir"
    $command
fi


echo "start_gollum.sh: done."
