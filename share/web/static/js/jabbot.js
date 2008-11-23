jQuery(function($) {
    var $s = $("input[name=s]", this);

    $s.focus();

    var i = 0;
    var zebra = ["odd", "even"];
    function appendTalk(nick, m) {
        $("<div class=\"message " + zebra[i] + "\"><span class=\"user from\">" + nick + "</span><span class=\"body\"></span></div>").find(".body").text(m).end().prependTo("#talk");
        i = 1-i;
    }

    $("form#m").submit(function() {
        var m = $s.val();
        if (!m) return false;

        var me = $("input[name=f]").val() || "CGI";
        appendTalk(me, m);

        $.getJSON(
            "cgi-bin/jabbot.cgi",
            { "s": m, "f": me },
            function(data) {
                if(data.reply && data.reply.text)
                    appendTalk("jabbot", data.reply.text);
            }
        );

        $s.val("").focus();
        return false;
    });

});
