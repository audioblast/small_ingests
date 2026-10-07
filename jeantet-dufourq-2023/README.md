# Jeantet & Dufourq (2023) as references to xeno-canto recordings

A corpus of bird songs marked by hand in 967 xeno-canto recordings of 22 species
(Jeantet, L. & Dufourq, E. 2023, Zenodo, doi:10.5281/zenodo.7828148, CC BY 4.0), given as
references to the recordings rather than copies of the audio: a record of the corpus, one region
of interest (ROI) per marked song on its xeno-canto recording, and links from each ROI to the
corpus. Made on 6 October 2026 for audioBlast's corpus pilot. `v1/` holds the corpus as
published.

Every row is given under the source `jeantet-dufourq-2023`, in audioBlastIngest's layouts:

| File | Type | Rows | What |
|---|---|---|---|
| `references.csv` | references | 1 | the corpus record: title, authors, year, DOI, note with its version and licence |
| `details.csv` | details | 8,645 | the record's licence, version and dates; the label in each ROI's Sonic Visualiser point as written (`svl_label`; 19 points have none) |
| `ann-o-mate.csv` | ann-o-mate | 8,660 | one ROI per marked song: `recording_source` xeno-canto and `source_id` the XC number, start and end (s), frequency bounds (`freq_low`, `freq_high`, Hz), the label as published (species, and the sound type from the file name), the corpus authors as annotators, the corpus DOI |
| `links.csv` | links | 8,661 | each ROI `dcterms:isPartOf` the corpus record, with the corpus's split (`Training` or `Validation`) as qualifier; the record `dcterms:type` `https://vocab.audioblast.org/Corpus` (a placeholder until the term is in the vocabulary), so corpora can be found |

ROI ids are `zenodo.7828148-v1-<XC number>-<point>`. The details' `record_source` is left empty,
as every detail is of one of the corpus's own records. The times were checked against the
recordings xeno-canto serves: every corpus file has the same number of samples as its source.

The frequency bounds were details (`frequency_low`, `frequency_high`) until 7 October 2026, when
the annomate table gained columns for them, which the API serves as Audiovisual Core's
`ac:freqLow` and `ac:freqHigh`. They are the bounds of each Sonic Visualiser point, to 0.01 Hz.
