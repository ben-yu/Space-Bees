###
 Modified FlyControls.js
 @author James Baicoianu / http://www.baicoianu.com/
###

module.exports = class LockedControls
    maxNormalSpeed: 500.0
    maxBoosterSpeed: 1000.0
    normalAccel: 0.05
    boosterAccel: 0.07
    autoForward: false
    rollSpeed: 0.05
    barrelRollSpeed: 5.0
    mouseStatus: 0
    fireStandard: false
    fireMissile: false
    prevKey: null
    rollAngle: 0
    aimMode: 0
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
        boost: 0

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

            @moveState.yawLeft  = event.movementX or event.mozMovementX or event.webkitMovementX or 0
            @moveState.pitchDown = event.movementY or event.mozMovementY or event.webkitMovementY or 0

            #console.log event.webkitMovementX + ":" + event.webkitMovementY

            @cursor_x += @moveState.yawLeft if @cursor_x + @moveState.yawLeft > 0 && @cursor_x + @moveState.yawLeft < @WIDTH
            @cursor_y += @moveState.pitchDown if @cursor_y + @moveState.pitchDown > 0 && @cursor_y + @moveState.pitchDown < @HEIGHT

            @updateRotationVector()

    onKeyDown: (event) =>
        #console.log "Pressed!" + event.keyCode

        switch event.keyCode

            when 16 then @aimMode = 1

            when 87 then @moveState.forward = 1 #w
            when 65
                @moveState.left = 1  # a

            when 83 then @moveState.back = 1  # s
            when 68
                @moveState.right = 1  #d


            when 32
                @speed = @maxBoosterSpeed # space
                @moveState.boost = true

        #@prevKey = event.keyCode
        @updateMovementVector()
        #@updateRotationVector()


    onKeyUp: (event) =>

        switch event.keyCode

            when 16 then @aimMode = 0

            when 37 then # left
            when 38 then # up
            when 39 then # right
            when 40 then # down

            when 87 then @moveState.forward = 0 #w
            when 65
                @moveState.left = 0 # a
                if @prevKey is 65 and not @moveState.rollLeft
                    @moveState.rollLeft = 1
            when 83 then @moveState.back = 0 # s
            when 68
                @moveState.right = 0 #d
                if @prevKey is 68 and not @moveState.rollRight
                    @moveState.rollRight = 1

            when 32
                @speed = @maxNormalSpeed
                @moveState.boost = false
        
        @prevKey = event.keyCode
        @updateMovementVector()
        @updateRotationVector()


    getObject: () =>
        return @targetObject

    update: (delta) =>
        if @enabled is false
            return

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
            @updateRotationVector()

        @targetObject.translateX(@movement.x * moveMult)
        @targetObject.translateY(@movement.y * moveMult)
        @targetObject.translateZ(@movement.z * moveMult)

        @tmpQuaternion.set(@rotationVector.x * rotMult, @rotationVector.y * rotMult, @rotationVector.z * barrelMult, 1 ).normalize()
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

    getContainerDimensions: () =>

        return { size : [ window.innerWidth, window.innerHeight ], offset : [ 0, 0 ] }

    collision: (boolean) =>

        @movement.x = -@movement.x
        @movement.y = -@movement.y
        @movement.z = -@movement.z

