# Handling JSON arrays

JSON arrays can be parsed into COBOL data items whose data description entries contain the OCCURS clause or the OCCURS DEPENDING ON clause. Consider the following example where JSON array named msg is parsed into the similarly named COBOL data item.

Assume the JSON text contained in data item json-text is:

```
{"some-data":{"msg":[{"ver":5,"uid":10,"txt":"Hello"},{"ver":5,"uid":11,"txt":"World"},{"ver":5,"uid":12,"txt":"!"}]}}
```

Following is a COBOL program that parses this JSON text using a fixed occurrence table with the OCCURS clause.

```
  Identification division.
    Program-id. occ1.
  Data division.
   Working-storage section.
    1 some-data.
     2 msg occurs 3.
      4 ver usage comp-1.
      4 uid pic 9999 usage display.
      4 txt pic x(32).
   Linkage section.
    1 json-text pic x(128).
  Procedure division using json-text.
      Json parse json-text into some-data
      end-json.
      If ver(1) equal to 5 then
        Display "Message ID is " uid(1)
        Display "Message text is '" txt(1) "'".
      If ver(2) equal to 5 then
        Display "Message ID is " uid(2)
        Display "Message text is '" txt(2) "'".
      If ver(3) equal to 5 then
        Display "Message ID is " uid(3)
        Display "Message text is '" txt(3) "'".
      Goback.
  End program occ1.
```

Executing the program results in this output:

```
  Message ID is 0010
  Message text is 'Hello                           '
  Message ID is 0011
  Message text is 'World                           '
  Message ID is 0012
  Message text is '!                               '
```

Parsing into a variable occurrence table with the OCCURS DEPENDING ON clause can be done similarly:

```
  Identification division.
    Program-id. odo1.
  Data division.
   Working-storage section.
    1 i pic 9.
    1 n pic 9.
    1 t pic x(128).
    1 msg_count pic 9.
    1 some-data.
     2 msg occurs 0 to 5 depending on n.
      4 ver usage comp-1.
      4 uid pic 9999 usage display.
      4 txt pic x(32).
   Linkage section.
    1 json-text pic x(128).
  Procedure division using json-text.
  Main section.
      Move 4 to n.
      Move 0 to ver(1).
      Move 0 to ver(2).
      Move 0 to ver(3).
      Move 0 to ver(4).
      Json parse json-text into some-data
      end-json.
      Perform disp_msg varying i from 1 by 1 until i > n.
      Display "Message count: " msg_count.
      Goback.
  Disp_msg section.
      If ver(i) equal to 5 then
        display "Message ID is " uid(I)
        display "Message text is '" txt(I) "'"
        add 1 to msg_count
      else
        display "Invalid Message Version, ID is " uid(I).
  End program odo1.
```

Executing the program results in this output:

```
  Message ID is 0010
  Message text is 'Hello                           '
  Message ID is 0011
  Message text is 'World                           '
  Message ID is 0012
  Message text is '!                               '
  Invalid Message Version, ID is 0001
  Message count: 3
```

Note that subordinate data items of table element msg(4) are not assigned by the JSON PARSE statement because the JSON text does not contain a fourth table entry for the msg table. Also the OCCURS DEPENDING ON object, defined in this example as n must not be subordinate to data item some-data and needs to be given a value before the JSON PARSE statement receives program control. The value of the OCCURS DEPENDING ON object is the maximum number of table elements that the JSON PARSE statement may populate. If, in the JSON text, there are more table elements than the value of the OCCURS DEPENDING ON object, then those table elements are ignored and the condition is indicated in the JSON-STATUS special register. The OCCURS DEPENDING ON object is not set or updated by the JSON PARSE statement.