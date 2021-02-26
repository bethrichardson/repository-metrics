package com.netflix.repositories

import com.netflix.repositories.client.RepositoryMetricsClient
import com.netflix.repositories.common.RepositoryMetric
import com.spotify.github.v3.clients.GitHubClient
import com.spotify.github.v3.clients.RepositoryClient
import com.spotify.github.v3.repos.Repository
import org.springframework.beans.factory.annotation.Autowired
import spock.lang.Specification

import java.util.concurrent.CompletableFuture

@ComponentTest
class RepositoryMetricsSpec extends Specification  {

    @Autowired
    RepositoryMetricsClient repositoryMetricsClient

    @Autowired
    RepositoryClient gitHubClient

    def "should call out to get a list of Netflix repos"() {
        given:
        int numberRepos = 5
        List<Repository> expectedList = []
        10.times {
            Repository repository = Mock(Repository)
            repository.forksCount() >> it
            expectedList.add(repository)
        }

        when:
        List<RepositoryMetric> actualList = repositoryMetricsClient.getTopRepositoriesByForks(numberRepos)

        then:
        1 * gitHubClient.listOrganizationRepositories() >> CompletableFuture.completedFuture(expectedList)
        assert actualList.size() == numberRepos
    }

    def "should return an empty list if result is not available"() {
        given:
        int numberRepos = 5

        when:
        List<RepositoryMetric> actualList = repositoryMetricsClient.getTopRepositoriesByForks(numberRepos)

        then:
        1 * gitHubClient.listOrganizationRepositories() >> { throw new InterruptedException() }
        assert actualList.isEmpty()
    }

}