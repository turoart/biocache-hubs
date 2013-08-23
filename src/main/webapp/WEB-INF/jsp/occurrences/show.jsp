<%--
    Document   : list
    Created on : Feb 2, 2011, 10:54:57 AM
    Author     : "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
--%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="/common/taglibs.jsp" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<!DOCTYPE html>
<c:choose>
    <c:when test="${skin == 'avh'}">
        <c:set var="recordId" value="${record.raw.occurrence.catalogNumber}"/>
    </c:when>
    <c:when test="${not empty record.raw.occurrence.collectionCode && not empty record.raw.occurrence.catalogNumber}">
        <c:set var="recordId" value="${record.raw.occurrence.collectionCode} - ${record.raw.occurrence.catalogNumber}"/>
    </c:when>
    <c:when test="${not empty record.processed.attribution.dataResourceName && not empty record.raw.occurrence.catalogNumber}">
        <c:set var="recordId" value="${record.processed.attribution.dataResourceName} - ${record.raw.occurrence.catalogNumber}"/>
    </c:when>
    <c:when test="${not empty record.raw.occurrence.occurrenceID}">
        <c:set var="recordId" value="${record.raw.occurrence.occurrenceID}"/>
    </c:when>
    <c:otherwise>
        <c:set var="recordId" value="${record.raw.uuid}"/>
    </c:otherwise>
</c:choose>
<c:set var="bieWebappContext" scope="request"><ala:propertyLoader checkSupplied="true" bundle="hubs" property="bieWebappContext"/></c:set>
<c:set var="collectionsWebappContext" scope="request"><ala:propertyLoader checkSupplied="true" bundle="hubs" property="collectionsWebappContext"/></c:set>
<c:set var="useAla" scope="request"><ala:propertyLoader checkSupplied="true" bundle="hubs" property="useAla"/></c:set>
<c:set var="hubDisplayName" scope="request"><ala:propertyLoader checkSupplied="true" bundle="hubs" property="site.displayName"/></c:set>
<c:set var="biocacheService" scope="request"><ala:propertyLoader checkSupplied="true" bundle="hubs" property="biocacheRestService.biocacheUriPrefix"/></c:set>
<c:set var="spatialPortalUrl" scope="request"><ala:propertyLoader checkSupplied="true" bundle="hubs" property="spatialPortalUrl"/></c:set>
<c:set var="serverName" scope="request"><ala:propertyLoader checkSupplied="true" bundle="hubs" property="serverName" checkInit="true"/></c:set>
<c:set var="scientificName">
    <c:choose>
        <c:when test="${not empty record.processed.classification.scientificName}">
            ${record.processed.classification.scientificName} ${record.processed.classification.scientificNameAuthorship}
        </c:when>
        <c:when test="${not empty record.raw.classification.scientificName}">
            ${record.raw.classification.scientificName} ${record.raw.classification.scientificNameAuthorship}
        </c:when>
        <c:otherwise>
            ${record.raw.classification.genus} ${record.raw.classification.specificEpithet}
        </c:otherwise>
    </c:choose>
</c:set>
<html>
    <head>
        <!-- Skin selected: ${skin} -->
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="decorator" content="${skin}"/>
        <meta name="section" content="search"/>
        <title>${recordId} | <fmt:message key="show.occurrenceRecord"/>  | ${hubDisplayName} </title>
        <script type="text/javascript">
            contextPath = "${pageContext.request.contextPath}";
            var OCC_REC = {
                userId: "${userId}",
                userDisplayName: "${userDisplayName}"
            }
        </script>
        <script src="${pageContext.request.contextPath}/static/js/audiojs/audio.min.js"></script>
        <%--<jwr:style src="/css/record.css"/>--%>
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/static/css/record.css"/>
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/static/css/button.css"/>
        <style type="text/css">
            #expertDistroMap img {  max-width: none; }
            #occurrenceMap img {  max-width: none; }
            div.audiojs { margin: 15px 0px 10px; }
            div.audiojs div.scrubber { width:120px;}
            div.audiojs div.time { width:50px; }
        </style>
        <script type="text/javascript">
            /**
             * Delete a user assertion
             */
            function deleteAssertion(recordUuid, assertionUuid){
                $.post('${pageContext.request.contextPath}/occurrences/assertions/delete',
                    { recordUuid: recordUuid, assertionUuid: assertionUuid },
                    function(data) {
                        //retrieve all asssertions
                        $.get('${pageContext.request.contextPath}/occurrences/groupedAssertions?recordUuid=${record.raw.uuid}', function(data) {
                            $('#'+assertionUuid).fadeOut('slow', function() {
                                $('#userAssertions').html(data);
                                //if theres no child elements to the list, hide the heading
                                //alert("Number of user assertions : " +  $('#userAssertions').children().size()   )
                                if($('#userAssertions').children().size() < 1){
                                    $('#userAssertionsContainer').hide("slow");
                                }
                            });
                        });
                        refreshUserAnnotations();
                    }
                );
            }

            /**
            * Convert camel case text to pretty version (all lower case)
            */
            function fileCase(str) {
                return str.replace(/([a-z])([A-Z])/g, "$1 $2").toLowerCase().capitalize();
            }

            //load the assertions
            function refreshUserAnnotations(){
                $.get("${pageContext.request.contextPath}/occurrences/${record.raw.uuid}/userAssertions.json", function(data) {

                    if(data.assertionQueries.length == 0 && data.userAssertions.length == 0){
                        $('#userAnnotationsDiv').hide('slow');
                    } else {
                        $('#userAnnotationsDiv').show('slow');
                    }
                    $('#userAnnotationsList').empty();

                    for(var i=0; i < data.assertionQueries.length; i++){
                        var $clone = $('#userAnnotationTemplate').clone();
                        $clone.find('.issue').text(data.assertionQueries[i].assertionType);
                        $clone.find('.user').text(data.assertionQueries[i].userName);
                        $clone.find('.comment').text(data.assertionQueries[i].comment);
                        $clone.find('.created').text(data.assertionQueries[i].created);
                        if(data.assertionQueries[i].recordCount > 1){
                            $clone.find('.viewMore').css({display:'block'});
                            $clone.find('.viewMoreLink').attr('href', '${pageContext.request.contextPath}/occurrences/search?q=query_assertion_uuid:' + data.assertionQueries[i].uuid);
                        }
                        $('#userAnnotationsList').append($clone);
                    }
                    for(var i = 0; i < data.userAssertions.length; i++){
                        var $clone = $('#userAnnotationTemplate').clone();
                        $clone.find('.issue').text(data.userAssertions[i].name);
                        $clone.find('.user').text(data.userAssertions[i].userDisplayName);
                        //$clone.find('.userDisplayName').text("User: " + data.userAssertions[i].userDisplayName);
                        $clone.find('.comment').text('Comment: ' + data.userAssertions[i].comment);
                        $clone.find('.userRole').text(data.userAssertions[i].userRole !=null ? data.userAssertions[i].userRole: '');
                        $clone.find('.userEntity').text(data.userAssertions[i].userEntityName !=null ? data.userAssertions[i].userEntityName: '');
                        $clone.find('.created').text('Date created: ' + (new Date(data.userAssertions[i].created)).toString('yyyy-MM-dd'));
                        if(data.userAssertions[i].userRole != null){
                            $clone.find('.userRole').text(', ' + data.userAssertions[i].userRole);
                        }
                        if(data.userAssertions[i].userEntityName !=null){
                            $clone.find('.userEntity').text(', ' + data.userAssertions[i].userEntityName);
                        }
                        if(OCC_REC.userId == data.userAssertions[i].userId){
                            $clone.find('.deleteAnnotation').css({display:'block'});
                            $clone.find('.deleteAnnotation').attr('id', data.userAssertions[i].uuid);
                        } else {
                            $clone.find('.deleteAnnotation').css({display:'none'});
                        }
                        $('#userAnnotationsList').append($clone);
                    }
                    updateDeleteEvents();
                });
            }

            function updateDeleteEvents(){
              $('.deleteAnnotation').off("click");
              $('.deleteAnnotation').on("click", function(e){
                e.preventDefault();
                var isConfirmed = confirm('Are you sure you want to delete this issue?');
                if (isConfirmed === true) {
                    deleteAssertion('${ala:escapeJS(record.raw.uuid)}', this.id);
                }
              });
            }

            /**
            * Capitalise first letter of string only
            * @return {String}
             */
            String.prototype.capitalize = function() {
                return this.charAt(0).toUpperCase() + this.slice(1);
            }

            /**
             * JQuery on document ready callback
             */
            $(document).ready(function() {

                <c:if test="${record.processed.attribution.provenance == 'Draft'}">
                $('#viewDraftButton').click(function(){
                    document.location.href = '${record.raw.occurrence.occurrenceID}';
                })
                </c:if>

                // add assertion form display
                $("#assertionButton, #verifyButton").fancybox({
                    //'href': '#loginOrFlag',
                    'hideOnContentClick' : false,
                    'hideOnOverlayClick': true,
                    'showCloseButton': true,
                    'titleShow' : false,
                    'autoDimensions' : true,
                    //'width': '500',
                    //'height': '400',
                    'padding': 15,
                    'margin': 10
                });

                $('#showUncheckedTests').on('click', function(e){
                    $('.uncheckTestResult').toggle();
                });

                $('#showMissingPropResult').on('click', function(e){
                    $('.missingPropResult').toggle();
                });

                // raw vs processed popup
                $("#showRawProcessed").fancybox({
                    //'href': '#loginOrFlag',
                    'hideOnContentClick' : false,
                    'hideOnOverlayClick': true,
                    'showCloseButton': true,
                    'titleShow' : false,
                    'centerOnScroll': true,
                    'transitionIn': 'elastic',
                    'transitionOut': 'elastic',
                    'speedIn': 500,
                    'speedOut': 500,
                    'autoDimensions' : false,
                    'width': '80%',
                    'height': '80%',
                    'padding': 15,
                    'margin': 10
                });

                refreshUserAnnotations();

                // bind to form submit for assertions
                $("form#issueForm").submit(function(e) {
                    e.preventDefault();
                    var comment = $("#issueComment").val();
                    var code = $("#issue").val();
                    var userDisplayName = '${userDisplayName}';
                    var recordUuid = '${ala:escapeJS(record.raw.rowKey)}';
                    if(code!=""){
                        $('#assertionSubmitProgress').css({'display':'block'});
                        $.post("${pageContext.request.contextPath}/occurrences/assertions/add",
                            { recordUuid: recordUuid, code: code, comment: comment, userId: OCC_REC.userId, userDisplayName: userDisplayName},
                            function(data) {
                                $('#assertionSubmitProgress').css({'display':'none'});
                                $("#submitSuccess").html("Thanks for flagging the problem!");
                                $("#issueFormSubmit").hide();
                                $("input:reset").hide();
                                $("input#close").show();
                                //retrieve all assertions
                                $.get('${pageContext.request.contextPath}/occurrences/groupedAssertions?recordUuid=${record.raw.uuid}', function(data) {
                                    //console.log("data", data);
                                    $('#userAssertions').html(data);
                                    $('#userAssertionsContainer').show("slow");
                                });
                                refreshUserAnnotations();
                            }
                        ).error(function() {
                            $('#assertionSubmitProgress').css({'display':'none'});
                            $("#submitSuccess").html("There was problem flagging the issue. Please try again later.");
                        });
                    } else {
                        alert("Please supply a issue type");
                    }
                });

                $(".userAssertionComment").each(function(i, el) {
                    var html = $(el).html();
                    $(el).html(replaceURLWithHTMLLinks(html)); // convert it
                });


                // bind to form "close" button
                $("input#close").live("click", function(e) {
                    // close the popup
                    $.fancybox.close();
                    // reset form back to default state
                    $('form#issueForm')[0].reset();
                    $("#submitSuccess").html("");
                    $("#issueFormSubmit").show("slow");
                    $("input:reset").show("slow");
                    $("input#close").hide("slow");
                });

                // give every second row a class="grey-bg"
//                $('table.occurrenceTable, table.inner, table.layerIntersections, table.duplicationTable').each(function(i, el) {
//                    $(this).find('tr').not('.sectionName').each(function(j, tr) {
//                        if (j % 2 == 0) {
//                            $(this).addClass("grey-bg");
//                        }
//                    });
//                });

                // convert camel case field names to "normal"
                $("td.dwc, span.dwc").each(function(i, el) {
                    var html = $(el).html();
                    $(el).html(fileCase(html)); // conver it
                });

                // load a JS map with sensitiveDatasets values from hubs.properties file
                var sensitiveDatasets = {
                    <c:forEach var="sds" items="${sensitiveDatasets}" varStatus="s">
                        ${sds}: '<ala:propertyLoader checkSupplied="true" bundle="hubs" property="sensitiveDatasets.${sds}"/>'<c:if test="${not s.last}">,</c:if>
                    </c:forEach>
                }

                // add links for dataGeneralizations pages in collectory
                $("span.dataGeneralizations").each(function(i, el) {
                    var field = $(this);
                    var text = $(this).text().match(/\[.*?\]/g);

                    if (text) {
                        $.each(text, function(j, el) {
                            var list = el.replace(/\[.*,(.*)\]/, "$1").trim();
                            var code = list.replace(/\s/g, "_").toUpperCase();

                            if (sensitiveDatasets[code]) {
                                var linked = "<a href='" + sensitiveDatasets[code] + "' title='" + list
                                    + " sensitive species list information page' target='collectory'>" + list + "</a>";
                                var regex = new RegExp(list, "g");
                                var html = $(field).html().replace(regex, linked);
                                $(field).html(html);
                            }
                        });
                    }
                });

                <c:if test="${isCollectionAdmin}">
                    $(".confirmVerifyCheck").click(function(e) {
                        $("#verifyAsk").hide();
                        $("#verifyDone").show();
                    });
                    $(".cancelVerify").click(function(e) {
                        $.fancybox.close();
                    });
                    $(".closeVerify").click(function(e) {
                        $.fancybox.close();
                    });
                    $(".confirmVerify").click(function(e) {
                        $("#verifySpinner").show();
                        var code = "50000";
                        var userDisplayName = '${userDisplayName}';
                        var recordUuid = '${ala:escapeJS(record.raw.rowKey)}';
                        var comment = $("#verifyComment").val();
                        if (!comment) {
                            alert("Please add a comment");
                            $("#verifyComment").focus();
                            $("#verifySpinner").hide();
                            return false;
                        }
                        // send assertion via AJAX... TODO catch errors
                        $.post("${pageContext.request.contextPath}/occurrences/assertions/add",
                            { recordUuid: recordUuid, code: code, comment: comment, userId: OCC_REC.userId, userDisplayName: userDisplayName},
                            function(data) {
                                // service simply returns status or OK or FORBIDDEN, so assume it worked...
                                $("#verifyAsk").fadeOut();
                                $("#verifyDone").fadeIn();
                            }
                        ).error(function (request, status, error) {
                            alert("Error verifying record: " + request.responseText);
                        }).complete(function() {
                            $("#verifySpinner").hide();
                        });
                    });
                </c:if>

                $("#backBtn a").click(function(e) {
                    e.preventDefault();
                    var url = $(this).attr("href");
                    if (url) {
                        // referer value from request object
                        window.location.href = url;
                    } else if (history.length) {
                        //There is history to go back to
                        history.go(-1);
                    } else {
                        alert("Sorry it appears the history has been lost, please use the browser&apso;s back button");
                    }
                });

                var sequenceTd = $("tr#nucleotides").find("td.value");
                var sequenceStr = sequenceTd.text().trim();
                if (sequenceStr.length > 10) {
                    // split long DNA sequences into blocks of 10 chars
                    $(sequenceTd).html("<code>"+sequenceStr.replace(/(.{10})/g,"$1 ")+"</code>");
                }

                // context sensitive help on data quality tests
                $(".dataQualityHelpLinkZZZ").click(function(e) {
                    e.preventDefault();
                    $("#dataQualityModal .modal-body").html(""); // clear content
                    var code = $(this).data("code");
                    var dataQualityItem = getDataQualityItem(code);
                    var content = "Error: info not found";
                    if (dataQualityItem) {
                        content = "<div><b>Name: " + dataQualityItem.name + "</b></div>";
                        content += "<div>" + dataQualityItem.description + "</div>";
                        content += "<div><a href='http://code.google.com/p/ala-dataquality/wiki/" +
                                dataQualityItem.name + "' target='wiki' title='More details on the wiki page'>Wiki page</a></div>";
                    }

                    //$("#dataQualityModal .modal-body").html(content);
                    //$('#dataQualityModal').modal({show:true});
                    $(this).popover({
                        html : true,
                        content: function() {
                            return content;
                        }
                    });
                });

                $(".dataQualityHelpLinkZZ").popover({
                    html : true,
                    content: "Just a test"
                }).click('click', function(e) { e.preventDefault(); });



                $(".dataQualityHelpLink").popover({
                    html : true,
                    trigger: "click",
                    title: function() {
                        var code = $(this).data("code");
                        var content = "";
                        var dataQualityItem = getDataQualityItem(code);
                        if (dataQualityItem) {
                            content = "<button type='button' class='close' onclick='$(&quot;.dataQualityHelpLink&quot;).popover(&quot;hide&quot;);'>×</button>" + dataQualityItem.name;
                        }
                        return content;
                    },
                    content: function() {
                        var code = $(this).data("code");
                        var dataQualityItem = getDataQualityItem(code);
                        var content = "Error: info not found";
                        if (dataQualityItem) {
                            //content = "<div><b>" + dataQualityItem.name + "</b></div>";
                            content = "<div>" + dataQualityItem.description + "</div>";
                            if (dataQualityItem.wiki) {
                                content += "<div><i class='icon-share-alt'></i>&nbsp;<a href='http://code.google.com/p/ala-dataquality/wiki/" +
                                        dataQualityItem.name + "' target='wiki' title='More details on the wiki page'>Wiki page</a></div>";
                            }
                        }
                        return content;
                    }
                }).click('click', function(e) { e.preventDefault(); });

            }); // end JQuery document ready

            var dataQualityDataIsLoaded = false;
            var dataQualityItems = {};

            function getDataQualityItem(code) {

                if (!dataQualityDataIsLoaded) {
                    var url = "${pageContext.request.contextPath}/data-quality/allCodes.json";
                    $.ajax({
                        type: 'GET',
                        url: url,
                        dataType: 'json',
                        success: function(data) {
                            if (data && data[1]) {
                                $.each(data, function(key, val) {
                                    console.log("data", key, val);
                                    dataQualityItems[key] = val;
                                });
                            }
                        },
                        complete: function() {
                            dataQualityDataIsLoaded = true;
                        },
                        async: false
                    });
                }
                console.log("dataQualityItems",dataQualityItems);
                if (dataQualityItems[code]) {
                    return dataQualityItems[code];
                }
            }

            /*
             * IE doesn't support String.trim(), so add it in manually
             */
            if(typeof String.prototype.trim !== 'function') {
                String.prototype.trim = function() {
                    return this.replace(/^\s+|\s+$/g, '');
                }
            }

            function replaceURLWithHTMLLinks(text) {
                var exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/i;
                return text.replace(exp,"<a href='$1'>$1</a>");
            }

            function renderOutlierCharts(data){
               var chartQuery = null;

               <c:choose>
                <c:when test="${record.processed.classification.taxonRank == 'species'}">
                chartQuery = 'species_guid:${fn:replace(record.processed.classification.taxonConceptID, ':', '\\:')}';
                </c:when>
                <c:when test="${record.processed.classification.taxonRank == 'subspecies'}">
                chartQuery = 'subspecies_guid:${fn:replace(record.processed.classification.taxonConceptID, ':', '\\:')}';
                </c:when>
               </c:choose>

               if(chartQuery != null){
                   $.each(data, function() {
                       drawChart(this.layerId, chartQuery, this.layerId+'Outliers', this.outlierValues, this.recordLayerValue, false);
                       drawChart(this.layerId, chartQuery, this.layerId+'OutliersCumm', this.outlierValues, this.recordLayerValue, true);
                   })
               }
            }

            function drawChart(facetName, biocacheQuery, chartName, outlierValues, valueForThisRecord, cumulative){

                var facetChartOptions = { error: "badQuery", legend: 'right'}
                facetChartOptions.query = biocacheQuery;
                facetChartOptions.charts = [chartName];
                facetChartOptions.backgroundColor = '#FFFEF7';
                facetChartOptions.width = "75%";
                facetChartOptions[facetName] = {chartType: 'scatter'};


                //additional config
                facetChartOptions.cumulative = cumulative;
                facetChartOptions.outlierValues = outlierValues;    //retrieved from WS
                facetChartOptions.highlightedValue = valueForThisRecord;           //retrieved from the record

                //console.log('Start the drawing...' + chartName);
                facetChartGroup.loadAndDrawFacetCharts(facetChartOptions);
                //console.log('Finished the drawing...' + chartName);
            }
            google.load("visualization", "1", {packages:["corechart"]});
        </script>
    </head>
    <body>
        <spring:url var="json" value="/occurrences/${record.raw.uuid}.json" />
        <c:if test="${not empty record.raw}">
            <div id="headingBar" class="recordHeader">
                <h1><fmt:message key="show.occurrenceRecord"/>: <span id="recordId">${recordId}</span></h1>
                <c:if test="${skin != 'avh'}">
                    <div id="jsonLink">
                        <c:if test="${isCollectionAdmin}">
                            <c:set var="admin" value=" - admin"/>
                        </c:if>
                        <c:if test="${not empty userDisplayName}">
                            Logged in as: ${userDisplayName}
                        </c:if>
                        <c:if test="${not empty clubView}">
                            <div id="clubView">Showing &quot;Club View&quot;</div>
                        </c:if>
                        <!-- <a href="${json}">JSON</a> -->
                    </div>
                </c:if>
                <c:if test="${not empty lastSearchUri}">
                    <div id="backBtn" class="pull-right">
                        <a href="${lastSearchUri}" title="Return to search results" class="btn">Back to search results</a>
                    </div>
                </c:if>
                <c:if test="${not empty record.raw.classification}">
                    <h2 id="headingSciName">
                        <c:choose>
                            <c:when test="${not empty record.processed.classification.scientificName}">
                                <alatag:formatSciName rankId="${record.processed.classification.taxonRankID}" name="${record.processed.classification.scientificName}"/>
                                ${record.processed.classification.scientificNameAuthorship}
                            </c:when>
                            <c:when test="${not empty record.raw.classification.scientificName}">
                                <alatag:formatSciName rankId="${record.raw.classification.taxonRankID}" name="${record.raw.classification.scientificName}"/>
                                ${record.raw.classification.scientificNameAuthorship}
                            </c:when>
                            <c:otherwise>
                                <i>${record.raw.classification.genus} ${record.raw.classification.specificEpithet}</i>
                                ${record.raw.classification.scientificNameAuthorship}
                            </c:otherwise>
                        </c:choose>
                        <c:choose>
                            <c:when test="${not empty record.processed.classification.vernacularName}">
                                | ${record.processed.classification.vernacularName}
                            </c:when>
                            <c:when test="${not empty record.raw.classification.vernacularName}">
                                | ${record.raw.classification.vernacularName}
                            </c:when>
                        </c:choose>
                    </h2>
                </c:if>
            </div>
            <div class="row-fluid">
                <div id="SidebarBoxZ" class="span4">
                <c:if test="${not empty collectionLogo}">
                    <div class="sidebar">
                        <img src="${collectionLogo}" alt="institution logo" id="institutionLogo"/>
                    </div>
                </c:if>

                <c:if test="${record.processed.attribution.provenance != 'Draft'}">
                    <div class="sidebar">
                        <div id="warnings">

                            <div id="systemAssertionsContainer" <c:if test="${empty record.systemAssertions}">style="display:none"</c:if>>
                                <h3>Data quality tests</h3>

                                <ul id="systemAssertions">
                                    <li class="failedTestCount">
                                        <spring:message code="failed" text="failed"/>: ${fn:length(record.systemAssertions['failed'])}
                                    </li>
                                    <li class="warningsTestCount">
                                        <spring:message code="warnings" text="warnings"/>: ${fn:length(record.systemAssertions['warning'])}
                                    </li>
                                    <li class="passedTestCount">
                                        <spring:message code="passed" text="passed"/>: ${fn:length(record.systemAssertions['passed'])}
                                    </li>
                                    <li class="missingTestCount">
                                        <spring:message code="missing" text="missing"/>: ${fn:length(record.systemAssertions['missing'])}
                                    </li>
                                    <li class="uncheckedTestCount">
                                        <spring:message code="unchecked" text="unchecked"/>: ${fn:length(record.systemAssertions['unchecked'])}
                                    </li>

                                    <li id="dataQualityFurtherDetails">
                                        <i class="icon-hand-right"></i>&nbsp;
                                        <a id="dataQualityReportLink" href="#dataQualityReport">
                                            View full data quality report
                                        </a>
                                    </li>

                                    <c:set var="hasExpertDistribution" value="false"/>
                                    <c:forEach var="systemAssertion" items="${record.systemAssertions['failed']}">
                                        <c:if test="${systemAssertion.code == 26}">
                                            <c:set var="hasExpertDistribution" value="true"/>
                                        </c:if>
                                    </c:forEach>

                                    <c:if test="${hasExpertDistribution}">
                                       <li><i class="icon-hand-right"></i>&nbsp;
                                        <a id="expertRangeLink" href="#expertReport">
                                            Outside expert range - view details
                                        </a>
                                        </li>
                                    </c:if>

                                    <c:if test="${not empty record.processed.occurrence.outlierForLayers}">
                                       <li><i class="icon-hand-right"></i>&nbsp;
                                        <a id="outlierReportLink" href="#outlierReport">
                                            Environmental outlier - view details
                                        </a>
                                        </li>
                                    </c:if>
                                </ul>

                                <!--<p class="half-padding-bottom">Data validation tools identified the following possible issues:</p>-->
                                <c:set var="recordIsVerified" value="false"/>

                                <c:forEach items="${record.userAssertions}" var="userAssertion">
                                    <c:if test="${userAssertion.name == 'userVerified'}"><c:set var="recordIsVerified" value="true"/></c:if>
                                </c:forEach>
                            </div>

                            <div id="userAssertionsContainer" <c:if test="${empty record.userAssertions && empty queryAssertions}">style="display:none"</c:if>>
                                <h3>User flagged issues</h3>
                                <ul id="userAssertions">
                                    <!--<p class="half-padding-bottom">Users have highlighted the following possible issues:</p>-->
                                    <alatag:groupedAssertions groupedAssertions="${groupedAssertions}" />
                                </ul>
                                <div id="userAssertionsDetailsLink">
                                    <a id="showUserFlaggedIssues" href="#userAnnotations">
                                        View issue list & comments
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </c:if>
                <c:if test="${isCollectionAdmin && (not empty record.systemAssertions || not empty record.userAssertions) && not recordIsVerified}">
                    <div class="sidebar">
                        <button class="btn" id="verifyButton" href="#verifyRecord">
                            <span id="verifyRecordSpan" title="">Verify record</span>
                        </button>
                        <div style="display:none;">
                            <div id="verifyRecord">
                                <h3>Confirmation</h3>
                                <div id="verifyAsk">
                                    <p>
                                        Record is marked as <b>${record.processed.geospatiallyKosher ? "geospatially suspect" : ""} ${record.processed.taxonomicallyKosher ? "taxonomically suspect" : ""}</b>
                                    </p>
                                    <p style="margin-bottom:10px;">
                                        Click the &quot;Confirm&quot; button to verify that this record is correct and that
                                        the listed &quot;validation issues&quot; are incorrect/invalid.<br/>Please provide a
                                        short comment supporting your verification.
                                    </p>
                                    <textarea id="verifyComment" rows="3"></textarea><br/>
                                    <button class="btn confirmVerify">Confirm</button>
                                    <button class="btn cancelVerify">Cancel</button>
                                    <img src="${pageContext.request.contextPath}/static/images/loading.gif" id="verifySpinner" class="hide" alt="spinner icon"/>
                                </div>
                                <div id="verifyDone" style="display:none;">
                                    Record successfully verified
                                    <br/>
                                    <button class="btn closeVerify">Close</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </c:if>
                <c:if test="${not empty record.processed.attribution.provenance && record.processed.attribution.provenance == 'Draft'}">
                    <div class="sidebar">
                        <p class="grey-bg" style="padding:5px; margin-top:15px; margin-bottom:10px;">
                            This record was transcribed from the label by an online volunteer.
                            It has not yet been validated by the owner institution
                            <a href="http://volunteer.ala.org.au/">Biodiversity Volunteer Portal</a>.
                        </p>

                        <button class="btn" id="viewDraftButton" >
                            <span id="viewDraftSpan" title="View Draft">See draft in Biodiversity Volunteer Portal</span>
                        </button>
                    </div>
                </c:if>
                <c:if test="${!isReadOnly && record.processed.attribution.provenance != 'Draft'}">
                    <div class="sidebar">
                        <button class="btn" id="assertionButton" href="#loginOrFlag">
                            <span id="loginOrFlagSpan" title="Flag an issue" class=""><i class="icon-flag"></i> Flag an issue</span>
                        </button>
                        <div style="display:none">
                            <c:choose>
                                <c:when test="${empty userId}">
                                    <div id="loginOrFlag">
                                        Login please
                                        <a href="https://auth.ala.org.au/cas/login?service=${serverName}${pageContext.request.contextPath}/occurrences/${record.raw.uuid}">Click here</a>
                                    </div>
                                </c:when>
                                <c:otherwise>
                                    <div id="loginOrFlag">
                                        You are logged in as  <strong>${userDisplayName} (${userEmail})</strong>.
                                        <form id="issueForm">
                                            <p style="margin-top:20px;">
                                                <label for="issue">Issue type:</label>
                                                <select name="issue" id="issue">
                                                    <c:forEach items="${errorCodes}" var="code">
                                                        <option value="${code.code}"><spring:message code="${code.name}" text="${code.name}"/></option>
                                                    </c:forEach>
                                                </select>
                                            </p>
                                            <p style="margin-top:30px;">
                                                <label for="issueComment" style="vertical-align:top;">Comment:</label>
                                                <textarea name="comment" id="issueComment" style="width:380px;height:150px;" placeholder="Please add a comment here..."></textarea>
                                            </p>
                                            <p style="margin-top:20px;">
                                                <input id="issueFormSubmit" type="submit" value="Submit" class="btn" />
                                                <input type="reset" value="Cancel" class="btn" onClick="$.fancybox.close();"/>
                                                <input type="button" id="close" value="Close" class="btn" style="display:none;"/>
                                                <span id="submitSuccess"></span>
                                            </p>
                                            <p id="assertionSubmitProgress" style="display:none;">
                                                <img src="${serverName}${pageContext.request.contextPath}/static/images/indicator.gif"/>
                                            </p>

                                        </form>
                                    </div>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>
                </c:if>
                <div class="sidebar">
                    <button class="btn" id="showRawProcessed" href="#processedVsRawView" title="Table showing both original and processed record values">
                        <span id="processedVsRawViewSpan" href="#processedVsRawView" title=""><i class="icon-th"></i> Original vs Processed</span>
                    </button>
                </div>
                <c:if test="${not empty record.images}">
                    <div class="sidebar">
                        <h3>Images</h3>
                        <div id="occurrenceImages" style="margin-top:5px;">
                            <c:forEach items="${record.images}" var="image">
                                <a href="${image.alternativeFormats['largeImageUrl']}" target="_blank">
                                    <img src="${image.alternativeFormats['smallImageUrl']}" style="max-width: 100%;"/>
                                </a>
                                <br/>
                                <c:if test="${not empty record.raw.occurrence.photographer}">
                                    <cite>Photographer: ${record.raw.occurrence.photographer}</cite>
                                </c:if>
                                <c:if test="${not empty record.raw.occurrence.rights}">
                                    <cite>Rights: ${record.raw.occurrence.rights}</cite>
                                </c:if>
                                <c:if test="${not empty record.raw.occurrence.rightsholder}">
                                    <cite>Rights holder: ${record.raw.occurrence.rightsholder}</cite>
                                </c:if>
                                <a href="${image.alternativeFormats['imageUrl']}" target="_blank">Original image (${formattedImageSizes[image.alternativeFormats['imageUrl']]})</a>
                            </c:forEach>
                        </div>
                    </div>
                </c:if>
                <c:if test="${not empty record.processed.location.decimalLatitude && not empty record.processed.location.decimalLongitude}">
                    <c:set var="latLngStr">
                        <c:choose>
                            <c:when test="${not empty clubView && not empty record.raw.location.decimalLatitude && record.raw.location.decimalLatitude != record.processed.location.decimalLatitude}">
                                ${record.raw.location.decimalLatitude},${record.raw.location.decimalLongitude}
                            </c:when>
                            <c:otherwise>
                                ${record.processed.location.decimalLatitude},${record.processed.location.decimalLongitude}
                            </c:otherwise>
                        </c:choose>
                    </c:set>
                    <div class="sidebar">

                        <script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false"></script>
                        <script type="text/javascript">
                            $(document).ready(function() {
                                var latlng = new google.maps.LatLng(${latLngStr});
                                var myOptions = {
                                    zoom: 5,
                                    center: latlng,
                                    scrollwheel: false,
                                    scaleControl: true,
                                    streetViewControl: false,
                                    mapTypeControl: true,
                                    mapTypeControlOptions: {
                                        style: google.maps.MapTypeControlStyle.DROPDOWN_MENU,
                                        mapTypeIds: [google.maps.MapTypeId.ROADMAP, google.maps.MapTypeId.HYBRID, google.maps.MapTypeId.TERRAIN ]
                                    },
                                    mapTypeId: google.maps.MapTypeId.ROADMAP
                                };

                                var map = new google.maps.Map(document.getElementById("occurrenceMap"), myOptions);

                                var marker = new google.maps.Marker({
                                    position: latlng,
                                    map: map,
                                    title:"Occurrence Location"
                                });

                                <c:if test="${not empty record.processed.location.coordinateUncertaintyInMeters}">
                                var radius = parseInt('${record.processed.location.coordinateUncertaintyInMeters}');
                                if (!isNaN(radius)) {
                                    // Add a Circle overlay to the map.
                                    circle = new google.maps.Circle({
                                        map: map,
                                        radius: radius, // 3000 km
                                        strokeWeight: 1,
                                        strokeColor: 'white',
                                        strokeOpacity: 0.5,
                                        fillColor: '#2C48A6',
                                        fillOpacity: 0.2
                                    });
                                    // bind circle to marker
                                    circle.bindTo('center', marker, 'position');
                                }
                                </c:if>
                            });
                        </script>
                        <h3>Location of record</h3>
                        <div id="occurrenceMap"></div>
                    </div>
                </c:if>
                <c:if test="${not empty record.sounds}">
                    <div class="sidebar">
                        <h3 id="soundsHeader">Sounds</h3>
                        <div class="row-fluid">
                        <div id="audioWrapper" class="span12">
                            <audio src="${record.sounds[0].alternativeFormats['audio/mpeg']}" preload="auto" />
                            <div class="track-details">
                              ${record.raw.classification.scientificName}
                            </div>
                        </div>
                        </div>
                        <c:if test="${not empty record.raw.occurrence.rights}">
                            <br/>
                            <cite>Rights: ${record.raw.occurrence.rights}</cite>
                        </c:if>
                        <p>
                            Please press the play button to hear the sound file
                            associated with this occurrence record.
                        </p>
                    </div>
                </c:if>
                <c:if test="${not empty record.raw.lastModifiedTime && not empty record.processed.lastModifiedTime}">
                    <div class="sidebar" style="margin-top: 10px;font-size: 12px; color: #555;">
                        <c:catch var="parseError">
                            <fmt:parseDate var="rawLastModified" value="${record.raw.lastModifiedTime}" pattern="yyyy-MM-dd'T'HH:mm:ss'Z'"/>
                            <fmt:formatDate var="rawLastModifiedString" value="${rawLastModified}" pattern="yyyy-MM-dd"/>
                            <fmt:parseDate var="processedLastModified" value="${record.processed.lastModifiedTime}" pattern="yyyy-MM-dd'T'HH:mm:ss'Z'"/>
                            <fmt:formatDate var="processedLastModifiedString" value="${processedLastModified}" pattern="yyyy-MM-dd"/>
                        </c:catch>
                        <c:if test="${not empty parseError}">
                            <c:set var="rawLastModifiedString" value="${record.raw.lastModifiedTime}"/>
                            <c:set var="processedLastModifiedString" value="${record.processed.lastModifiedTime}"/>
                        </c:if>
                        <p style="margin-bottom:20px;">
                            Date loaded: ${rawLastModifiedString}<br/>
                            Date last processed: ${processedLastModifiedString}<br/>
                        </p>
                    </div>
                </c:if>
                </div><!-- end div#SidebarBox -->
                <div id="content2Z" class="span8">
                    <jsp:include page="recordCoreDiv.jsp"/>
                </div><!-- end of div#content2 -->
            </div>

            <c:if test="${hasExpertDistribution}">
                <div id="hasExpertDistribution"  class="additionalData" style="clear:both;padding-top: 20px;">
                    <h2>Record outside of expert distribution area (shown in red) <a id="expertReport" href="#expertReport">&nbsp;</a></h2>
                    <script type="text/javascript" src="${pageContext.request.contextPath}/static/js/wms2.js"></script>
                    <script type="text/javascript">
                        $(document).ready(function() {
                            var latlng1 = new google.maps.LatLng(${latLngStr});
                            var mapOptions = {
                                zoom: 4,
                                center: latlng1,
                                scrollwheel: false,
                                scaleControl: true,
                                streetViewControl: false,
                                mapTypeControl: true,
                                mapTypeControlOptions: {
                                    style: google.maps.MapTypeControlStyle.DROPDOWN_MENU,
                                    mapTypeIds: [google.maps.MapTypeId.ROADMAP, google.maps.MapTypeId.HYBRID, google.maps.MapTypeId.TERRAIN ]
                                },
                                mapTypeId: google.maps.MapTypeId.ROADMAP
                            };

                            var distroMap = new google.maps.Map(document.getElementById("expertDistroMap"), mapOptions);

                            var marker1 = new google.maps.Marker({
                                position: latlng1,
                                map: distroMap,
                                title:"Occurrence Location"
                            });

                            // Attempt to display expert distribution layer on map
                            var SpatialUrl = "${spatialPortalUrl}ws/distribution/lsid/${record.processed.classification.taxonConceptID}?callback=?";
                            $.getJSON(SpatialUrl, function(data) {

                                if (data.wmsurl) {
                                    var urlParts = data.wmsurl.split("?");

                                    if (urlParts.length == 2) {
                                        var baseUrl = urlParts[0] + "?";
                                        var paramParts = urlParts[1].split("&");
                                        loadWMS(distroMap, baseUrl, paramParts);
                                        // adjust bounds for both Aust (centre) and marker
                                        var AusCentre = new google.maps.LatLng(-27, 133);
                                        var dataBounds = new google.maps.LatLngBounds();
                                        dataBounds.extend(AusCentre);
                                        dataBounds.extend(latlng1);
                                        distroMap.fitBounds(dataBounds);
                                    }

                                }
                            });

                            <c:if test="${not empty record.processed.location.coordinateUncertaintyInMeters}">
                                var radius1 = parseInt('${record.processed.location.coordinateUncertaintyInMeters}');

                                if (!isNaN(radius)) {
                                    // Add a Circle overlay to the map.
                                    circle1 = new google.maps.Circle({
                                        map: distroMap,
                                        radius: radius1, // 3000 km
                                        strokeWeight: 1,
                                        strokeColor: 'white',
                                        strokeOpacity: 0.5,
                                        fillColor: '#2C48A6',
                                        fillOpacity: 0.2
                                    });
                                    // bind circle to marker
                                    circle1.bindTo('center', marker1, 'position');
                                }
                            </c:if>
                        });
                    </script>
                    <div id="expertDistroMap" style="width:80%;height:400px;margin:20px 20px 10px 0;"></div>
                </div>
            </c:if>

                <style type="text/css">
                    #outlierFeedback #inferredOccurrenceDetails { clear:both; margin-left:20px;margin-top:30px; width:100%; }
                        /*#outlierFeedback h3 {color: #718804; }*/
                    #outlierFeedback #outlierInformation #inferredOccurrenceDetails { margin-bottom:20px; }
                </style>

            <script type="text/javascript" src="${biocacheService}/outlier/record/${uuid}.json?callback=renderOutlierCharts"></script>

            <div id="userAnnotationsDiv" class="additionalData">
                <h2>User flagged issues<a id="userAnnotations">&nbsp;</a></h2>
                <ul id="userAnnotationsList"></ul>
            </div>

            <div id="dataQuality" class="additionalData"><a name="dataQualityReport"></a>
                <h2>Data quality tests</h2>
                <div id="dataQualityModal" class="modal hide fade" tabindex="-1" role="dialog">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal">×</button>
                        <h3>Data Quality Details</h3>
                    </div>
                    <div class="modal-body">
                        <p>loading...</p>
                    </div>
                    <div class="modal-footer">
                        <button class="btn" data-dismiss="modal">Close</button>
                    </div>
                </div>
                <table class="dataQualityResults table-striped table-bordered table-condensed">
                    <%--<caption>Details of tests that have been performed for this record.</caption>--%>
                    <thead>
                        <tr class="sectionName">
                            <td class="dataQualityTestName">Test name</td>
                            <td class="dataQualityTestResult">Result</td>
                            <%--<th class="dataQualityMoreInfo">More information</th>--%>
                        </tr>
                    </thead>
                    <tbody>
                        <c:set var="testSet" value="${record.systemAssertions['failed']}"/>
                        <c:forEach items="${testSet}" var="test">
                        <tr>
                            <td><spring:message code="${test.name}" text="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                            <td><i class="icon-thumbs-down icon-red"></i> Failed</td>
                            <%--<td>More info</td>--%>
                        </tr>
                        </c:forEach>

                        <c:set var="testSet" value="${record.systemAssertions['warning']}"/>
                        <c:forEach items="${testSet}" var="test">
                        <tr>
                            <td><spring:message code="${test.name}" text="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                            <td><i class="icon-warning-sign"></i> Warning</td>
                            <%--<td>More info</td>--%>
                        </tr>
                        </c:forEach>

                        <c:set var="testSet" value="${record.systemAssertions['passed']}"/>
                        <c:forEach items="${testSet}" var="test">
                        <tr>
                            <td><spring:message code="${test.name}" text="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                            <td><i class="icon-thumbs-up icon-green"></i> Passed</td>
                            <%--<td>More info</td>--%>
                        </tr>
                        </c:forEach>

                        <c:if test="${not empty record.systemAssertions['missing']}">
                            <tr>
                                <td colspan="2">
                                <a href="javascript:void(0)" id="showMissingPropResult">Show/Hide  ${fn:length(record.systemAssertions['missing'])} missing properties</a>
                                </td>
                            </tr>
                        </c:if>
                        <c:set var="testSet" value="${record.systemAssertions['missing']}"/>
                        <c:forEach items="${testSet}" var="test">
                        <tr class="missingPropResult" style="display:none;">
                            <td><spring:message code="${test.name}" text="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                            <td><i class=" icon-question-sign"></i> Missing</td>
                        </tr>
                        </c:forEach>

                        <c:if test="${not empty record.systemAssertions['unchecked']}">
                            <tr>
                                <td colspan="2">
                                <a href="javascript:void(0)" id="showUncheckedTests">Show/Hide  ${fn:length(record.systemAssertions['unchecked'])} tests that havent been ran</a>
                                </td>
                            </tr>
                        </c:if>
                        <c:set var="testSet" value="${record.systemAssertions['unchecked']}"/>
                        <c:forEach items="${testSet}" var="test">
                        <tr class="uncheckTestResult" style="display:none;">
                            <td><spring:message code="${test.name}" text="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                            <td>Unchecked (lack of data)</td>
                        </tr>
                        </c:forEach>

                    </tbody>
                </table>
            </div>

            <div id="outlierFeedback">
                <c:if test="${not empty record.processed.occurrence.outlierForLayers}">
                    <div id="outlierInformation" class="additionalData">
                        <h2>Outlier information <a id="outlierReport" href="#outlierReport">&nbsp;</a></h2>
                        <p>
                            This record has been detected as an outlier using the
                            <a href="http://code.google.com/p/ala-dataquality/wiki/DETECTED_OUTLIER_JACKKNIFE">Reverse Jackknife algorithm</a>
                            for the following layers:</p>
                        <ul>
                        <c:forEach items="${metadataForOutlierLayers}" var="layerMetadata">
                            <li>
                                <a href="http://spatial.ala.org.au/layers/more/${layerMetadata['name']}">${layerMetadata['displayname']} - ${layerMetadata['source']}</a><br/>
                                Notes: ${layerMetadata['notes']}<br/>
                                Scale: ${layerMetadata['scale']}
                            </li>
                        </c:forEach>
                        </ul>

                        <p style="margin-top:20px;">More information on the data quality work being undertaken by the Atlas is available here:
                            <ul>
                                <li><a href="http://code.google.com/p/ala-dataquality/wiki/DETECTED_OUTLIER_JACKKNIFE">http://code.google.com/p/ala-dataquality/wiki/DETECTED_OUTLIER_JACKKNIFE</a></li>
                                <li><a href="https://docs.google.com/open?id=0B7rqu1P0r1N0NGVhZmVhMjItZmZmOS00YmJjLWJjZGQtY2Y0ZjczZmUzZTZl">Notes on Methods for Detecting Spatial Outliers</a></li>
                            </ul>
                        </p>
                    </div>
                    <div id="charts" style="margin-top:20px;"></div>
                </c:if>

				<c:if test="${not empty record.processed.occurrence.duplicationStatus}">
					<div id="inferredOccurrenceDetails">
              		<a href="#inferredOccurrenceDetails" name="inferredOccurrenceDetails" id="inferredOccurrenceDetails" hidden="true"></a>
              		<h2>Inferred associated occurrence details</h2>
					<p style="margin-top:5px;">
					<c:choose>
						<c:when test="${record.processed.occurrence.duplicationStatus == 'R' }">
                            This record has been identified as the <em>representative</em> occurrence in a group of associated occurrences.
                            This mean other records have been detected that seem to relate to this record and this particular record has the most detailed
                            information on the occurrence.
						</c:when>
						<c:otherwise>This record is associated with the <em>representative</em> record.
                            This mean another record has been detected to be similar to this record, and that the other
                            record (the representative record) has the most detailed information for the occurrence.
						</c:otherwise>
					</c:choose>
					    More information about the duplication detection methods and terminology in use is available here:
						<ul>
							<li>
							<a href="http://code.google.com/p/ala-dataquality/wiki/INFERRED_DUPLICATE_RECORD">http://code.google.com/p/ala-dataquality/wiki/INFERRED_DUPLICATE_RECORD</a>
							</li>
						</ul>
					</p>
					<c:if test="${not empty duplicateRecordDetails}">
						<table class="duplicationTable table-striped table-bordered table-condensed" style="border-bottom:none;">
							<tr class="sectionName"><td colspan="4">Representative Record</td></tr>
							<alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Record UUID">
                            <a href="${pageContext.request.contextPath}/occurrences/${duplicateRecordDetails.uuid}">${duplicateRecordDetails.uuid}</a></alatag:occurrenceTableRow>
                            <alatag:occurrenceTableRow
        							annotate="false"
        							section="duplicate"
        							fieldName="Data Resource">
        					<c:set var="dr">${fn:substring(duplicateRecordDetails.rowKey,0,fn:indexOf(duplicateRecordDetails.rowKey,"|"))}</c:set>
        					<a href="${collectionsWebappContext}/public/show/${dr}">${dataResourceCodes[dr]}</a>
				 			</alatag:occurrenceTableRow>
                            <c:if test="${not empty duplicateRecordDetails.rawScientificName}">
			        		<alatag:occurrenceTableRow
	                				annotate="false"
	                				section="duplicate"
	                				fieldName="Raw Scientific Name">
	        					${duplicateRecordDetails.rawScientificName}</alatag:occurrenceTableRow>
		        			</c:if>
                            <alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Coordinates">
                            ${duplicateRecordDetails.latLong}</alatag:occurrenceTableRow>
                            <c:if test="${not empty duplicateRecordDetails.collector }">
                            	<alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Collector">
                            ${duplicateRecordDetails.collector}</alatag:occurrenceTableRow>
                            </c:if>
                            <c:if test="${not empty duplicateRecordDetails.year }">
                            	<alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Year">
                            ${duplicateRecordDetails.year}</alatag:occurrenceTableRow>
                            </c:if>
                            <c:if test="${not empty duplicateRecordDetails.month }">
                            	<alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Month">
                            ${duplicateRecordDetails.month}</alatag:occurrenceTableRow>
                            </c:if>
                            <c:if test="${not empty duplicateRecordDetails.day }">
                            	<alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Day">
                            ${duplicateRecordDetails.day}</alatag:occurrenceTableRow>
                            </c:if>
                            <!-- Loop through all the duplicate records -->
                            <tr class="sectionName"><td colspan="4">Related records</td></tr>
                            <c:forEach items="${duplicateRecordDetails.duplicates }" var="dup">
                            	<alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Record UUID">
                            <a href="${pageContext.request.contextPath}/occurrences/${dup.uuid}">${dup.uuid}</a></alatag:occurrenceTableRow>
                            <alatag:occurrenceTableRow
        							annotate="false"
        							section="duplicate"
        							fieldName="Data Resource">
        					<c:set var="dr">${fn:substring(dup.rowKey,0,fn:indexOf(dup.rowKey,"|"))}</c:set>
        					<a href="${collectionsWebappContext}/public/show/${dr}">${dataResourceCodes[dr]}</a>
				 			</alatag:occurrenceTableRow>
                            <c:if test="${not empty dup.rawScientificName}">
			        		<alatag:occurrenceTableRow
	                				annotate="false"
	                				section="duplicate"
	                				fieldName="Raw Scientific Name">
	        					${dup.rawScientificName}</alatag:occurrenceTableRow>
		        			</c:if>
                            <alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Coordinates">
                            ${dup.latLong}</alatag:occurrenceTableRow>
                             <c:if test="${not empty dup.collector }">
                            	<alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Collector">
                            ${dup.collector}</alatag:occurrenceTableRow>
                            </c:if>
                            <c:if test="${not empty dup.year }">
                            	<alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Year">
                            ${dup.year}</alatag:occurrenceTableRow>
                            </c:if>
                            <c:if test="${not empty dup.month }">
                            	<alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Month">
                            ${dup.month}</alatag:occurrenceTableRow>
                            </c:if>
                            <c:if test="${not empty dup.day }">
                            	<alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Day">
                            ${dup.day}</alatag:occurrenceTableRow>
                            </c:if>
                            <c:if test="${not empty dup.dupTypes }">
                            <alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Comments">
                            	<c:forEach items="${dup.dupTypes }" var="dupType">
                            		<fmt:message key="duplication.${dupType.id}"/>
                            		<br>
                            	</c:forEach>
                            	</alatag:occurrenceTableRow>
                            	<tr class="sectionName"><td colspan="4"></td></tr>
                            </c:if>
                            </c:forEach>
						</table>
					</c:if>
					</p>
				</c:if>
			</div>

                <div id="outlierInformation" class="additionalData">
                    <c:if test="${not empty contextualSampleInfo}">
                    <h3>Additional political boundaries information</h3>
                    <table class="layerIntersections table-striped table-bordered table-condensed">
                        <tbody>
                        <c:forEach items="${contextualSampleInfo}" var="sample" varStatus="vs">
                            <c:if test="${not empty sample.classification1 && (vs.first || (sample.classification1 != contextualSampleInfo[vs.index-1].classification1 && !vs.end))}">
                                <tr class="sectionName"><td colspan="2">${sample.classification1}</td></tr>
                            </c:if>
                            <alatag:occurrenceTableRow
                                    annotate="false"
                                    section="contextual"
                                    fieldCode="${sample.layerName}"
                                    fieldName="<a href=\"${spatialPortalUrl}layers/more/${sample.layerName}\" title=\"More information about this layer\">${sample.layerDisplayName}</a>">
                            ${sample.value}</alatag:occurrenceTableRow></c:forEach>
                        </tbody>
                    </table>
                    </c:if>

                    <c:if test="${not empty environmentalSampleInfo}">
                    <h3>Environmental sampling for this location</h3>
                    <table class="layerIntersections table-striped table-bordered table-condensed" >
                        <tbody>
                        <c:forEach items="${environmentalSampleInfo}" var="sample" varStatus="vs">
                            <c:if test="${not empty sample.classification1 && (vs.first || (sample.classification1 != environmentalSampleInfo[vs.index-1].classification1 && !vs.end))}">
                                <tr class="sectionName"><td colspan="2">${sample.classification1}</td></tr>
                            </c:if>
                            <alatag:occurrenceTableRow
                                    annotate="false"
                                    section="contextual"
                                    fieldCode="${sample.layerName}"
                                    fieldName="<a href=\"${spatialPortalUrl}layers/more/${sample.layerName}\" title=\"More information about this layer\">${sample.layerDisplayName}</a>">
                                ${sample.value} <c:if test="${not empty sample.units && !fn:containsIgnoreCase(sample.units,'dimensionless')}">${sample.units}</c:if>
                            </alatag:occurrenceTableRow>
                        </c:forEach>
                        </tbody>
                    </table>
                    </c:if>
                </div>
            </div>

            <div style="display:none;clear:both;">
                <div id="processedVsRawView">
                    <h2>&quot;Original versus Processed&quot; Comparison Table</h2>
                    <table>
                        <thead>
                            <tr>
                                <th style="width:15%;text-align:center;">Group</th>
                                <th style="width:15%;text-align:center;">Field Name</th>
                                <th style="width:35%;text-align:center;">Original</th>
                                <th style="width:35%;text-align:center;">Processed</th>
                            </tr>
                        </thead>
                        <tbody>
                            <alatag:formatRawVsProcessed map="${compareRecord}"/>
                        </tbody>
                    </table>
                </div>
            </div>
        </c:if>

        <ul style="display:none;">
        <li id="userAnnotationTemplate" class="userAnnotationTemplate">
           <h3><span class="issue"></span> - flagged by <span class="user"></span><span class="userRole"></span><span class="userEntity"></span></h3>
           <p class="comment"></p>
           <p class="hide userDisplayName"></p>
           <p class="created"></p>
           <p class="viewMore" style="display:none;">
               <a class="viewMoreLink" href="#">View more with this annotation</a>
           </p>
           <p class="deleteAnnotation" style="display:none;">
               <a class="deleteAnnotationButton btn" href="#">Delete this annotation</a>
           </p>
        </li>
        </ul>

        <c:if test="${empty record.raw}">
            <div id="headingBar">
                <h1>Record Not Found</h1>
                <p>The requested record ID "${uuid}" was not found</p>
            </div>
        </c:if>
        <c:if test="${not empty record.sounds}">
        <script>
          audiojs.events.ready(function() {
            var as = audiojs.createAll();
          });
        </script>
        </c:if>
    </body>
</html>
