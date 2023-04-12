#!/usr/bin/env bash
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'
messages=$(echo '[]' | jq)
echo -ne "$YELLOW""Welcome to a CLI for interacting with GPT chat models. Press Ctrl-D to send your input to the model, and Ctrl-C to exit $NC\n\n"
echo -ne "$GREEN""User: $NC"

while line=$(cat); do
    messages=$(echo "$messages" | jq -c '. += [{"role": "user", "content": '"$(echo "$line" | jq -sR .)"'}]')
    response=''
    echo -ne "$RED""GPT: $NC"

    response=$(curl --no-buffer -s -X POST -H 'Content-Type: application/json' -H 'Accept: text/event-stream' -H 'Authorization: Bearer '"$OPENAI_API_KEY" -d '{"model": "'"${CHAT_MODEL_NAME:="gpt-4"}"'", "messages": '"$messages"', "stream": true}' https://api.openai.com/v1/chat/completions > >(while read -r resp; do
        if [[ $resp == *"delta\":{\"content"* ]]; then
		content="$(echo -E "$resp" | cut -c 7- | jq '.choices[].delta.content' | jq -r)"
	    echo -ne "$content"
        fi
    done) | tee /dev/tty)
    messages=$(echo "$messages" | jq -c '. += [{"role": "assistant", "content": '"$(echo "$response" | jq -sR .)"'}]')
    echo -ne "\n$GREEN""User: $NC"
done
