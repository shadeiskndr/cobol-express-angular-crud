# Processing JSON input

You can process JSON text input in a COBOL program by using the JSON PARSE statement. The statement identifies the source data item containing the JSON text, and the receiving data item that is populated by the parser.

You can optionally also specify the following phrases:

- WITH DETAIL to indicate that messages should be generated for any nonexception and exception conditions
- ENCODING to specify the encoding assumed for the source JSON document
- NAME OF to provide alternative names for the populated data items
- SUPPRESS for data items to be excluded from assignment by the JSON parser
- CONVERTING for data items to be converted from JSON BOOLEAN name/value pairs
- ON EXCEPTION to receive control if an exception occurs
- NOT ON EXCEPTION to receive control if an exception does not occur

The JSON text input is assumed to be encoded in UTF-8 (CCSID 1208) and must be contained within an alphanumeric, national, or UTF-8 group item, or elementary data item of category alphanumeric, national, or UTF-8.
Specifying the JSON PARSE statement will pass control to the JSON parser and will read the input JSON text and populate the receiving data item using the same semantics as the equivalent COBOL MOVE statements.

Following the execution of a JSON PARSE statement, you can use these special registers to receive information from the parser:
- A non-zero JSON-CODE will indicate the kind of exception conditions that have occurred
- A non-zero JSON-STATUS will indicate the kind of nonexception conditions that have occurred