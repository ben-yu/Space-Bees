###
 Modified FlyControls.js
 @author James Baicoianu / http://www.baicoianu.com/
###

module.exports = class LockedControls
    maxNormalSpeed: 10.0
    maxBoosterSpeed: 500.0
    normalAccel: 0.05
    boosterAccel: 0.07
    autoForward: false
    rollSpeed: 0.05
    mouseStatus: 0
    fireMissile: false
    moveState:
        up: 0
        down: 0
        left: 0
        right: 0
        forward: 0
        back: 0
        pitchUp: 0
        pitchDown: 0
        yawLeft: 0
        yawRight: 0
        rollLeft: 0
        rollRight: 0

    constructor: (ship,domElement) ->

        @domElement = ( domElement isnt undefined ) ? domElement : document
        if domElement
            @domElement.setAttribute( 'tabindex', -1 )

        @targetObject = ship
        @targetObject.useQuaternion = true

        @tmpQuaternion = new THREE.Quaternion()

        @speed = 0.1
        @velocity = new THREE.Vector3(0,0,0)
        @accel = new THREE.Vector3(0,0,0)
        @movement = new THREE.Vector3(0,0,0)
        @rotationVector = new THREE.Vector3(0,0,0)

        @PI_2 = Math.PI / 2

        @enabled = false

        document.addEventListener( 'mouseup', @onMouseUp, false )
        document.addEventListener( 'mousedown', @onMouseDown, false )
        document.addEventListener( 'mousemove', @onMouseMove, false )
        document.addEventListener( 'keydown', @onKeyDown, false )
        document.addEventListener( 'keyup', @onKeyUp, false )

    onMouseDown: (event) =>

        switch ( event.button )

            when 0 then @fireMissile = true
            when 2 then @fireMissile = true


    onMouseUp: (event) =>

        switch ( event.button )

            when 0 then @fireMissile = false
            when 2 then @fireMissile = false

    onMouseMove: (event) =>

        if not @dragToLook or @mouseStatus > 0

            @moveState.yawLeft  = event.movementX or event.mozMovementX or event.webkitMovementX or 0
            @moveState.pitchDown = event.movementY or event.mozMovementY or event.webkitMovementY or 0

            @updateRotationVector()

    onKeyDown: (event) =>
        #console.log "Pressed!" + event.keyCode

        switch event.keyCode

            when 37 then # left
            when 38 then # up
            when 39 then # right
            when 40 then # down

            when 87 then @moveState.forward = 1 #w
            when 65 then @moveState.left = 1  # a
            when 83 then @moveState.back = 1  # s
            when 68 then @moveState.right = 1  #d

            when 32 then @speed = @maxBoosterSpeed # space

        @updateMovementVector()
        #console.log @targetObject.position.z


    onKeyUp: (event) =>

        switch event.keyCode

            when 37 then # left
            when 38 then # up
            when 39 then # right
            when 40 then # down

            when 87 then @moveState.forward = 0 #w
            when 65 then @moveState.left = 0 # a
            when 83 then @moveState.back = 0 # s
            when 68 then @moveState.right = 0 #d

            when 32 then @speed = @maxNormalSpeed

        @updateMovementVector()

    getObject: () =>
        return @targetObject

    update: (delta) =>
        if @enabled is false
            return

        moveMult = delta * @speed
        rotMult = delta * @rollSpeed

        @targetObject.translateX(@movement.x * moveMult)
        @targetObject.translateY(@movement.y * moveMult)
        @targetObject.translateZ(@movement.z * moveMult)

        @tmpQuaternion.set(@rotationVector.x * rotMult, @rotationVector.y * rotMult, @rotationVector.z * rotMult, 1 ).normalize()
        @targetObject.quaternion.multiply(@tmpQuaternion)

        # expose the rotation vector for convenience
        @targetObject.rotation.setEulerFromQuaternion( @targetObject.quaternion, @targetObject.eulerOrder )


    updateMovementVector: () =>

        forward = ( @moveState.forward or ( @autoForward and not @moveState.back ) ) ? 1 : 0

        @movement.x = ( -@moveState.left + @moveState.right )
        @movement.y = ( -@moveState.down + @moveState.up )
        @movement.z =  -forward + @moveState.back

    updateRotationVector: () =>

        @rotationVector.x = ( -@moveState.pitchDown + @moveState.pitchUp )
        @rotationVector.y = ( @moveState.yawRight  + -@moveState.yawLeft )
        @rotationVector.z = ( -@moveState.rollRight + @moveState.rollLeft )
        #console.log 'rotate:', [ @rotationVector.x, @rotationVector.y, @rotationVector.z ]

    getContainerDimensions: () =>

        return { size : [ window.innerWidth, window.innerHeight ], offset : [ 0, 0 ] }

    collision: (boolean) =>

        @movement.x = -@movement.x
        @movement.y = -@movement.y
        @movement.z = -@movement.z

