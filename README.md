# API Read Cache

A GitHub API read caching service for Netflix organization data. The API Read Cache service caches selected GitHub API
endpoints periodically to avoid overloading the GitHub API with requests. The service proxies all GitHub API endpoints
outside this set to GitHub.

## API Reference

### Caching APIs

The service collects metrics every 5 minutes from the GitHub API and provides cached metrics at the following URLs:

| Endpoint               | Description                                   |
| ---------------------- | --------------------------------------------- |
|`/`                     | Root node data for the github API             |
|`/orgs/Netflix`         | Overview of data for the Netflix organization |
|`/orgs/Netflix/repos`   | List of repositories for Netflix organization |
|`/orgs/Netflix/members` | List of members for Netflix organization      |

The service proxies all other paths directly to the GitHub API without caching values.

### Metric View Endpoints

The service provides a set of views for the latest repository metrics that can be accessed at the following URLs:

| Endpoint                  | Description                                    |
| ------------------------- | ---------------------------------------------- |
|`/view/top/N/forks`        | Top-N repos by number of forks                 |
|`/view/top/N/last_updated` | Top-N repos by updated time (most recent first)|
|`/view/top/N/open_issues ` | Top-N repos by number of open issues           |
`/view/top/N/stars`         | Top-N repos by number of stars                 |

### Healthcheck

The application will respond on `/healthcheck` with a 200 status when it is ready to receive requests.

## Building

This project is built using gradle 6. It was originally built using
the [Netflix/gradle-template](https://github.com/Netflix/gradle-template) project.

To execute a build, run the following command:

```
./gradlew build
```

To view all available gradle tasks, run the following command:

```
./gradlew tasks
```

## Running

To start the application locally:
Set the `GITHUB_API_TOKEN` environment variable containing your GitHub API token

```
export GITHUB_API_TOKEN=<your_token_here>
```

You can get a new Personal Access Token from your
[GitHub Developer Settings](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)
.

To start the application, run the following command, supplying the port on which you want to accept requests:

```
./gradlew bootRun --args='--server.port=<port_number>'
```

**Note**: To use the default 8080 port, leave off the args after `bootRun`

### Configuration Options

You can configure the following options by either passing them to the bootRun process or by setting them using the usage
format in the following table in the
`application.properties` file.

| Option                    | Description                                                                           | Usage                         |
| ------------------------- | ------------------------------------------------------------------------------------- | ----------------------------- |
| `github.api.url`          | The URL for the GitHub API. Default is https://api.github.com                         | `github.api.url=<api_url>`    |
| `port`                    | Configure the port used by the running application. Default is 8080                   | `server.port=<port_number>`   |
| `cache.refresh.frequency` | New metrics are collected at this frequency. In Duration format. Default is 5 minutes.| `cache.refresh.frequency=PT5M`|
| `cache.refresh.threads`   | The number of threads used to refresh the cache. Default is 2 threads.                | `cache.refresh.threads=2`     |

## Testing

Component tests are included that will execute tests against the running application.

To run all the tests, run the following command:

```
./gradlew check
```

Alternatively, to run the provided curl/jq specs, execute one of the following commands while running the application
locally.

```
sh ./api-suite.sh <port_number>
sh ./api-suite-fixed.sh <port_number> 
```

Note that these specs use static values that change over time and thus have unreliable results. The "fixed" results has
metrics recorded at the time of its creation.




