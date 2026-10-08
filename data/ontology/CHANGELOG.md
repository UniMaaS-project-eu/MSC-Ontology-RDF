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

## [1.2.0] - 2026-05-27
### Added
- Prefixes for IOF and skos for clear IOF-alignment
- Class mappings to classes of IOF and BFO
- New sub-classes of Resource class: MaterialResource, HumanResource, SoftwareResource, EquipmentResource 
- New class ResourceConf inserted between ProcessConfigurations and Resource nodes to allow multiple uses of the same resource in different configurations.

## [1.3.0] - 2026-12-07
### Added
- New class CharacteristicType, completing the characteristic pattern: it carries the name, measurement unit, and documentation of a kind of characteristic once, while Characteristic instances bind values to specific configurable entities. Related to qudt:QuantityKind via skos:relatedMatch.
- New object property hasCharacteristicType linking a Characteristic instance to its CharacteristicType.
- New datatype properties characteristicValue (on Characteristic) and unit (on CharacteristicType), so characteristic instances can carry literal values and their types can declare units.
- New object properties subClassOf and superClassOf (Resource to Resource), declared as owl:inverseOf each other, enabling instance-level specialization hierarchies of resources (e.g. supplier-specific material variants under a generic material resource).
- ProcessConfiguration, ResourceConf, and LogisticRoute are now subclasses of ConfigurableEntity, so hasCharacteristic and pilot datatype properties formally cover them.
- Datatype properties introduced to support the four pilot datasets.

### Changed
- IOF/BFO alignment annotations revised to direction-aware SKOS mapping properties. skos:closeMatch and skos:relatedMatch were replaced with skos:narrowMatch where the external term is narrower than the MSC class and with skos:broadMatch where the external term is broader.
- LogisticRoute endpoints generalized: the range of hasStartingPoint and hasEndingPoint changed from Location only to the union of Site, Supplier, and Location, matching how the pilot datasets connect routes directly to sites and suppliers.

### Fixed
- Malformed BFO IRIs: the bfo prefix was corrected from http://purl.obolibrary.org/obo/bfo.owl to http://purl.obolibrary.org/obo/, so bfo:BFO_0000019 (quality), bfo:BFO_0000020 (specifically dependent continuant), and bfo:BFO_0000029 (site) now resolve to valid OBO Foundry IRIs in the Site, Location, and Characteristic mappings.

### Removed
- Unused datatype properties from 1.2.0.
- Secondary skos:relatedMatch annotations pruned to keep alignments minimal.

## [1.4.0] - 2026-10-08
### Added
- New object property producesProduct (Site to Product), with inverse isProducedAt, linking each site to the finished good it produces (Adient "Finished Good Produced").
- New datatype properties latitude and longitude (decimal degrees, WGS84) on Site, Supplier and Location, mapped to geo:lat / geo:long via skos:closeMatch.
- New LogisticRoute demand properties: avgDailyDemand and maxDailyDemand (containers/day, derived from the monthly average daily demand), and demandPeriodStart / demandPeriodEnd (xsd:gYearMonth) stating the period they cover.
- New LogisticRoute lane parameters: loadState (full/empty), fullContainerValue (EUR), boxKmPerDay (container-km/day), fullRatio (share of network full box-km/day), freightCapacity (trucks) and leadTimeDaysExact (unrounded lead time in days).
- owl:priorVersion pointing to 1.3.0.

### Changed
- Unit annotations (rdfs:comment) added to the existing Adient LogisticRoute properties: leadTimeDays, emptyTruckCap, fullTruckCap, qDaysBetweenReceivingsForFTLs, qDaysBetweenEmptyReturnsFTLs and approxTransportCostFullTruck.
