###
 * @class bkcore.threejs.Loader
 *
 * Loads multiple recources, get progress, callback friendly.
 * Supports textures, texturesCube, geometries, analysers, images.
 *
 * @author Thibaut 'BKcore' Despoulain <http://bkcore.com>
###

###
 * Creates a new loader
 * @param {Object{onLoad, onError, onProgress}} opts Callbacks
###

module.exports = class Loader
    constructor: (opts) ->
        @jsonLoader = new THREE.JSONLoader()
        
        @errorCallback = if opts.onError is undefined then ((s) -> console.warn("Error while loading %s.".replace("%s", s))) else opts.onError
        @loadCallback = if opts.onLoad is undefined then (-> console.log("Loaded.")) else opts.onLoad
        @progressCallback = if opts.onProgress is undefined then ((progress, type, name) -> ) else opts.onProgress

        @types = ['textures','texturesCube','geometries','analysers','images','sounds']

        @states = {}
        @data = {}

        for t in @types
            @data[t] = {}
            @states[t] = {}

        @progress = {
            total: 0,
            remaining: 0,
            loaded: 0,
            finished: false
        }

    ###
     Load the given list of resources
     @param  {textures, texturesCube, geometries, analysers, images} data
    ###
    load: (data) =>

        for k in @types
            if data[k]?
                size = 0
                for j,l of data[k]
                    size++
                @progress.total += size
                @progress.remaining += size

        for k,t of data.textures
            @loadTexture k, t

        for k,c of data.texturesCube
            @loadTextureCube k, c

        for k,g of data.geometries
            @loadGeometry k, g

        for k,a of data.analysers
            @loadAnalyser k, a

        for k,i of data.images
            @loadImage k, i

        @progressCallback.call this, @progress

    updateState: (type, name, state) =>

        if type not in @types
            console.warn "Unknown loader type."
            return

        if state is true
            this.progress.remaining--
            this.progress.loaded++
            this.progressCallback.call(this, this.progress, type, name)

        this.states[type][name] = state

        if this.progress.loaded is this.progress.total
            this.loadCallback.call(this)

    ###
     * Get loaded resource
     * @param  string type [textures, texturesCube, geometries, analysers, images]
     * @param  string name
     * @return Mixed
    ###
    get: (type, name) =>
	
        if type not in @types
            console.warn("Unkown loader type.")
            return null

        if name not of @data[type]
            console.warn "Unknown file."
            return null

        return this.data[type][name]

    loaded: (type, name) =>

        if type not in @types
            console.warn("Unkown loader type.")
            return null

        if name not in @data[type]
            console.warn("Unkown file.")
            return null
        
        return this.states[type][name]

    loadTexture: (name, url) =>

        @updateState("textures", name, false)
        @data.textures[name] = THREE.ImageUtils.loadTexture(
            url,
            undefined,
            (=> @updateState("textures", name, true)),
            (=> @errorCallback.call(this, name))
        )

    loadTextureCube: (name, url) =>

        urls = [
            url.replace("%1", "px"), url.replace("%1", "nx"),
            url.replace("%1", "py"), url.replace("%1", "ny"),
            url.replace("%1", "pz"), url.replace("%1", "nz")
        ]

        @updateState("texturesCube", name, false)
        @data.texturesCube[name] = THREE.ImageUtils.loadTextureCube(
            urls,
            new THREE.CubeRefractionMapping(),
            (=> @updateState("texturesCube", name, true))
        )

    loadGeometry: (name, url) =>

        @data.geometries[name] = null
        @updateState("geometries", name, false)
        @jsonLoader.load(
            url,
            (a) =>
                @data.geometries[name] = a
                @updateState("geometries", name, true)
        )

    loadAnalyser: (name, url) =>

        @updateState("analysers", name, false)
        @data.analysers[name] = new bkcore.ImageData(
            url,
            () =>
                @updateState("analysers", name, true)
        )

    loadImage: (name, url) =>

        @updateState("images", name, false)
        e = new Image()
        e.onload = () =>
            @updateState("images", name, true)
        e.crossOrigin = "anonymous"
        e.src = url
        @data.images[name] = e
