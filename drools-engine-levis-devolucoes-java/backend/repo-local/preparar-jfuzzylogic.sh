#!/usr/bin/env bash
# Gera o artefacto Maven do jFuzzyLogic usado pelo pericial-uncertainty (ADR 0012).
#
# O jFuzzyLogic não está no Maven Central. O autor publica o jar no SourceForge (licença LGPL-3.0,
# github.com/pcingola/jFuzzyLogic). O jFuzzyLogic_core.jar traz embutidas outras bibliotecas, entre
# elas o ANTLR 3.1 (org.antlr.runtime), que colide com o antlr-runtime 3.5.2 usado pelo Drools. Este
# script mantém só as classes do jFuzzyLogic (net/sourceforge/jFuzzyLogic), sem as alterar, e declara
# o antlr-runtime como dependência. O resultado fica versionado em backend/repo-local, para que o
# build não dependa do SourceForge. Só é preciso correr o script para mudar de versão.
set -euo pipefail

URL="https://downloads.sourceforge.net/project/jfuzzylogic/jfuzzylogic/jFuzzyLogic_core.jar"
SHA256="9c6d6f3151af7f5e532041aa9946a525dbe84e0a67bc619b4de7c1ff22e0a934"
GRUPO="net/sourceforge/jfuzzylogic"
ARTEFACTO="jfuzzylogic-core"
VERSAO="3.3-sem-dependencias"

AQUI="$(cd "$(dirname "$0")" && pwd)"
DESTINO="$AQUI/$GRUPO/$ARTEFACTO/$VERSAO"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -sSL -o "$TMP/original.jar" "$URL"
echo "$SHA256  $TMP/original.jar" | sha256sum -c -

mkdir -p "$TMP/classes"
(cd "$TMP/classes" && jar -xf "$TMP/original.jar" net/sourceforge/jFuzzyLogic)
mkdir -p "$DESTINO"
JAR="$DESTINO/$ARTEFACTO-$VERSAO.jar"
jar --create --file "$JAR" --date=2015-04-09T00:00:00Z -C "$TMP/classes" .

cat > "$DESTINO/$ARTEFACTO-$VERSAO.pom" <<POM
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>net.sourceforge.jfuzzylogic</groupId>
  <artifactId>$ARTEFACTO</artifactId>
  <version>$VERSAO</version>
  <name>jFuzzyLogic 3.3 (só as classes do jFuzzyLogic)</name>
  <url>https://jfuzzylogic.sourceforge.net</url>
  <licenses>
    <license>
      <name>GNU Lesser General Public License v3.0</name>
      <url>https://www.gnu.org/licenses/lgpl-3.0.html</url>
    </license>
  </licenses>
  <dependencies>
    <dependency>
      <groupId>org.antlr</groupId>
      <artifactId>antlr-runtime</artifactId>
      <version>3.5.2</version>
    </dependency>
  </dependencies>
</project>
POM

for f in "$JAR" "$DESTINO/$ARTEFACTO-$VERSAO.pom"; do
  sha1sum "$f" | cut -d' ' -f1 | tr -d '\n' > "$f.sha1"
done
echo "Gerado: $DESTINO"
