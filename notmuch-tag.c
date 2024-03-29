/* notmuch - Not much of an email program, (just index and search)
 *
 * Copyright © 2009 Carl Worth
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see http://www.gnu.org/licenses/ .
 *
 * Author: Carl Worth <cworth@cworth.org>
 */

#include "notmuch-client.h"
#include "tag-util.h"
#include "string-util.h"

static volatile sig_atomic_t interrupted;

static void
handle_sigint (unused (int sig))
{
    static char msg[] = "Stopping...         \n";

    /* This write is "opportunistic", so it's okay to ignore the
     * result.  It is not required for correctness, and if it does
     * fail or produce a short write, we want to get out of the signal
     * handler as quickly as possible, not retry it. */
    IGNORE_RESULT (write (2, msg, sizeof (msg) - 1));
    interrupted = 1;
}


static char *
_optimize_tag_query (void *ctx, const char *orig_query_string,
		     const tag_op_list_t *list)
{
    /* This is subtler than it looks.  Xapian ignores the '-' operator
     * at the beginning both queries and parenthesized groups and,
     * furthermore, the presence of a '-' operator at the beginning of
     * a group can inhibit parsing of the previous operator.  Hence,
     * the user-provided query MUST appear first, but it is safe to
     * parenthesize and the exclusion part of the query must not use
     * the '-' operator (though the NOT operator is fine). */

    char *escaped = NULL;
    size_t escaped_len = 0;
    char *query_string;
    const char *join = "";
    size_t i;

    /* Don't optimize if there are no tag changes. */
    if (tag_op_list_size (list) == 0)
	return talloc_strdup (ctx, orig_query_string);

    /* Build the new query string */
    if (strcmp (orig_query_string, "*") == 0)
	query_string = talloc_strdup (ctx, "(");
    else
	query_string = talloc_asprintf (ctx, "( %s ) and (", orig_query_string);

    for (i = 0; i < tag_op_list_size (list) && query_string; i++) {
	/* XXX in case of OOM, query_string will be deallocated when
	 * ctx is, which might be at shutdown */
	if (make_boolean_term (ctx,
			       "tag", tag_op_list_tag (list, i),
			       &escaped, &escaped_len))
	    return NULL;

	query_string = talloc_asprintf_append_buffer (
	    query_string, "%s%s%s", join,
	    tag_op_list_isremove (list, i) ? "" : "not ",
	    escaped);
	join = " or ";
    }

    if (query_string)
	query_string = talloc_strdup_append_buffer (query_string, ")");

    talloc_free (escaped);
    return query_string;
}

/* Tag messages matching 'query_string' according to 'tag_ops'
 */
static int
tag_query (void *ctx, notmuch_database_t *notmuch, const char *query_string,
	   tag_op_list_t *tag_ops, tag_op_flag_t flags)
{
    notmuch_query_t *query;
    notmuch_messages_t *messages;
    notmuch_message_t *message;
    int ret = NOTMUCH_STATUS_SUCCESS;

    if (! (flags & TAG_FLAG_REMOVE_ALL)) {
	/* Optimize the query so it excludes messages that already
	 * have the specified set of tags. */
	query_string = _optimize_tag_query (ctx, query_string, tag_ops);
	if (query_string == NULL) {
	    fprintf (stderr, "Out of memory.\n");
	    return 1;
	}
	flags |= TAG_FLAG_PRE_OPTIMIZED;
    }

    query = notmuch_query_create (notmuch, query_string);
    if (query == NULL) {
	fprintf (stderr, "Out of memory.\n");
	return 1;
    }

    /* tagging is not interested in any special sort order */
    notmuch_query_set_sort (query, NOTMUCH_SORT_UNSORTED);

    for (messages = notmuch_query_search_messages (query);
	 notmuch_messages_valid (messages) && ! interrupted;
	 notmuch_messages_move_to_next (messages)) {
	message = notmuch_messages_get (messages);
	ret = tag_op_list_apply (message, tag_ops, flags);
	notmuch_message_destroy (message);
	if (ret != NOTMUCH_STATUS_SUCCESS)
	    break;
    }

    notmuch_query_destroy (query);

    return ret || interrupted;
}

/* Wrapper around getline() that supports line continuation.
 *
 * If any line ends with "\\\n", then the "\\\n" is removed and the line is
 * joined with the next line.
 */
static ssize_t
getline_cont (char **line, size_t *n, FILE *input)
{
	char *multi_line = NULL;
	size_t multi_line_size = 0;
	ssize_t multi_line_len = -1;

	char *single_line = NULL;
	size_t single_line_size = 0;
	ssize_t single_line_len = -1;

	while (1) {
		single_line_len = getline (&single_line, &single_line_size,
				           input);
		if (single_line_len == -1 || interrupted) {
			free (multi_line);
			free (single_line);
			return -1;
		}

		if (multi_line_size == 0) {
			multi_line = single_line;
			multi_line_len = single_line_len;
			multi_line_size = single_line_size;

			single_line = NULL;
			single_line_size = 0;
			single_line_len = -1;
		} else {
			ssize_t multi_line_old_len = multi_line_len;
			ssize_t multi_line_new_len = multi_line_len + single_line_len;

			if ((ssize_t)multi_line_size < multi_line_new_len + 1) {
				multi_line_size = multi_line_new_len + 1;
				multi_line = realloc(multi_line, multi_line_size);
			}

			memcpy(multi_line + multi_line_old_len, single_line,
			       single_line_len);
			multi_line[multi_line_new_len] = '\0';
			multi_line_len = multi_line_new_len;

			free (single_line);
			single_line = NULL;
		}

		if (multi_line_len < 2) {
			break;
		} else if (multi_line[multi_line_len - 1] == '\n' &&
		           multi_line[multi_line_len - 2] == '\\') {
			multi_line_len -= 2;
			multi_line[multi_line_len] = '\0';
		} else {
			break;
		}
	}

	if (*line != NULL) {
		free (*line);
	}

	*line = multi_line;
	*n = multi_line_size;
	return multi_line_len;
}

static int
tag_file (void *ctx, notmuch_database_t *notmuch, tag_op_flag_t flags,
	  FILE *input)
{
    char *line = NULL;
    char *query_string = NULL;
    size_t line_size = 0;
    ssize_t line_len;
    int ret = 0;
    int warn = 0;
    tag_op_list_t *tag_ops;

    tag_ops = tag_op_list_create (ctx);
    if (tag_ops == NULL) {
	fprintf (stderr, "Out of memory.\n");
	return 1;
    }

    while ((line_len = getline_cont (&line, &line_size, input)) != -1 &&
	   ! interrupted) {

	ret = parse_tag_line (ctx, line, TAG_FLAG_NONE,
			      &query_string, tag_ops);

	if (ret > 0) {
	    if (ret != TAG_PARSE_SKIPPED)
		/* remember there has been problematic lines */
		warn = 1;
	    ret = 0;
	    continue;
	}

	if (ret < 0)
	    break;

	ret = tag_query (ctx, notmuch, query_string, tag_ops, flags);
	if (ret)
	    break;
    }

    if (line)
	free (line);

    return ret || warn;
}

int
notmuch_tag_command (notmuch_config_t *config, int argc, char *argv[])
{
    tag_op_list_t *tag_ops = NULL;
    char *query_string = NULL;
    notmuch_database_t *notmuch;
    struct sigaction action;
    tag_op_flag_t tag_flags = TAG_FLAG_NONE;
    notmuch_bool_t batch = FALSE;
    notmuch_bool_t remove_all = FALSE;
    FILE *input = stdin;
    char *input_file_name = NULL;
    int opt_index;
    int ret = 0;

    /* Setup our handler for SIGINT */
    memset (&action, 0, sizeof (struct sigaction));
    action.sa_handler = handle_sigint;
    sigemptyset (&action.sa_mask);
    action.sa_flags = SA_RESTART;
    sigaction (SIGINT, &action, NULL);

    notmuch_opt_desc_t options[] = {
	{ NOTMUCH_OPT_BOOLEAN, &batch, "batch", 0, 0 },
	{ NOTMUCH_OPT_STRING, &input_file_name, "input", 'i', 0 },
	{ NOTMUCH_OPT_BOOLEAN, &remove_all, "remove-all", 0, 0 },
	{ 0, 0, 0, 0, 0 }
    };

    opt_index = parse_arguments (argc, argv, options, 1);
    if (opt_index < 0)
	return 1;

    if (input_file_name) {
	batch = TRUE;
	input = fopen (input_file_name, "r");
	if (input == NULL) {
	    fprintf (stderr, "Error opening %s for reading: %s\n",
		     input_file_name, strerror (errno));
	    return 1;
	}
    }

    if (batch) {
	if (opt_index != argc) {
	    fprintf (stderr, "Can't specify both cmdline and stdin!\n");
	    return 1;
	}
	if (remove_all) {
	    fprintf (stderr, "Can't specify both --remove-all and --batch\n");
	    return 1;
	}
    } else {
	tag_ops = tag_op_list_create (config);
	if (tag_ops == NULL) {
	    fprintf (stderr, "Out of memory.\n");
	    return 1;
	}

	if (parse_tag_command_line (config, argc - opt_index, argv + opt_index,
				    &query_string, tag_ops))
	    return 1;

	if (tag_op_list_size (tag_ops) == 0 && ! remove_all) {
	    fprintf (stderr, "Error: 'notmuch tag' requires at least one tag to add or remove.\n");
	    return 1;
	}

	if (*query_string == '\0') {
	    fprintf (stderr, "Error: notmuch tag requires at least one search term.\n");
	    return 1;
	}
    }

    if (notmuch_database_open (notmuch_config_get_database_path (config),
			       NOTMUCH_DATABASE_MODE_READ_WRITE, &notmuch))
	return 1;

    if (notmuch_config_get_maildir_synchronize_flags (config))
	tag_flags |= TAG_FLAG_MAILDIR_SYNC;

    if (remove_all)
	tag_flags |= TAG_FLAG_REMOVE_ALL;

    if (batch)
	ret = tag_file (config, notmuch, tag_flags, input);
    else
	ret = tag_query (config, notmuch, query_string, tag_ops, tag_flags);

    notmuch_database_destroy (notmuch);

    if (input != stdin)
	fclose (input);

    return ret || interrupted;
}
