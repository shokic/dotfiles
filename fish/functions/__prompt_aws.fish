# AWS part of the prompt: the profile assumed with granted's `assume`, from $AWS_PROFILE.
# Prints nothing when no profile is set (`assume --unset` clears it).
#   aws dev-as-dev            prod profiles in red, so they stand out
#   aws dev-as-dev expired    the credentials have expired: run `assume` again
function __prompt_aws
    set -q AWS_PROFILE[1]; or return
    test -n "$AWS_PROFILE"; or return

    set_color brblack
    echo -n '  aws '
    if string match -q 'prod*' -- $AWS_PROFILE
        set_color red
    else
        set_color magenta
    end
    echo -n $AWS_PROFILE

    # assume sets the expiry as an RFC 3339 date, e.g. 2026-11-02T16:30:00Z or ...+01:00.
    # macOS date only reads offsets without the colon, so turn Z/+01:00 into +0000/+0100.
    if set -q AWS_SESSION_EXPIRATION[1]; and test -n "$AWS_SESSION_EXPIRATION"
        set -l expiry (string replace -r 'Z$' '+00:00' -- $AWS_SESSION_EXPIRATION | string replace -r ':(\d\d)$' '$1')
        set -l expiry_seconds (date -j -f '%Y-%m-%dT%H:%M:%S%z' $expiry +%s 2>/dev/null)
        if test -n "$expiry_seconds"; and test $expiry_seconds -le (date +%s)
            set_color red
            echo -n ' expired'
        end
    end
    set_color normal
end
