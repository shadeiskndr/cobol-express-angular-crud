# Parsing JSON documents

Consider a COBOL source program containing the following statements.

```
  Identification division.
    Program-id. jparse1.
  Data division.
   Working-storage section.
    1 msg.
      4 ver usage comp-1.
      4 uid pic 9999 usage display.
      4 txt pic x(32).
   Linkage section.
    1 json-text pic x(128).
  Procedure division using json-text.
      Json parse json-text into msg
      end-json.
      If ver equal to 5 then
        display "Message ID is " uid
        display "Message text is '" txt "'".
      Goback.
  End program jparse1.
```

The JSON PARSE statement above identifies data item json-text as the UTF-8 encoded source of JSON text, and data item msg-data as the receiver of the JSON values.
Assuming that data item json-text contains:

```
  {"msg":{"ver":5,"uid":1000,"txt":"Hello World!"}}
```

then the output of executing the program is:

```
  Message ID is 1000
  Message text is 'Hello World!' 
```