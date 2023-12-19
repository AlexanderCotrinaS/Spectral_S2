// Import a third-party module: snazzy
var snazzy = require("users/aazuspan/snazzy:styles");

// Adding new map styles from Snazzy
snazzy.addStyle("https://snazzymaps.com/style/235815/retro", "Retro");
snazzy.addStyle("https://snazzymaps.com/style/6376/masik-www", "Masik");
// snazzy.addStyle("https://snazzymaps.com/style/126378/vintage-old-golden-brown", "Vintage");

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Sentinel-2 Image Collection with specific filters
var S2 = ee.ImageCollection("COPERNICUS/S2_SR_HARMONIZED")
  .filterBounds(point) // Insert Point
  .filterDate("2022-07-10","2022-07-18") // Filter by date range
  .filter(ee.Filter.lt("CLOUDY_PIXEL_PERCENTAGE",5)); // Filter by metadata

// Print filtered items to the console
print("Sentinel-2 L2A Harmonized:", S2);

// Add an RGB composition to the map
Map.addLayer(S2, {min:0, max:2000, bands: ["B4","B3","B2"]}, "S2 RGB");

// Require a third-party module: spectral
var spectral = require("users/dmlmont/spectral:spectral");

// Print available indices in the module
print("Spectral Indices", spectral.indices);

// Create a function to map the collection
function addIndices(img) {
  
  // Scale the image
  img = spectral.scale(img, "COPERNICUS/S2_SR_HARMONIZED");
  
  // Define parameters for each image
  var parameters = {
    "A": img.select("B1"),
    "R": img.select("B4"),
    "G": img.select("B3"),
    "B": img.select("B2"),
    "N": img.select("B8"),
    "RE1": img.select("B5"),
    "RE2": img.select("B6"),
    "RE3": img.select("B7"),
    "N2": img.select("B8A"),
    "S1": img.select("B11"),
    "S2": img.select("B12"),
    "L": 0.5,
    "g":2.5,
    "C1":6,
    "C2": 7.5,
    "gamma": 1,
    "sla": 1,
    "epsilon": 1,
    "nexp": 2,
    "slb": 0,
  };
  
  // Calculate multiple indices
  return spectral.computeIndex(img, [
                                    "RENDVI", "ARI", "IRECI", "TCARI", "MCARI", "EVI", "SIPI",
                                    "NDII", "PSRI", "VARI",
                                    "NDVI","SR","ARVI",
                                    "ATSAVI","AVI","CIG","CIRE","DVI","EVI2","ExGR",
                                    "GBNDVI","GDVI","GLI","GNDVI","GRNDVI","GSAVI",
                                    "IPVI","MCARI705","MGRVI","MNDVI","MSAVI","MSR",
                                    "MSR705","NDVI705","NIRv","OSAVI","RVI","SAVI",
                                    "SeLI", "EMBI"
  ], parameters);
}

// Map the function over the image collection
var S2 = S2.map(addIndices);
print(S2, "S2_Indices")

// Require a third-party module: ee-palettes
var palettes = require('users/gena/packages:palettes');

// Use the viridis color palette
var Speed = palettes.cmocean.Speed[7];

// Add the image to the map
Map.addLayer(S2.first(), {min:0, max:1, bands:"EVI2", palette:Speed}, "S2 EVI");

/////////////////////////////////////////////////////////////////////////////// Select Image /////////////////////////////////
var S2_select = S2.first();

// Spectral Indices to Export
var S2_export = S2_select.select([
                                    "RENDVI", "ARI", "IRECI", "TCARI", "MCARI", "EVI", "SIPI",
                                    "NDII", "PSRI", "VARI",
                                    "NDVI","SR","ARVI",
                                    "ATSAVI","AVI","CIG","CIRE","DVI","EVI2","ExGR",
                                    "GBNDVI","GDVI","GLI","GNDVI","GRNDVI","GSAVI",
                                    "IPVI","MCARI705","MGRVI","MNDVI","MSAVI","MSR",
                                    "MSR705","NDVI705","NIRv","OSAVI","RVI","SAVI",
                                    "SeLI", "EMBI"
]); 

// Export the image to Google Drive
Export.image.toDrive({
  image: S2_export,
  description: 'S2_20m',
  folder: 'GEE', //create folder before export
  fileNamePrefix: 's2_20m',
  region: roi, //Draw roi using Map
  crs:'EPSG:32633', //UTM 
  scale: 20,
  maxPixels: 1e13
});

