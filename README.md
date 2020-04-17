# m4proc

m4proc - (c) Copyright clyvari - 2020

v1.0-a

This tool parse an input file then send it to a macro processor.

This should work independently of the input file language.

### OPTIONS

* ```m4proc --help```
* ```m4proc [--comment|-c <PATTERN>] [--m4-switch|-s <PATTERN>] [--input-file|-f <FILE>|-] [--no-m4|-n] [--pre-m4-comment|-p <PATTERN>] [--post-remove-unmarked|-r] [--macro-processor|-m <EXEC>] [<PROCESSOR_OPTIONS> [...]]```


| Argument         | Description   |
| -----------------| ------------- |
| --comment\|-c    | What combination of characters serves as a single line comment in the source language |
| --m4-switch\|-s  | Indicate the string immediatelly after the --comment that indicate a macro directive  |
| --input-file\|-f | The file to process, or - to read from stdin                                          |
| --no-m4\|-n      | No macro processing. This will show you the file that is going to be sent to the macro processor. Useful for debugging.  |
| --pre-m4-comment\|-p  | The single line comment characters in the macro processor language, and/or additional characters to mark input file lines that are not part of the processors directives. This is especially usefull if some input file language syntax could be mis-interpreted by the macro processor. This is mandatory with the -r option, or else output will be empty.  |
| --post-remove-unmarked\|-r | Remove lines that are unmarked (mark is given by --pre-m4-comment). This can be usefull to "clean" output, since a lot of empty space can be left by the macro processor. WARNING: it FORCES you to generate text from your macro that start with the value of --pre-m4-comment, or else it WILL be removed. |
| --macro-processor\|-m | The macro processor to use. |
| <PROCESSOR_OPTIONS> | All options not recognized by m4proc will be passed to the macro processor. If processor option is alreay taken by m4proc, you can pass it this way: " -x", with quotes and a leading space. |

### INFORMATIONS:

For this file to be useful, you nee to be working with an input file syntax that doesn't handle preprocessing directives.

This script as been written with m4 in mind, though it should with any macro processor.

The goal is to keep the input file syntaxically correct, but allow preprocessor directives anyway. You could then keep working on your file without having to process it every time with your macro processor.

As an example, let's say we are working with a file whose syntax for comments is `#'

Let's use the symbol `@' as the processor 'switch', to indicate to m4proc that we are not ealing with an ordinary comment, but rather a macro:

    <example1.sh>
    #@define(SYMBOL,VALUE) dnl define is a valid m4 directive

For this file to be processed by m4proc, we nee these options:
`m4proc --comment '#' --m4-switch '@' -f example1.sh`

    <example2.sh>
    #@ifdef(`RELEASE',`
    version="v0.1-release"
    #@',`
    version="v0.1-devel"
    #@')

This file also gets processed with:

      m4proc --comment '#' --m4-switch '@' -f example12.sh
      
and

      m4proc --comment '#' --m4-switch '@' -f example12.sh -DRELEASE

Please note the lines ening in ` and the lines starting with ' as this is important to avoid errors if commas are present in the generated strings.
