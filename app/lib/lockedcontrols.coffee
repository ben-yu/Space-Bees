###
 Modified FlyControls.js
 @author James Baicoianu / http://www.baicoianu.com/
###

module.exports = class LockedControls
    minNormalSpeed: 1000.0
    maxNormalSpeed: 1000.0
    maxBoosterSpeed: 1000.0
    normalAccel: 100.0
    boosterAccel: 200.0
    boostTimer: 0
    rollSpeed: 0.5
    barrelRollSpeed: 5.0

    mouseStatus: 0
    autoForward: true
    dragToLook : false
    fireStandard: false
    fireMissile: false
    prevKey: null
    rollAngle: 0
    aimMode: 0

    forwardDir : new THREE.Vector3(0,0,-1)
    tmpQuaternion : new THREE.Quaternion()
    moveVector : new THREE.Vector3(0,0,0)
    rotationVector : new THREE.Vector3(0,0,0)
    moveState:
        accelerating: 0
        up: 0
        down: 0
        left: 0
        right: 0
        forward: 1
        backward: 0
        pitchUp: 0
        pitchDown: 0
        yawLeft: 0
        yawRight: 0
        rollLeft: 0
        rollRight: 0
        boost: 0

    constructor: (ship,domElement) ->

        @domElement = ( domElement isnt undefined ) ? domElement : document
        if domElement
            @domElement.setAttribute( 'tabindex', -1 )

        @targetObject = ship
        @targetObject.useQuaternion = true

        @tmpQuaternion = new THREE.Quaternion()

        @speed = @minNormalSpeed
        @minSpeed = @minNormalSpeed
        @maxSpeed = @maxNormalSpeed

        @accel = @normalAccel

        @velocity = new THREE.Vector3(0,0,0)

        @WIDTH =  window.innerWidth
        @HEIGHT = window.innerHeight

        @cursor_x = @WIDTH/2
        @cursor_y = @HEIGHT/2

        @PI_2 = Math.PI / 2

        @enabled = false

        document.addEventListener( 'mouseup', @onMouseUp, false )
        document.addEventListener( 'mousedown', @onMouseDown, false )
        document.addEventListener( 'mousemove', @onMouseMove, false )
        document.addEventListener( 'keydown', @onKeyDown, false )
        document.addEventListener( 'keyup', @onKeyUp, false )

    onMouseDown: (event) =>

        switch ( event.button )

            when 0
                @fireStandard = true
            when 2
                @fireMissile = true


    onMouseUp: (event) =>

        switch ( event.button )

            when 0
                @fireStandard = false
            when 2
                @fireMissile = false
                missle_sound = new Howl({
                    urls: ['sounds/effects/missile_launch.wav'],
                })
                missle_sound.play()


    onMouseMove: (event) =>

        if not @dragToLook or @mouseStatus > 0

            xDiff = event.movementX or event.mozMovementX or event.webkitMovementX or 0
            yDiff = event.movementY or event.mozMovementY or event.webkitMovementY or 0

            @cursor_x += xDiff if @cursor_x + xDiff > 0 && @cursor_x + xDiff < @WIDTH
            @cursor_y += yDiff if @cursor_y + yDiff > 0 && @cursor_y + yDiff < @HEIGHT

            @updateRotationVector()

    onKeyDown: (event) =>
        #console.log "Pressed!" + event.keyCode

        switch event.keyCode

            when 16 then @aimMode = 1 # shift

            when 87 then @moveState.accelerating = 1 #w
            when 65 then @moveState.left = 1  # a
            when 83 then @moveState.back = 1  # s
            when 68 then @moveState.right = 1 # d


            when 32
                @maxSpeed = @maxBoosterSpeed # space
                @accel = @boosterAccel
                @moveState.boost = true

        @updateMovementVector()
        @updateRotationVector()


    onKeyUp: (event) =>

        switch event.keyCode

            when 16 then @aimMode = 0

            when 87 then @moveState.accelerating = 0 # w
            when 65      # a
                @moveState.left = 0
                if @prevKey is 65 and not @moveState.rollLeft
                    @moveState.rollLeft = 1
            when 83 then @moveState.back = 0 # s
            when 68      # d
                @moveState.right = 0
                if @prevKey is 68 and not @moveState.rollRight
                    @moveState.rollRight = 1

            when 32
                @maxSpeed = @maxNormalSpeed
                @accel = @boosterAccel
                @moveState.boost = false
        
        @prevKey = event.keyCode
        @updateMovementVector()
        @updateRotationVector()


    getObject: () =>
        return @targetObject

    update: (delta) =>
        if @enabled is false
            return
        
        #if @moveState.accelerating
        #    if @speed < @maxSpeed
        #        @speed += delta * @accel
        #        @speed = Math.floor(@speed)
        #else
        #   if @speed >= 0
        #        @speed -= delta * @accel
        #        @speed = Math.ceil(@speed)
        @updateMovementVector()
        @updateRotationVector()


        moveMult = delta * @speed
        rotMult = delta * @rollSpeed
        barrelMult = delta * @barrelRollSpeed

        if @moveState.rollLeft or @moveState.rollRight
            @updateRotationVector()
            @rollAngle += @rotationVector.z * barrelMult

        if Math.abs(@rollAngle) >= Math.PI
            @moveState.rollLeft = 0
            @moveState.rollRight = 0
            @rollAngle = 0
        
        @targetObject.translateX(@moveVector.x * moveMult)
        @targetObject.translateY(@moveVector.y * moveMult)
        @targetObject.translateZ(@moveVector.z * moveMult)

        @tmpQuaternion.set(@rotationVector.x * rotMult, @rotationVector.y * rotMult, @rotationVector.z * barrelMult, 1 ).normalize()
        @targetObject.quaternion.multiply(@tmpQuaternion)

        # expose the rotation vector for convenience
        @targetObject.rotation.setEulerFromQuaternion( @targetObject.quaternion, @targetObject.eulerOrder )


    updateMovementVector: () =>

        forward = ( @moveState.forward or @autoForward ) ? 1 : 0

        @moveVector.x = ( -@moveState.left + @moveState.right )
        @moveVector.y = ( -@moveState.down + @moveState.up )
        @moveVector.z =  -1

    updateRotationVector: () =>

        if @aimMode
            @rotationVector.x = 0
            @rotationVector.y = 0
            @rotationVector.z = 0
        else
            @rotationVector.x = -(@cursor_y/@HEIGHT - 0.5)
            @rotationVector.y = -(@cursor_x/@WIDTH - 0.5)
            @rotationVector.z = ( -@moveState.rollRight + @moveState.rollLeft )

    getContainerDimensions: () =>

        return { size : [ window.innerWidth, window.innerHeight ], offset : [ 0, 0 ] }

    collision: (boolean) =>

        @moveVector.x = -@moveVector.x
        @moveVector.y = -@moveVector.y
        @moveVector.z = -@moveVector.z

