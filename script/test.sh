#!/bin/zsh

xcodebuild test -workspace './Example/CalmGeo.xcworkspace' -scheme 'CalmGeo-Example' -destination 'platform=iOS Simulator,name=iPhone 15' | xcpretty -s
