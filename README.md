# NK Statements Text Analysis Code
This repo contains code and data used for the text analysis section of Dr Ellen Kim's book chapter.

## Basic requirements
* [Python](https://www.python.org/downloads/) (version 3 or greater)
* [R >4.3.0 and RStudio](https://posit.co/download/rstudio-desktop/)
* Kiwipiepy library (link)
* Fasttext (link)

### `/kcna webscraping`
This folder contains R scripts used for downloading article content from kcnawatch.org.

### `/nlpy`
This folder contains Python scripts and data used for tokenizing Korean text and sentences.

### `/nlpy/fasttext_files`
This folder contains Python scripts and data uesd for building the [fasttext](https://fasttext.cc) models for each category and using them to predict on unseen data.

### `/old`
This folder contains some deprecated R scripts used for previous modeling attempts such as CNN and GLM.

### `/preprocessing`
This folder contains R scripts that preprocess data by filtering undesired articles and splitting into sentences.

## Adding new unprocessed articles published on KCNA
If you want to download a new CSV of articles from scratch, use `kcna_korean_scrape.R`. Since starting from scratch takes a long time, this is not recommended.
If you want to add new data to a preexisting CSV of articles, use `kcna_scrape_update.R`.
More documentation (by Junah) can be found on [this Sharepoint Word document.](https://csis365.sharepoint.com/:w:/s/KoreaChairDrive/EZiUUkKA9ThMso8LHVyT8NEBwvtkIETba23wUQEIJiwlzQ?e=RNImbB)

## Processing text for use in a model
1. `preprocessing/split_sentences.R`

Input: `xlsx` Output: `csv`

2. `nlpy/tokenize_docs.py`

Input: `xlsx` Output: `xlsx`

Run in command line like so:

`python nlpy/tokenize_docs.py -i input_file -o output_file -t text_column_number`

Example:

`python nlpy/tokenize_docs.py -i sampleset.xlsx -o sampleset-tokenized.xlsx -t 2`

Note that column indexing starts from 0.

3. `preprocessing/select_documents.R`

Input: `xlsx` Output: `csv`

To convert from csv to xlsx, open the file in Excel and Save As an xlsx file.

## Building a model
1. `nlpy/fasttext_files/make_train_test.py`

Input: `xlsx` Output: `xlsx`, `txt`

Run in command line:

`python nlpy/fasttext_file/make_train_test.py -i input_file -l label`

Example:

`python nlpy/fasttext_file/make_train_test.py -i sampleset-tokenized.xlsx -l badge`

2. `nlpy/fasttext_files/build_ft_model.py`

Input: `txt` Output: `bin`

Run in command line:

`python nlpy/fasttext_file/build_ft_model.py -l label train -t train_mode`

Example:

`python nlpy/fasttext_file/build_ft_model.py -l badge train -t pretrained`

## Predict on unseen data
1. `build_ft_model.py`

Input: `txt` Output: `xlsx`

Run in command line:

`python nlpy/fasttext_file/build_ft_model.py -l label predict -i input_file`

Example:

`python nlpy/fasttext_file/build_ft_model.py -l badge predict -i unseen_sentences_tokenized.xlsx`

## Potential questions

#### How do I run command line interface commands?
Open Command Prompt or Windows Powershell in the directory with the script file. On Windows you can do this with, click File > Open Windows Powershell. If you use Mac, I don't know.

#### Isn't 750 sentences for three categories too little data?
That's correct. But given the time limit and scale of this study, that's what we went with...

#### Cross-validation?
I don't remember if fasttext comes with CV already. But I didn't implement it manually with sklearn or anything, because I forgot...

#### Comparison to other methods?
Previous methods included keyword CNN on whole articles and also trying LSTM with sentence-level data, but neither of these performed very well. I recorded the metrics here and there in the R script comments, but basically they didn't do much better or even worse than the null models.
