<%--
  - Copyright (C) 2014 Atlas of Living Australia
  - All Rights Reserved.
  -
  - The contents of this file are subject to the Mozilla Public
  - License Version 1.1 (the "License"); you may not use this file
  - except in compliance with the License. You may obtain a copy of
  - the License at http://www.mozilla.org/MPL/
  -
  - Software distributed under the License is distributed on an "AS
  - IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  - implied. See the License for the specific language governing
  - rights and limitations under the License.
--%>
<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 4/03/2014
  Time: 4:39 PM
--%>
<%@ page contentType="text/html;charset=UTF-8" %>
<g:set var="biocacheServiceUrl" value="${grailsApplication.config.biocacheServicesUrl}"/>
<g:set var="queryContext" value="${grailsApplication.config.biocacheRestService.queryContext}"/>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${grailsApplication.config.ala.skin}"/>
    <meta name="section" content="yourArea"/>
    <title>Explore Your Area | Atlas of Living Australia</title>
    <script type="text/javascript" src="https://www.google.com/jsapi?key=${grailsApplication.config.googleKey}"></script>
    <r:require modules="exploreYourArea, qtip"/>
    <script type="text/javascript">
        // Global variables for yourAreaMap.js
        var EYA_CONF = {
            contextPath: "${request.contextPath}",
            imagesUrlPrefix: "${r.resource(dir:'images',file:'', plugin:'biocache-hubs').replaceFirst(/\?.*$/, '')}",
            biocacheServiceUrl: "${biocacheServiceUrl.encodeAsHTML()?:''}",
            zoom: ${zoom},
            radius: ${radius},
            speciesPageUrl: "${speciesPageUrl}",
            queryContext: "${queryContext}"
        }

        //make the taxa and rank global variable so that they can be used in the download
        var taxa = ["*"], rank = "*";
    </script>
</head>
<body class="nav-locations">
<div id="header">
    <g:if test="${grailsApplication.config.ala.skin == 'ala'}">
        <div id="breadcrumb">
            <ol class="breadcrumb">
                <li><a href="${grailsApplication.config.ala.baseURL}">Home</a> <span class=" icon icon-arrow-right"></span></li>
                <li><a href="${grailsApplication.config.ala.baseURL}/species-by-location/">Locations</a> <span class=" icon icon-arrow-right"></span></li>
                <li class="active">Your Area</li>
            </ol>
        </div>
    </g:if>
    <h1>Explore Your Area</h1>
</div>
<form name="searchForm" id="searchForm" class="" action="" method="GET">
    <div class="control-group">
        <label class="control-label" for="address"><h4>Enter your location or address:</h4></label>
        <div class="controls row-fluid">
            <div class="input-append span5">
                <input type="text" name="address" id="address" class="span10X">
                <input type="hidden" name="latitude" id="latitude" value="${latitude}"/>
                <input type="hidden" name="longitude" id="longitude" value="${longitude}"/>
                <input type="hidden" name="location" id="location" value="${location}"/>
                <input id="locationSearch" type="submit" class="btn" value="Search"/>
            </div>
            <div class="span7 help-inline">E.g. a street address, place name, postcode or GPS coordinates (as lat, long)</div>
        </div>
    </div>
    <div id="locationInfo" class="span12 row-fluid ">
        <g:if test="${true || location}">
            <div id="resultsInfo">
                Showing records for: <span id="markerAddress">${location}</span>&nbsp;&nbsp<a href="#" id="addressHelp" style="text-decoration: none"><span class="help-container">&nbsp;</span></a>
            </div>
        </g:if>
        <div class="row-fluid">
            <span class="pad">
                Display records in a
                <select id="radius" name="radius" class="" style="height:24px;width:auto;line-height:18px;margin-bottom:0;">
                    <option value="1" <g:if test="${radius == 1}">selected</g:if>>1</option>
                    <option value="5" <g:if test="${radius == 5}">selected</g:if>>5</option>
                    <option value="10" <g:if test="${radius == 10}">selected</g:if>>10</option>
                </select> km radius
            </span>
            <span class="pad">
                <a href="#" id="viewAllRecords" class="btn btn-small"><i class="icon-list"></i>&nbsp;&nbsp;View
                    <span id="recordsGroupText">all</span>  records</a>
            </span>
            <span class="pad">
                <a href="#download" role="button" data-toggle="modal" class="btn btn-small tooltips" title="Download all records OR species checklist">
                    <i class="icon-download"></i> Downloads</a>
            </span>
        </div>
        <div id="dialog-confirm" title="Continue with download?" style="display: none">
            <p><span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>You are about to
            download a list of species found within a <span id="rad"></span> km radius of <code>${location}</code>.<br/>
                Format: tab-delimited text file (called data.xls)</p>
        </div>
    </div>
</form>
<div class="row-fluid">
    <div class="span7">
        <div id="taxaBox">
            <div id="leftList">
                <table id="taxa-level-0">
                    <thead>
                    <tr>
                        <th>Group</th>
                        <th>Species</th>
                    </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>
            <div id="rightList" class="tableContainer">
                <table>
                    <thead class="fixedHeader">
                    <tr>
                        <th class="speciesIndex">&nbsp;&nbsp;</th>
                        <th class="sciName"><a href="0" id="speciesSort" data-sort="taxa" title="sort by taxa">Species</a>
                            <span id="sortSeparator">:</span>
                            <a href="0" id="commonSort" data-sort="common" title="sort by common name">Common Name</a></th>
                        <th class="rightCounts"><a href="0" data-sort="count" title="sort by record count">Records</a></th>
                    </tr>
                    </thead>
                    <tbody class="scrollContent">
                    </tbody>
                </table>
            </div>
        </div>
    </div><!-- .span7 -->
    <div class="span5">
        <div id="mapCanvas" style="width: 100%; height: 490px;"></div>
        <div style="font-size:11px;width:100%;color:black;height:20px;" class="show-80">
            <table id="cellCountsLegend">
                <tr>
                    <td style="background-color:#000; color:white; text-align:right;">Records:&nbsp;</td>
                    <td style="background-color:#ffff00;">1&ndash;9</td>
                    <td style="background-color:#ffcc00;">10&ndash;49</td>
                    <td style="background-color:#ff9900;">50&ndash;99</td>
                    <td style="background-color:#ff6600;">100&ndash;249</td>
                    <td style="background-color:#ff3300;">250&ndash;499</td>
                    <td style="background-color:#cc0000;">500+</td>
                </tr>
            </table>
        </div>
        <div id="mapTips">
            <b>Tip</b>: you can fine-tune the location of the area by dragging the red marker icon
        </div>
    </div><!-- .span5 -->
</div><!-- .row-fluid -->

<g:render template="download"/>

</body>
</html>