module.exports = class ChaseCamera
    cameraCube: null
    yoffset: 50.0
    zoffset: -200.0
    viewOffset: 20.0
    lerp: 0.5

    constructor: (@camera, @targetObject) ->
        @dir = new THREE.Vector3(0,0,1)
        @up = new THREE.Vector3(0,1,0)
        @target = new THREE.Vector3()
        @speedOffset = 0
        @speedOffsetMax = 10
        @speedOffsetStep = 0.05

    update : (dt) =>
        @dir.set(0,0,1)
        @up.set(0,1,0)

        # transform to obj space
        @up.transformDirection(@targetObject.matrix)
        @dir.transformDirection(@targetObject.matrix)

        @speedOffset += (@speedOffsetMax - @speedOffset) * Math.min(1, 0.3*dt)

        @target.copy(@targetObject.position)
        @target.sub(@dir.multiplyScalar(@zoffset))
        @target.add(@up.multiplyScalar(@yoffset))
        @target.y += -@up.y + @yoffset
        @camera.position.copy(@target, @lerp)

        @camera.lookAt(@dir.normalize().multiplyScalar(@viewOffset).add(@targetObject.position))