# Producing JSON output

You can express COBOL data items as JSON text by using the JSON GENERATE statement, which identifies the source and output data items.

You can optionally also specify:
- A data item to receive the count of characters generated
- The encoding of the generated JSON document
- Alternative names for the input data items
- Data items to be excluded from the output JSON text
- Data items to be converted into JSON BOOLEAN name/value pairs
- A statement to receive control if an exception occurs

The JSON text can be used to represent a resource for the interface to a Web service, and is encoded in UTF-8 if the output data item is alphanumeric or UTF-8, or UTF-16 if the output data item is national.
Using the JSON GENERATE statement

Consider the following example:

```
01 Greeting.
 02 Msg pic x(80) value 'Hello, World!'.
01 Jtext national pic n(80).
01 i binary pic 99.
...
  JSON generate Jtext from Greeting count in i
   on exception
   display 'JSON generation error: ' json-code
   not on exception
   display function display-of(Jtext(1:i))
  End-JSON
```

The above code sequence produces the following output:

```
{"Greeting":{"msg":"Hello, World!"}}
```

The following example is more complex which illustrates optional phrases that:
- Provide alternative JSON names for the included data items (NAME)
- Allow you to exclude sensitive or unwanted information from the output (SUPPRESS)

```
01 GRP.
 05 Ac-No PIC AA9999 value 'SX1234'.
 05 More.
 10 Stuff PIC S99V9 OCCURS 2.
 05 SSN PIC 999/99/9999 value '987-65-4321'.
01 d pic x(80).
01 i binary pic 99.
 ...
 move 7.8 to stuff(1), move -9 to stuff(2)
 JSON generate d from grp count i
 NAME of stuff is 'Value' SUPPRESS ssn
 display function display-of(function national-of(
 d(1:i) 1208))
```

The example produces the following output:
```
{"GRP":{"Ac-No":"SX1234","More":{"Value":[7.8,-9.0]}}}
```

Generating JSON anonymous arrays
You can generate JSON anonymous arrays by specifying the data name of the table on the JSON GENERATE statement while using the NAME IS OMITTED phrase.
Generating JSON null values
This section describes the ways to generate JSON null values using the JSON GENERATE statement.