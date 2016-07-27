# Locative for iOS

[![Twitter: @Kidmar](https://img.shields.io/badge/contact-@Kidmar-blue.svg?style=flat)](https://twitter.com/Kidmar)
[![App Store](https://img.shields.io/badge/app%20store-%20Download-red.svg)](https://itunes.apple.com/us/app/geofancy/id725198453)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/LocativeHQ/Locative-iOS/blob/master/LICENSE.md)
[![TravisCI](https://api.travis-ci.org/LocativeHQ/Locative-iOS.svg?branch=master)](https://travis-ci.org/LocativeHQ/Locative-iOS) [![Join the chat at https://gitter.im/LocativeHQ/Locative-iOS](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/LocativeHQ/Locative-iOS?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![codecov.io](https://codecov.io/github/LocativeHQ/Locative-iOS/coverage.svg?branch=master)](https://codecov.io/github/LocativeHQ/Locative-iOS?branch=master)

![Screenshot](screenshot.png)


## Preamble

I'm open sourcing this sideproject of mine as I'm not enough time to actively care about it and due to the high number of requests I've got from the community, it feels about right to make further work to it possible.

#### So you're going open source now, what about my data, is it also going open source?
No, no, no. Of course not, you're data is still stored on the Locative servers and it will stay there until further notice. No third party will have access to your data.

## Technologies used

Objective-C, Swift and dependency management using CocoaPods (>= 1.0).

## Development

The following commands will clone this repository and spin up the dev environment.

```
git clone https://github.com/LocativeHQ/Locative-iOS
cd Locative-iOS
bundle install
bundle exec rake dev
```

## Changelog

The `github_changelog_generator` gem is used to generate a changelog.

To generate the most current changelog perform

```
bundle install
bundle exec rake changelog
```

## Deployment

I'm going to regularly deploy releases to the App Store.

## Issues

Right now I'm still getting issues / feature requests etc. reported via UserVoice but I'm planning on moving to GitHub issues with this.

## The Locative License

Copyright (c) 2013-today Marcus Kida

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

You are not eligible to distribute this Software under the name or appearance
of Locative, you may release it under another name and appearance though.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
