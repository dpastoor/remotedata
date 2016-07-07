remotedata
=========

This package was designed to help facilitate working with data pulled from network locations by automagically managing local caching such that files
will only need to be pulled from the network once. Likewise, given the 255 character limit on paths for windows, the flat cache folder prevents problems with managing
deeply nested folder/file naming conventions.

Install the package via:

```
devtools::install_github("dpastoor/remotedata")
```

Once installed, functions will be available with the signature

```
read_remote_<datatype>
```

The following formats are already created:

* xpt - sas transport files
* sas - sas7bdat
* csv - comma separated values
* xlsx - excel files

eg.

```
read_remote_xpt
```

Each file is used by pointing to the remote file, as well as the cache *directory*

```
read_remote_xpt("remotefolder/remotefile.xpt", ".cache") #common practice to prepend a . to "system" folders not to be personally managed
```

## Creating Your Own Readers

A factory function is also available for you to give any file reader function, as long as the first argument to the reader function is the file path.
New remote readers can be created via:

```
read_remote_nonmem <- read_remote_factory(PKPDmisc::read_nonmem) #creation
read_remote_nonmem("<remotepath>/<remotefile>") #use
```

## Caching technique

The caching is done in a flat format to make it easy to see what files are avaiable and not worry about path issues. 
It is common with STDM and ADAM datasets to have concises names within a heirarchical folder structure, 
therefore a 20 character hash is derived from the absolute file path to create a unique prefix for each file. 
For example, a given files at the locations "~/compoundX/PK.xpt" and "~/compoundY/PK.xpt" the cache directory might contain files like
"b98ef5d1f7df9fb_PK.feather" and "cbc07d0bb84ec43_PK.feather".

To track the names of the files, in case you want to delete a specific file from the cache as well as to provide a 
degree of an audit trail for where data came from, a `cache_record.csv` file is created inside the cache folder that contains
information like the following:

|     remote_file     | cache_name                  | time_cached    |
|---------------------|-----------------------------|----------------|
| ~/compoundY/PK.xpt  | cbc07d0bb84ec43_PK.feather  | 7/6/2016 14:07 |
| ~/compoundX/PK.xpt  | b98ef5d1f7df9fb_PK.feather  | 7/6/2016 16:07 |


**NOTE: if you read a file while the cache_record.csv is open (for example, in excel), it locks the file from editing and therefore the cache will not be updated properly**


