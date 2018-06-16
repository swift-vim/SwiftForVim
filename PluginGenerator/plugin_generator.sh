set +e

if [[ $plugin_path == "" ]]; then
    echo "Usage plugin_path=/path/to/output"
    exit 1
fi

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

REV=$(cd $SCRIPTPATH/../ && echo $(git rev-parse HEAD))
echo "Hardcoding to revision $REV"

OUT_DIR=$plugin_path

PLUGIN=$(basename $OUT_DIR)
echo "Generating $PLUGIN in $OUT_DIR"

mkdir -p $OUT_DIR
cd $OUT_DIR

swift package init

mkdir -p plugin
sed "s,__VIM_PLUGIN_NAME__,$PLUGIN,g" $SCRIPTPATH/plugin.tpl.vim \
    > plugin/$PLUGIN
sed "s,__VIM_PLUGIN_NAME__,$PLUGIN,g" $SCRIPTPATH/PluginMain.tpl.swift \
    > Sources/$PLUGIN/$PLUGIN.swift

sed "s,__VIM_PLUGIN_NAME__,$PLUGIN,g" $SCRIPTPATH/Package.tpl.swift \
    > Package.swift
sed -i "" "s,__GIT_REVISION__,$REV,g"  Package.swift

mkdir -p VimUtils
ditto $SCRIPTPATH/../Utils/make_lib.sh VimUtils/

sed "s,__VIM_PLUGIN_NAME__,$PLUGIN,g" $SCRIPTPATH/Makefile.tpl \
    > Makefile

