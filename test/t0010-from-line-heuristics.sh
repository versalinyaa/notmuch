#!/bin/bash
test_description="From line heuristics (with multiple configured addresses)"
. ./test-lib.sh

test_expect_success "Magic from guessing (nothing to go on)" '
add_message "[from]=\"Sender <sender@example.com>\"" \
             [to]=mailinglist@notmuchmail.org \
             [subject]=notmuch-reply-test \
            "[date]=\"Tue, 05 Jan 2010 15:43:56 -0000\"" \
            "[body]=\"from guessing test\"" &&

output=$($NOTMUCH reply id:${gen_msg_id}) &&
pass_if_equal "$output" "From: Notmuch Test Suite <test_suite@notmuchmail.org>
Subject: Re: notmuch-reply-test
To: Sender <sender@example.com>, mailinglist@notmuchmail.org
Bcc: test_suite@notmuchmail.org
In-Reply-To: <${gen_msg_id}>
References: <${gen_msg_id}>

On Tue, 05 Jan 2010 15:43:56 -0000, Sender <sender@example.com> wrote:
> from guessing test"

'
test_expect_success "Magic from guessing (Envelope-to:)" '
add_message "[from]=\"Sender <sender@example.com>\"" \
             [to]=mailinglist@notmuchmail.org \
             [subject]=notmuch-reply-test \
            "[header]=\"Envelope-To: test_suite_other@notmuchmail.org\"" \
            "[date]=\"Tue, 05 Jan 2010 15:43:56 -0000\"" \
            "[body]=\"from guessing test\"" &&

output=$($NOTMUCH reply id:${gen_msg_id}) &&
pass_if_equal "$output" "From: Notmuch Test Suite <test_suite_other@notmuchmail.org>
Subject: Re: notmuch-reply-test
To: Sender <sender@example.com>, mailinglist@notmuchmail.org
Bcc: test_suite@notmuchmail.org
In-Reply-To: <${gen_msg_id}>
References: <${gen_msg_id}>

On Tue, 05 Jan 2010 15:43:56 -0000, Sender <sender@example.com> wrote:
> from guessing test"

'
test_expect_success "Magic from guessing (X-Original-To:)" '
add_message "[from]=\"Sender <sender@example.com>\"" \
             [to]=mailinglist@notmuchmail.org \
             [subject]=notmuch-reply-test \
            "[header]=\"X-Original-To: test_suite_other@notmuchmail.org\"" \
            "[date]=\"Tue, 05 Jan 2010 15:43:56 -0000\"" \
            "[body]=\"from guessing test\"" &&

output=$($NOTMUCH reply id:${gen_msg_id}) &&
pass_if_equal "$output" "From: Notmuch Test Suite <test_suite_other@notmuchmail.org>
Subject: Re: notmuch-reply-test
To: Sender <sender@example.com>, mailinglist@notmuchmail.org
Bcc: test_suite@notmuchmail.org
In-Reply-To: <${gen_msg_id}>
References: <${gen_msg_id}>

On Tue, 05 Jan 2010 15:43:56 -0000, Sender <sender@example.com> wrote:
> from guessing test"

'
test_expect_success "Magic from guessing (Received: .. for ..)" '
add_message "[from]=\"Sender <sender@example.com>\"" \
             [to]=mailinglist@notmuchmail.org \
             [subject]=notmuch-reply-test \
            "[header]=\"Received: from mail.example.com (mail.example.com [1.1.1.1])\
        by mail.notmuchmail.org (some MTA) with ESMTP id 12345678\
        for <test_suite_other@notmuchmail.org>; Sat, 10 Apr 2010 07:54:51 -0400 (EDT)\"" \
            "[date]=\"Tue, 05 Jan 2010 15:43:56 -0000\"" \
            "[body]=\"from guessing test\"" &&

output=$($NOTMUCH reply id:${gen_msg_id}) &&
pass_if_equal "$output" "From: Notmuch Test Suite <test_suite_other@notmuchmail.org>
Subject: Re: notmuch-reply-test
To: Sender <sender@example.com>, mailinglist@notmuchmail.org
Bcc: test_suite@notmuchmail.org
In-Reply-To: <${gen_msg_id}>
References: <${gen_msg_id}>

On Tue, 05 Jan 2010 15:43:56 -0000, Sender <sender@example.com> wrote:
> from guessing test"

'
test_expect_success "Magic from guessing (Received: domain)" '
add_message "[from]=\"Sender <sender@example.com>\"" \
             [to]=mailinglist@notmuchmail.org \
             [subject]=notmuch-reply-test \
            "[header]=\"Received: from mail.example.com (mail.example.com [1.1.1.1])\
        by mail.otherdomain.org (some MTA) with ESMTP id 12345678\
        Sat, 10 Apr 2010 07:54:51 -0400 (EDT)\"" \
            "[date]=\"Tue, 05 Jan 2010 15:43:56 -0000\"" \
            "[body]=\"from guessing test\"" &&

output=$($NOTMUCH reply id:${gen_msg_id}) &&
pass_if_equal "$output" "From: Notmuch Test Suite <test_suite@otherdomain.org>
Subject: Re: notmuch-reply-test
To: Sender <sender@example.com>, mailinglist@notmuchmail.org
Bcc: test_suite@notmuchmail.org
In-Reply-To: <${gen_msg_id}>
References: <${gen_msg_id}>

On Tue, 05 Jan 2010 15:43:56 -0000, Sender <sender@example.com> wrote:
> from guessing test"


'
test_expect_success "Testing From line heuristics (with single configured address)" '
sed -i -e "s/^other_email.*//" "${NOTMUCH_CONFIG}"

'
test_expect_success "Magic from guessing (nothing to go on)" '
add_message "[from]=\"Sender <sender@example.com>\"" \
             [to]=mailinglist@notmuchmail.org \
             [subject]=notmuch-reply-test \
            "[date]=\"Tue, 05 Jan 2010 15:43:56 -0000\"" \
            "[body]=\"from guessing test\"" &&

output=$($NOTMUCH reply id:${gen_msg_id}) &&
pass_if_equal "$output" "From: Notmuch Test Suite <test_suite@notmuchmail.org>
Subject: Re: notmuch-reply-test
To: Sender <sender@example.com>, mailinglist@notmuchmail.org
Bcc: test_suite@notmuchmail.org
In-Reply-To: <${gen_msg_id}>
References: <${gen_msg_id}>

On Tue, 05 Jan 2010 15:43:56 -0000, Sender <sender@example.com> wrote:
> from guessing test"

'
test_expect_success "Magic from guessing (Envelope-to:)" '
add_message "[from]=\"Sender <sender@example.com>\"" \
             [to]=mailinglist@notmuchmail.org \
             [subject]=notmuch-reply-test \
            "[header]=\"Envelope-To: test_suite_other@notmuchmail.org\"" \
            "[date]=\"Tue, 05 Jan 2010 15:43:56 -0000\"" \
            "[body]=\"from guessing test\"" &&

output=$($NOTMUCH reply id:${gen_msg_id}) &&
pass_if_equal "$output" "From: Notmuch Test Suite <test_suite@notmuchmail.org>
Subject: Re: notmuch-reply-test
To: Sender <sender@example.com>, mailinglist@notmuchmail.org
Bcc: test_suite@notmuchmail.org
In-Reply-To: <${gen_msg_id}>
References: <${gen_msg_id}>

On Tue, 05 Jan 2010 15:43:56 -0000, Sender <sender@example.com> wrote:
> from guessing test"

'
test_expect_success "Magic from guessing (X-Original-To:)" '
add_message "[from]=\"Sender <sender@example.com>\"" \
             [to]=mailinglist@notmuchmail.org \
             [subject]=notmuch-reply-test \
            "[header]=\"X-Original-To: test_suite_other@notmuchmail.org\"" \
            "[date]=\"Tue, 05 Jan 2010 15:43:56 -0000\"" \
            "[body]=\"from guessing test\"" &&

output=$($NOTMUCH reply id:${gen_msg_id}) &&
pass_if_equal "$output" "From: Notmuch Test Suite <test_suite@notmuchmail.org>
Subject: Re: notmuch-reply-test
To: Sender <sender@example.com>, mailinglist@notmuchmail.org
Bcc: test_suite@notmuchmail.org
In-Reply-To: <${gen_msg_id}>
References: <${gen_msg_id}>

On Tue, 05 Jan 2010 15:43:56 -0000, Sender <sender@example.com> wrote:
> from guessing test"

'
test_expect_success "Magic from guessing (Received: .. for ..)" '
add_message "[from]=\"Sender <sender@example.com>\"" \
             [to]=mailinglist@notmuchmail.org \
             [subject]=notmuch-reply-test \
            "[header]=\"Received: from mail.example.com (mail.example.com [1.1.1.1])\
        by mail.notmuchmail.org (some MTA) with ESMTP id 12345678\
        for <test_suite_other@notmuchmail.org>; Sat, 10 Apr 2010 07:54:51 -0400 (EDT)\"" \
            "[date]=\"Tue, 05 Jan 2010 15:43:56 -0000\"" \
            "[body]=\"from guessing test\"" &&

output=$($NOTMUCH reply id:${gen_msg_id}) &&
pass_if_equal "$output" "From: Notmuch Test Suite <test_suite@notmuchmail.org>
Subject: Re: notmuch-reply-test
To: Sender <sender@example.com>, mailinglist@notmuchmail.org
Bcc: test_suite@notmuchmail.org
In-Reply-To: <${gen_msg_id}>
References: <${gen_msg_id}>

On Tue, 05 Jan 2010 15:43:56 -0000, Sender <sender@example.com> wrote:
> from guessing test"

'
test_expect_success "Magic from guessing (Received: domain)" '
add_message "[from]=\"Sender <sender@example.com>\"" \
             [to]=mailinglist@notmuchmail.org \
             [subject]=notmuch-reply-test \
            "[header]=\"Received: from mail.example.com (mail.example.com [1.1.1.1])\
        by mail.otherdomain.org (some MTA) with ESMTP id 12345678\
        Sat, 10 Apr 2010 07:54:51 -0400 (EDT)\"" \
            "[date]=\"Tue, 05 Jan 2010 15:43:56 -0000\"" \
            "[body]=\"from guessing test\"" &&

output=$($NOTMUCH reply id:${gen_msg_id}) &&
pass_if_equal "$output" "From: Notmuch Test Suite <test_suite@notmuchmail.org>
Subject: Re: notmuch-reply-test
To: Sender <sender@example.com>, mailinglist@notmuchmail.org
Bcc: test_suite@notmuchmail.org
In-Reply-To: <${gen_msg_id}>
References: <${gen_msg_id}>

On Tue, 05 Jan 2010 15:43:56 -0000, Sender <sender@example.com> wrote:
> from guessing test"
'
test_done