$(document).ready(function() {

    if(askOauthRegistration) {
        opts =
        $('#modal').reveal({
            animation: 'none',
            animationspeed: 300
        });
    }

    var url = window.location.hash;

    if (/^#target/.test(url)) {
        iframe = $('iframe');
        url = url.substring("#target/".length, url.length);
        url = decodeURIComponent(url);
        iframe[0].src = iframe[0].src + url;
    }
});