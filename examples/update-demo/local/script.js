var base = "/api/v1/";

var updateImage = function($http, server) {
  $http.get(base + "proxy/namespaces/default/pods/" + server.podId + "/data.json")
    .success(function(data) {
      console.log('data: ', data);
      server.image = data.image;
    })
    .error(function(data) {
      console.log('update image error: ', data);
      server.image = "";
    });
};

var updateServer = function($http, server) {
  $http.get(base + "namespaces/default/pods/" + server.podId)
    .success(function(data) {
      console.log('pod: %s: %o', server.podId, data);
      server.labels = data.metadata.labels;
      server.host = data.status.hostIP.split('.')[0];
      server.hostIp = data.spec.nodeName;
      server.publicIp = data.status.podIP;
      server.status = data.status.phase;
      server.dockerImage = data.status.containerStatuses[0].image;
      updateImage($http, server);
    })
    .error(function(data) {
      console.log(data);
    });
};

var updateData = function($scope, $http) {
  var servers = $scope.servers;
  for (var i = 0; i < servers.length; ++i) {
    var server = servers[i];
    updateServer($http, server);
  }
};

var ButtonsCtrl = function ($scope, $http, $interval) {
  $scope.servers = [];
  update($scope, $http);
  $interval(angular.bind({}, update, $scope, $http), 2000);
};

var getServer = function($scope, id) {
  var servers = $scope.servers;
  for (var i = 0; i < servers.length; ++i) {
    if (servers[i].podId == id) {
      return servers[i];
    }
  }
  return null;
};

var isUpdateDemoPod = function(pod) {
    return pod.metadata && pod.metadata.labels && pod.metadata.labels.name == "update-demo";
};

var update = function($scope, $http) {
  if (!$http) {
    console.log("No HTTP!");
    return;
  }
  $http.get(base + "namespaces/default/pods")
    .success(function(data) {
      // console.log('data: ', data);
      var newServers = [];
      for (var i = 0; i < data.items.length; ++i) {
        var pod = data.items[i];
        if (!isUpdateDemoPod(pod)) {
          continue;
        }
        var server = getServer($scope, pod.metadata.name);
        if (server == null) {
          server = { "podId": pod.metadata.name };
        }
        newServers.push(server);
      }
      $scope.servers = newServers;
      updateData($scope, $http);
    })
    .error(function(data) {
      console.log("ERROR: " + data);
    })
};
