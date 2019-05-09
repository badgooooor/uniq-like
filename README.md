# uniq-like
"uniq"-unix command clone, a Computer Organization assignment, KMITL.

## About uniq
uniq is a command for filtering out repeated lines from text. It is also have a functionality in querying repeated line and unique line from text and counting a set of repeated line from text.

## Functions
- receive arguments from command itself by this format
```
./uniq-like -[option] filename.txt          # Run with option 
./uniq-like filename.txt                    # Run in normal mode
```
- receive arguments from stdin
```
./uniq-like       # Run the command
> [provide argument]

format
-[option] filename.txt                      # Run with option
filename.txt                                @ Run in normal mode
```
- Run program with following options
```
- "-n"(no option/default) get unique line from text file
- "-u" get only a line that showed up once
- "-d" get only a line that is repeated
```
