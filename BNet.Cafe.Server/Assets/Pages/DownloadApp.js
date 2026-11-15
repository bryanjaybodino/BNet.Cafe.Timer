function openFlagLink(e, flagUrl) {
    e.preventDefault();
    try {
        window.open(flagUrl, '_blank');
    } catch (err) {
        navigator.clipboard.writeText(flagUrl);
        alert("Copied link to clipboard: " + flagUrl + "\n\nPlease paste it into your browser's address bar.");
    }
}