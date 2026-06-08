## Summing CPU usage

The sum of CPU percentages across all processes can be calculated with:

```sh
sum=$(ps -eo pcpu --no-headers | awk '{sum+=$1} END{print sum}')
```

* `ps -eo pcpu` prints the CPU usage for each process without the header.
* The `awk` script aggregates the values.  Be careful with quoting; nested single quotes need to be escaped or the command wrapped in double quotes.

Use this pattern to avoid the syntax‑error that occurs when the shell mis‑interprets the single‑quoted `awk` program.