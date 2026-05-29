#!/bin/sh
export IJ_MCP_SERVER_PORT=64342
/Applications/IntelliJ\ IDEA.app/Contents/jbr/Contents/Home/bin/java -classpath /Applications/IntelliJ\ IDEA.app/Contents/plugins/mcpserver/lib/mcpserver-frontend.jar:/Applications/IntelliJ\ IDEA.app/Contents/lib/util-8.jar com.intellij.mcpserver.stdio.McpStdioRunnerKt

