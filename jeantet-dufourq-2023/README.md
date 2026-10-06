# Jeantet & Dufourq (2023) as references to xeno-canto recordings

A corpus of bird songs marked by hand in 967 xeno-canto recordings of 22 species
(Jeantet, L. & Dufourq, E. 2023, Zenodo, doi:10.5281/zenodo.7828148, CC BY 4.0), given as
references to the recordings rather than copies of the audio: a record of the corpus, one region
of interest (ROI) per marked song on its xeno-canto recording, and links from each ROI to the
corpus. Made on 6 October 2026 for audioBlast's corpus pilot.

| Folder | Version |
|---|---|
| `v1/` | the corpus as published |
| `v2/` | the same 8,660 ROIs, each labelled with the current species of its xeno-canto recording in audioBlast (5 October 2026); `changelog.csv` lists the 5 labels that changed, all in XC699100 (Troglodytes aedon to Cantorchilus superciliaris) |

Every row is given under the source `jeantet-dufourq-2023`, in audioBlastIngest's layouts:

| File | Type | Rows | What |
|---|---|---|---|
| `references.csv` | references | 1 | the corpus record: title, authors, year, DOI (v1), note with its version and licence |
| `details.csv` | details | 25,965 | the record's licence, version and dates; each ROI's frequency bounds (`frequency_low`, `frequency_high`, Hz) and the label in its Sonic Visualiser point as written (`svl_label`; 19 points have none) |
| `ann-o-mate.csv` | ann-o-mate | 8,660 | one ROI per marked song: `recording_source` xeno-canto and `source_id` the XC number, start and end (s), the label as published (species, and the sound type from the file name), the corpus authors as annotators, the corpus DOI |
| `links.csv` | links | 8,660 (v2: 8,661) | each ROI `dcterms:isPartOf` its version's corpus record, with the corpus's split (`Training` or `Validation`) as qualifier; v2's record `dcterms:source` v1's (derived from) |

ROI ids are `zenodo.7828148-<version>-<XC number>-<point>`. The times were checked against the
recordings xeno-canto serves: every corpus file has the same number of samples as its source.
`v2/changelog.csv` is for reading, not for the ingest.
