function vencord --wraps='sh -c "$(curl -sS https://vencord.dev/install.sh)"' --description 'alias vencord sh -c "$(curl -sS https://vencord.dev/install.sh)"'
    sh -c "$(curl -sS https://vencord.dev/install.sh)" $argv
end
