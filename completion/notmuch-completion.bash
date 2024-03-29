# bash completion for notmuch                              -*- shell-script -*-
#
# Copyright © 2013 Jani Nikula
#
# Based on the bash-completion package:
# http://bash-completion.alioth.debian.org/
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses/ .
#
# Author: Jani Nikula <jani@nikula.org>
#
#
# BUGS:
#
# Add space after an --option without parameter (e.g. reply --decrypt)
# on completion.
#

_notmuch_user_emails()
{
    notmuch config get user.primary_email
    notmuch config get user.other_email
}

_notmuch_search_terms()
{
    local cur prev words cword split
    # handle search prefixes and tags with colons and equal signs
    _init_completion -n := || return

    case "${cur}" in
	tag:*)
	    COMPREPLY=( $(compgen -P "tag:" -W "`notmuch search --output=tags \*`" -- ${cur##tag:}) )
	    ;;
	to:*)
	    COMPREPLY=( $(compgen -P "to:" -W "`_notmuch_user_emails`" -- ${cur##to:}) )
	    ;;
	from:*)
	    COMPREPLY=( $(compgen -P "from:" -W "`_notmuch_user_emails`" -- ${cur##from:}) )
	    ;;
	*)
	    local search_terms="from: to: subject: attachment: tag: id: thread: folder: date:"
	    compopt -o nospace
	    COMPREPLY=( $(compgen -W "${search_terms}" -- ${cur}) )
	    ;;
    esac
    # handle search prefixes and tags with colons
    __ltrim_colon_completions "${cur}"
}

_notmuch_compact()
{
    local cur prev words cword split
    _init_completion -s || return

    $split &&
    case "${prev}" in
	--backup)
	    _filedir
	    return
	    ;;
    esac

    ! $split &&
    case "${cur}" in
	-*)
	    local options="--backup= --quiet"
	    compopt -o nospace
	    COMPREPLY=( $(compgen -W "$options" -- ${cur}) )
	    ;;
    esac
}

_notmuch_config()
{
    local cur prev words cword split
    _init_completion || return

    case "${prev}" in
	config)
	    COMPREPLY=( $(compgen -W "get set list" -- ${cur}) )
	    ;;
	get|set)
	    COMPREPLY=( $(compgen -W "`notmuch config list | sed 's/=.*\$//'`" -- ${cur}) )
	    ;;
	# these will also complete on config get, but we don't care
	database.path)
	    _filedir
	    ;;
	maildir.synchronize_flags)
	    COMPREPLY=( $(compgen -W "true false" -- ${cur}) )
	    ;;
    esac
}

_notmuch_count()
{
    local cur prev words cword split
    _init_completion -s || return

    $split &&
    case "${prev}" in
	--output)
	    COMPREPLY=( $( compgen -W "messages threads files" -- "${cur}" ) )
	    return
	    ;;
	--exclude)
	    COMPREPLY=( $( compgen -W "true false" -- "${cur}" ) )
	    return
	    ;;
	--input)
	    _filedir
	    return
	    ;;
    esac

    ! $split &&
    case "${cur}" in
	-*)
	    local options="--output= --exclude= --batch --input="
	    compopt -o nospace
	    COMPREPLY=( $(compgen -W "$options" -- ${cur}) )
	    ;;
	*)
	    _notmuch_search_terms
	    ;;
    esac
}

_notmuch_dump()
{
    local cur prev words cword split
    _init_completion -s || return

    $split &&
    case "${prev}" in
	--format)
	    COMPREPLY=( $( compgen -W "sup batch-tag" -- "${cur}" ) )
	    return
	    ;;
	--output)
	    _filedir
	    return
	    ;;
    esac

    ! $split &&
    case "${cur}" in
	-*)
	    local options="--format= --output="
	    compopt -o nospace
	    COMPREPLY=( $(compgen -W "$options" -- ${cur}) )
	    ;;
	*)
	    _notmuch_search_terms
	    ;;
    esac
}

_notmuch_insert()
{
    local cur prev words cword split
    # handle tags with colons and equal signs
    _init_completion -s -n := || return

    $split &&
    case "${prev}" in
	--folder)
	    _filedir
	    return
	    ;;
    esac

    ! $split &&
    case "${cur}" in
	--*)
	    local options="--create-folder --folder="
	    compopt -o nospace
	    COMPREPLY=( $(compgen -W "$options" -- ${cur}) )
	    return
	    ;;
	+*)
	    COMPREPLY=( $(compgen -P "+" -W "`notmuch search --output=tags \*`" -- ${cur##+}) )
	    ;;
	-*)
	    COMPREPLY=( $(compgen -P "-" -W "`notmuch search --output=tags \*`" -- ${cur##-}) )
	    ;;
    esac
    # handle tags with colons
    __ltrim_colon_completions "${cur}"
}

_notmuch_new()
{
    local cur prev words cword split
    _init_completion || return

    case "${cur}" in
	-*)
	    local options="--no-hooks"
	    COMPREPLY=( $(compgen -W "${options}" -- ${cur}) )
	    ;;
    esac
}

_notmuch_reply()
{
    local cur prev words cword split
    _init_completion -s || return

    $split &&
    case "${prev}" in
	--format)
	    COMPREPLY=( $( compgen -W "default json sexp headers-only" -- "${cur}" ) )
	    return
	    ;;
	--reply-to)
	    COMPREPLY=( $( compgen -W "all sender" -- "${cur}" ) )
	    return
	    ;;
    esac

    ! $split &&
    case "${cur}" in
	-*)
	    local options="--format= --format-version= --reply-to= --decrypt"
	    compopt -o nospace
	    COMPREPLY=( $(compgen -W "$options" -- ${cur}) )
	    ;;
	*)
	    _notmuch_search_terms
	    ;;
    esac
}

_notmuch_restore()
{
    local cur prev words cword split
    _init_completion -s || return

    $split &&
    case "${prev}" in
	--format)
	    COMPREPLY=( $( compgen -W "sup batch-tag auto" -- "${cur}" ) )
	    return
	    ;;
	--input)
	    _filedir
	    return
	    ;;
    esac

    ! $split &&
    case "${cur}" in
	-*)
	    local options="--format= --accumulate --input="
	    compopt -o nospace
	    COMPREPLY=( $(compgen -W "$options" -- ${cur}) )
	    ;;
    esac
}

_notmuch_search()
{
    local cur prev words cword split
    _init_completion -s || return

    $split &&
    case "${prev}" in
	--format)
	    COMPREPLY=( $( compgen -W "json sexp text text0" -- "${cur}" ) )
	    return
	    ;;
	--output)
	    COMPREPLY=( $( compgen -W "summary threads messages files tags" -- "${cur}" ) )
	    return
	    ;;
	--sort)
	    COMPREPLY=( $( compgen -W "newest-first oldest-first" -- "${cur}" ) )
	    return
	    ;;
	--exclude)
	    COMPREPLY=( $( compgen -W "true false flag all" -- "${cur}" ) )
	    return
	    ;;
    esac

    ! $split &&
    case "${cur}" in
	-*)
	    local options="--format= --output= --sort= --offset= --limit= --exclude= --duplicate="
	    compopt -o nospace
	    COMPREPLY=( $(compgen -W "$options" -- ${cur}) )
	    ;;
	*)
	    _notmuch_search_terms
	    ;;
    esac
}

_notmuch_show()
{
    local cur prev words cword split
    _init_completion -s || return

    $split &&
    case "${prev}" in
	--entire-thread)
	    COMPREPLY=( $( compgen -W "true false" -- "${cur}" ) )
	    return
	    ;;
	--format)
	    COMPREPLY=( $( compgen -W "text json sexp mbox raw" -- "${cur}" ) )
	    return
	    ;;
	--exclude|--body)
	    COMPREPLY=( $( compgen -W "true false" -- "${cur}" ) )
	    return
	    ;;
    esac

    ! $split &&
    case "${cur}" in
	-*)
	    local options="--entire-thread= --format= --exclude= --body= --format-version= --part= --verify --decrypt --include-html"
	    compopt -o nospace
	    COMPREPLY=( $(compgen -W "$options" -- ${cur}) )
	    ;;
	*)
	    _notmuch_search_terms
	    ;;
    esac
}

_notmuch_tag()
{
    local cur prev words cword split
    # handle tags with colons and equal signs
    _init_completion -s -n := || return

    $split &&
    case "${prev}" in
	--input)
	    _filedir
	    return
	    ;;
    esac

    ! $split &&
    case "${cur}" in
	--*)
	    local options="--batch --input= --remove-all"
	    compopt -o nospace
	    COMPREPLY=( $(compgen -W "$options" -- ${cur}) )
	    return
	    ;;
	+*)
	    COMPREPLY=( $(compgen -P "+" -W "`notmuch search --output=tags \*`" -- ${cur##+}) )
	    ;;
	-*)
	    COMPREPLY=( $(compgen -P "-" -W "`notmuch search --output=tags \*`" -- ${cur##-}) )
	    ;;
	*)
	    _notmuch_search_terms
	    return
	    ;;
    esac
    # handle tags with colons
    __ltrim_colon_completions "${cur}"
}

_notmuch()
{
    local _notmuch_commands="compact config count dump help insert new reply restore search setup show tag"
    local arg cur prev words cword split
    _init_completion || return

    COMPREPLY=()

    # subcommand
    _get_first_arg

    # complete --help option like the subcommand
    if [ -z "${arg}" -a "${prev}" = "--help" ]; then
	arg="help"
    fi

    if [ -z "${arg}" ]; then
	# top level completion
	local top_options="--help --version"
	case "${cur}" in
	    -*) COMPREPLY=( $(compgen -W "${top_options}" -- ${cur}) ) ;;
	    *) COMPREPLY=( $(compgen -W "${_notmuch_commands}" -- ${cur}) ) ;;
	esac
    elif [ "${arg}" = "help" ]; then
	# handle help command specially due to _notmuch_commands usage
	local help_topics="$_notmuch_commands hooks search-terms"
	COMPREPLY=( $(compgen -W "${help_topics}" -- ${cur}) )
    else
	# complete using _notmuch_subcommand if one exist
	local completion_func="_notmuch_${arg//-/_}"
	declare -f $completion_func >/dev/null && $completion_func
    fi
} &&
complete -F _notmuch notmuch
