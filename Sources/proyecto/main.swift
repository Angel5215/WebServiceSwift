
import Kitura
import HeliumLogger
import KituraStencil
import MongoKitten
import ExtendedJSON
import GeoJSON

//	Database configuration (2 meses)
let myDatabase = try MongoKitten.Database("mongodb://localhost/espaciales")
/*//conexion para cada coleccion de la base de datos
let estacionamiento = myDatabase["estacionamiento"] // colección en MongoDB
let actividad = myDatabase["actividad"]
let comida = myDatabase["comida"]
let facultad = myDatabase["facultad"]
let representativo = myDatabase["representativo"]
let ruta = myDatabase["ruta"]*/


//	Bitácora (warnings, errores, info, verbose, etc...)
HeliumLogger.use()

//	Routing (Kitura)
let router = Router()

router.setDefault(templateEngine: StencilTemplateEngine())

// function(req, res) { }

//	router.get(path: String, handler: (Request, Response, Next) -> ())
//	Trailing Closure
router.get("/:topico") {
	request, response, next in 
	
	//	defer se llama al final de terminar el método
	defer { next() }

	guard let topico = request.parameters["topico"] else {
		try response.status(.badRequest).end()
		return
	}

		let coleccion = myDatabase[topico]

		let query = try Array(coleccion.find())

		print(query)
		print(query.count)
		response.send(query.makeExtendedJSON().serializedString())

}

//Inserción de un punto definido
router.post("/insert/:topico", middleware: BodyParser())
router.post("/insert/:topico") {
	request, response, next in

	//	defer se llama al final de terminar el método
	defer { next() }

	guard let topico = request.parameters["topico"] else {
		try response.status(.badRequest).end()
		return
	}

	let coleccion = myDatabase[topico]

	guard let values = request.body else {
		try response.status(.badRequest).end()
		return
	}

	guard case .urlEncoded(let body) = values else {
		try response.status(.badRequest).end()
		return
	}

	if let latitudCadena = body["latitud"], let longitudCadena = body["longitud"], let latitud = Double(latitudCadena), let longitud = Double(longitudCadena), let titulo = body["titulo"], let descripcion = body["descripcion"] {


		//let position = try Position(values: [longitud, latitud])
		
		let nuevo: Document = [ "type": "Feature", 
		"properties": [ "Name": titulo, "description": descripcion, "tessellate": -1, "extrude": 0, "visibility": -1 ], 
		"geometry": [ "type": "Point", "coordinates": [longitud, latitud, 0 ]]]

		try coleccion.insert(nuevo)

		response.send(nuevo.makeExtendedJSON().serializedString())

	}


}

//Buffer para buscar topicos a partir de la ubicacion actual
router.post("/buffer/:topico", middleware: BodyParser())
router.post("/buffer/:topico"){
	request, response, next in

	//	defer se llama al final de terminar el método
	defer { next() }

	guard let topico = request.parameters["topico"] else {
		try response.status(.badRequest).end()
		return
	}
	let coleccion = myDatabase[topico]

	guard let values = request.body else {
		try response.status(.badRequest).end()
		return
	}

	guard case .urlEncoded(let body) = values else {
		try response.status(.badRequest).end()
		return
	}
	
	print(body)


	if let latitudCadena = body["latitud"], let longitudCadena = body["longitud"], let latitud = Double(latitudCadena), let longitud = Double(longitudCadena), let metrosCadena = body["metros"], let metros = Double(metrosCadena){


		let position = try Position(values: [longitud, latitud])
		let punto = Point(coordinate: position)
		let geoNearOption = GeoNearOptions(near: punto, spherical: true, distanceField: "dist.calculated", maxDistance: metros)

        let geoNearStage = AggregationPipeline.Stage.geoNear(options: geoNearOption)

        let pipeline: AggregationPipeline = [geoNearStage]

        let results = Array(try coleccion.aggregate(pipeline))

        response.send(results.makeExtendedJSON().serializedString())

	}

}


Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()