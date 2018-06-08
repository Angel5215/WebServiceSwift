
import Kitura
import HeliumLogger
import KituraStencil
import MongoKitten
import ExtendedJSON

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

	//	select * from espaciales.salon as salones; [Document] coordinates: [1, 2] BSON
/*	for salon in try salones.find() {
		response.send(salon.makeExtendedJSON().serializedString())
	}*/

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




Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()