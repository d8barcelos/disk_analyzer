# Disk Usage Analyzer

A terminal utility written in Crystal for analyzing disk usage in a directory, listing the largest files and directories.

## Features
- Scans directories recursively
- Shows file and directory sizes in human-readable format
- Customizable number of results to display
- Sorts results by size in descending order

## Installation

First, make sure you have [Crystal](https://crystal-lang.org/install/) installed on your system.

Then compile the project:

```bash
crystal build src/disk_usage_analyzer.cr --release
```

## Usage

Basic syntax:
```bash
./disk_usage_analyzer <directory> [top_n]
```

Parameters:
- `<directory>`: The directory you want to analyze
- `[top_n]`: (Optional) Number of entries to display (default: 10)

### Example

To display the 5 largest items in your home directory:

```bash
./disk_usage_analyzer /home/user 5
```

Sample output:
```
Top 5 largest space consumers in '/home/user':
1. /home/user/videos - 15 GB
2. /home/user/downloads - 10 GB
3. /home/user/documents - 5 GB
4. /home/user/music - 2 GB
5. /home/user/pictures - 1 GB
```

## Requirements

- [Crystal](https://crystal-lang.org/install/) programming language