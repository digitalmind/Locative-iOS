#!/bin/bash

BASE_PATH="${SRCROOT}/swiftybeaver"
PLIST_NAME="SwiftyBeaver.plist"
PLIST="${BASE_PATH}/${PLIST_NAME}"
SCRIPT="${BASE_PATH}/vars.sh"

if [ ! -d $BASE_PATH ]; then
  mkdir -p $BASE_PATH
fi

if [ -f $SCRIPT ]; then
  if [ -f $PLIST ]; then
   rm $PLIST
  fi
  echo "Sourced SwiftyBeaver…"
  source $SCRIPT
  if [ -n $SB_APP_ID -a -n $SB_APP_SECRET -a -n $SB_ENCRYPTION_KEY ]; then
    echo "SwiftyBeaver Token setup correctly. Creating Plist…"
    /usr/libexec/PlistBuddy -c "Add :SBAppId string ${SB_APP_ID}" $PLIST
    /usr/libexec/PlistBuddy -c "Add :SBAppSecret string ${SB_APP_SECRET}" $PLIST
    /usr/libexec/PlistBuddy -c "Add :SBEncryptionKey string ${SB_ENCRYPTION_KEY}" $PLIST
    echo "Copying SwiftyBeaver.plist into application bundle…"
    cp $PLIST "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/${PLIST_NAME}"
  fi
fi