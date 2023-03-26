#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

messages=$(echo '[]' | jq)
echo -ne "$GREEN""User: $NC"

while IFS='$\n' read -r line; do
    messages=$(echo "$messages" | jq -c '. += [{"role": "user", "content": '"$(echo "$line" | jq -sR .)"'}]')
    response=''
    echo -ne "$RED""GPT: $NC"

    curl --no-buffer -s -X POST -H 'Content-Type: application/json' -H 'Accept: text/event-stream' -H 'Authorization: Bearer '"$OPENAI_API_KEY" -d '{"model": "'"${CHAT_MODEL_NAME:="gpt-3.5-turbo"}"'", "messages": '"$messages"', "stream": true}' https://api.openai.com/v1/chat/completions > >(while read -r resp; do
        if [[ $resp == *"delta\":{\"content"* ]]; then
            content=$(echo "$resp" | cut -c 7- | jq -r '.choices[].delta.content')
            echo -ne "$content"
            response+=$content
        fi
    done)
    messages=$(echo "$messages" | jq -c '. += [{"role": "assistant", "content": '"$(echo "$response" | jq -sR .)"'}]')
    echo -ne "\n$GREEN""User: $NC"
done
