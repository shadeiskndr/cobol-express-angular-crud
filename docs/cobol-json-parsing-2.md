# How to match JSON names that are not valid COBOL data names to data items

JSON allows many more characters and types of characters to appear in JSON names than COBOL allows in data names. To facilitate the match of JSON names with COBOL data names, you can use the NAME phrase on the JSON PARSE statement. Consider the following JSON text.

```
{"abc+":100}
```

The JSON name abc+ is not a valid COBOL data name but you can use the NAME phrase to match it to a valid COBOL data name. The following COBOL program illustrates how to parse that JSON text into a COBOL data item.

```
  Identification division.
     Program-id. name1.
   Data division.
    Working-storage section.
     1 mydata pic 999.
    Linkage section.
     1 json-text pic x(128).
   Procedure division using json-text.
       Json parse json-text into mydata
         name of mydata is "abc+"
       end-json.
       Display "mydata is " mydata.
       Goback.
   End program name1.
```

Notice the use of the NAME phrase. Executing the program produces the following output:

```
  mydata is 100
```

There are several important details to consider from the above example:
- Characters appearing in literal-1 on the NAME phrase are assumed to be encoded using the CCSID of the CODEPAGE compiler option in effect.
- Characters appearing in literal-1 will be matched to the JSON names in a case-sensitive manner, unlike COBOL data names which are matched in a case-insensitive manner.
- The NAME phrase, in aggregate, must not result in an ambiguous name specification1.

1. For more details about ambiguous name specifications, see the "NAME phrase" of the JSON PARSE statement in the Enterprise COBOL Language Reference.