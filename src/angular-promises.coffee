###
angular-promises v0.2.0
Released under the MIT License
By Ian McNally (ia-n.com)
###

$q = null
$timeout = null

makeApplyCallback = (action, self) ->
  ->
    callbacks = self["__#{action}Callbacks__"].slice()
    self["__#{action}Callbacks__"] = []
    for callback in callbacks
      callback.apply(null, arguments)

class Promise

  # Promise is a wrapper for $q.defer().promise
  # that provides a similar promise interface
  # to jQuery.Deferred().promise,
  # with the added benefit of performing
  # a $scope.$apply on all promise callbacks,
  # to keep them in the angular event loop.
  #
  # Note: like jQuery but unlike $q, more than one
  # callback can be registered on `done`, `fail` and `always`.

  # Arguments:
  #  promise - $q.defer().promise to be wrapped (required)

  constructor : (@__promise__) ->
    @__doneCallbacks__ = []
    @__failCallbacks__ = []
    @__alwaysCallbacks__ = []
    @__progressCallbacks__ = []
    @__promise__.then(
      makeApplyCallback('done', this),
      makeApplyCallback('fail', this),
      makeApplyCallback('progress', this))
    @__promise__.finally makeApplyCallback('always', this)
    this

  # Add handler to be called when Deferred object is resolved
  done : (callback) =>
    @__doneCallbacks__.push callback
    this

  # Add handler to be called when Deferred object is reject
  fail : (callback) =>
    @__failCallbacks__.push callback
    this

  # Add handler to be called when Deferred object is resolved or reject
  always : (callback) =>
    @__alwaysCallbacks__.push callback
    this

  # Add handler to be called when Deferred object sends a notification
  progress : (callback) =>
    @__progressCallbacks__.push callback
    this

  # Return the unwrapped $.defer().promise
  # Note: it is useful for compatibility with other $q methods, like `all`
  getRawPromise : =>
    @__promise__

class QNotDefinedError extends Error

  constructor : ->
    @name = 'QNotDefinedError'
    @message = '$q must injected. Did you instantiate Deferred with `new`?'

class TimeoutNotDefinedError extends Error

  constructor : ->
    @name = 'TimeoutNotDefinedError'
    @message = '$timeout must injected. Did you instantiate Deferred with `new`?'

performDeferredAction = (action, calledArguments) ->
  $timeout (=> @__deferred__[action].apply(this, calledArguments)), 0

class Deferred

  ###
  Deferred is a wrapper for $q.defer()
  that allows for chaining, ala jQuery.Deferred()
  as well as a similar promise interface,
  with the added benefit of performing
  a $scope.$apply on all promise callbacks,
  to keep them in the angular event loop.

  Additionally, Deferred provides two instances methods,
  `all` and `until`, that wrap an array of Deferred promise objects
  and returns a single promise that is fulfilled when all
  the input objects are fulfilled.
  ###

  constructor : ->
    # $q and $timeout must be injected before creating an instance
    throw new QNotDefinedError unless $q
    throw new TimeoutNotDefinedError unless $timeout
    @__deferred__ = $q.defer()
    @__promise__ = new Promise @__deferred__.promise
    this

  ###
  Resolve the Deferred object and call its handler
  ###
  resolve : =>
    performDeferredAction.call(this, 'resolve', arguments)
    this

  ###
  Reject the Deferred object and call its handler
  ###
  reject : =>
    performDeferredAction.call(this, 'reject', arguments)
    this

  ###
  Call the progress callback on a Deferred object
  ###
  notify : =>
    performDeferredAction.call(this, 'notify', arguments)
    this

  ###
  Return the Deferred promise object
  ###
  promise : =>
    @__promise__

  ###
  Returns a single promise, which is fulfilled when all `promises`
  are resolved or rejected.

  Note: this is unlike Deferred.until (or $q.all) which rejects immediately
    on a rejected promise.

  Params: Array of promises (Deferred().promise() instances)

  Returns: promise
  ###
  @all : (promises) ->
    deferred = new Deferred()
    fulfillments = resolved : [], rejected : []
    amtPromises = promises.length
    for promise in promises
      throw new InvalidPromiseInstanceError unless promise instanceof Promise
      promise.done -> fulfillments.resolved.push promise
      promise.fail -> fulfillments.rejected.push promise
    checkFulfillments = ->
      # Not all promises have been fulfilled
      if fulfillments.resolved.length + fulfillments.rejected.length isnt amtPromises
        $timeout checkFulfillments, 0
      # Promises fulfilled, but some rejected
      else if fulfillments.rejected.length
        deferred.reject fulfillments
      # Promises fulfilled, and all resolved
      else
        deferred.resolve fulfillments
    checkFulfillments()
    deferred.promise()

  ###
  Returns a single promise, which is fulfilled when all `promises`
  are resolved or until a promise in `promises` is rejected.

  Params: Array of promises - Deferred().promise() instances

  Returns: promise
  ###
  @until : (promises) ->
    deferred = new Deferred()
    rawPromises = for promise in promises
      throw new InvalidPromiseInstanceError unless promise instanceof Promise
      promise.__promise__
    $q.all promises
      .then deferred.resolve, deferred.reject
    deferred.promise()

angular.module('angular-promises', [])
.factory 'Deferred', [
  '$q', '$timeout',
  (_$q_, _$timeout_) ->
    $q = _$q_
    $timeout = _$timeout_
    Deferred
]
