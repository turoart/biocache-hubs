/* *************************************************************************
 *  Copyright (C) 2011 Atlas of Living Australia
 *  All Rights Reserved.
 * 
 *  The contents of this file are subject to the Mozilla Public
 *  License Version 1.1 (the "License"); you may not use this file
 *  except in compliance with the License. You may obtain a copy of
 *  the License at http://www.mozilla.org/MPL/
 * 
 *  Software distributed under the License is distributed on an "AS
 *  IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 *  implied. See the License for the specific language governing
 *  rights and limitations under the License.
 ***************************************************************************/

package org.ala.hubs.service;

import au.org.ala.biocache.ErrorCode;
import au.org.ala.biocache.QualityAssertion;
import org.ala.biocache.dto.SearchRequestParams;
import org.ala.biocache.dto.SearchResultDTO;
import org.ala.biocache.dto.store.OccurrenceDTO;
import org.springframework.web.bind.annotation.PathVariable;

import javax.servlet.http.HttpServletResponse;
import java.util.List;
import java.util.Map;

/**
 * Service layer for accessing Biocache data
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
public interface BiocacheService {

    public SearchResultDTO findByFulltextQuery(SearchRequestParams requestParams);

    public SearchResultDTO findByTaxonConcept(String guid, SearchRequestParams requestParams);

    public OccurrenceDTO getRecordByUuid(String uuid);

    public List<ErrorCode> getErrorCodes();

    public List<ErrorCode> getUserCodes();

    public List<ErrorCode> getGeospatialCodes();

    public List<ErrorCode> getTaxonomicCodes();

    public List<ErrorCode> getTemporalCodes();

    public List<ErrorCode> getMiscellaneousCodes();

    public boolean addAssertion(String recordUuid, String code, String comment, String userId, String userDisplayName);

    public boolean deleteAssertion(String uuid, String assertionUuid);

    public List<QualityAssertion> getUserAssertions(String recordUuid);
}