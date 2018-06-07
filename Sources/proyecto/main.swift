
import Kitura
import HeliumLogger
import KituraStencil
import MongoKitten
import ExtendedJSON

//	Database configuration (2 meses)
let myDatabase = try MongoKitten.Database("mongodb://192.168.0.15/espaciales")
let salones = myDatabase["salon"] // colección en MongoDB

//	Bitácora (warnings, errores, info, verbose, etc...)
HeliumLogger.use()

//	Routing (Kitura)
let router = Router()

router.setDefault(templateEngine: StencilTemplateEngine())

// function(req, res) { }

//	router.get(path: String, handler: (Request, Response, Next) -> ())
//	Trailing Closure
router.get("/") {
	request, response, next in 
	
	//	defer se llama al final de terminar el método
	defer { next() }

	//	select * from espaciales.salon as salones; [Document] coordinates: [1, 2] BSON
	for salon in try salones.find() {
		response.send(salon.makeExtendedJSON().serializedString())
	}
}


Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()