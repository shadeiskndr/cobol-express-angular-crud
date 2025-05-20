# Handling JSON null values

This section describes the ways to parse JSON null values using the JSON PARSE statement.

You can parse JSON null values in one of the following ways:
- Using the IGNORING phrase to ignore JSON null values.
- Using the CONVERTING phrase to convert JSON null values to specific values.
- Using the INDICATING phrase to assign a satellite data item as a null indicator.
Details of each way are as follows.

## Ignoring JSON null values
If you want JSON null values to simply be ignored by the JSON PARSE statement, use the IGNORING phrase. You can specify individual items on the IGNORING phrase when you know in advance what items can be null, or you can use the ALL keyword to ignore all null values.

## Converting JSON null values to specific values
Use the CONVERTING phrase when you want a JSON null to be converted into a specific value in the COBOL data item where the null occurred. For example, consider the following COBOL source:
```
   `Identification division.`
Program-id. myprog.
Data division.
Working-storage section.
1 json-text pic u dynamic.
1 A.
2 B-data PIC X(10).
Procedure division.
move all 'z' to B-data
move u'{"A":{"B-data":null}}' to json-text
json parse json-text into A
converting B-data from json null using space
display "B-data: '" B-data "'"
goback.
End program myprog.
```

When compiled and run, the JSON PARSE statement encounters "B-data":null so SPACE is effectively moved into B-data, and indeed the output of this program is as follows:
```
B-data: ' '
```

Note that not all items can be used on the CONVERTING phrase due to the MOVE compatibility rules.

## Assigning a satellite data item as a null indicator
Use the INDICATING phrase in the case where you can or want to designate satellite data items as null indicators. For example, consider the following COBOL source:
```
   `Identification division.`
Program-id. myprog.
Data division.
Working-storage section.
1 json-text pic u dynamic.
1 A.
2 B-data pic x(10).
2 B-indicator pic x.
Procedure division.
move all 'z' to A.
move u'{"A":{"B-data":null}}' to json-text
json parse json-text into A
indicating B-data is json null
using 'Y' and 'N' in B-indicator
display "B-data: '" B-data "'"
display "B-indicator: " B-indicator
goback.
End program myprog.
```

When compiled and run, the JSON PARSE statement encounters "B-data":null and hence populates B-indicator with 'Y', as can be seen in the program output:

```
B-data: 'zzzzzzzzzz'
B-indicator: Y
```

Note that B-data was not populated by JSON PARSE.