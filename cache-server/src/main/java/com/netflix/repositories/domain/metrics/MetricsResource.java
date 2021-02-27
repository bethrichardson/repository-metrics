package com.netflix.repositories.domain.metrics;

import com.netflix.repositories.client.ResourcePaths;
import com.netflix.repositories.common.MetricTuple;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.stream.Collectors;

import static org.springframework.http.MediaType.APPLICATION_JSON_VALUE;

@Slf4j
@RestController
@SuppressWarnings("PMD.BeanMembersShouldSerialize")
@RequestMapping(path = "/", produces = APPLICATION_JSON_VALUE)
public class MetricsResource {

    @Autowired
    private MetricsService metricsService;


    @GetMapping
    public Object overview() {
        return metricsService.getOverview();
    }

    /**
     * Only returns data for Netflix repositories.
     */
    @GetMapping(path = ResourcePaths.ORGS + "/Netflix")
    public Object organization() {
        return metricsService.getOrganization();
    }

    /**
     * Only returns data for Netflix repositories.
     */
    @SneakyThrows
    @GetMapping(path = ResourcePaths.ORGS + "/Netflix" + ResourcePaths.REPOS)
    public Object repositories() {
        return metricsService.getRepositoriesAsJsonString();
    }

    /**
     * Only returns data for Netflix repositories.
     */
    @GetMapping(path = ResourcePaths.ORGS + "/Netflix" + ResourcePaths.MEMBERS)
    public Object members() {
        return metricsService.getMembers();
    }

    @GetMapping(ResourcePaths.VIEW + "/{numRepositories}" + ResourcePaths.FORKS)
    public List<List<Object>> forks(@PathVariable("numRepositories") Integer numRepositories) {
        return metricsService.getMetricsByForkCount(numRepositories)
                .stream()
                .map(MetricTuple::getAsTuple)
                .collect(Collectors.toList());
    }

    @GetMapping(ResourcePaths.VIEW + "/{numRepositories}" + ResourcePaths.LAST_UPDATED)
    public List<List<Object>> lastUpdated(@PathVariable("numRepositories") Integer numRepositories) {
        return metricsService.getMetricsByLastUpdated(numRepositories)
                .stream()
                .map(MetricTuple::getAsTuple)
                .collect(Collectors.toList());
    }

    @GetMapping(ResourcePaths.VIEW + "/{numRepositories}" + ResourcePaths.OPEN_ISSUES)
    public List<List<Object>> openIssues(@PathVariable("numRepositories") Integer numRepositories) {
        return metricsService.getMetricsByOpenIssues(numRepositories)
                .stream()
                .map(MetricTuple::getAsTuple)
                .collect(Collectors.toList());
    }

    @RequestMapping(value="**",method = RequestMethod.GET)
    public Object proxyOtherRequests(final HttpServletRequest request){
        String path = request.getRequestURI();
        return metricsService.getProxiedResponse(path);
    }

}