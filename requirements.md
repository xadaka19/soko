xadakamobileaccessories@penguin:/mnt/chromeos/MyFiles/Downloads/soko$ flutter build apk --debug
Support for Android x86 targets will be removed in the next stable release after 3.27. See
https://github.com/flutter/flutter/issues/157543 for details.

FAILURE: Build failed with an exception.

* Where:
Build file '/mnt/chromeos/MyFiles/Downloads/soko/android/build.gradle.kts' line: 26

* What went wrong:
A problem occurred configuring project ':app'.
>                         Build Type 'debug' contains custom BuildConfig fields, but the feature is disabled.
                          To enable the feature, add the following to your module-level build.gradle:
  `android.buildFeatures.buildConfig true`

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 1m 30s
Running Gradle task 'assembleDebug'...                             92.1s
Gradle task assembleDebug failed with exit code 1

clear all problems 