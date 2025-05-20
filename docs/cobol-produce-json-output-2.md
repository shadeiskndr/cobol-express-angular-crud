# Generating JSON null values

This section describes the ways to generate JSON null values using the JSON GENERATE statement.

You can use either of the following ways to generate JSON null values:
Using the CONVERTING phrase to convert certain values of COBOL data items to JSON null.
Using the INDICATING phrase to assign a satellite data item as a null indicator.
Details of each way are as follows.
Converting certain values of COBOL data items to JSON null
Use the CONVERTING phrase when you want certain values of COBOL data items to represent JSON null. For example, consider the following COBOL source:

```
   CBL CODEPAGE(1047)
   Identification division.
     Program-id. myprog.
   Data division.
    Working-storage section.
     1 json-text pic u dynamic.
     1 A.
       2 B-data PIC X(10).
   Procedure division.
       move space to B-data
       set length of json-text to 0
       json generate json-text from A
         converting B-data to json null using space
       display function display-of(json-text 1047)
       goback.
   End program myprog.
```

When compiled and run, the JSON GENERATE statement converts B-data to a JSON null when B-data contains spaces. The output of the program is as follows:

```
{"A":{"B-data":null}}
```

Note that not all items can be specified on the CONVERTING phrase due to the MOVE compatibility rules.

# Assigning a satellite data item as a null indicator
Use the INDICATING phrase in the case where you can or want to designate a satellite data item as a null indicator. For example, consider the following COBOL source:

``` 
   `CBL CODEPAGE(1047)`
Identification division.
Program-id. myprog.
Data division.
Working-storage section.
1 json-text pic u dynamic.
1 A.
2 B-data pic x(10).
2 B-indicator pic x.
Procedure division.
move "Y" to B-indicator
json generate json-text from A
indicating B-data is json null
using 'Y' in B-indicator
display function display-of(json-text 1047)
goback.
End program myprog.
```

When compiled and run, the JSON GENERATE statement generates a JSON null if B-indicator contains 'Y', as specified on the INDICATING phrase. The output of the program is as follows:

```
{"A":{"B-data":null}}
```