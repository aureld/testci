jQuery.ajax({
    url: "http://publisher-pr490:8080/s/d41d8cd98f00b204e9800998ecf8427e/en_US-fwumir-1988229788/6155/6/1.4.0-m6/_/download/batch/com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector-embededjs/com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector-embededjs.js?collectorId=6b527edf",
    type: "get",
    cache: true,
    dataType: "script"
});

window.ATL_JQ_PAGE_PROPS = {
        "triggerFunction": function(showCollectorDialog) {
            jQuery("#add").click(function(e) {
                e.preventDefault();
                showCollectorDialog();
            });
        }
    };