library streamy.labs.offline;

import 'dart:async';
import 'dart:collection';

import 'package:streamy/base.dart' show Entity; // Generated file.
import 'package:streamy/streamy.dart';

part 'src/offline_handler_impl.dart';

typedef Entity EntityResponseFactory();

/// A simple implementation of [RequestHandler] that stores preopulated
/// responses to a (unique) [HttpRequest].
///
/// Example usage:
///     var offlineHandler = new OfflineRequestHandler({
///       'foos': () => new FoosListResponse()
///     });
///
///     offlineHandler.populate(api.foos.list(), [
///       new Foo(),
///       new Foo()
///       new Foo()
///     ]);
abstract class OfflineRequestHandler extends RequestHandler {
  /// Create a new instance of [OfflineRequestHandler] that creates response
  /// objects automatically for entities defined in [factories]. For example:
  ///     new OfflineRequestHandler({
  ///       'foos': () => new FoosListResponse()
  ///     });
  factory OfflineRequestHandler(Map<String, EntityResponseFactory> factories) =>
      new _OfflineRequestHandlerImpl._withFactories(factories);

  /// Given a [request], populate responses with [entities].
  void populate(HttpRequest request, Iterable<Entity> entities);
}
