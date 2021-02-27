package com.netflix.apireadcache.metrics

import com.fasterxml.jackson.databind.ObjectMapper
import com.netflix.apireadcache.ComponentTest
import com.netflix.apireadcache.client.ApiReadCache
import com.netflix.apireadcache.metrics.github.ProxiedGitHubClient
import com.spotify.github.v3.clients.RepositoryClient
import com.spotify.github.v3.repos.Repository
import org.springframework.beans.factory.annotation.Autowired
import spock.lang.Specification

import java.util.concurrent.CompletableFuture

@ComponentTest
class MetricsResourceSpec extends Specification implements MetricsTestingSupport {

    @Autowired
    ApiReadCache metricsCachingClient

    @Autowired
    RepositoryClient spotifyGitHubClient

    @Autowired
    ProxiedGitHubClient cachingGitHubClient

    @Autowired
    MetricsService metricsService

    @Autowired
    ObjectMapper githubObjectMapper;

    def "should call through to API when unhandled path requested"() {
        given:
        String unhandledPath = "/gists"
        Object fakeResult = '''
            {
              "url": "https://api.github.com/gists/bafa226fdfc58b078276bc741fff82ca"
            }
        '''

        when:
        Object actual = metricsCachingClient.getApiEndpoint(unhandledPath)

        then:
        1 * cachingGitHubClient.getUnhandledRoute(unhandledPath) >> fakeResult

        then:
        assert actual.toString().contains("bafa226fdfc58b078276bc741fff82ca")
    }

    def "should return a root node overview when requested"() {
        given:
        Object fakeResult = '''
            {
                "current_user_url": "https://api.github.com/user",
                "current_user_authorizations_html_url": "https://github.com/settings/connections/applications{/client_id}",
                "authorizations_url": "https://api.github.com/authorizations"
            }
        '''

        when:
        metricsService.refreshAllData()

        then:
        1 * cachingGitHubClient.getOverview() >> fakeResult

        when:
        Object actual = metricsCachingClient.getOverview()

        then:
        assert actual.toString().contains("https://api.github.com")
    }

    def "should return an organization overview when requested"() {
        given:
        Object fakeResult = '''
            {
                "login": "Netflix",
                "id": 913567,
                "email": "netflixoss@netflix.com",
                "type": "Organization"
            }
        '''

        when:
        metricsService.refreshAllData()

        then:
        1 * cachingGitHubClient.getOrganization("Netflix") >> fakeResult

        when:
        Object actual = metricsCachingClient.getOrganization("Netflix")

        then:
        assert actual.toString().contains("netflixoss@netflix.com")
    }

    def "should return a flat list of members when requested"() {
        given:
        Object fakeResult = '''
            [{
                "login": "person",
                "id": 42,
                "node_id": "fakeid"
            }]
        '''

        when:
        metricsService.refreshAllData()

        then:
        1 * cachingGitHubClient.getOrganizationMembers("Netflix") >> fakeResult

        when:
        Object actual = metricsCachingClient.getOrganizationMembers("Netflix")

        then:
        assert actual.toString().contains("fakeid")
    }

    def "should return a flat list of repos when requested"() {
        given:
        List<Repository> expectedList = buildRepositoryList(10)

        when:
        metricsService.refreshAllData()

        then:
        1 * spotifyGitHubClient.listOrganizationRepositories() >> CompletableFuture.completedFuture(expectedList)

        when:
        Object actualList = metricsCachingClient.getOrganizationRepos("Netflix")

        then:
        assert actualList == githubObjectMapper.readValue(githubObjectMapper.writeValueAsString(expectedList), Object)
    }

    def "should return a list of top N repositories by number of forks"() {
        given:
        int numberRepos = 5
        List<Repository> expectedList = buildRepositoryList(10)

        when:
        metricsService.refreshAllData()

        then:
        1 * spotifyGitHubClient.listOrganizationRepositories() >> CompletableFuture.completedFuture(expectedList)

        when:
        List<List<Object>> actualList = metricsCachingClient.getTopRepositoriesByForkCount(numberRepos)

        then:
        assert actualList.size() == numberRepos
    }

    def "should return an empty list if result is not available"() {
        given:
        int numberRepos = 5

        when:
        metricsService.refreshAllData()

        then:
        1 * spotifyGitHubClient.listOrganizationRepositories() >> { throw new InterruptedException() }

        when:
        List<List<Object>> actualList = metricsCachingClient.getTopRepositoriesByForkCount(numberRepos)

        then:
        assert actualList.isEmpty()
    }

    def "should return all of the repos if that number is less than number requested"() {
        given:
        int numberRepos = 5
        List<Repository> expectedList = buildRepositoryList(3)

        when:
        metricsService.refreshAllData()

        then:
        1 * spotifyGitHubClient.listOrganizationRepositories() >> CompletableFuture.completedFuture(expectedList)

        when:
        List<List<Object>> actualList = metricsCachingClient.getTopRepositoriesByForkCount(numberRepos)

        then:
        assert actualList.size() == 3
    }

    def "should return a list of top N repositories by last updated time"() {
        given:
        int numberRepos = 5
        List<Repository> expectedList = buildRepositoryList(10)

        when:
        metricsService.refreshAllData()

        then:
        1 * spotifyGitHubClient.listOrganizationRepositories() >> CompletableFuture.completedFuture(expectedList)

        when:
        List<List<Object>> actualList = metricsCachingClient.getTopRepositoriesByLastUpdated(numberRepos)

        then:
        assert actualList.size() == numberRepos
    }

    def "should return a list of top N repositories by number of open issues"() {
        given:
        int numberRepos = 5
        List<Repository> expectedList = buildRepositoryList(10)

        when:
        metricsService.refreshAllData()

        then:
        1 * spotifyGitHubClient.listOrganizationRepositories() >> CompletableFuture.completedFuture(expectedList)

        when:
        List<List<Object>> actualList = metricsCachingClient.getTopRepositoriesByOpenIssueCount(numberRepos)

        then:
        assert actualList.size() == numberRepos
    }

    def "should return a list of top N repositories by number of stars"() {
        given:
        int numberRepos = 5
        List<Repository> expectedList = buildRepositoryList(10)

        when:
        metricsService.refreshAllData()

        then:
        1 * spotifyGitHubClient.listOrganizationRepositories() >> CompletableFuture.completedFuture(expectedList)

        when:
        List<List<Object>> actualList = metricsCachingClient.getTopRepositoriesByStarCount(numberRepos)

        then:
        assert actualList.size() == numberRepos
    }

}