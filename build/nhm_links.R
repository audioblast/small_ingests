# Builds nhm_links.csv, the links from BioAcoustica's Natural History Museum
# specimens to the objects that hold them in the NHM Data Portal. Run it from
# the root of this repository:
#
#   Rscript build/nhm_links.R
#
# Every specimen that BioAcoustica gives audioBLAST! with the institution code
# NHMUK and a barcode is looked up in the Data Portal's collection specimens by
# it, one request for each. A barcode is the nine figure number on the specimen
# itself, which no other specimen in the collection has, so the one object it
# matches holds the same specimen and gives a link. Registration numbers, such
# as the zoology collection's 1978.1575, are not looked up: the collections
# each register their own specimens, so the same number is a frog here and a
# crab there, and matching on one gives links to the wrong animal. The numbers
# that are no barcode, or that match no object or several, are listed at the
# end for BioAcoustica to correct, and give no link.
library(curl)
library(jsonlite)

#The specimens as audioBlastIngest reads them from BioAcoustica
SPECIMENS <- "https://raw.githubusercontent.com/BioAcoustica/audioblast_ingest/main/specimens.csv"
#The source that holds them, which the links give as their subjects' source
SUBJECT_SOURCE <- "bio.acousti.ca"
#The institution code of the specimens to look up
INSTITUTION <- "NHMUK"

#The collection specimens of the dataset at
#https://data.nhm.ac.uk/dataset/collection-specimens
PORTAL <- "https://data.nhm.ac.uk/api/3/action/datastore_search"
RESOURCE <- "05ff2255-c38a-40c9-b657-4ccb55ab2feb"
#The fields of a record that the matching needs
FIELDS <- c("occurrenceID", "scientificName", "collectionCode")
#The Data Portal identifies each object by its occurrenceID here, and answers
#for it with the record that holds it
OBJECT <- "https://data.nhm.ac.uk/object/"
#The subject and the object are the same specimen
EXACT_MATCH <- "http://www.w3.org/2004/02/skos/core#exactMatch"
#Seconds to wait between requests, to go easy on the Data Portal
PAUSE <- 0.2
#Requests that say who is asking
HANDLE <- function() {
  return(curl::new_handle(useragent=paste("audioBLAST-small-ingests/1.0",
    "(+https://github.com/audioblast/small_ingests)"), timeout=120L))
}

#The records of the collection specimens that match filters. One failed request
#is not worth losing a run of over a thousand to, so each is tried again.
portal <- function(filters, tries=3) {
  url <- paste0(PORTAL, "?resource_id=", RESOURCE,
                "&limit=10",
                "&fields=", curl::curl_escape(paste(FIELDS, collapse=",")),
                "&filters=", curl::curl_escape(toJSON(filters, auto_unbox=TRUE)))
  for (try in seq_len(tries)) {
    answer <- tryCatch({
      got <- curl::curl_fetch_memory(url, handle=HANDLE())
      if (got$status_code != 200) stop("HTTP ", got$status_code)
      fromJSON(rawToChar(got$content), simplifyVector=FALSE)
    }, error=function(e) conditionMessage(e))
    if (is.list(answer) && isTRUE(answer$success)) return(answer$result)
    if (try == tries) {
      stop("The Data Portal did not answer for ", toJSON(filters, auto_unbox=TRUE),
           ": ", if (is.character(answer)) answer else "no success")
    }
    Sys.sleep(PAUSE * 10)
  }
}

#Whether a catalogue number is a barcode, and so can be looked up. BioAcoustica
#writes a barcode it cannot read with question marks, and a few of its numbers
#have a figure too many or too few.
isBarcode <- function(number) {
  return(grepl("^[0-9]{9}$", number))
}

#The genus and the specific epithet of a determination, in lower case, and
#nothing where there is no determination. What is in brackets is dropped first:
#the Data Portal gives the subgenus and the author of the name, e.g. Uromenus
#(Bolivarius) catalaunicus (Bolivar, 1898), and a subgenus read as the epithet
#would make every name moved to another genus look like another animal.
nameParts <- function(name) {
  if (length(name) == 0 || is.na(name[1])) return(character(0))
  words <- strsplit(tolower(gsub("[^A-Za-z ]", " ", gsub("[(][^()]*[)]", " ", name[1]))), " +")[[1]]
  words <- words[words != ""]
  return(words[seq_len(min(2, length(words)))])
}

#Whether two determinations are of the same animal: they share a genus, or the
#specific epithet, which a species keeps when it is moved to another genus.
#Neither being named is no disagreement.
sameAnimal <- function(a, b) {
  a <- nameParts(a)
  b <- nameParts(b)
  if (length(a) == 0 || length(b) == 0) return(TRUE)
  if (a[1] == b[1]) return(TRUE)
  return(length(a) > 1 && length(b) > 1 && a[2] == b[2])
}

#Sources are UTF-8, and R sessions that are not (e.g. Windows R < 4.2) double
#encode non-ASCII text without being told so
specimens <- read.csv(SPECIMENS, colClasses="character", encoding="UTF-8")
specimens <- specimens[trimws(specimens$institutionCode) == INSTITUTION, , drop=FALSE]
message(nrow(specimens), " ", INSTITUTION, " specimens to look up")

links <- data.frame(subject_type=character(), subject_source=character(),
                    subject_id=character(), predicate=character(),
                    object_type=character(), object_source=character(),
                    object_id=character(), qualifier=character(),
                    remarks=character(), stringsAsFactors=FALSE)
#What each number that gave no link, or a link worth looking at, came to
notes <- data.frame(id=character(), number=character(), note=character(),
                    stringsAsFactors=FALSE)
note <- function(row, number, text) {
  notes[nrow(notes) + 1, ] <<- c(row$id, paste(row$collectionCode, number), text)
}

for (i in seq_len(nrow(specimens))) {
  if (i %% 100 == 0) message("  ", i, " of ", nrow(specimens), " looked up, ",
                             nrow(links), " links so far")
  row <- lapply(specimens[i, ], trimws)
  number <- row$catalogNumber
  if (!isBarcode(number)) {
    note(row, number, "not a barcode")
    next
  }

  #A barcode is looked up on its own: it is the whole collection's, not one
  #department's, so narrowing the search to BioAcoustica's collection code could
  #only hide a barcode that is not the one it was meant to be
  found <- portal(list(barcode=number))
  Sys.sleep(PAUSE)

  if (found$total == 0) {
    note(row, number, "no object in the Data Portal")
    next
  }
  if (found$total > 1) {
    note(row, number, paste(found$total, "objects in the Data Portal"))
    next
  }

  object <- if (length(found$records) > 0) found$records[[1]] else list()
  if (is.null(object$occurrenceID) || !nzchar(object$occurrenceID)) {
    note(row, number, "the object it matches has no occurrenceID")
    next
  }
  #The barcode says which specimen it is, so a determination that one of the two
  #has not caught up with is reported rather than kept from linking. The
  #collection the object is in is reported with it, as a barcode with a figure
  #wrong can be another department's specimen altogether.
  if (!sameAnimal(row$scientificName, object$scientificName)) {
    note(row, number, paste0("linked, but the Data Portal has ", object$scientificName,
                             " in ", object$collectionCode, ", not ", row$scientificName))
  }

  links[nrow(links) + 1, ] <- c("specimens", SUBJECT_SOURCE, row$id, EXACT_MATCH,
                                "iri", "", paste0(OBJECT, object$occurrenceID), "",
                                paste(row$collectionCode, number))
}

links <- links[order(suppressWarnings(as.numeric(links$subject_id)), links$subject_id), ,
               drop=FALSE]
csv <- file("nhm_links.csv", "wb")
write.csv(links, csv, row.names=FALSE, eol="\r\n")
close(csv)
message(nrow(links), " links written to nhm_links.csv")

#What each number came to, for BioAcoustica to work through. The numbers the
#Data Portal simply does not hold are only counted, as most of the collection's
#specimens are not published there, and so are the ones that are no barcode.
counts <- table(ifelse(startsWith(notes$note, "linked, but"),
                       "linked, but another determination", notes$note))
print(as.data.frame(counts, responseName="numbers"), row.names=FALSE)
worth <- notes[!notes$note %in% c("no object in the Data Portal", "not a barcode"), ]
if (nrow(worth) > 0) {
  message("Numbers to look at:")
  writeLines(paste0("  ", worth$number, " (specimen ", worth$id, "): ", worth$note))
}
