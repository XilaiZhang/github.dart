part of github.client;

/**
 * The Repository Model
 */
class Repository {
  final GitHub github;

  String name;
  int id;

  @ApiName("full_name")
  String fullName;
  RepositoryOwner owner;
  bool private;
  bool fork;
  String url;
  String description;
  
  @ApiName("clone_urls")
  CloneUrls cloneUrls;
  String homepage;
  int size;

  @ApiName("stargazers_count")
  int stargazersCount;

  @ApiName("watchers_count")
  int watchersCount;

  String language;

  @ApiName("has_issues")
  bool hasIssues;

  @ApiName("has_wiki")
  bool hasWiki;

  @ApiName("has_downloads")
  bool hasDownloads;

  @ApiName("forks_count")
  int forksCount;

  @ApiName("open_issues_count")
  int openIssuesCount;

  String defaultBranch;

  @ApiName("subscribers_count")
  int subscribersCount;

  @ApiName("network_count")
  int networkCount;

  @ApiName("created_at")
  DateTime createdAt;

  @ApiName("pushed_at")
  DateTime pushedAt;

  Map<String, dynamic> json;

  Repository(this.github);

  static Repository fromJSON(GitHub github, input) {
    if (input == null) return null;
    return new Repository(github)
        ..name = input['name']
        ..id = input['id']
        ..fullName = input['full_name']
        ..fork = input['fork']
        ..url = input['html_url']
        ..description = input['description']
        ..cloneUrls = new CloneUrls()
        ..cloneUrls.git = input['git_url']
        ..cloneUrls.ssh = input['ssh_url']
        ..cloneUrls.https = input['clone_url']
        ..cloneUrls.svn = input['svn_url']
        ..homepage = input['homepage']
        ..size = input['size']
        ..stargazersCount = input['stargazers_count']
        ..watchersCount = input['watchers_count']
        ..language = input['language']
        ..hasIssues = input['has_issues']
        ..hasDownloads = input['has_downloads']
        ..hasWiki = input['has_wiki']
        ..defaultBranch = input['default_branch']
        ..openIssuesCount = input['open_issues_count']
        ..networkCount = input['network_count']
        ..subscribersCount = input['subscribers_count']
        ..forksCount = input['forks_count']
        ..createdAt = parse_date(input['created_at'])
        ..pushedAt = parse_date(input['pushed_at'])
        ..private = input['private']
        ..json = input
        ..owner = RepositoryOwner.fromJSON(input['owner']);
  }

  RepositorySlug get slug => new RepositorySlug(owner.login, name);

  Future<List<Issue>> issues({int limit: 30}) => github.getJSON("/repos/${fullName}/issues", statusCode: 200, params: {
    "per_page": limit
  }).then((json) {
    return json.map((it) => Issue.fromJSON(github, it));
  });

  Future<List<Commit>> get commits => github.getJSON("/repos/${fullName}/commits", convert: (github, it) => it.map((i) => Commit.fromJSON(github, i)));

  Future<List<ContributorStatistics>> contributorStatistics({int limit: 30}) {
    var completer = new Completer<List<ContributorStatistics>>();
    var path = "/repos/${fullName}/stats/contributors";
    var handle;
    handle = (GitHub gh, json) {
      if (json is Map) {
        new Future.delayed(new Duration(milliseconds: 200), () {
          github.getJSON(path, statusCode: 200, convert: handle, params: {
            "per_page": limit
          });
        });
        return null;
      } else {
        completer.complete(json.map((it) => ContributorStatistics.fromJSON(github, it)));
      }
    };
    github.getJSON(path, convert: handle, params: {
      "per_page": limit
    });
    return completer.future;
  }

  Future<List<Repository>> forks({int limit: 30}) {
    return github.getJSON("/repos/${fullName}/forks", statusCode: 200, params: {
      "per_page": limit
    }).then((forks) {
      return copyOf(forks.map((it) => Repository.fromJSON(github, it)));
    });
  }

  Future<List<PullRequest>> pullRequests({int limit: 30}) {
    return github.getJSON("/repos/${fullName}/pulls", statusCode: 200, params: {
      "per_page": limit
    }).then((List<Map> pulls) {
      return copyOf(pulls.map((it) => PullRequest.fromJSON(github, it)));
    });
  }

  Future<RepositoryPages> pages() {
    return github.getJSON("/repos/${fullName}/pages", statusCode: 200, convert: RepositoryPages.fromJSON);
  }

  Future<List<Hook>> hooks({int limit: 30}) {
    return github.getJSON("/repos/${fullName}/hooks", statusCode: 200, params: {
      "per_page": limit
    }).then((hooks) {
      return copyOf(hooks.map((it) => Hook.fromJSON(github, fullName, it)));
    });
  }

  Future<List<Release>> releases({int limit}) => github.releases(slug, limit: limit);

  Future<Release> release(int id) => github.release(slug, id);

  Future<Hook> hook(int id) =>
    github.getJSON("/repos/${fullName}/hooks/${id}", convert: (g, i) => Hook.fromJSON(g, fullName, i));

  Future<Hook> createHook(CreateHookRequest request) {
    return github.postJSON("/repos/${fullName}/hooks", convert: (g, i) => Hook.fromJSON(g, fullName, i), body: request.toJSON());
  }

  Future<Hook> createRelease(CreateReleaseRequest request) {
    return github.postJSON("/repos/${fullName}/releases", convert: Release.fromJSON, body: request.toJSON());
  }

  Future<PullRequest> createPullRequest(CreateReleaseRequest request) {
    return github.postJSON("/repos/${fullName}/pulls", convert: PullRequest.fromJSON, body: request.toJSON());
  }
}

class CloneUrls {
  String git;
  String ssh;
  String https;
  String svn;
}

class RepositoryOwner {
  String login;
  int id;

  @ApiName("avatar_url")
  String avatarUrl;

  @ApiName("html_url")
  String url;

  static RepositoryOwner fromJSON(input) {
    if (input == null) return null;
    var owner = new RepositoryOwner();
    owner
        ..login = input['login']
        ..id = input['id']
        ..avatarUrl = input['avatar_url']
        ..url = input['html_url'];
    return owner;
  }
}

class RepositorySlug {
  final String owner;
  final String name;

  RepositorySlug(this.owner, this.name);

  String get fullName => "${owner}/${name}";

  bool operator ==(Object obj) => obj is RepositorySlug && obj.fullName == fullName;
}

class CreateRepositoryRequest {
  final String name;
  String description;
  String homepage;
  bool private = false;

  @ApiName("has_issues")
  bool hasIssues = true;

  @ApiName("has_wiki")
  bool hasWiki = true;

  @ApiName("has_downloads")
  bool hasDownloads = true;

  @OnlyWhen("Creating a repository for an organization")
  @ApiName("team_id")
  int teamID;

  @ApiName("auto_init")
  bool autoInit = false;

  @OnlyWhen("autoInit is true")
  String gitignoreTemplate;

  @OnlyWhen("autoInit is true")
  String licenseTemplate;

  CreateRepositoryRequest(this.name);

  String toJSON() {
    return JSON.encode({
      "name": name,
      "description": description,
      "homepage": homepage,
      "private": private,
      "has_issues": hasIssues,
      "has_wiki": hasWiki,
      "has_downloads": hasDownloads,
      "team_id": teamID,
      "auto_init": autoInit,
      "gitignore_template": gitignoreTemplate,
      "license_template": licenseTemplate
    });
  }
}

class LanguageBreakdown {
  final Map<String, int> _data;
  
  LanguageBreakdown(Map<String, int> data) : _data = data;
  
  String get primary {
    var list = mapToList(_data);
    list.sort((a, b) {
      return a.value.compareTo(b.value);
    });
    return list.first.key;
  }
  
  List<String> get names => _data.keys.toList()..sort();
  
  Map<String, int> get info => _data;
  
  List<List<dynamic>> toList() {
    var out = [];
    for (var key in info.keys) {
      out.add([key, info[key]]);
    }
    return out;
  }
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    _data.forEach((key, value) {
      buffer.writeln("${key}: ${value}");
    });
    return buffer.toString();
  }
}