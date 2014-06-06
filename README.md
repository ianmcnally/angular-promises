# angular-promises
### v 0.2.0

angular-promises is a wrapper for Angular's $q.defer that allows for chaining, ala jQuery.Deferred(), as well as a similar promise interface, with the added benefit of performing a $scope.$apply on all promise callbacks, to keep them in the angular event loop.

Additionally, Deferred provides two instances methods, `all` and `until`, that wrap an array of Deferred promise objects and returns a single promise that is fulfilled when all the input objects are fulfilled. You can use these in place of `$q.all`, with more variety.

## setup
`npm install`

## test
`npm test` - Requires [PhantomJS](http://phantomjs.org)

## use
Install via bower:
`bower install angular-promises`

Or include dist/angular-promises.js in your project.

## documentation
### Deferred
Methods (all but `promise` return deferred instance):

`resolve` - Resolve the Deferred object and call its handler

`reject` - Reject the Deferred object and call its handler

`notify` - Call the progress callback on a Deferred object

`promise` - Return the Deferred promise object

Instance methods:

`all` - Returns a single promise, which is fulfilled when all `promises` are resolved or rejected.

`until` - Returns a single promise, which is fulfilled when all `promises` are resolved or until a promise in `promises` is rejected.

### Promise

Methods (all return promise instance):

`done` - Add handler to be called when Deferred object is resolved

`fail` - Add handler to be called when Deferred object is reject

`always` - Add handler to be called when Deferred object is resolved or reject

`progress` - Add handler to be called when Deferred object sends a notification

Note: like jQuery but unlike $q, more than one callback can be registered on `done`, `fail` and `always`.

## example

```javascript
// Deferred object
var deferred = new Deferred();

// Promise
var someAsyncFunction = function() {
  var deferred = new Deferred();
  setTimeout(function(){
    deferred.resolve();
  }, 1000);
  return deferred.promise();
};
var promise = someAsyncFunction();
promise.done(onDone).fail(onFail).always(thingIAlwaysDo);

// All
var promises = [giveMeAPromise1(), giveMeAPromise2()];
Deferred.all(promise).done(successFunction).fail(failureFunction);

// Until
var promises = [giveMeAPromise1(), giveMeAPromise2()];
Deferred.until(promise).done(successFunction).fail(failureFunction);
```