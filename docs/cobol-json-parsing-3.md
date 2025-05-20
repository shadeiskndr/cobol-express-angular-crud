# Preventing data items from being populated by the JSON PARSE statement

It is possible you may not want specific data items subordinate to the receiver to be populated by the JSON PARSE statement. To prevent specific data items from being populated you can use the SUPPRESS phrase of the JSON PARSE statement to tell the JSON parser to ignore data items. Consider the following COBOL program:

```
  Identification division.
    Program-id. supp1.
  Data division.
   Working-storage section.
    1 msg.
     4 ver usage comp-1.
     4 uid pic 9999 usage display.
     4 txt pic x(32).
   Linkage section.
    1 json-text       pic x(128).
  Procedure division using json-text.
      Move 2 to uid.
      Json parse json-text INTO msg
        SUPPRESS uid
      end-json.
      If ver equal to 5 then
        display "Message ID is " uid
        display "Message text is '" txt "'".
      Goback.
  End program supp1.
```

Notice that the data item uid has been set in the program to the value 2 and we wish to suppress its assignment in the JSON PARSE statement using the SUPPRESS phrase. Assuming the incoming JSON text in data item json-text contains:

```
  {"msg":{"ver":5,"uid":10,"txt":"Hello"}}
```

then the execution of the program results in this output:

```
  Message ID is 0002
  Message text is 'Hello' 
```

The data item uid retained the value 2 instead of being populated with the value 10.