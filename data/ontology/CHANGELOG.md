# Manufacturing Service Chain Ontology - CHANGELOG

## [1.0.0] - 2026-02-24
### Added
- Initial release with core entities and relationships
- Core classes: Product, Process, Resource, Supplier, Site

## [1.1.0] - 2026-03-23
### Added
- New class: ConfigurableEntity - superclass of Device, Site, Supplier, Resource, Process, Product
- New classs Location connected with object property hasLocation to classes Site and Supplier
- Added versioning information 

### Changed
- Class LogisticRoute is now connected only with class Location via the object properties hasStartingPoint and hasEndingPoint
- ProcessConfiguration nodes are now connected between them via the inverse relationships hasNextStep and hasPreviousStep
- Class Supplier is now also directly connected with Product
- Renamed Class Property to Characteristic and renamed object property hasProperty to hasCharacteristic
- Merged classes EndProduct and IntermediateProduct into one unified class Product with revised relationships
- Changed the namespace to http://unimaas-project.eu/MSCOntology

### Deprecated
- Old classed EndPoduct and iNtermediaryProduct are deleted
- Deleted unnecessary inverseOf relationships
