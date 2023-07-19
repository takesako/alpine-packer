#!/bin/sh -x
apk add virtualbox-guest-additions
rc-update add virtualbox-guest-additions
rc-update add local
addgroup vagrant vboxsf
