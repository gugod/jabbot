jQuery(function($) {
    var $s = $("input[name=s]", this);

    $s.focus();

    function appendTalk(nick, m) {
        $("#talk").prepend(
            "<div class=\"message\"><span class=\"user from\">" + nick + "</span><span class=\"body\">" + m + "</span></div>"
        );
    }

    $("form#m").submit(function() {
        var m = $s.val();
        if (!m) return false;

        appendTalk("You", m);

        $.getJSON(
            "cgi-bin/jabbot.cgi",
            { "s": m },
            function(data) {
                if(data.reply && data.reply.text)
                    appendTalk("jabbot", data.reply.text);
            }
        );

        $s.val("").focus();
        return false;
    });

});
