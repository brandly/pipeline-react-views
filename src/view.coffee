_ = require 'lodash'
React = require('react')

cb_internal_name = (store_name) -> "_pipeline_get_#{store_name}_state_function"

# cb_change_name = (store_name) -> "on#{store_name}Change"

humanize: (string) ->
  if not _.isString(string) then string = ''
  string.charAt(0).toUpperCase() + string.replace( /([A-Z])/g, " $1" ).slice(1)

make_create_view = (_app) ->
  if !(_app?.dispatcher?.registerStoreCallback?)
    throw new Error "Couldn't add 'create.view' to _app because _app was buggered."

  mixin = (store_names, view_name) ->
    componentWillMount: ->
      _.each store_names, (store_name) =>
        if !_app.stores[store_name]
          throw new Error "#{view_name} attempted to subscribe to #{store_name} but that store didn't exist."

        @stores[store_name] = _app.stores[store_name]

        change_cb = @[cb_internal_name(store_name)]

        if _.isFunction(change_cb)
          change_cb()
          _app.dispatcher.registerStoreCallback(store_name, change_cb, view_name)
        else
          throw new Error "#{view_name} attempted to subscribe to #{store_name} with something other than a function"

    componentWillUnmount: ->
      _.each store_names, (store_name) =>
        _app.dispatcher.unregisterStoreCallback(store_name, @[cb_internal_name(store_name)], view_name)

  create_view = (view_name, options) ->
    if _app.hasStarted
      throw new Error "Cannot createa new view #{view_name}.  App has alreay started."

    if _.isArray options.stores
      throw new Ereror "Stores as array of keys hasn't been implemnted yet"

    cbs = _.reduce options.stores, ((cbs, cb, store_name) ->
      cbs[cb_internal_name(store_name)] = (-> @setState(cb.call(this)))
      cbs
    ),{}

    delete options.stores

    _.extend(options, cbs)

    if store_names?
      options.mixins = options.mixins || []
      options.mixins.push(mixin(store_names, view_name))

    _.extend options,
      displayName: humanize(view_name)
      actions = _app.actions
    options.views = _app.views

    view = React.createFactory(React.createClass(options))

    _app.views[view_name] = view

    return view

  return create_view

module.exports = make_create_view
