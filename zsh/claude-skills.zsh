# Claude Code skills
#
# Repositories keep their skills in .agents/skills, which OpenCode and Pi read
# directly. Claude Code only scans .claude/skills, so `claude-skills` links the
# current repository's skills into the personal skills directory.
#
# Personal scope means they load in every Claude Code session, not only in that
# repository, so unlink them when they stop being useful. The links point at the
# checkout you ran the command in, so run it in the worktree whose branch you
# want, and prune after deleting a worktree.
#
#   claude-skills          link .agents/skills from here into ~/.claude/skills
#   claude-skills list     show each link and where it points
#   claude-skills unlink   remove the links pointing into the current directory
#   claude-skills prune    remove links whose target is gone

claude-skills() {
    emulate -L zsh
    setopt local_options null_glob

    local store="$HOME/.claude/skills"
    local action="${1:-link}"
    local link target name

    case "$action" in
        link)
            local source_dir="$PWD/.agents/skills"
            if [[ ! -d "$source_dir" ]]; then
                print -u2 "claude-skills: no .agents/skills directory in $PWD"
                return 1
            fi
            mkdir -p "$store" || return 1

            local -i linked=0 skipped=0
            local skill
            for skill in "$source_dir"/*(/); do
                [[ -f "$skill/SKILL.md" ]] || continue
                name="${skill:t}"
                link="$store/$name"
                if [[ -e "$link" && ! -L "$link" ]]; then
                    print -u2 "claude-skills: $name is a real directory in $store, left alone"
                    (( skipped++ ))
                    continue
                fi
                ln -sfn "$skill" "$link"
                (( linked++ ))
            done

            print "claude-skills: linked $linked skill(s) from $source_dir"
            (( skipped )) && print "claude-skills: skipped $skipped"
            return 0
            ;;
        list)
            for link in "$store"/*(N@); do
                target="${link:A}"
                if [[ -e "$target" ]]; then
                    print "  ${link:t} -> $target"
                else
                    print "  ${link:t} -> $target (broken)"
                fi
            done
            for link in "$store"/*(N/); do
                [[ -L "$link" ]] || print "  ${link:t} (real directory, not managed here)"
            done
            return 0
            ;;
        unlink)
            local -i removed=0
            for link in "$store"/*(N@); do
                case "${link:A}" in
                    "$PWD"/*) rm -- "$link"; (( removed++ )) ;;
                esac
            done
            print "claude-skills: removed $removed link(s) pointing into $PWD"
            return 0
            ;;
        prune)
            local -i removed=0
            for link in "$store"/*(N@); do
                [[ -e "${link:A}" ]] && continue
                rm -- "$link"
                (( removed++ ))
            done
            print "claude-skills: removed $removed broken link(s)"
            return 0
            ;;
        *)
            print -u2 "usage: claude-skills [link|list|unlink|prune]"
            return 2
            ;;
    esac
}
