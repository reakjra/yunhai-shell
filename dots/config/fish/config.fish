function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    # Use starship
    starship init fish | source
    if test -f ~/.local/state/quickshell/yunhai/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/yunhai/user/generated/terminal/sequences.txt
    end

    # Aliases
    alias pamcan pacman
    alias ls 'eza --icons'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias q 'qs -c yunhai'
    
end

functions --erase __fish_prompt_newline 2>/dev/null
functions --erase __store_last_cmd 2>/dev/null

function __store_last_cmd --on-event fish_preexec
    set -g __last_cmd $argv
end

function __fish_prompt_newline --on-event fish_postexec
    if not set -q __last_cmd
        return
    end

    set cmd (string lower -- "$__last_cmd")

    if test "$cmd" = "clear" -o "$cmd" = "reset" -o "$cmd" = "cls"
        return
    end

    echo ""
end



fish_add_path ~/.local/bin

if test -z "$DISPLAY"; and test (tty) = "/dev/tty1"
    exec Hyprland
end

set -gx GTK_IM_MODULE fcitx
set -gx QT_IM_MODULE fcitx
set -gx XMODIFIERS @im=fcitx
