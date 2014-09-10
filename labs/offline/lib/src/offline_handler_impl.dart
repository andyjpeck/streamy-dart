part of streamy.labs.offline;

/// Default implementation of the offline [RequestHandler].
class _OfflineRequestHandlerImpl
    extends RequestHandler
    implements OfflineRequestHandler {
  /// If [url] has query parameters, we sort them by key name.
  static String _positionIndependentUrl(String url) {
    var uri = Uri.parse(url);
    if (uri.queryParameters.isEmpty) {
      return uri.path;
    } else {
      return uri.path + '?' +
          (uri.queryParameters.keys.toList(growable: false)..sort()).map((e) =>
              '$e=${uri.queryParameters[e]}')
                  .toList(growable: false).join('&');
    }
  }

  /// Return [request] serialized into a string key. As long as the path and
  /// query parameters remain constant (order is not important), then we will
  /// consider the request the same.
  static String _getKeyForRequest(HttpRequest request) =>
      '${request.httpMethod.toUpperCase()} '
      '${_positionIndependentUrl(request.path)}';

  /// Mapping of entity type to factory to construct that type.
  final Map<String, EntityResponseFactory> _entityFactoryMap;

  final bool _failWhenUndefined;

  /// Mapping of request path to a response to generate.
  ///
  /// TODO(matanl): This is too strict to be useful outside of mocking.
  /// Consider storing as 'entity': <List of entities>, and instead add the
  /// ability to filter a subset based on request parameters.
  final _responseMap = new HashMap<String, List<Entity>>;

  /// Creates a new handler with a mapping of factories.
  /// This mapping is required, because otherwise we will have no idea how to
  /// create the appropriate response object for a set of entities
  ///
  /// [failWhenUndefined]: If true, and a request is made for a list of entities
  /// that does not exist, an error will be thrown. If false, a blank list will
  /// be returned instead.
  ///
  /// TODO(matanl): Add schema parsing so this can be generated/automated.
  _OfflineRequestHandlerImpl._withFactories(this._entityFactoryMap,
      {bool failWhenUndefined})
          : this._failWhenUndefined = failWhenUndefined {
    assert(_entityFactoryMap != null);
  }

  @override
  Stream<Response> handle(HttpRequest request, Trace trace) {
    final entity = request.pathParameters[0];
    final factory = _entityFactoryMap[entity];

    // If we don't have a factory function defined, throw a 500.
    if (factory == null) {
      throw new StreamyRpcException(500, request,
          {'message': 'Could not find factory for $factory.'});
    }

    var key = _getKeyForRequest(request);
    List<Entity> entities = _responseMap[key];

    // If we don't have any entities set, and [_failWhenUndefined] is set, then
    // we will return a 404. Otherwise, we will pretend there are just no
    // elements and silenty fail with a blank list.
    if (entities == null) {
      if (_failWhenUndefined) {
        throw new StreamyRpcException(404, request,
            {'message': 'No elements found for request.'});
      } else {
        entities = const [];
      }
    }

    var responsePayload = factory()..['items'] = entities;

    return new Stream<Response>.fromIterable([new Response(responsePayload,
        Source.RPC, new DateTime.now().millisecondsSinceEpoch)]);
  }

  @override
  void populate(HttpRequest request, Iterable<Entity> entities) {
    _responseMap[_getKeyForRequest(request)] = entities.toList(growable: false);
  }
}
