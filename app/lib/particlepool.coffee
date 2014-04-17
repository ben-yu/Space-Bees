module.exports = class ParticlePool
    @_pools: []
    @get : ->
        if @_pools.length > 0
            return @_pools.pop()
         return null
    @add : (v) ->
        @_pools.push v