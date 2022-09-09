#!/bin/bash
# Author: arneson
# This Script Generates a new Inventory for a new Version or New Plugin

SRCDIR=/Users/Shared/Kodi-18.9/addons
REPONAME=repository.tidal2
REPO=~/git/$REPONAME/until-leia
ZIP="$(command -v zip)"

if [ "$1" != "" ]
then
    REPO="$1"
fi
if [ -f "$(pwd)/addons.xml" ]
then
    REPO="$(pwd)"
fi
if [ ! -f "$REPO/addons.xml" ]
then
    echo "repo path nicht korrekt"
    exit 0
fi

if [ "$ZIP" = "" ]
then
    echo "zip not found. eg: apt-get install zip"
    exit 0
fi

# Check if all files have 2 hard links (linked to original source file is intact)
for name in `find "$REPO" -depth 1 -type d -not -name "script.module.pyaes" -not -name ".git" -not -name "$REPONAME" -exec basename {} \;`; do
    for name in `find $SRCDIR/$name -type f -not -links 2 -not -name "*.pyo" -not -name ".DS_Store"`; do
        echo "Hardlink to file missing:" $name
        ERRMSG="Please correct hard links first using: cd src_folder ; pax -rwlpe . dest_folder"
    done
done
if [ "$ERRMSG" != "" ]; then
	echo "$ERRMSG"
	exit 0
fi

cd $REPO
echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' >$REPO/addons.xml
echo '<addons>' >> $REPO/addons.xml
# for name in `find . -maxdepth 1 -type d |grep -v \.git|grep -v addons|egrep -v "^\.$"|cut -d \/ -f 2 `; do
for name in `find . -depth 1 -type d -not -name ".git" -exec basename {} \;`; do

    if [ -f "$SRCDIR/$name/addon.xml" ]; then
        if [ ! -d "$REPO/$name/resources" ]; then
            mkdir $REPO/$name/resources
        fi
        cp -a $SRCDIR/$name/addon.xml  $REPO/$name
        cp -a $SRCDIR/$name/icon.png   $REPO/$name
        cp -a $SRCDIR/$name/fanart.jpg $REPO/$name

        cp -a $SRCDIR/$name/resources/icon.png        $REPO/$name/resources/
        cp -a $SRCDIR/$name/resources/fanart.jpg      $REPO/$name/resources/
        cp -a $SRCDIR/$name/resources/screenshot*.jpg $REPO/$name/resources/
    fi
    VERSION=`cat $REPO/$name/addon.xml|grep \<addon|grep $name |tr 'A-Z' 'a-z'|sed 's/.*version="\([^"]*\)"*.*/\1/g'`
    echo "Adding $name V$VERSION"
    if [ ! -f "$REPO/$name/$name-$VERSION.zip" ]; then
        if [ -f "$SRCDIR/$name/changelog.txt" ]; then
            cp -a $SRCDIR/$name/changelog.txt $REPO/$name/changelog-$VERSION.txt
        fi
        if [ -f "$SRCDIR/$name/addon.xml" ]; then
            cd $SRCDIR
            zip -q -r $REPO/$name/$name-$VERSION.zip $name -x \*.zip -x *tests* -x *build* -x *__pycache__ -x *.externalTool* -x \*.pyo -x \*.pyc -x *.git* -x *.DS_Store* -x *.settings* -x *.project* -x *.pydevproject* -x \*.pxm -x *strings.xml
    	else
            cd $REPO
            zip -q -r $REPO/$name/$name-$VERSION.zip $name -x \*.zip -x \*.md5
        fi
        cd $REPO/$name
        md5 -r $name-$VERSION.zip > $name-$VERSION.zip.md5
    fi
    cat $REPO/$name/addon.xml|grep -v "<?xml " >> $REPO/addons.xml
    echo "" >> $REPO/addons.xml
done
echo "</addons>" >> $REPO/addons.xml
cd $REPO
md5 -r  addons.xml > addons.xml.md5
