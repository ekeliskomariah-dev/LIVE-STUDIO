#!/bin/sh
#
# Gradle start up script
# Standard Gradle wrapper script. The actual gradle-wrapper.jar must be
# downloaded once (e.g. by running `gradle wrapper` or by downloading from
# https://raw.githubusercontent.com/gradle/gradle/v8.7.0/gradle/wrapper/gradle-wrapper.jar).
#
# In GitHub Actions we use the `gradle/actions/setup-gradle` action which
# does not require the wrapper jar to be committed. Locally, if you don't
# have a wrapper jar, run `gradle wrapper --gradle-version 8.7` once.

APP_NAME="Gradle"
APP_BASE_NAME=$(basename "$0")
DEFAULT_JVM_OPTS='"-Xmx64m" "-Xms64m"'

die() { echo "$*"; exit 1; } >&2

# OS specific support
cygwin=false
msys=false
darwin=false
nonstop=false
case "$(uname)" in
  CYGWIN* ) cygwin=true ;;
  Darwin* ) darwin=true ;;
  MSYS* | MINGW* ) msys=true ;;
  NONSTOP* ) nonstop=true ;;
esac

# Determine the Java binary
if [ -n "$JAVA_HOME" ] ; then
  if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
    JAVACMD="$JAVA_HOME/jre/sh/java"
  else
    JAVACMD="$JAVA_HOME/bin/java"
  fi
  if [ ! -x "$JAVACMD" ] ; then
    die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME"
  fi
else
  JAVACMD="java"
  command -v "$JAVACMD" >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and 'java' command could not be found in your PATH."
fi

# Increase the maximum file descriptors if possible
if ! "$cygwin" && ! "$darwin" && ! "$nonstop" ; then
  case $MAX_FD in
    max*)
      MAX_FD=$(ulimit -H -n) || warn "Could not query maximum file descriptor limit"
    ;;
  esac
  case $MAX_FD in
    '' | soft) ;;
    *)
      ulimit -n "$MAX_FD" || warn "Could not set maximum file descriptor limit to $MAX_FD"
    ;;
  esac
fi

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

# Collect all arguments
eval set -- "$DEFAULT_JVM_OPTS" "-Dorg.gradle.appname=$APP_BASE_NAME" -classpath "\"$CLASSPATH\"" org.gradle.wrapper.GradleWrapperMain "$@"

exec "$JAVACMD" "$@"
