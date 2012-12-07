noflo = require "../../lib/NoFlo"

class GetObjectKey extends noflo.Component
  constructor: ->
    @data = []
    @key = []

    @inPorts =
      in: new noflo.Port()
      key: new noflo.ArrayPort()
    @outPorts =
      out: new noflo.Port()
      object: new noflo.Port()
      missed: new noflo.Port()

    @inPorts.in.on "connect", =>
      @data = []
    @inPorts.in.on "begingroup", (group) =>
      @outPorts.out.beginGroup group
    @inPorts.in.on "data", (data) =>
      return @getKey data if @key.length
      @data.push data
    @inPorts.in.on "endgroup", =>
      @outPorts.out.endGroup()
    @inPorts.in.on "disconnect", =>
      unless @data.length
        # Data already sent
        @outPorts.out.disconnect()
        return
      
      # No key, data will be sent when we get it
      return unless @key.length

      # Otherwise send data we have an disconnect
      @getKey data for data in @data
      @outPorts.out.disconnect()

    @inPorts.key.on "data", (data) =>
      @key.push data
    @inPorts.key.on "disconnect", =>
      return unless @data.length

      @getKey data for data in @data
      @data = []
      @outPorts.out.disconnect()

  getKey: (data) ->
    throw new Error "Key not defined" unless @key.length
    throw new Error "Data is not an object" unless typeof data is "object"
    for key in @key
      if data[key] is undefined
        if @outPorts.missed.isAttached()
          @outPorts.missed.send new Error "Object has no key #{key}"
        continue
      @outPorts.out.beginGroup key
      @outPorts.out.send data[key]
      @outPorts.out.endGroup()

    return unless @outPorts.object.isAttached()
    @outPorts.object.send data
    @outPorts.object.disconnect()

exports.getComponent = ->
  new GetObjectKey
