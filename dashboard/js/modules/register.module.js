config.controller('register', ['$scope', '$rootScope', 'dataService', '$timeout', '$interval', '$location', '$sce', '$routeParams', 'ngDialog', '$window', function($scope, $rootScope, dataService, $timeout, $interval, $location, $sce, $routeParams, ngDialog, $window) {
	var tmrStatus = null;
	$scope.loading = false;
	$scope.code = '';
	$scope.hasRegistered = dataService.listLocations().length > 0;

	// Local endpoint override: route dashboard API traffic to a local hub /
	// reverse proxy instead of the Hubitat cloud. Persisted in localStorage.
	$scope.showLocalEndpoint = false;
	$scope.localApiBase = getLocalApiBase();

	$scope.toggleLocalEndpoint = function() {
		$scope.showLocalEndpoint = !$scope.showLocalEndpoint;
	};

	$scope.saveLocalApiBase = function() {
		var v = ($scope.localApiBase || '').trim().replace(/\/+$/, '');
		if (v && !/^https?:\/\//i.test(v)) {
			$scope.setStatus('Local endpoint must start with http:// or https://');
			return;
		}
		try {
			if (v) {
				window.localStorage.setItem('webcore:localApiBase', v);
				$scope.setStatus('Local endpoint saved: ' + v);
			} else {
				window.localStorage.removeItem('webcore:localApiBase');
				$scope.setStatus('Local endpoint cleared; using the cloud endpoint.');
			}
			$scope.localApiBase = v;
		} catch (e) {
			$scope.setStatus('Unable to save the local endpoint setting.');
		}
	};

	// Direct instance login: connect straight to a Hubitat instance using its
	// webCoRE dashboard endpoint URL, bypassing the registration code (which
	// otherwise just fetches that same URL from api.webcore.co).
	$scope.showInstanceLogin = false;
	$scope.instanceUri = '';

	$scope.toggleInstanceLogin = function() {
		$scope.showInstanceLogin = !$scope.showInstanceLogin;
	};

	$scope.loginWithInstance = function() {
		var input = ($scope.instanceUri || '').trim();
		if (!input) {
			$scope.setStatus('Please paste your Hubitat instance URL.');
			return;
		}

		var uri = null;
		if (/^https?:\/\//i.test(input) && (input.indexOf('access_token=') >= 0)) {
			// A raw Hubitat endpoint URL (cloud or local). Use it directly,
			// ensuring the app path ends with a slash before the query string.
			var qi = input.indexOf('?');
			var query = qi >= 0 ? input.substr(qi) : '';
			var base = qi >= 0 ? input.substr(0, qi) : input;
			if (!/\/$/.test(base)) base += '/';
			uri = base + query;
		} else {
			// A dashboard init link (…/init/<token>) or a bare init token.
			// Decode it and let loadInstance normalize the endpoint.
			var initMatch = input.match(/\/init\/([^\s\/]+)\/?$/i);
			var token = initMatch ? initMatch[1] : input;
			try {
				uri = atou(decodeURIComponent(token).replace(/\s+/g, ''));
			} catch (e) {
				uri = null;
			}
			if (uri && (uri.indexOf('access_token') < 0)) uri = null;
		}

		if (!uri) {
			$scope.setStatus('That does not look like a valid instance URL. Paste the full endpoint URL including ?access_token=, or your dashboard init link.');
			return;
		}

		$scope.loading = true;
		app.initialInstanceUri = uri;
		$location.path('/');
	};

	$scope.init = function() {
	};

    $scope.setStatus = function(status) {
        if (tmrStatus) $timeout.cancel(tmrStatus);
        tmrStatus = null;
        $scope.status = status;
        if ($scope.status) {
            tmrStatus = $timeout(function() { $scope.setStatus(); }, 10000);
        }
    }

    $scope.$on('$destroy', function() {
		if (tmrStatus) $timeout.cancel(tmrStatus);
    });


	$scope.register = function() {
		$scope.loading = true;
		dataService.registerDashboard($scope.code).then(function(data) {
			if (data && (data.length >= 80) && (data.length <= 180)) {
				$location.path('/init/' + data);
			} else {
				$scope.setStatus("Sorry, the registration code you provided did not work...");
			}
			$scope.loading = false;
		});
    };



	$scope.cancel = function() {
		$location.path('/');
	};


    //init
	$scope.init();
	var userAgent = navigator.userAgent || navigator.vendor || window.opera;
	if( userAgent.match( /Android/i ) ) {
		$scope.android = true;
	}
	$scope.url = window.location.href;
	$scope.mobile = window.mobileCheck();
	$scope.tablet = (!$scope.mobile) && (window.mobileOrTabletCheck());
	$scope.formatTime = formatTime;
	$scope.utcToString = utcToString;
	
	// i dont understand why those 2 blocks were required here to
	// trigger an AngularJS 2-way binding to be updated ¯\_(ツ)_/¯
	$rootScope.$on('dataService.initialized', function(event){ 
		$scope.$apply();
	});	
	dataService.whenReady().then(function() {});
}]);
